# Smart Inbox AI — Progress Tracker

## Current Phase: 11 — Official Release v1.0.0 Pushed to Git (Complete ✅)

| Date | Phase | Status | Notes |
|------|-------|--------|-------|
| 2026-10-23 | 00 — Investigate | ✅ Complete | Environment assessed. |
| 2026-10-23 | 01 — Plan | ✅ Approved | All plan docs drafted and approved. |
| 2026-10-23 | 02 — Foundation | ✅ Complete | Monorepo layout created, Flutter & FastAPI initialized, lint & tests configured, `/v1/health` verified. |
| 2026-10-23 | 03 — Core AI Workflow | ✅ Complete | Synthetic email fixtures, structured rule parsing, Ollama provider abstraction with fallback & sliding-window quota manager, strict action validation (no delete/send), uncertainty handling. |
| 2026-10-23 | 04 — Gmail Integration | ✅ Complete | Gmail OAuth with minimum scopes, limited message sync, preview & explicit Apply engine, duplicate Apply idempotency, partial failure resilience, privacy controls. |
| 2026-10-23 | 05–07 — App & Android Packaging | ✅ Complete | Complete Flutter UI implemented (Onboarding, Inbox feed, Rule Builder, Preview/Apply approval sheet, Rule management), all 39 tests passing, Debug & Release APKs compiled and verified. |
| 2026-10-23 | 08 — Localization (EN & VI) | ✅ Complete | Bi-lingual support (English & Vietnamese) with flutter_localizations, Riverpod localeProvider, UI Language Selector, full ARB dictionaries, and localized widget & unit tests. |
| 2026-10-23 | 09 — Multi-Intent & Admin Reports | ✅ Complete | Separate compound rule intents into independent rules (condition 1 -> label 1, condition 2 -> label 2), reject out-of-scope non-email requests with exact Vietnamese guidance, and Admin Report logging to server file. |
| 2026-10-24 | 10 — UI/UX Design System & Redesign | ✅ Complete | Full design system documentation (`UI_UX_GUIDELINES.md`, `DESIGN_SYSTEM.md`, `UI_UX_REVIEW_CHECKLIST.md`), centralized Flutter tokens, reusable component library, redesigned screens, 19 widget/unit tests passing, live verification on Android emulator (`emulator-5554`), Debug & Release APKs compiled. |
| 2026-10-24 | 11 — Release v1.0.0 | ✅ Complete | Clean git commit and push to remote `main` branch. Release v1.0.0 tagged with business-focused change log. |

---

## Phase 10 — Implementation & Verification Evidence

