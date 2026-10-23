# Smart Inbox AI — Test Plan

## 1. Testing Strategy Overview

| Level | Target | Tools | Coverage Goal |
|-------|--------|-------|---------------|
| Unit (Backend) | Services, validators, LLM output parsing | `pytest`, `pytest-asyncio` | 80%+ |
| Unit (Mobile) | Providers, models, utils | `flutter_test` | 70%+ |
| Widget (Mobile) | Individual screens and widgets | `flutter_test` | Key flows |
| Integration (Backend) | API endpoints with mock Gmail + mock LLM | `pytest`, `httpx` | All endpoints |
| Integration (E2E) | Mobile ↔ Backend | `flutter_test` + test server | Happy paths |
| Manual | Physical device testing | APK on device | All user stories |

## 2. Development Modes

### 2.1 Mock Mode (Default for development)
- Gmail Service returns hardcoded sample emails.
- LLM Provider returns predefined structured rules.
- No network calls to external services.
- Enabled by: `DEV_MODE=mock` environment variable.

### 2.2 Ollama Mode (Local LLM, mock Gmail)
- LLM calls go to local Ollama instance.
- Gmail Service still uses mock data.
- Enabled by: `DEV_MODE=ollama` environment variable.

### 2.3 Gmail Test Mode (Real Gmail, local LLM)
- Gmail connected to a real test account.
- LLM calls go to local Ollama.
- Only label operations permitted.
- Enabled by: `DEV_MODE=gmail_test` environment variable.

## 3. Backend Tests

### 3.1 Unit Tests

#### Rules Service
```bash
pytest backend/tests/test_rules_service.py -v
```
- Create rule from valid natural language → success.
- Create rule from empty string → validation error.
- Create rule with >500 chars → rejected.
- Update rule → re-runs LLM, returns new structure.
- Delete rule → removed from DB.
- Toggle enabled/disabled → state changes.

#### Classification Service
```bash
pytest backend/tests/test_classification_service.py -v
```
- Valid LLM output → parsed correctly.
- Invalid LLM output (missing fields) → `ValidationError`.
- LLM timeout → fallback triggered.
- Prompt injection in email subject → not treated as instruction.
- Empty email list → empty matches.

#### Gmail Service
```bash
pytest backend/tests/test_gmail_service.py -v
```
- Fetch emails → returns structured list.
- Apply label (existing) → success.
- Apply label (new) → creates label, then applies.
- Apply label (already applied) → idempotent, no duplicate.
- Token expired → raises `AuthExpiredError`.

#### Auth Service
```bash
pytest backend/tests/test_auth_service.py -v
```
- Valid auth code → returns session token.
- Invalid auth code → 401 error.
- Expired session → 401 on protected endpoints.
- Refresh session → new token with extended expiry.
- Revoke → clears all session data.

#### LLM Output Validator
```bash
pytest backend/tests/test_llm_validator.py -v
```
- Valid rule schema → passes.
- Unknown action type → rejected.
- Missing required fields → rejected.
- Extra unexpected fields → stripped.
- `delete` action → rejected (not in allowed set).

### 3.2 Integration Tests

```bash
pytest backend/tests/integration/ -v
```
- POST `/api/v1/rules` with mock LLM → 201 + valid rule.
- POST `/api/v1/classify/preview` → matches returned.
- POST `/api/v1/classify/apply` with mock Gmail → actions applied.
- Rate limiting → 429 after limit exceeded.
- Unauthorized requests → 401.

### 3.3 Security Tests

```bash
pytest backend/tests/security/ -v
```
- No tokens in log output.
- No email bodies in log output.
- Prompt injection test cases.
- SQL injection test cases.
- Request size limit enforcement.

## 4. Mobile Tests

### 4.1 Unit Tests
```bash
cd app && flutter test test/unit/ -v
```
- Model serialization/deserialization.
- API client error handling.
- Rule display formatting.
- Date/time formatting.

### 4.2 Widget Tests
```bash
cd app && flutter test test/widget/ -v
```
- Auth screen: shows connect button, handles sign-in flow.
- Email list: renders emails, shows loading state, handles errors.
- Rule editor: accepts input, shows validation, displays result.
- Preview screen: shows matches, apply button state.
- History screen: renders action log.

### 4.3 Integration Tests
```bash
cd app && flutter test integration_test/ -v
```
- Full rule creation flow with test backend.
- Sync → Preview → Apply flow.

## 5. Build & Package Tests

### 5.1 Android Debug Build
```bash
cd app && flutter build apk --debug
```
- Expect: Build succeeds, APK at `build/app/outputs/flutter-apk/app-debug.apk`.

### 5.2 Android Release Build
```bash
cd app && flutter build apk --release
```
- Expect: Build succeeds, APK < 50 MB.

### 5.3 Install on Physical Device
```bash
adb install build/app/outputs/flutter-apk/app-debug.apk
```
- Expect: App installs and launches on connected device.

## 6. Manual Test Scenarios

### MT-01: First-time setup
1. Install APK on Android device.
2. Open app → Auth screen appears.
3. Tap "Connect Gmail" → Google sign-in appears.
4. Sign in → Connected status shown.

### MT-02: Sync and browse emails
1. From connected state, tap "Sync".
2. Loading indicator appears.
3. Email list populates with recent emails.
4. Tap an email → metadata detail shown.

### MT-03: Create and preview a rule
1. Navigate to Rules screen.
2. Type: "Label emails from github.com as Development".
3. Tap "Create Rule".
4. Structured rule displayed for review.
5. Tap "Preview" → matching emails shown.

### MT-04: Apply actions
1. From preview screen with matches.
2. Tap "Apply".
3. Confirmation dialog appears.
4. Confirm → success summary shown.
5. Check Gmail → labels applied correctly.

### MT-05: Rule management
1. View rules list.
2. Toggle a rule off → grayed out.
3. Edit a rule → modify text, re-submit.
4. Delete a rule → confirmation, removed.

### MT-06: View action history
1. Navigate to History screen.
2. Previously applied actions visible.
3. Filter by rule → filtered list shown.

## 7. Continuous Integration Plan (Future)

For the PoC, all tests are run manually. Future CI:
```yaml
# Planned GitHub Actions workflow
- Backend: pytest on push
- Mobile: flutter test on push
- APK build: flutter build apk on tag
```

## 8. Test Data

### Sample Emails (for mock mode)
20+ emails covering:
- Newsletters (substack, medium)
- Shopping (amazon, ebay)
- Social (github notifications, linkedin)
- Finance (bank statements, receipts)
- Personal (friends, family)
- Promotions (marketing emails)

### Sample Rules
- "Label emails from github.com as Development"
- "Move newsletters to Newsletters label"
- "Label receipts and invoices as Finance"
- "Mark social media notifications as Social"
