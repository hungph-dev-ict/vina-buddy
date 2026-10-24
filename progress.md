# Vina Buddy — Progress Tracker
## Current Phase: 34 — Fix Assistant Chat Freeze, 3-Intent Coordinator & Widget Tests (Complete ✅)

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
| 2026-10-24 | 10 — UI/UX Design System & Redesign | ✅ Complete | Full design system documentation, centralized Flutter tokens, reusable component library, redesigned screens. |
| 2026-10-24 | 11 — Release v1.0.0 | ✅ Complete | Clean git commit and push to remote `main` branch. Release v1.0.0 tagged with business-focused change log. |
| 2026-10-24 | 12 — Mobile-Design Home Screen Redesign | ✅ Complete | Adaptive Material 3 (Android) and Apple HIG (iOS) Home Screen (`inbox_screen.dart`, `main_navigation_screen.dart`, `email_card.dart`), live platform toggle, verified on running Android 16 emulator (`emulator-5554`), 20 Flutter tests passing. |
| 2026-10-24 | 13 — Conversational Pivot & 2-Tab Navigation | ✅ Complete | Pivoted VinaBuddy to Conversational Email Assistant (`POST /api/v1/assistant/chat`). Removed redundant Rule Builder tab. Streamlined bottom bar to 2 tabs (Trợ lý / Assistant & Quy tắc của tôi / My Rules). Verified on Android emulator. All 45 backend & 23 Flutter tests passing. |
| 2026-10-24 | 14 — Personal & Settings Screen | ✅ Complete | Added Tab 3 "Personal" (`personal_screen.dart`) with profile avatar & email, Google OAuth/Sandbox status, reactive Light/Dark/System theme switcher (`themeModeProvider`), reactive Language switcher (`localeProvider`), and Privacy & Security guarantees. Verified on emulator. 26 Flutter tests passing. |
| 2026-10-24 | 15 — Physical Device Connectivity & Dynamic Server URL | ✅ Complete | Solved `10.0.2.2` emulator loopback socket exception on physical phones. Added INTERNET & Cleartext HTTP permissions in AndroidManifest. Added dynamic `serverUrlProvider`, AuthScreen & PersonalScreen server URL switcher dialog with Test Connection ping, and fallback offline sandbox bypass. Recompiled release APK. |
| 2026-10-24 | 16 — Disentangle Auth Loading & Distinct Account Flows | ✅ Complete | Split shared `isLoading` into `isGoogleLoading` and `isDevLoading` so only the pressed button spins. Added `_showConnectGmailDialog` in AuthScreen allowing user to connect with their personal email address in PoC mode. Dedicated Dev Mode to `dev.sandbox@vinabuddy.ai`. Recompiled release APK. |
| 2026-10-24 | 17 — Conversational Rule Builder & LLM Classification Monitor | ✅ Complete | Redesigned label workflow: tapping "Gán nhãn email" prompts user for rule description with examples. Parsing natural language rules adds and saves them directly to My Rules (`rules_service`). Rejects invalid or out-of-scope non-rules with helpful guidance. Added dev monitor banner to all assistant responses showing classified intent group, confidence percentage, and provider/model. Added UI Dev badge in chat bubble. 48 backend & 26 Flutter tests passing. |
| 2026-10-24 | 18 — Authentic Google SSO (OAuth 2.0 Web Flow) & Real Gmail API | ✅ Complete | Implemented authentic Google OAuth 2.0 consent & web flow (`GET /auth/google/url`, `GET /auth/google/callback`, `GET /auth/google/poll`, `POST /auth/google/config`). Integrated real Google Gmail API in `gmail_service.py` to fetch real message headers/snippets (`gmail.googleapis.com/v1/users/me/messages`), create/read real Gmail labels (`users/me/labels`), and modify labels on real messages (`users/me/messages/{id}/modify`). Added Android deep link `vinabuddy://auth` and in-app OAuth configuration setup. 50 backend & 26 Flutter tests passing. Recompiled release APK. |
| 2026-10-24 | 19 — Strict LLM Boundary & Confidence JSON Headers | ✅ Complete | Enforced strict 2-step LLM boundary: (1) Call 1 on user input classifies into 4 intents (`stats`, `classify`, `label`, `other`) with confidence scores JSON output at top of reply; (2) Hardcoded fixed response when user selects label; (3) Call 2 on rule input validates `is_valid_rule: true | false`, condition & label JSON at top of reply; (4) Zero LLM calls for inbox operations (100% deterministic code tools). 51 backend tests & 26 Flutter tests passing. Recompiled release APK. |
| 2026-10-24 | 20 — Production Google SSO Credentials & Zero-Config Mobile Flow | ✅ Complete | Ingested genuine Web OAuth credentials (`548888108664-ai02lqldvrsam9lamdeq5c81h8ga9h4b...` & `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`) in `backend/.env`. Removed manual credential dialog `_showGoogleOAuthConfigDialog` completely from mobile UI. Users directly tap 'Connect Gmail' to launch Google SSO. All 26 Flutter & 51 backend tests pass. Recompiled release APK. |
| 2026-10-24 | 21 — Cloudflare HTTPS Public Tunnel for Real Android Wi-Fi SSO | ✅ Complete | Launched persistent Cloudflare Tunnel (`bass-toll-displays-emacs.trycloudflare.com`) routing to local backend on port 8000. Configured `GOOGLE_REDIRECT_URI` in `.env` to public HTTPS domain. Set Flutter `defaultApiBaseUrl` to tunnel URL for cable-free Wi-Fi/4G testing on physical Android devices. Recompiled release APK. |
| 2026-10-24 | 22 — Fix OAuth Token Exchange Redirect URI Mismatch | ✅ Complete | Eliminated hardcoded localhost redirect_uri in `google_callback`. Dynamically extract matched redirect URI from `settings.GOOGLE_REDIRECT_URI` or `request.url`. Enhanced Google token error inspection. Reloaded backend server. |
| 2026-10-24 | 23 — Fix Post-Login Dialog Stack Mismatch | ✅ Complete | Identified dialog dismissal popping root route. Replaced with rootNavigator check. |
| 2026-10-24 | 24 — Resolve Deep Link Navigator Black Screen | ✅ Complete | Disabled Flutter automatic deep-link routing (`flutter_deeplinking_enabled: false`) in AndroidManifest. Overrode `onNewIntent` in MainActivity. Added `appNavigatorKey.currentState?.pushAndRemoveUntil` and `KeyedSubtree` to cleanly purge Navigator stack and present `MainNavigationScreen`. Replaced DecoratedBox ListTile with Row in PersonalScreen. All 51 backend & 27 Flutter tests passing. Recompiled release APK. |
| 2026-10-24 | 25 — Wire Live Gmail API into Conversational Assistant | ✅ Complete | Extracted Authorization Bearer token in `POST /assistant/chat`. Passed live Google OAuth access_token to `get_inbox_statistics`, `get_inbox_classification`, and `preview_rule`. Purged mock synthetic fixtures on live fetch. Tested with 52 backend & 27 mobile tests. |
| 2026-10-24 | 26 — Eliminate Silent Dummy Fallback & Persist Google Sessions | ✅ Complete | Persisted sessions and tokens to disk (`.sessions_store.json`) across uvicorn reloads. Added auto-refresh for Google access tokens using refresh_token. Completely eliminated silent dummy email fallback on live Google accounts. Surfaced actionable Gmail API activation URL with direct link for project 548888108664. All 52 backend and 27 Flutter tests pass. |
| 2026-10-24 | 27 — Transformation into vnverse | ✅ Complete | Transformed product into `vnverse` virtual office. Hierarchy established: User as Giám đốc, Coordinator as Trợ lý Giám đốc, creator as Bộ trưởng vnverse, and first specialist Thầy Cúng with 3 capabilities. Added Friends tab, Recruitment Market, dedicated Agent Chat, on-device local storage persistence, out-of-scope handoff routing, and 100% Vietnamese tone. 56 backend tests and 44 Flutter tests passing. |
| 2026-10-24 | 28 — Chat Harmonization, Dismissal Flow & Static Config | ✅ Complete | 1) Dynamic Tab 0 title matching assistant name. 2) Tab 1 renamed to 'Nhân viên'. 3) Assistant chat bubbles & pill input bar harmonized with employee chat. 4) Staff dismissal with chat history retention, input guard banner, and show/hide toggle. 5) In-app server URL UI removed; clear uncommentable backend environments in constants.dart for Android emulator, real device via Ngrok, and localhost. 57 backend & 48 Flutter tests pass (0 analyzer warnings). |
| 2026-10-24 | 29 — Modular Agent Structure & Dynamic LLM Scope Classification | ✅ Complete | 1) Modular agent directory pattern (`backend/app/agents/<agent_name>/` and `app/lib/agents/<agent_name>/`) where adding new agents requires only copying folder with `definition.json`, `system_prompt.txt`, and `handler.py`. 2) Dynamic LLM intent & scope classification replacing hardcoded heuristics. 3) Cross-agent capability routing via Coordinator and escalation to 'Bộ trưởng vnverse'. 4) Permission gate on Recruitment Market checking required permissions (e.g. Gmail) before hiring. 60 backend & 48 Flutter tests pass. |
| 2026-10-24 | 30 — Fix Null Subtype Error in FriendsScreen & Widget Tests | ✅ Complete | Diagnosed and resolved `type 'Null' is not a subtype of type 'bool' of 'function result'` occurring in `RecruitedAgent.isDismissed` when hot-reloading legacy in-memory heap instances. Made `_isDismissed` nullable backing field with safe fallback getter (`_isDismissed ?? false`), added defensive comparison `a.isDismissed != true` in `friends_screen.dart`, executed hot restart via DTD MCP, and authored 3 new widget tests covering legacy deserialization, empty state navigation, and employee renaming (51/51 Flutter tests passing). |
| 2026-10-24 | 31 — Dynamic Capability Scoring Header & Workplace Prayers | ✅ Complete | 1) Dynamic AI Dev Monitor header scoring query against agent's specific defined capabilities (`traditional_offerings_and_prayers`, `lunar_day_reminder`, `vietnamese_traditional_holidays`, `other`) instead of hardcoded Gmail categories. 2) Thầy Cúng handles 'bài cúng cho dự án đang cháy' as `traditional_offerings_and_prayers` (0.95 score) delivering dedicated văn khấn Thần Code / Thần Cloud / Thần Mạng. 3) Coordinator fallback scans all platform agent skills dynamically and escalates out-of-company tasks to Bộ trưởng vnverse. All 61 backend & 52 Flutter tests passing. |
| 2026-10-24 | 32 — Purge Hardcoded Frontend ThayCungKnowledgeEngine | ✅ Complete | Completely removed `thay_cung_knowledge_engine.dart` and `thay_cung_knowledge_engine_test.dart` from the mobile project. Cleaned `app_providers.dart` so `AgentChatNotifier` uses a purely generic, agnostic network communication & error handling pattern. No agent-specific logic remains on frontend. Ran `flutter analyze` (0 warnings) and `flutter test` (all 46 tests passing). |
| 2026-10-24 | 33 — Cultural Holiday Knowledge Engine & Agent Chat Widget Test | ✅ Complete | 1) Diagnosed and fixed missing handler branch for `vietnamese_traditional_holidays` in `backend/app/agents/thay_cung/handler.py`. Thầy Cúng now delivers rich, culturally accurate responses for Tết Đoan Ngọ (Mùng 5/5 Âm, diệt sâu bọ, cơm rượu nếp, mận hậu), Tết Hàn Thực, Vu Lan, Trung Thu, Ông Công Ông Táo, Giỗ Tổ Hùng Vương thay vì rơi xuống câu chào mặc định. 2) Added backend test `test_assistant_chat_thay_cung_tet_doan_ngo_answers_cultural_holiday` (62/62 passed). 3) Implemented `/flutter-add-widget-test` in `app/test/widget/agent_chat_screen_test.dart` asserting input flow, chat bubble rendering, and AI Dev Monitor capability header (all 47 Flutter tests passed). |
| 2026-10-24 | 34 — Fix Assistant Freeze, 3-Intent Coordinator & Widget Tests | ✅ Complete | 1) Diagnosed and resolved assistant freeze root causes (expired Cloudflare tunnel URL, missing HTTP timeout, and riverpod watch bug on recruitment button). 2) Re-aligned Assistant Coordinator to 3 core intents (`recommend_agent`, `chitchat`, `out_of_scope` for politics/ethics). 3) Created `app/test/widget/chat_assistant_screen_test.dart` with 7 comprehensive widget tests (all passing). 4) 20/20 backend tests, 61/61 Flutter tests passing, hot reloaded on Android emulator. |


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

