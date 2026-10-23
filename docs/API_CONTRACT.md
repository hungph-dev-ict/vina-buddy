# Smart Inbox AI — API Contract

## Base URL
```
https://<backend-host>/api/v1
```

## Authentication
All endpoints (except `/auth/callback`) require a session token in the `Authorization` header:
```
Authorization: Bearer <session-token>
```
Session tokens are opaque, short-lived (1 hour), and refreshable.

---

## 1. Auth Endpoints

### POST /auth/google
Exchange Google authorization code for a session.

**Request:**
```json
{
  "auth_code": "4/0AX4XfWh...",
  "redirect_uri": "com.vinabuddy.smartinbox:/oauth2callback"
}
```

**Response (200):**
```json
{
  "session_token": "eyJhbGciOiJIUzI1NiIs...",
  "email": "user@gmail.com",
  "expires_at": "2026-10-24T10:00:00Z"
}
```

**Errors:** `400` invalid code, `401` OAuth failure.

### POST /auth/refresh
Refresh the session token.

**Request:**
```json
{
  "session_token": "eyJhbGciOiJIUzI1NiIs..."
}
```

**Response (200):**
```json
{
  "session_token": "eyJhbGciOiJIUzI1NiIs...",
  "expires_at": "2026-10-24T11:00:00Z"
}
```

### POST /auth/revoke
Disconnect Gmail and clear all data.

**Response (200):**
```json
{
  "status": "revoked"
}
```

---

## 2. Gmail Endpoints

### POST /gmail/sync
Fetch recent emails from Gmail.

**Request:**
```json
{
  "max_results": 50,
  "page_token": null
}
```

**Response (200):**
```json
{
  "emails": [
    {
      "id": "msg_abc123",
      "thread_id": "thread_xyz",
      "from": "sender@example.com",
      "from_name": "Sender Name",
      "subject": "Your order has shipped",
      "snippet": "Your order #12345 has been shipped and...",
      "date": "2026-10-23T10:30:00Z",
      "labels": ["INBOX", "UNREAD"],
      "has_attachments": false
    }
  ],
  "total_count": 50,
  "next_page_token": "token_xyz",
  "synced_at": "2026-10-23T12:00:00Z"
}
```

### GET /gmail/labels
List all Gmail labels for the connected account.

**Response (200):**
```json
{
  "labels": [
    {"id": "Label_1", "name": "Newsletters", "type": "user"},
    {"id": "INBOX", "name": "INBOX", "type": "system"}
  ]
}
```

---

## 3. Rules Endpoints

### GET /rules
List all rules.

**Response (200):**
```json
{
  "rules": [
    {
      "id": "rule_001",
      "name": "Label newsletters",
      "natural_language": "Move emails from newsletter senders to Newsletters label",
      "conditions": [
        {
          "field": "from",
          "operator": "contains",
          "value": "newsletter"
        }
      ],
      "actions": [
        {
          "type": "add_label",
          "label": "Newsletters"
        }
      ],
      "priority": 1,
      "enabled": true,
      "created_at": "2026-10-23T08:00:00Z",
      "updated_at": "2026-10-23T08:00:00Z"
    }
  ]
}
```

### POST /rules
Create a rule from natural language.

**Request:**
```json
{
  "natural_language": "Label emails from amazon.com as Shopping"
}
```

**Response (201):**
```json
{
  "id": "rule_002",
  "name": "Amazon Shopping",
  "natural_language": "Label emails from amazon.com as Shopping",
  "conditions": [
    {
      "field": "from",
      "operator": "contains",
      "value": "amazon.com"
    }
  ],
  "actions": [
    {
      "type": "add_label",
      "label": "Shopping"
    }
  ],
  "priority": 2,
  "enabled": true,
  "created_at": "2026-10-23T09:00:00Z",
  "updated_at": "2026-10-23T09:00:00Z",
  "llm_confidence": 0.92,
  "llm_provider": "ollama"
}
```

**Errors:** `422` LLM output validation failed, `504` LLM timeout.

### PUT /rules/{rule_id}
Update a rule.

**Request:**
```json
{
  "natural_language": "Label emails from amazon.com or amazon.co.jp as Shopping",
  "enabled": true
}
```

**Response (200):** Updated rule object.

