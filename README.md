# KittenTTS-iOS

Run [KittenTTS](https://github.com/KittenML/KittenTTS) on your iPhone. Ultra-lightweight TTS (15M params, ~25MB model) running 100% on-device via [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx). No internet required.

## Demo

https://github.com/user-attachments/assets/3df9db22-c79e-42fd-8cec-cc095cab7b19

## Features

- All 8 KittenTTS voices: Bella, Jasper, Luna, Bruno, Rosie, Hugo, Kiki, Leo
- Adjustable speech speed (0.5x – 2.0x)
- ~300ms inference on modern iPhones
- SwiftUI app, iOS 15+

## Deploy to iPhone — Step by Step

### Prerequisites

- Mac with Apple Silicon
- Xcode 15+ installed
- Homebrew packages: `brew install cmake wget xcodegen`
- An Apple Developer account (free works for personal devices)

### Step 1: Clone this repo

```bash
git clone https://github.com/pepinu/KittenTTS-iOS.git
cd KittenTTS-iOS
```

### Step 2: Build sherpa-onnx from source (~15-30 min)

KittenTTS requires sherpa-onnx built from source (pre-built versions don't include KittenTTS support yet).

```bash
cd ..
git clone https://github.com/k2-fsa/sherpa-onnx.git sherpa-onnx-build
cd sherpa-onnx-build
./build-ios.sh
cd ../KittenTTS-iOS
```

### Step 3: Copy the built frameworks

```bash
cp -R ../sherpa-onnx-build/build-ios/sherpa-onnx.xcframework Frameworks/
cp -R ../sherpa-onnx-build/build-ios/ios-onnxruntime/1.17.1/onnxruntime.xcframework Frameworks/
```

### Step 4: Download the KittenTTS model (~25MB)

```bash
curl -L -O https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/kitten-nano-en-v0_1-fp16.tar.bz2
tar xjf kitten-nano-en-v0_1-fp16.tar.bz2 -C KittenTTSonIphone/
rm kitten-nano-en-v0_1-fp16.tar.bz2
```

### Step 5: Generate the Xcode project

```bash
xcodegen generate
```

### Step 6: Open in Xcode and deploy

```bash
open KittenTTSonIphone.xcodeproj
```

1. In Xcode, select **KittenTTSonIphone** target → **Signing & Capabilities**
2. Set your **Team** (your Apple ID)
3. Connect your iPhone via USB
4. Select your iPhone as the run destination
5. Press **Cmd+R** to build and run

> First launch on a new device: go to **Settings → General → VPN & Device Management** and trust your developer certificate.

## Voices

| ID | Name   | Gender |
|----|--------|--------|
| 0  | Bella  | Female |
| 1  | Jasper | Male   |
| 2  | Luna   | Female |
| 3  | Bruno  | Male   |
| 4  | Rosie  | Female |
| 5  | Hugo   | Male   |
| 6  | Kiki   | Female |
| 7  | Leo    | Male   |

## Project Structure

```
KittenTTSonIphone/
  KittenTTSonIphoneApp.swift          # App entry point
  ContentView.swift                    # SwiftUI UI
  KittenTTSEngine.swift                # TTS engine (sherpa-onnx C API)
  SherpaOnnx.swift                     # Swift wrapper (from sherpa-onnx repo)
  KittenTTSonIphone-Bridging-Header.h  # Bridges C API to Swift
  Headers/c-api.h                      # sherpa-onnx C API header
  kitten-nano-en-v0_1-fp16/            # Model files (download in step 4)
Frameworks/                            # xcframeworks (built in step 2-3)
project.yml                            # xcodegen project spec
```

## Troubleshooting

- **"Module not found" or linker errors**: Make sure you completed steps 2-3 (building and copying frameworks)
- **"Model files not found"**: Make sure you completed step 4 (downloading the model into `KittenTTSonIphone/`)
- **Code signing errors**: Set your development team in Xcode (step 6)
- **App crashes on launch**: Verify `espeak-ng-data/` directory exists inside `KittenTTSonIphone/kitten-nano-en-v0_1-fp16/`

## Credits

- [KittenTTS](https://github.com/KittenML/KittenTTS) by KittenML
- [sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx) by k2-fsa
- Model: [kitten-nano-en-v0_1-fp16](https://github.com/k2-fsa/sherpa-onnx/releases/tag/tts-models)

## License

MIT