---

## Phase 10 — VinaBuddy Conversational Assistant & Strict LLM Boundaries

### 1. Vision & Architectural Pivot
- **Core Concept**: Shifted from an email reader/feed client into a privacy-first **VinaBuddy AI Assistant**.
- **Privacy Assurance**: The app **does not render customer email feeds**. Instead, users interact with the assistant via chat and structured overview summaries.
- **Strict LLM Boundary**:
  - LLM only performs **Intent Classification & Parameter Extraction**.
  - Exactly 3 supported features:
    1. `stats`: Email statistics (inbox total, unread counts, top senders, category breakdown).
    2. `classify`: Email smart categorization with description & sample senders.
    3. `label`: Natural language rule creation and preview proposal with explicit user approval required.
    4. `other`: Rejects out-of-scope queries (weather, general QA, or unsupported delete/send operations) and presents **3 quick action buttons**.

### 2. Backend Implementation
- `backend/app/schemas/assistant.py`: `AssistantIntent`, `EmailStatsPayload`, `EmailClassifyPayload`, `CleanupProposalPayload`, `ChatRequest`, and `ChatResponse`.
- `backend/app/services/gmail_service.py`: Added deterministic `get_inbox_statistics()` and `get_inbox_classification()` methods that safely aggregate metadata without exposing email bodies.
- `backend/app/services/assistant_service.py`: LLM intent classifier prompt with resilient heuristics, tool dispatching, and fallback rule caching.
- `backend/app/routers/assistant.py`: `POST /api/v1/assistant/chat` endpoint.
- `backend/tests/test_assistant.py`: 5 automated tests verifying intent classification, payload generation, and rejection boundaries (45/45 backend pytest tests passing).