### PATCH /rules/{rule_id}
Toggle rule enabled/disabled.

**Request:**
```json
{
  "enabled": false
}
```

**Response (200):** Updated rule object.

### DELETE /rules/{rule_id}
Delete a rule.

**Response (204):** No content.

---

## 4. Classification Endpoints

### POST /classify/preview
Preview which emails match a rule without applying changes.

**Request:**
```json
{
  "rule_id": "rule_002"
}
```

**Response (200):**
```json
{
  "rule_id": "rule_002",
  "rule_name": "Amazon Shopping",
  "matches": [
    {
      "email_id": "msg_abc123",
      "subject": "Your order has shipped",
      "from": "ship-confirm@amazon.com",
      "proposed_actions": [
        {
          "type": "add_label",
          "label": "Shopping"
        }
      ],
      "confidence": 0.95
    }
  ],
  "total_matches": 1,
  "total_emails_evaluated": 50,
  "evaluation_time_ms": 2340
}
```

### POST /classify/apply
Apply approved actions to Gmail.

**Request:**
```json
{
  "rule_id": "rule_002",
  "approved_email_ids": ["msg_abc123", "msg_def456"]
}
```

**Response (200):**
```json
{
  "rule_id": "rule_002",
  "results": [
    {
      "email_id": "msg_abc123",
      "status": "success",
      "actions_applied": [{"type": "add_label", "label": "Shopping"}]
    },
    {
      "email_id": "msg_def456",
      "status": "failed",
      "error": "Label 'Shopping' could not be created"
    }
  ],
  "summary": {
    "total": 2,
    "succeeded": 1,
    "failed": 1
  }
}
```

---

## 5. History Endpoints

### GET /history
Get action history.

**Query Parameters:**
- `rule_id` (optional): Filter by rule.
- `limit` (default 50, max 200): Number of records.
- `offset` (default 0): Pagination offset.

**Response (200):**
```json
{
  "actions": [
    {
      "id": "action_001",
      "rule_id": "rule_002",
      "rule_name": "Amazon Shopping",
      "email_id": "msg_abc123",
      "email_subject": "Your order has shipped",
      "action_type": "add_label",
      "label": "Shopping",
      "status": "success",
      "applied_at": "2026-10-23T12:30:00Z"
    }
  ],
  "total": 1,
  "limit": 50,
  "offset": 0
}
```

---

## 6. Health Endpoints

### GET /health
Backend health check.

**Response (200):**
```json
{
  "status": "healthy",
  "ollama": "connected",
  "version": "0.1.0"
}
```

---

## 7. Error Format

All errors follow a consistent format:

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "LLM output did not match expected schema",
    "details": {
      "field": "conditions[0].operator",
      "expected": "one of: equals, contains, starts_with, ends_with, regex",
      "received": "matches"
    }
  }
}
```

**Standard Error Codes:**
| HTTP | Code | Description |
|------|------|-------------|
| 400 | `BAD_REQUEST` | Malformed request |
| 401 | `UNAUTHORIZED` | Invalid or expired session |
| 403 | `FORBIDDEN` | Action not permitted |
| 404 | `NOT_FOUND` | Resource not found |
| 422 | `VALIDATION_ERROR` | Schema validation failed |
| 429 | `RATE_LIMITED` | Too many requests |
| 500 | `INTERNAL_ERROR` | Server error |
| 502 | `LLM_ERROR` | LLM provider error |
| 504 | `LLM_TIMEOUT` | LLM response timeout |

---

## 8. Rate Limits

| Endpoint | Limit |
|----------|-------|
| `/auth/*` | 10 req/min |
| `/gmail/sync` | 5 req/min |
| `/rules` (POST/PUT) | 20 req/min |
| `/classify/*` | 10 req/min |
| All others | 60 req/min |

## 9. Schema Definitions

### Rule Condition
```json
{
  "field": "from | subject | snippet | label | date",
  "operator": "equals | contains | starts_with | ends_with | regex | before | after",
  "value": "string"
}
```

### Rule Action
```json
{
  "type": "add_label | remove_label",
  "label": "string"
}
```

Allowed action types: **`add_label`**, **`remove_label`** only.
`delete`, `send`, `archive`, `mark_read` are **not permitted** in the PoC.