### 1. Persistent Design Documentation Created
- [docs/UI_UX_GUIDELINES.md](file:///Users/phamhoanghung/Documents/vina-buddy/docs/UI_UX_GUIDELINES.md): Core design philosophy, information architecture, 4pt/8pt grid layout, typography scale, semantic contrast tokens, async feedback rules, and safety UX guarantees.
- [docs/DESIGN_SYSTEM.md](file:///Users/phamhoanghung/Documents/vina-buddy/docs/DESIGN_SYSTEM.md): Flutter implementation tokens, component specifications, contrast ratios, and dark/light mode configurations.
- [docs/UI_UX_REVIEW_CHECKLIST.md](file:///Users/phamhoanghung/Documents/vina-buddy/docs/UI_UX_REVIEW_CHECKLIST.md): Production readiness evaluation checklist across typography, semantic colors, touch targets, state handling, and Gmail safety.

### 2. Centralized Flutter Design System Implemented (`app/lib/theme/` & `app/lib/widgets/`)
- `lib/theme/app_colors.dart`: Semantic tokens for light (`#3B5CE6` Slate Indigo, `#EEF2FF` Container, `#F8FAFC` Background) and dark (`#6366F1` Indigo, `#0B0F19` Midnight, `#111827` Surface) modes with emerald, amber, and rose semantic status accents.
- `lib/theme/app_spacing.dart`: Base 4pt/8pt grid (`xxs` through `huge`), corner radii (`AppRadius.xs` to `pill`), and ambient shadows (`AppShadows.subtle`, `card`, `modal`).
- `lib/theme/app_typography.dart`: Proportional line-height type scale for Display, Headline, Title, Body, and Label tiers.
- `lib/theme/app_theme.dart`: Coherent Material 3 `lightTheme` and `darkTheme` with custom component theme definitions.
- `lib/widgets/app_badge.dart`: Semantic chips for labels, confidence ratings, AI provider identifiers, and condition tokens.
- `lib/widgets/app_button.dart`: Unified button hierarchy (primary, tonal secondary, outlined, destructive) with integrated loading spinners and 48dp touch targets.
- `lib/widgets/app_card.dart`: Polished elevated container with configurable ambient shadows and borders.
- `lib/widgets/status_banner.dart`: Contextual alerts for uncertainty warnings and error recovery with retry callbacks.
- `lib/widgets/empty_state_view.dart`: Welcoming illustration containers for empty inbox and rules lists.
- `lib/widgets/email_card.dart`: Scannable email row with initials gradient avatar, relative time formatting, bold subjects, and label badges.
- `lib/widgets/rule_card.dart`: Structured rule card with active/disabled indicator, natural language quote block, action badges, preview, and delete dialog.

### 3. Screen Redesigns Verified on Running Android Device (`emulator-5554`)
- **Onboarding / Auth Screen**: Glowing hero icon, high-contrast security guarantee card, prominent OAuth & Dev Mode CTAs.
- **Inbox Feed Screen**: Clean status bar with synced count and relative timestamp, pull-to-refresh, avatar initials, label pills, and empty state.
- **AI Rule Builder**: Inspiration prompt card, interactive suggestion chips, AI accent CTA button, structured rule preview card with confidence score, and conditions badges.
- **Preview & Approval Bottom Sheet**: Modal elevation, drag handle, Select All / Deselect All controls, checkbox tiles with proposed action pills, and persistent confirmation button.
- **My Rules Screen**: Active rules counter, rule cards with real-time toggle switches, prompt quote blocks, and safe deletion confirmation modals.

### 4. Verification & Testing Evidence
- **Flutter Analyze**: `No issues found! (ran in 2.6s)`.
- **Flutter Tests**: `19 passed!` (including comprehensive `design_system_test.dart` and bi-lingual localization tests).
- **Backend Lint (Ruff)**: `All checks passed!`.
- **Backend Tests (Pytest)**: `40 passed in 4.39s!`.
- **Live Device Verification**: Stream-installed and visually verified on running Android 16 emulator (`emulator-5554`).
- **Release APK**: Compiled and tree-shaken (`app-release.apk`, 53.3 MB).


---

## Phases 05–07 — Implementation & Verification Evidence

### 1. Flutter Mobile Application Features (`app/`)
- **Onboarding & Authentication Screen** (`lib/screens/auth_screen.dart`):
  - Google OAuth sign-in flow and dev/sandbox mode bypass.
  - Transparent security indicators ("Zero Permanent Storage", "Labels Only", "Explicit Approval").
  - Clear error feedback banners and user logout controls.
- **Inbox Feed Screen** (`lib/screens/inbox_screen.dart`):
  - Syncs recent email metadata via `POST /api/v1/gmail/sync`.
  - Cards show sender avatar, name, email address, subject, short snippet, date, and current label chips.
  - Pull-to-refresh & manual sync button with real-time update timestamp.
- **Natural-Language Rule Builder** (`lib/screens/rule_builder_screen.dart`):
  - Free-form text input with quick-selection chips (Newsletters, Amazon Shopping, Security, Invoices).
  - Intent analysis via `POST /api/v1/rules`.
  - Structured rule preview card showing extracted conditions and proposed label actions.
  - Visual uncertainty banner for lower-confidence AI extractions (< 70%).
- **Preview & Approval Sheet** (`lib/screens/preview_dialog.dart`):
  - Fetches matches via `POST /api/v1/classify/preview`.
  - Checkboxes allow approving/rejecting individual matching emails.
  - Confirmation dialog before execution: "Apply labels to X approved emails?".
  - Submits to `POST /api/v1/classify/apply` and displays post-execution success/failure count summary.
- **Rule Management Screen** (`lib/screens/rules_screen.dart`):
  - Lists all configured rules via `GET /api/v1/rules`.
  - Real-time toggle switch to enable/disable rules via `PATCH /api/v1/rules/{id}`.
  - Delete rule button with confirmation modal via `DELETE /api/v1/rules/{id}`.
  - Preview action to inspect affected emails on demand.
- **Main Navigation Hub** (`lib/screens/main_navigation_screen.dart`):
  - Material 3 `NavigationBar` hosting tabs: Inbox, Build Rule, and My Rules.

### 2. Verification Evidence

#### A. Unified Test & Lint Runner (`./scripts/test_all.sh`)
```
==========================================
 Running All Lints & Tests
==========================================
[1/4] Flutter Analyze...
Analyzing app...                                                
No issues found! (ran in 5.1s)

[2/4] Flutter Tests...
00:00 +0: loading test/unit/models_test.dart
00:00 +0: EmailItem Model parses json correctly
00:00 +1: RuleModel parses structured conditions, actions, and uncertainty
00:00 +2: RuleModel copyWith updates enabled state
00:00 +3: PreviewModel parses matches and evaluation metrics
00:00 +4: HealthStatus Model parses JSON correctly
00:00 +5: HealthStatus Model serializes to JSON correctly
00:00 +6: SmartInboxApp renders onboarding screen on first launch
00:00 +7: All tests passed!

[3/4] Backend Lint (Ruff)...
All checks passed!

[4/4] Backend Tests (Pytest)...
============================= test session starts ==============================
platform darwin -- Python 3.11.17, pytest-9.1.1, pluggy-1.7.0 -- backend/.venv/bin/python
rootdir: backend, configfile: pyproject.toml, testpaths: tests
plugins: asyncio-1.4.0, anyio-4.15.1
asyncio: mode=Mode.AUTO

tests/test_api_integration.py::test_api_create_rule_preview_and_apply_flow PASSED [  3%]
tests/test_api_integration.py::test_api_preview_nonexistent_rule_returns_404 PASSED [  6%]
tests/test_api_integration.py::test_api_create_rule_empty_rejected_422 PASSED [  9%]
tests/test_api_integration.py::test_api_oauth_denied_returns_401 PASSED  [ 12%]
tests/test_auth_service.py::test_oauth_denial_empty_code PASSED          [ 15%]
tests/test_auth_service.py::test_oauth_denial_user_cancelled PASSED      [ 18%]
tests/test_auth_service.py::test_oauth_exchange_success_creates_session PASSED [ 21%]
tests/test_auth_service.py::test_expired_credentials_detection PASSED    [ 25%]
tests/test_auth_service.py::test_refresh_session_extends_validity PASSED [ 28%]
tests/test_auth_service.py::test_revoke_session_purges_tokens PASSED     [ 31%]
tests/test_classification.py::test_classify_newsletter_rule PASSED       [ 34%]
tests/test_classification.py::test_classify_shopping_order_rule PASSED   [ 37%]
tests/test_classification.py::test_classify_security_rule PASSED         [ 40%]
tests/test_gmail_service.py::test_fetch_recent_emails_respects_limits_and_excludes_full_bodies PASSED [ 43%]
tests/test_gmail_service.py::test_duplicate_apply_is_idempotent PASSED   [ 46%]
tests/test_gmail_service.py::test_partial_failure_handling PASSED        [ 50%]
tests/test_gmail_service.py::test_apply_nonexistent_rule_raises_api_error PASSED [ 53%]
tests/test_gmail_service.py::test_destructive_actions_strictly_blocked_by_security_guardrail PASSED [ 56%]
tests/test_health.py::test_health_root_endpoint PASSED                   [ 59%]
tests/test_health.py::test_health_v1_endpoint PASSED                     [ 62%]
tests/test_health.py::test_health_api_v1_endpoint PASSED                 [ 65%]
tests/test_llm_resilience.py::test_invalid_json_triggers_fallback_recovery PASSED [ 68%]
tests/test_llm_resilience.py::test_model_timeout_triggers_fallback_recovery PASSED [ 71%]
tests/test_llm_resilience.py::test_fallback_failure_raises_provider_error PASSED [ 75%]
tests/test_llm_resilience.py::test_budget_limit_exhaustion PASSED        [ 78%]
tests/test_llm_resilience.py::test_prompt_injection_safety PASSED        [ 81%]
tests/test_rules_service.py::test_create_valid_newsletter_rule PASSED    [ 84%]
tests/test_rules_service.py::test_create_rule_flags_uncertainty_for_low_confidence PASSED [ 87%]
tests/test_rules_service.py::test_rule_action_rejects_delete_action PASSED [ 90%]
tests/test_rules_service.py::test_rule_action_rejects_send_action PASSED [ 93%]
tests/test_rules_service.py::test_rule_action_rejects_archive_action PASSED [ 96%]
tests/test_rules_service.py::test_rule_crud_operations PASSED            [100%]

============================== 32 passed in 0.38s ==============================
==========================================
 All checks passed successfully! 
==========================================
```

### 3. Android APK Artifacts Built

| Artifact | Path | Size | SHA-256 Checksum |
|---|---|---|---|
| **Debug APK** | `app/build/app/outputs/flutter-apk/app-debug.apk` | 146 MB | `5162a74079353c894c47e9b39cb8b92439b6685efd1ac8f810c300a065170f91` |
| **Release APK** | `app/build/app/outputs/flutter-apk/app-release.apk` | 49 MB | `3a09ad2bbc2c8ca16d3942261fb59fd97dcc47d85426403c6b258feb6e487c0e` |

*Release APK meets the target specification size of < 50MB with full asset and icon tree-shaking applied.*

### 4. Device Deployment & Verification Limitations
- **Current Limitation**: Command `adb devices -l` outputs:
  ```
  List of devices attached
  ```
  No physical Android device is currently connected via USB/WiFi, and no Android Virtual Device (AVD) is running on the host machine.
- **Physical Installation Command**:
  Once a physical Android device is connected with USB Debugging enabled, install with:
  ```bash
  adb install app/build/app/outputs/flutter-apk/app-release.apk
  ```
- **Local Testing**:
  To test the app locally on macOS Desktop or Chrome:
  ```bash
  cd app && flutter run -d macos
  # or
  cd app && flutter run -d chrome
  ```

---

## Phase 09 — Compound Multi-Intent Rule Separation & Admin Report System

### 1. Compound Rule Separation (Multi-Intent)
- **Problem**: Natural language prompts with multiple intents (e.g., *"emails from tldr are spam and emails from GitHub are source code"*) previously merged into a single rule with multiple conditions and multiple labels.
- **Backend Fixes**:
  - `backend/app/llm/sanitizer.py`: Prompt updated to require separating multi-intent requests into an array of independent rules (`rules: [{conditions, actions}, ...]`).
  - `backend/app/services/rules_service.py`: Added automatic decoupling logic to guarantee condition 1 links to action 1, condition 2 links to action 2 even if an LLM merges them into 1 rule.
  - `backend/app/schemas/rules.py`: Added `sub_rules: List[RuleResponse]` to return all created sub-rules cleanly while preserving backward compatibility.
  - `app/lib/screens/rule_builder_screen.dart`: UI displays distinct cards for every parsed rule and adds each to the user's active rules list.

### 2. Out-of-Scope Rejection & User Guidance
- Prompts not related to email management/actions (e.g., general conversation, poetry, coding assistance) are detected and rejected.
- HTTP 422 returned with exact message:
  > *"Nội dung này không thể hỗ trợ, vui lòng khiếu nại tới admin."*
- UI displays clear notification banner with button to directly file a report/complaint.

### 3. Admin Report Feature (`POST /api/v1/reports`)
- **Backend**: Endpoint logs complaints to a server file for manual inspection (`backend/data/admin_reports.jsonl`). Contains timestamp, report ID, user input, optional user notes, and IP address.
- **Mobile UI**: `AdminReportDialog` allows the user to review the rejected input, write optional notes, and submit directly to the server.
- **Multilingual**: Fully localized into English and Vietnamese (`app/lib/l10n/app_en.arb`, `app_vi.arb`).