### 3. Flutter Mobile Implementation
- `app/lib/models/assistant_chat.dart`: Typed models for chat stream, statistics data, category classification, and cleanup proposals.
- `app/lib/services/api_service.dart`: Added `sendAssistantMessage` method.
- `app/lib/providers/app_providers.dart`: Added `ChatAssistantNotifier` and `chatAssistantProvider`.
- `app/lib/screens/chat_assistant_screen.dart`: Rich conversational UI featuring:
  - Header with VinaBuddy avatar, online status indicator, and instant language switch (EN/VI).
  - 3 prominent action shortcut chips: `📊 Thống kê email`, `📁 Phân loại email`, `🏷️ Gắn nhãn email`.
  - In-chat interactive cards:
    - `StatsCardWidget`: Total/unread metric cards, category distribution with color dots, top senders ranking.
    - `ClassificationCardWidget`: Category breakdown cards with email counts and sample senders.
    - `ProposalCardWidget`: Labeling proposal with preview matching count, sample subjects, and **"Phê duyệt & Áp dụng" (Approve & Apply)** button.
- `app/lib/screens/main_navigation_screen.dart`: `ChatAssistantScreen` placed as central Home tab (Tab 0).
- Localized in English & Vietnamese (`app_en.arb`, `app_vi.arb`).
- 23/23 Flutter tests passing with 0 analyze issues.

