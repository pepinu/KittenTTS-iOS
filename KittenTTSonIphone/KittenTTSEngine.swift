import Foundation
import AVFoundation

enum TTSState: Equatable {
    case loading
    case ready
    case generating
    case playing
    case error(String)
}

@MainActor
class KittenTTSEngine: ObservableObject {
    @Published private(set) var state: TTSState = .loading

    private var tts: SherpaOnnxOfflineTtsWrapper?
    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var audioNodesAttached = false
    private var currentSampleRate: Int32 = 22050
    private var currentPlaybackToken: UUID?

    struct Voice: Identifiable, Hashable {
        let id: Int
        let name: String
    }

    static let voices: [Voice] = [
        Voice(id: 0, name: "Bella"),
        Voice(id: 1, name: "Jasper"),
        Voice(id: 2, name: "Luna"),
        Voice(id: 3, name: "Bruno"),
        Voice(id: 4, name: "Rosie"),
        Voice(id: 5, name: "Hugo"),
        Voice(id: 6, name: "Kiki"),
        Voice(id: 7, name: "Leo"),
    ]

    init() {
        Task {
            setupAudioSession()
            attachAudioNodes()
            await loadModel()
        }
    }

    // MARK: - Audio Session & Engine

    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("KittenTTS: Failed to set up audio session: \(error)")
        }
    }

    private func attachAudioNodes() {
        guard !audioNodesAttached else { return }
        audioEngine.attach(playerNode)
        audioNodesAttached = true
        connectAndStartEngine(sampleRate: Double(currentSampleRate))
    }

    private func connectAndStartEngine(sampleRate: Double) {
        audioEngine.stop()
        audioEngine.disconnectNodeOutput(playerNode)

        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else {
            print("KittenTTS: Failed to create audio format for sample rate \(sampleRate)")
            return
        }

        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try audioEngine.start()
        } catch {
            print("KittenTTS: Could not start audio engine: \(error)")
        }
    }

    // MARK: - Model Loading

    private static let modelDir = "kitten-nano-en-v0_1-fp16"

    private func loadModel() async {
        let dir = Self.modelDir
        guard let modelPath = Bundle.main.path(forResource: "model.fp16", ofType: "onnx", inDirectory: dir),
              let voicesPath = Bundle.main.path(forResource: "voices", ofType: "bin", inDirectory: dir),
              let tokensPath = Bundle.main.path(forResource: "tokens", ofType: "txt", inDirectory: dir),
              let dataDir = Bundle.main.resourceURL?.appendingPathComponent("\(dir)/espeak-ng-data").path
        else {
            state = .error("Model files not found in bundle")
            return
        }

        let kittenConfig = sherpaOnnxOfflineTtsKittenModelConfig(
            model: modelPath,
            voices: voicesPath,
            tokens: tokensPath,
            dataDir: dataDir,
            lengthScale: 1.0
        )

        let modelConfig = sherpaOnnxOfflineTtsModelConfig(
            numThreads: 2,
            debug: 1,
            kitten: kittenConfig
        )

        var ttsConfig = sherpaOnnxOfflineTtsConfig(model: modelConfig)

        let wrapper = SherpaOnnxOfflineTtsWrapper(config: &ttsConfig)
        if wrapper.tts != nil {
            self.tts = wrapper
            state = .ready
            print("KittenTTS: Model loaded successfully!")
        } else {
            state = .error("Failed to initialize TTS model")
            print("KittenTTS: Failed to create TTS wrapper")
        }
    }

    // MARK: - Generate & Play

    func generate(text: String, voiceId: Int, speed: Float) {
        guard let tts = self.tts, state == .ready else { return }
        state = .generating

        let token = UUID()
        currentPlaybackToken = token

        Task.detached { [weak self] in
            let audio = tts.generate(text: text, sid: voiceId, speed: speed)

            await MainActor.run {
                guard let self = self, self.currentPlaybackToken == token else { return }

                let sampleCount = Int(audio.n)
                let sampleRate = audio.sampleRate

                guard sampleCount > 0, sampleRate > 0 else {
                    self.state = .error("Generation produced empty audio")
                    return
                }

                // Reconnect engine if sample rate changed
                if sampleRate != self.currentSampleRate {
                    self.currentSampleRate = sampleRate
                    self.connectAndStartEngine(sampleRate: Double(sampleRate))
                }

                guard let format = AVAudioFormat(standardFormatWithSampleRate: Double(sampleRate), channels: 1),
                      let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleCount))
                else {
                    self.state = .error("Failed to create audio buffer")
                    return
                }

                buffer.frameLength = AVAudioFrameCount(sampleCount)
                let samples = audio.samples
                if let dst = buffer.floatChannelData?[0] {
                    for i in 0..<sampleCount {
                        dst[i] = samples[i]
                    }
                }

                // Ensure engine is running
                if !self.audioEngine.isRunning {
                    self.connectAndStartEngine(sampleRate: Double(sampleRate))
                }

                self.state = .playing
                self.playerNode.play()
                self.playerNode.scheduleBuffer(buffer, at: nil, options: []) { [weak self] in
                    Task { @MainActor [weak self] in
                        guard let self = self, self.currentPlaybackToken == token else { return }
                        self.state = .ready
                    }
                }
            }
        }
    }

    func stop() {
        currentPlaybackToken = nil
        if playerNode.isPlaying {
            playerNode.stop()
        }
        playerNode.reset()
        if state != .ready && state != .loading {
            state = .ready
        }
    }
}
