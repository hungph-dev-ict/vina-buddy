# Smart Inbox AI — Product Specification

## 1. Overview

Smart Inbox AI is an Android proof-of-concept application that helps personal Gmail users manage their inboxes using natural-language rules. Users describe their email-management intent in plain language; the system converts that into structured rules, classifies emails, previews the proposed actions, and applies Gmail labels only after explicit user approval.

## 2. Target User

- Personal Gmail users (single Google account).
- Non-technical users who want AI-assisted inbox triage.
- Users who prefer explicit control over automated actions.

## 3. Core Workflows

### 3.1 Connect Gmail
- User signs in with Google OAuth 2.0 on the mobile app.
- App receives an authorization code, exchanges it server-side for access/refresh tokens.
- Tokens are stored only in server-side memory or encrypted secrets; never logged.
- Minimal OAuth scopes: `gmail.readonly`, `gmail.labels`, `gmail.modify`.

### 3.2 Analyze Recent Emails
- User taps "Sync" to fetch the most recent N emails (default: 50, max: 200).
- Backend fetches email metadata + limited body (first 500 chars or snippet).
- Full bodies are never persisted; only metadata is stored temporarily.
- Emails are cached per-session; cache expires when the user logs out or after 24 hours.

### 3.3 Describe Rules in Natural Language
- User types a rule like: "Move newsletters to a 'Newsletters' label."
- The app sends the text to the backend for LLM processing.
- The LLM converts the natural-language instruction into a structured JSON rule.

### 3.4 Convert to Validated Structured Rules
- Backend validates the LLM output against a strict JSON schema.
- Invalid or ambiguous outputs are rejected with clear error messages.
- A rule consists of:
  - `name`: human-readable label
  - `conditions`: list of match criteria (sender, subject, body keywords, date range)
  - `actions`: list of actions (`add_label`, `remove_label`) — never `delete` or `send`
  - `priority`: integer for ordering
  - `enabled`: boolean

### 3.5 Preview Affected Emails
- After rule creation, the system runs the rule against cached emails.
- A preview screen shows which emails match and what action would be taken.
- No changes are made to Gmail at this stage.

### 3.6 Approve and Apply Labels
- User reviews the preview and taps "Apply" to confirm.
- Backend applies the approved label changes via Gmail API.
- Each action is logged in a local action history with timestamps.
- Failed actions are reported; no automatic retries on non-idempotent actions.

### 3.7 Manual Sync
- User can re-sync at any time to fetch newer emails.
- No background sync; all syncs are user-initiated.

### 3.8 Rule Management
- List all rules with status (enabled/disabled).
- Edit rule text (re-runs LLM conversion).
- Enable/disable rules without deleting.
- View action history per rule (what was applied, when, to which emails).

## 4. Out of Scope (PoC)
- Multiple Gmail accounts.
- Background/scheduled sync.
- Email deletion or sending.
- iOS support.
- Push notifications.
- Multi-language UI (English only).
- Attachment processing.
- Conversation threading.

## 5. Non-Functional Requirements

| Requirement | Target |
|-------------|--------|
| Email fetch latency | < 5 seconds for 50 emails |
| Rule classification latency | < 10 seconds per rule evaluation |
| LLM response timeout | 30 seconds with fallback |
| Max concurrent users (PoC) | 1–5 |
| APK size | < 50 MB |
| Min Android version | Android 8.0 (API 26) |

## 6. Security Requirements
- See [SECURITY.md](SECURITY.md) for full details.
- Never log email bodies, tokens, or secrets.
- OAuth tokens stored only server-side, encrypted at rest.
- Email content treated as untrusted input, never injected into prompts as instructions.
- All LLM outputs validated before use.

## 7. Privacy
- Email content is processed in-memory only; never written to disk or logs.
- Minimal data sent to LLM: subject line, sender domain, snippet (no full body).
- No telemetry or analytics in the PoC.
- User can disconnect Gmail and clear all cached data.