## Phase 28: Refine vnverse Coordinator, Market Recruitment Filtering & Spiritual Intent Routing

### Summary of Enhancements:
1. **Trợ lý Điều phối vnverse (`chat_assistant_screen.dart`)**:
   - Bỏ toàn bộ các nút/gợi ý liên quan đến email (Thống kê email, Phân loại email, Gắn nhãn email) - dành riêng cho Thư ký Email sắp ra mắt.
   - Bổ sung phím tắt Điều phối vnverse: `Tra cứu ngày cúng 🏮`, `Chợ tuyển dụng 🎪`, `Danh sách nhân sự 👥`.
   - Cập nhật thông điệp trạng thái hệ thống thành `vnverse đang xử lý yêu cầu...`.

2. **Chợ tuyển dụng (`recruitment_market_screen.dart`)**:
   - Lọc hoàn toàn các nhân sự đã được tuyển (`where(!recruitedAgents.any(...))`), không hiển thị lại trên Chợ.
   - Thêm trạng thái chúc mừng khi Giám đốc đã chiêu mộ toàn bộ nhân sự trên thị trường (`Đã chiêu mộ toàn bộ nhân sự!`).

3. **Màn hình Thầy Cúng (`agent_chat_screen.dart`)**:
   - Bỏ chip gợi ý `Dọn hộp thư Gmail` và các icon cảnh báo; toàn bộ chip gợi ý tập trung 100% vào nghiệp vụ tâm linh/văn hoá công sở chuẩn mực.

