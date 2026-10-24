# Vina Buddy

An Android proof-of-concept for AI-assisted Gmail inbox management using natural language rules.

## Features

- **Connect Gmail** — Sign in with Google OAuth to access your inbox
- **Natural Language Rules** — Describe email rules in plain English
- **AI Classification** — LLM converts your rules into structured filters
- **Preview Before Apply** — See which emails match before making changes
- **Safe Actions Only** — Only add/remove labels; never delete or send
- **Action History** — Full audit trail of every change made

## Architecture

```
Flutter App → FastAPI Backend → Ollama (Local LLM)
                    ↕
              Gmail API
```

## Project Structure

```
app/        — Flutter mobile app
backend/    — Python FastAPI backend
infra/      — Docker and infrastructure configs
scripts/    — Development scripts
docs/       — All specifications and documentation
```

## Quick Start

### Prerequisites

- Flutter SDK
- JDK 17 (Azul Zulu recommended)
- Android SDK / Android Studio
- Python 3.11+
- Ollama
- ngrok (for physical device testing)

### Development Setup

```bash
# 1. Install dependencies
./scripts/setup_env.sh

# 2. Start Ollama with the model
ollama pull qwen2.5:3b
ollama serve

# 3. Start the backend
./scripts/run_backend.sh
# Backend runs at http://127.0.0.1:8000

# 4. Run the Flutter app:

# Option A: Android Studio / Android Emulator (Recommended for local dev - No ngrok needed!)
# Mặc định app trỏ về http://10.0.2.2:8000 (loopback IP của Android Emulator nối về localhost Mac)
# Mở máy ảo trong Android Studio (Device Manager -> Play ▶), sau đó chạy:
cd app && flutter run

# Option B: Physical Device with Ngrok
# 1. Tạo tunnel ngrok: ngrok http 8000 -> lấy https://xxxx.ngrok-free.app
# 2. Build lại APK (Bắt buộc phải build lại vì APK compile cứng URL):
cd app && flutter build apk --release --dart-define=API_BASE_URL=https://xxxx.ngrok-free.app
# 3. Cài vào điện thoại:
adb install -r build/app/outputs/flutter-apk/app-release.apk

# Option C: Desktop (macOS) hoặc Chrome
cd app && flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

### Install Pre-built APK into Android Emulator

Nếu bạn đã có máy ảo Android chạy trong Android Studio:
- **Cách 1**: Kéo thả trực tiếp file `app/build/app/outputs/flutter-apk/app-debug.apk` vào màn hình máy ảo.
- **Cách 2**: Chạy lệnh: `adb install app/build/app/outputs/flutter-apk/app-debug.apk`


## Documentation

| Document | Description |
|----------|-------------|
| [Product Spec](docs/PRODUCT_SPEC.md) | Features and requirements |
| [Architecture](docs/ARCHITECTURE.md) | System design and data flows |
| [API Contract](docs/API_CONTRACT.md) | REST API endpoints and schemas |
| [Security](docs/SECURITY.md) | Threat model and mitigations |
| [Test Plan](docs/TEST_PLAN.md) | Testing strategy and commands |
| [User Stories](docs/USER_STORIES.md) | Acceptance criteria |
| [Decisions](docs/DECISIONS.md) | Architecture Decision Records |
| [PoC Handoff & Checkpoint](docs/HANDOFF_REPORT.md) | Complete PoC checkpoint, test evidence, APK hashes & run guide |

## Security

- OAuth tokens are stored server-side only
- Email content is never persisted
- LLM prompts treat email content as data, not instructions
- All model outputs are validated before use

## License

Private — All rights reserved.
