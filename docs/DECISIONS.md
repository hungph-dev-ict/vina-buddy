# Smart Inbox AI — Architecture Decision Records

## ADR-001: Monorepo Structure
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** The project has a Flutter mobile app, a Python backend, infrastructure configs, and documentation. We need a structure that keeps everything cohesive for a small team.

**Decision:** Use a single monorepo with `app/`, `backend/`, `infra/`, `scripts/`, `docs/` top-level directories.

**Rationale:** Simplifies dependency management, ensures docs stay in sync with code, enables atomic commits across frontend/backend.

**Alternatives Considered:** Separate repos for app and backend — rejected for PoC complexity.

---

## ADR-002: State Management — Riverpod
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Flutter needs a state management solution. Options: Provider, Riverpod, BLoC, GetX.

**Decision:** Use Riverpod (v2+).

**Rationale:** Compile-safe, testable, no `BuildContext` dependency for providers, good async support. Simpler than BLoC for a PoC, more robust than Provider.

---

## ADR-003: LLM Provider Abstraction
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Primary LLM is Ollama (local). Need fallback to external API. Must be replaceable.

**Decision:** Define a `LLMProvider` protocol. Implement `OllamaProvider`, `ExternalAPIProvider`, and `FallbackProvider` (tries Ollama first, falls back to external).

**Rationale:** Clean separation. Adding a new provider requires only implementing the protocol. Fallback logic is centralized.

---

## ADR-004: Session-Based Auth (Not Token Pass-Through)
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Mobile app needs to authenticate with the backend. Options: pass Google tokens to backend on every request, or exchange for a session.

**Decision:** Mobile app sends Google auth code to backend once. Backend exchanges for OAuth tokens and issues its own short-lived session token. Mobile app uses only the session token.

**Rationale:** OAuth tokens never leave the backend. Session tokens are simpler, shorter-lived, and can be revoked independently. If mobile device is compromised, only the session token is exposed (1h expiry).

---

## ADR-005: SQLite for Persistence
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Need to store rules and action history. Options: PostgreSQL, SQLite, in-memory only.

**Decision:** SQLite for the PoC backend.

**Rationale:** Zero setup, file-based, sufficient for single-user PoC. Easy migration to PostgreSQL later if needed. Action history and rules don't require complex queries.

---

## ADR-006: Email Data Minimization for LLM
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Sending full email content to LLM is a privacy risk and increases latency.

**Decision:** Send only: sender domain, subject line, and a sanitized snippet (first 200 chars, PII stripped) to the LLM.

**Rationale:** Sufficient for classification. Minimizes data exposure. Reduces prompt size and LLM cost.

---

## ADR-007: No Background Sync
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Background sync would require persistent services, token refresh, and battery management.

**Decision:** All syncs are user-initiated (manual tap).

**Rationale:** Simpler implementation. Clearer user control. No background process concerns for PoC.

---

## ADR-008: HTTPS Tunnel for Physical Device Testing
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Physical Android devices need to reach the backend server running on the dev machine.

**Decision:** Use ngrok or cloudflared to create an HTTPS tunnel during development.

**Rationale:** Provides a public HTTPS URL. No DNS or SSL cert management. Free tier sufficient for PoC.

---

## ADR-009: Ollama Model Selection
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** 16 GB RAM on M1 Pro. Need a model that fits in memory and responds quickly.

**Decision:** Start with `qwen2.5:3b` or `phi3:mini` (3–4B parameters, Q4 quantized).

**Rationale:** Fits comfortably in 16 GB. Good instruction-following for structured output. Fast inference on Metal. Can upgrade to 7B if quality is insufficient.

**Open Question:** Need to benchmark actual classification accuracy with sample emails.

---

## ADR-010: Allowed Gmail Actions
**Status:** Proposed  
**Date:** 2026-10-23

**Context:** Need to strictly limit what Gmail modifications the app can make.

**Decision:** Allow only `add_label` and `remove_label`. Block `delete`, `send`, `archive`, `trash`, `mark_read` at the API router level.

**Rationale:** Labeling is safe and reversible. Deletion and sending are destructive/irreversible. Even `archive` is excluded for PoC simplicity.

---

## Unresolved Decisions

| # | Decision | Options | Notes |
|---|----------|---------|-------|
| UD-1 | Exact Ollama model | `qwen2.5:3b`, `phi3:mini`, `llama3.2:3b` | Need accuracy benchmarks |
| UD-2 | External LLM fallback provider | OpenAI, Anthropic, Google | User preference needed |
| UD-3 | Mobile app name / package ID | `com.vinabuddy.smartinbox` | Confirm before APK build |
| UD-4 | OAuth consent screen branding | App name, logo, privacy policy URL | Required for Google Cloud |
| UD-5 | Test Gmail account | Create dedicated test account? | Recommended for safety |
| UD-6 | Python version for backend | 3.11 (available) vs 3.12+ | 3.11 is installed via brew |
| UD-7 | HTTP client library (mobile) | `dio` vs `http` | Dio recommended for interceptors |