4. **Luồng phân loại Intent & Điều chuyển Nhân sự (Handoff)**:
   - Khi Giám đốc ra lệnh ngoài phạm vi cho Thầy Cúng (ví dụ: "dọn cho tôi email"):
     - Thầy Cúng phân loại out-of-scope và gửi sang Trợ lý điều phối.
     - Trợ lý nhận diện intent "dọn email", tra cứu Chợ tuyển dụng thấy có `thu_ky_email` (`Thư ký Email`) và hướng dẫn Giám đốc tuyển Thư ký Email.
     - Nếu yêu cầu là skill công ty chưa có (đặt vé máy bay, khách sạn, gym...): báo rõ "skill này em không có, để bảo Bộ trưởng chiêu mộ thêm nhân tài nước ngoài".
   - Đồng bộ logic xử lý ở cả backend (`assistant_service.py`) và on-device engine (`thay_cung_knowledge_engine.dart` & `app_providers.dart`).

### Quality Gates & Verification:
- **Backend Tests**: 57/57 pytest passed (`.venv/bin/pytest tests/ -v`).
- **Mobile Tests**: 45/45 Flutter tests passed (`flutter test`).
- **Static Analysis**: `flutter analyze` completed with 0 errors / 0 warnings.
- **Code Formatting**: `dart format lib test` formatted cleanly.

## Phase 29: Autonomous 24/24 Background Agents & Multi-Turn Interactive Reminders

### Summary of Enhancements:
1. **Kiến Trúc Hai Tầng (Two-Tier Capability Architecture)**:
   - **Tầng Hệ thống (Platform-Level System Capability)**: Tạo `backend/app/platform/capabilities/reminder_definition.json` định nghĩa chuẩn năng lực `reminder` cho toàn hệ sinh thái vnverse (chế độ chạy: in-app chat bubble, local device notification; giới hạn nghiêm ngặt: KHÔNG đồng bộ Google/Apple Calendar, KHÔNG gửi SMS/gọi điện).
   - **Tầng Nhân sự (Agent-Level Customization)**: Cấu hình `reminder` trong `backend/app/agents/thay_cung/definition.json` với `required_fields` (`days`, `target_time`) và `optional_fields` (`occasion` như "Sóc vọng", "Giỗ cụ"), kèm quick options.
   - **LLM Intent & Boundary Classification**: LLM phân loại chính xác các yêu cầu đặt lịch tâm linh (mùng 1, rằm, ngày giỗ) vào năng lực `reminder`; các yêu cầu ngoài giới hạn (đọc Google Calendar, đặt lịch họp chung) bị phân loại `other = 0.98` và từ chối/điều chuyển rõ ràng.

2. **Dịch Vụ & API Lập Lịch Chạy Ngầm (Reminders Engine)**:
   - `backend/app/schemas/reminders.py`: Pydantic models `ReminderSchedule`, `ReminderCreate`, `ReminderUpdate`, `ReminderResponse`, `ReminderTestRunResponse`.
   - `backend/app/services/reminders_service.py`: Lưu trữ tự chủ (`.reminders_store.json`), seed sẵn lịch nhắc sóc vọng mặc định cho Thầy Cúng, hỗ trợ CRUD, bật/tắt (toggle) và chạy thử ngay lập tức (`execute_test_run`).
   - `backend/app/routers/reminders.py`: REST API endpoints đầy đủ (`GET/POST /api/v1/agents/{id}/reminders`, `GET/PATCH/DELETE /api/v1/reminders/{id}`, `POST /api/v1/reminders/{id}/test-run`).

3. **Giao Diện Hội Thoại Tương Tác Nhiều Lựa Chọn (Interactive Multi-Checkbox Chat Widget)**:
   - Khi Giám đốc yêu cầu nhắc nhở, Thầy Cúng trả về bong bóng chat kèm khối tương tác `InteractiveConfigPrompt`.
   - Render multi-checkbox trực quan: `[x] Mùng 1 Âm lịch`, `[x] Ngày rằm (15) Âm lịch`, `[ ] Ngày khác tuỳ chọn`, cùng nút `Xác nhận lịch nhắc`.
   - Cho phép chọn/bỏ chọn trực tiếp trên bong bóng chat và gửi xác nhận tức thì.

