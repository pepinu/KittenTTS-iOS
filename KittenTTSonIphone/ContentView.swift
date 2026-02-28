import SwiftUI

struct ContentView: View {
    @StateObject private var engine = KittenTTSEngine()
    @State private var text = "Hello! This is a test of KittenTTS running on device. The quick brown fox jumps over the lazy dog."
    @State private var selectedVoice = KittenTTSEngine.voices[0]
    @State private var speed: Float = 1.0

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                statusBanner

                TextEditor(text: $text)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal)

                voicePicker

                speedSlider

                actionButton

                Spacer()
            }
            .padding(.top)
            .navigationTitle("KittenTTS Demo")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Subviews

    private var statusBanner: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            Text(statusText)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal)
    }

    private var voicePicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Voice")
                .font(.subheadline)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(KittenTTSEngine.voices) { voice in
                        Button {
                            selectedVoice = voice
                        } label: {
                            Text(voice.name)
                                .font(.subheadline.weight(.medium))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    selectedVoice == voice
                                        ? Color.accentColor
                                        : Color(.systemGray5)
                                )
                                .foregroundColor(selectedVoice == voice ? .white : .primary)
                                .cornerRadius(20)
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    private var speedSlider: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Speed")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.1fx", speed))
                    .font(.subheadline.monospacedDigit())
                    .foregroundColor(.secondary)
            }
            Slider(value: $speed, in: 0.5...2.0, step: 0.1)
        }
        .padding(.horizontal)
    }

    private var actionButton: some View {
        Button {
            if engine.state == .playing || engine.state == .generating {
                engine.stop()
            } else {
                engine.generate(text: text, voiceId: selectedVoice.id, speed: speed)
            }
        } label: {
            HStack {
                Image(systemName: isActive ? "stop.fill" : "play.fill")
                Text(isActive ? "Stop" : "Generate")
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isActive ? Color.red : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(engine.state == .loading)
        .padding(.horizontal)
    }

    // MARK: - Helpers

    private var isActive: Bool {
        engine.state == .playing || engine.state == .generating
    }

    private var statusColor: Color {
        switch engine.state {
        case .loading: return .orange
        case .ready: return .green
        case .generating: return .blue
        case .playing: return .blue
        case .error: return .red
        }
    }

    private var statusText: String {
        switch engine.state {
        case .loading: return "Loading model..."
        case .ready: return "Ready"
        case .generating: return "Generating..."
        case .playing: return "Playing"
        case .error(let msg): return "Error: \(msg)"
        }
    }
}

#Preview {
    ContentView()
}
