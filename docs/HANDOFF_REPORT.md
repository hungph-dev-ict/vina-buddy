# Smart Inbox AI — Final Project Handoff Report

## 1. Executive Summary

**Smart Inbox AI** is an Android proof-of-concept application enabling personal Gmail users to manage their inboxes using natural-language rules. The system parses plain-English requests into validated structured rules, classifies recent email metadata, previews proposed label changes, and modifies Gmail labels **only upon explicit user approval**.

All technical and security requirements have been fulfilled across the full stack:
- **Zero Permanent Storage**: Email bodies and raw OAuth tokens are never logged or persisted.
- **Strictly Non-Destructive**: Delete, send, trash, and archive actions are strictly blocked by schema validation and service guardrails.
- **Resilient AI Pipeline**: LM Studio / Ollama local LLM (`qwen/qwen3-4b-2507`) with configurable fallback, sliding-window quota limits, and prompt injection defense.
- **Both Android Debug & Release APKs compiled and verified**.

---

## 2. Monorepo Architecture & Artifacts

```
vina-buddy/
├── app/                          # Flutter Mobile App (Riverpod + Material 3)
│   ├── lib/
│   │   ├── config/constants.dart
│   │   ├── models/               # EmailItem, RuleModel, PreviewModel, HealthStatus
│   │   ├── providers/            # Riverpod Notifiers (Auth, Emails, Rules)
│   │   ├── screens/
│   │   │   ├── auth_screen.dart          # Onboarding, OAuth, Sandbox mode
│   │   │   ├── inbox_screen.dart         # Email feed, pull-to-refresh, sync
│   │   │   ├── rule_builder_screen.dart  # NL input, AI rule extraction, uncertainty banner
│   │   │   ├── preview_dialog.dart       # Email approval checkboxes, apply trigger
│   │   │   ├── rules_screen.dart         # Rule list, enable/disable toggle, delete
│   │   │   └── main_navigation_screen.dart # Material 3 NavigationBar hub
│   │   ├── services/api_service.dart     # HTTP client with error mapping
│   │   └── main.dart
│   ├── test/
│   │   ├── unit/models_test.dart
│   │   ├── unit/health_status_test.dart
│   │   └── widget_test.dart
│   └── build/app/outputs/flutter-apk/    # Compiled APKs
├── backend/                      # Python 3.11+ FastAPI Service
│   ├── app/
│   │   ├── config.py             # Type-safe settings with timeout & quotas
│   │   ├── fixtures/             # Realistic synthetic email dataset
│   │   ├── llm/                  # Base protocol, Ollama, Fallback, QuotaManager, Sanitizer
│   │   ├── routers/              # Health, Auth, Gmail, Rules, Classify
│   │   ├── schemas/              # Pydantic models with strict action validation
│   │   ├── services/             # AuthService, GmailService, RulesService, ClassificationService
│   │   └── main.py
│   ├── tests/                    # 32 Pytest suites (unit, resilience, integration)
│   └── pyproject.toml
├── infra/
│   └── docker-compose.yml        # Backend + Ollama container definition
├── scripts/
│   ├── setup_env.sh              # Virtualenv + Flutter pub setup
│   ├── run_backend.sh            # Local FastAPI server
│   └── test_all.sh               # Monorepo lint & test runner
├── docs/                         # Specifications & ADRs
└── progress.md                   # Real-time phase tracker
```

---

## 3. Compiled Android APK Deliverables

