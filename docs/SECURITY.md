# Smart Inbox AI — Security Plan

## 1. Threat Model

### 1.1 Assets to Protect
| Asset | Sensitivity | Storage |
|-------|------------|---------|
| Gmail OAuth tokens | **Critical** | Server-side memory + encrypted secrets only |
| Email content | **High** | In-memory only, never persisted |
| Email metadata | **Medium** | Temporary cache (≤24h), cleared on logout |
| User rules | **Low** | SQLite database |
| Action history | **Low** | SQLite database |
| LLM API keys | **Critical** | Environment variables only |
| Google OAuth client secret | **Critical** | Environment variables only |

### 1.2 Threat Actors
- **Compromised device**: Attacker with access to the Android device.
- **Network attacker**: MITM on the network path.
- **Malicious email sender**: Crafted email content designed to exploit LLM.
- **Backend compromise**: Attacker with access to the server.

### 1.3 Attack Vectors

| # | Vector | Risk | Mitigation |
|---|--------|------|------------|
| S1 | Token leakage in logs | Critical | Strip tokens from all log output; structured logging with sanitization |
| S2 | Email body in logs | High | Never log email bodies; log only message IDs |
| S3 | Prompt injection via email content | High | Treat email content as data, not instructions; template-based prompts; validate outputs |
| S4 | LLM hallucination → unintended Gmail action | High | Strict schema validation; preview before apply; user approval required |
| S5 | Token stored on mobile device | High | Tokens never sent to mobile app; session tokens only |
| S6 | MITM on HTTP | Medium | HTTPS only; certificate pinning optional for PoC |
| S7 | Excessive Gmail API calls | Medium | Rate limiting; quota tracking |
| S8 | Unauthorized API access | Medium | Session-based auth; CORS restrictions |
| S9 | SQL injection in rules | Low | Parameterized queries via SQLAlchemy ORM |
| S10 | Denial of service | Low | Rate limiting; request size limits |

## 2. Security Controls

### 2.1 Authentication & Authorization
- Google OAuth 2.0 with server-side token exchange.
- Short-lived session tokens (1 hour expiry, refreshable).
- Mobile app holds only the session token, never OAuth tokens.
- All API endpoints require valid session token.
- Session invalidation on disconnect/logout.

### 2.2 Credential Management
- **Backend secrets**: Loaded from environment variables or `.env` file (never committed).
- **No hardcoded secrets** in source code.
- **`.env.example`** contains placeholder keys only.
- **`.gitignore`** excludes `.env`, `*.key`, `*.pem`, token files.
- Google OAuth client ID is public (embedded in mobile app).
- Google OAuth client secret is **server-side only**.

### 2.3 Data Minimization
- Only fetch email metadata + snippet (not full body) for classification.
- Strip personal data before sending to LLM:
  - Remove email addresses → replace with `[sender]`, `[recipient]`.
  - Remove phone numbers, URLs with personal paths.
  - Keep only: subject, sender domain, snippet keywords.
- Email cache auto-expires after 24 hours or on logout.
- No long-term email content storage.

### 2.4 LLM Security
- **Prompt injection defense**: Email content is inserted into a structured data field, never into the instruction portion of the prompt.
- **Output validation**: All LLM responses must match a strict Pydantic schema.
- **Timeout**: 30-second timeout on LLM requests.
- **Fallback budget**: Configurable max requests per hour to external LLM API.
- **No auto-retry**: LLM classification failures require user-initiated retry.
- **Provider abstraction**: LLM provider is replaceable without code changes.

### 2.5 Gmail API Safety
- **Allowed actions**: `add_label`, `remove_label` only.
- **Blocked actions**: `delete`, `send`, `archive`, `trash` — enforced at API router level.
- **Idempotency check**: Before applying a label, verify current label state.
- **No auto-retry on write operations**: If a label application fails, log the error and report to user.
- **Scope restrictions**: Request only `gmail.readonly`, `gmail.labels`, `gmail.modify`.

### 2.6 Logging Policy
**NEVER log:**
- Email bodies or full content
- OAuth access tokens or refresh tokens
- Authorization headers
- API keys or secrets
- User passwords (N/A but policy stands)

**Safe to log:**
- Email message IDs (not content)
- Request paths and methods
- Response status codes
- Rule IDs and names
- Timestamps
- Error types (not error details containing sensitive data)

### 2.7 Network Security
- All client-backend communication over HTTPS.
- Backend does not accept HTTP (redirect to HTTPS or reject).
- CORS restricted to the mobile app origin.
- Request body size limit: 1 MB.
- Rate limiting per endpoint (see API_CONTRACT.md).

### 2.8 Input Validation
- All API inputs validated via Pydantic schemas.
- Natural language rule input: max 500 characters, UTF-8 only.
- Email count limits enforced (max 200 per sync).
- Rule count limit: max 50 active rules per user.

## 3. Google OAuth / Gmail API Setup Checklist

- [ ] Create a Google Cloud Platform project.
- [ ] Enable the Gmail API.
- [ ] Configure the OAuth consent screen (external, testing mode).
- [ ] Add test user email addresses.
- [ ] Create OAuth 2.0 Client ID (type: Android + Web).
- [ ] Download the client configuration JSON.
- [ ] Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` as environment variables.
- [ ] Configure authorized redirect URIs.
- [ ] Request scopes: `gmail.readonly`, `gmail.labels`, `gmail.modify`.
- [ ] Verify token exchange works with a test account.
- [ ] Set up SHA-1 fingerprint for the Android app.

## 4. Incident Response (PoC)

If a security issue is discovered:
1. Immediately revoke affected OAuth tokens.
2. Rotate any exposed secrets.
3. Clear all cached email data.
4. Document the issue and notify affected test users.

## 5. Security Testing Plan

| Test | Method | When |
|------|--------|------|
| Token leak in logs | Grep logs for token patterns | Every build |
| Prompt injection | Test with crafted email subjects | Rule creation tests |
| Schema validation bypass | Fuzz LLM output validator | Classification tests |
| Unauthorized access | Test endpoints without/with expired token | Auth tests |
| Rate limit enforcement | Load test endpoints | Integration tests |
| SQL injection | Test with special chars in rule names | Rule CRUD tests |