4. **Quản Lý Tác Vụ Chạy Ngầm Trên Màn Hình Nhân Viên (`AgentRemindersSheet`)**:
   - Trên mỗi thẻ nhân viên trong `FriendsScreen`, hiển thị badge `⚡ Lịch nhắc 24/24` và menu item `Lịch nhắc nhở (24/24)`.
   - Mở Bottom Sheet Material 3 hiển thị toàn bộ tác vụ chạy ngầm của nhân viên:
     - Banner thông báo cơ chế tự chủ 24/24.
     - Switch bật/tắt kích hoạt tác vụ.
     - Nút `⚡ Chạy thử ngay` gọi API test-run và phản hồi Toast kết quả.
     - Nút xoá tác vụ kèm hộp thoại xác nhận.
     - Nút `Thêm lịch nhắc thủ công` cho phép chọn giờ và ngày sóc vọng/giỗ chạp.

### Quality Gates & Verification:
- **Backend Tests**: 67/67 pytest passed (`.venv/bin/pytest tests/ -v`). Đã thêm 5 tests mới trong `backend/tests/test_reminders.py`.
- **Mobile Tests**: 61/61 Flutter tests passed (`flutter test`). Đã thêm test unit `reminder_model_test.dart` và 2 test widget `agent_reminders_sheet_test.dart`, `interactive_checkbox_chat_test.dart`.
- **Static Analysis**: `flutter analyze` completed with 0 errors / 0 warnings.

## Phase 30: Slot-Filling for Custom Reminders & Dynamic Lunar Date Parsing

### Summary of Fixes & Enhancements:
1. **Dynamic Slot-Filling cho Reminder (Chỉ bắt buộc Date, Time & Occasion là Optional)**:
   - Trong `definition.json`, chuẩn hoá `required_fields: ["date"]`, các trường `occasion`, `time`, `notes` là `optional_fields`.
   - Khi người dùng chưa nhập ngày, Thầy Cúng chỉ hỏi duy nhất ngày âm lịch một cách tự nhiên và ngắn gọn, không hỏi liệt kê 3 câu hỏi rườm rà.
   - Khi người dùng phản hồi dạng ngắn gọn như `giỗ cụ 10/24 lúc 2:04` hoặc `10/24`:
     - Tự động nhận diện `date = 10/24` (day 24, month 10).
     - Tự động nhận diện `occasion = Giỗ cụ`.
     - Tự động nhận diện `time = 02:04` (nếu không có thì mặc định `07:00`).
     - Xác nhận ngay: *"Dạ thưa Giám đốc! Thầy đã cài đặt lịch nhắc nhở ngày 10/24 Âm lịch (dịp Giỗ cụ) vào lúc 02:04 cho sếp rồi ạ!"*.
2. **Cập nhật nhận diện Intent Scope cho câu trả lời Slot-Filling**:
   - Bổ sung quy tắc trong `base_agent.py` và `definition.json` để các câu trả lời slot-filling ngắn (ví dụ: `giỗ cụ 10/24 lúc 2:04`, `10/24`) được phân loại đúng vào `reminder` của Thầy Cúng (không bị đánh giá nhầm là out-of-scope).
3. **Bộ bóc tách linh hoạt ngày âm (`_parse_lunar_date`, `_parse_occasion`, `_parse_target_time`)**:
   - Hỗ trợ đảo vị trí ngày/tháng thông minh (`10/24` -> ngày 24 tháng 10, `24/10` -> ngày 24 tháng 10, `15/3` -> ngày 15 tháng 3).
   - Hỗ trợ giờ 12h/24h và thời gian buổi chiều/tối (`2:04` -> `02:04`, `2h chiều` -> `14:00`).
4. **Tests & Verification**:
   - Thêm test `test_thay_cung_dynamic_slot_filling_with_short_user_answer` trong `backend/tests/test_reminders.py`.
   - **Backend Tests**: 73/73 tests passed (`.venv/bin/pytest tests/ -q`).
   - **Flutter Tests**: 61/61 tests passed (`flutter test`).