| Artifact | Location | Size | SHA-256 Checksum |
|---|---|---|---|
| **Release APK** | [`app/build/app/outputs/flutter-apk/app-release.apk`](file:///Users/phamhoanghung/Documents/vina-buddy/app/build/app/outputs/flutter-apk/app-release.apk) | **49 MB** | `3a09ad2bbc2c8ca16d3942261fb59fd97dcc47d85426403c6b258feb6e487c0e` |
| **Debug APK** | [`app/build/app/outputs/flutter-apk/app-debug.apk`](file:///Users/phamhoanghung/Documents/vina-buddy/app/build/app/outputs/flutter-apk/app-debug.apk) | 146 MB | `5162a74079353c894c47e9b39cb8b92439b6685efd1ac8f810c300a065170f91` |

*Release APK is optimized with tree-shaking and adheres to the `< 50MB` non-functional constraint.*

---

## 4. Verification Evidence & Test Results

The unified monorepo verification script ([`./scripts/test_all.sh`](file:///Users/phamhoanghung/Documents/vina-buddy/scripts/test_all.sh)) passed with **100% success rate across all 39 tests**:

### A. Flutter Static Analysis & Tests
- **`flutter analyze`**: 0 errors, 0 warnings (`No issues found!`)
- **`flutter test` (7 tests passed)**:
  - `SmartInboxApp renders onboarding screen on first launch`
  - `EmailItem Model parses json correctly`
  - `RuleModel parses structured conditions, actions, and uncertainty`
  - `RuleModel copyWith updates enabled state`
  - `PreviewModel parses matches and evaluation metrics`
  - `HealthStatus Model parses JSON correctly`
  - `HealthStatus Model serializes to JSON correctly`

### B. Backend Linter & Tests
- **Ruff Linter**: `All checks passed!`
- **Pytest (32 tests passed)**:
  - **Auth & Security**: OAuth denial on empty code/user denial, session creation & token protection, session expiry detection, refresh token extension, session revocation, token leak prevention.
  - **Resilience & LLM**: Invalid JSON fallback recovery, model timeout recovery (8s limit), dual fallback failure diagnostics, sliding-window quota exhaustion (HTTP 429), prompt injection defense.
  - **Rules & Guardrails**: Rejection of `delete`, `send`, `archive`, `trash`; uncertainty flagging for low confidence; Rule CRUD operations.
  - **Gmail Service & Actions**: Metadata sync limit enforcement (max 50, snippet only, bodies excluded), duplicate Apply idempotency (no duplicate writes or errors), partial failure batch resilience (failed item does not block successful items), destructive action security guardrail.
  - **Integration**: End-to-end API flows from login -> sync -> rule creation -> preview -> apply.

---

## 5. Explicit Limitations & Notice

1. **Physical Device / Emulator Execution**:
   - `adb devices -l` confirmed that **no physical Android device is currently plugged in via USB**, and **no Android Virtual Device (AVD) is running**.
   - Therefore, automatic `adb install` could not be executed on a live device during this run.
2. **Google OAuth Production Verification**:
   - Production Google OAuth App Verification on Google Cloud Console is **pending user setup**.
   - The application is fully prepared to use real Google OAuth credentials once `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` are added to `.env`.
   - In the interim, both the Flutter app and FastAPI backend feature a full **Dev/Sandbox Mode** allowing complete end-to-end evaluation with realistic synthetic mailboxes.

---

## 6. How to Run & Verify

### Step 1: Start Backend
```bash
./scripts/run_backend.sh
# Server running at http://127.0.0.1:8000
```

---

### Step 2: Run with Android Studio & Android Emulator (Khuyến nghị cho Local Dev)

Khi chạy trên máy ảo Android (AVD) trong Android Studio, **KHÔNG CẦN NGROK** và **KHÔNG CẦN CẤU HÌNH LẠI URL** vì app đã cấu hình mặc định trỏ về `http://10.0.2.2:8000` (đây là IP loopback mà Android Emulator tự động trỏ về `localhost:8000` của máy Mac/PC).

#### Các bước thực hiện:
1. **Khởi động Máy ảo trong Android Studio**:
   - Mở **Android Studio** -> Chọn **Device Manager** (thanh công cụ bên phải hoặc menu *Tools* -> *Device Manager*).
   - Nếu chưa có máy ảo: Bấm **Create Device** (ví dụ chọn *Pixel 8*, chọn System Image Android 34/35/36 rồi bấm *Finish*).
   - Bấm nút **Play (▶)** tại máy ảo để khởi động AVD.
2. **Kiểm tra kết nối**:
   ```bash
   adb devices
   # Kết quả sẽ hiển thị: emulator-5554    device
   ```
3. **Chạy ứng dụng lên máy ảo**:
   - **Cách 1 (Từ Android Studio)**: Mở thư mục `app` trong Android Studio -> Chọn thiết bị `emulator-5554` từ thanh dropdown -> Nhấn nút **Run (Shift+F10)**.
   - **Cách 2 (Từ dòng lệnh Terminal)**:
     ```bash
     cd app && flutter run
     ```
   - **Cách 3 (Cài trực tiếp file APK đã build)**:
     Kéo thả trực tiếp file [`app/build/app/outputs/flutter-apk/app-debug.apk`](file:///Users/phamhoanghung/Documents/vina-buddy/app/build/app/outputs/flutter-apk/app-debug.apk) vào cửa sổ máy ảo Android, hoặc chạy:
     ```bash
     adb install app/build/app/outputs/flutter-apk/app-debug.apk
     ```

---

### Step 3: Dùng Ngrok cho Physical Device (Thiết bị Android thật)

> **Hỏi: Config link ngrok ở đâu và có cần build lại APK không?**
>
> 1. **Cấu hình ở đâu?**
>    - **Cách 1 (Khuyến nghị - Không sửa code)**: Truyền cờ `--dart-define=API_BASE_URL=...` khi build hoặc chạy.
>    - **Cách 2**: Sửa trực tiếp trong file [`app/lib/config/constants.dart`](file:///Users/phamhoanghung/Documents/vina-buddy/app/lib/config/constants.dart) tại biến `defaultApiBaseUrl`.
>
> 2. **Có cần build lại APK không?**
>    - **CÓ, BẮT BUỘC PHẢI BUILD LẠI (hoặc chạy lại qua `flutter run`)**: Vì file APK đóng gói sẵn (static APK) đã compile hằng số URL vào mã máy của ứng dụng. Do đó khi ngrok tạo ra URL mới, bạn cần build lại APK với URL đó.

#### Quy trình chi tiết với Ngrok:
1. Mở tunnel ngrok:
   ```bash
   ngrok http 8000
   # Lấy URL HTTPS trả về, ví dụ: https://abcxyz.ngrok-free.app
   ```
2. Build lại APK với link ngrok:
   ```bash
   cd app
   flutter build apk --release --dart-define=API_BASE_URL=https://abcxyz.ngrok-free.app
   ```
3. Cài APK mới vào điện thoại Android thật (kết nối USB Debugging):
   ```bash
   adb install -r build/app/outputs/flutter-apk/app-release.apk
   ```
   *(Hoặc chạy trực tiếp không cần build APK file: `flutter run -d <device_id> --dart-define=API_BASE_URL=https://abcxyz.ngrok-free.app`)*

---

### Step 4: Run Locally on Desktop (macOS) hoặc Chrome
```bash
# Chạy desktop macOS
cd app && flutter run -d macos --dart-define=API_BASE_URL=http://127.0.0.1:8000

# Hoặc chạy trên trình duyệt web Chrome
cd app && flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000
```
