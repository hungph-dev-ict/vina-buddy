# Vina Buddy — Architecture

## 1. High-Level Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        User's Android Device                            │
│  ┌────────────────────────────────────────────────────────────────────┐  │
│  │                    Flutter Mobile App                              │  │
│  │  ┌──────────┐ ┌───────────┐ ┌──────────┐ ┌─────────────────────┐  │  │
│  │  │  Auth    │ │  Email    │ │  Rules   │ │  Preview & Approve  │  │  │
│  │  │  Screen  │ │  List     │ │  Editor  │ │  Screen             │  │  │
│  │  └────┬─────┘ └─────┬─────┘ └────┬─────┘ └──────────┬──────────┘  │  │
│  │       │             │            │                   │             │  │
│  │  ┌────┴─────────────┴────────────┴───────────────────┴──────────┐  │  │
│  │  │               State Management (Riverpod)                    │  │  │
│  │  └──────────────────────────┬───────────────────────────────────┘  │  │
│  │                             │                                      │  │
│  │  ┌──────────────────────────┴───────────────────────────────────┐  │  │
│  │  │                API Client (Dio + interceptors)               │  │  │
│  │  └──────────────────────────┬───────────────────────────────────┘  │  │
│  └─────────────────────────────┼──────────────────────────────────────┘  │
└─────────────────────────────────┼────────────────────────────────────────┘
                                  │ HTTPS
                                  ▼
┌──────────────────────────────────────────────────────────────────────────┐
│                     Backend Server (FastAPI)                             │
│  ┌────────────┐ ┌────────────┐ ┌──────────────┐ ┌───────────────────┐   │
│  │ Auth       │ │ Gmail      │ │ Rules        │ │ Classification    │   │
│  │ Router     │ │ Router     │ │ Router       │ │ Router            │   │
│  └─────┬──────┘ └─────┬──────┘ └──────┬───────┘ └────────┬──────────┘   │
│        │              │               │                   │              │
│  ┌─────┴──────────────┴───────────────┴───────────────────┴──────────┐   │
│  │                     Service Layer                                 │   │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │   │
│  │  │ Auth     │  │ Gmail    │  │ Rules    │  │ Classification   │  │   │
│  │  │ Service  │  │ Service  │  │ Service  │  │ Service          │  │   │
│  │  └──────────┘  └────┬─────┘  └──────────┘  └────────┬─────────┘  │   │
│  └──────────────────────┼──────────────────────────────┼─────────────┘   │
│                         │                              │                 │
│                         ▼                              ▼                 │
│            ┌────────────────────┐         ┌────────────────────────┐     │
│            │   Gmail API       │         │   LLM Provider         │     │
│            │   (google-api-    │         │   (Abstraction Layer)  │     │
│            │    python-client) │         │   ┌────────┐ ┌──────┐  │     │
│            └────────────────────┘         │   │ Ollama │ │ API  │  │     │
│                                          │   │ Local  │ │ Fall │  │     │
│                                          │   │        │ │ back │  │     │
│                                          │   └────────┘ └──────┘  │     │
│                                          └────────────────────────┘     │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐   │
│  │  Data Layer: SQLite (rules, action history) + In-memory cache    │   │
│  │  (email metadata, tokens — never persisted to disk as plaintext) │   │
│  └───────────────────────────────────────────────────────────────────┘   │
└──────────────────────────────────────────────────────────────────────────┘
```

## 2. Component Breakdown

### 2.1 Flutter Mobile App (`app/`)

| Component | Responsibility |
|-----------|---------------|
| **Auth Screen** | Google sign-in, token exchange, connection status |
| **Email List** | Display synced emails, trigger manual sync |
| **Rules Editor** | Natural language input, rule CRUD, enable/disable |
| **Preview Screen** | Show matched emails and proposed actions |
| **Approve Screen** | Confirm and apply actions, show results |
| **History Screen** | View action history log |
| **Settings** | Backend URL config, dev mode toggle |

**Key Libraries:**
- `riverpod` — State management
- `dio` — HTTP client with interceptors
- `google_sign_in` — Google OAuth on device
- `flutter_secure_storage` — Store session tokens
- `go_router` — Navigation

### 2.2 Backend Server (`backend/`)

| Layer | Responsibility |
|-------|---------------|
| **Routers** | FastAPI route handlers, request validation |
| **Services** | Business logic, orchestration |
| **Gmail Service** | Gmail API calls (fetch, label, sync) |
| **Auth Service** | OAuth token management, verification |
| **Rules Service** | CRUD for rules, validation |
| **Classification Service** | LLM interaction, output validation |
| **LLM Provider** | Abstract interface for Ollama / external API |
| **Data Layer** | SQLite for rules + history, in-memory for emails |

**Key Libraries:**
- `fastapi` + `uvicorn` — Web framework
- `google-api-python-client` + `google-auth` — Gmail API
- `pydantic` — Schema validation
- `httpx` — Async HTTP client (for Ollama)
- `sqlalchemy` — ORM for SQLite
- `python-jose` — JWT handling

### 2.3 LLM Provider Abstraction

```python
class LLMProvider(Protocol):
    async def classify(self, prompt: str, schema: dict) -> dict: ...
    async def health_check(self) -> bool: ...

class OllamaProvider(LLMProvider): ...
class ExternalAPIProvider(LLMProvider): ...
class FallbackProvider(LLMProvider):  # tries Ollama, falls back to external
    ...
```

## 3. Data Flow

### 3.1 Rule Creation Flow
```
User types rule → App → POST /api/rules → Rules Service
  → Classification Service → LLM Provider → Ollama
  → Validate JSON schema → Store rule → Return structured rule
  → App displays for review
```

### 3.2 Email Classification Flow
```
User taps "Preview" → App → POST /api/classify
  → Gmail Service fetches email metadata (cached)
  → Classification Service strips PII, builds prompt
  → LLM evaluates each email against rule conditions
  → Returns matched emails + proposed actions
  → App displays preview
```

### 3.3 Action Application Flow
```
User taps "Apply" → App → POST /api/actions/apply
  → Gmail Service checks current label state
  → Applies label changes via Gmail API
  → Records each action in history
  → Returns success/failure summary
  → App updates UI
```

## 4. Security Boundaries

```
┌─────────────────┐      ┌─────────────────┐      ┌──────────────────┐
│   Mobile App    │      │   Backend       │      │   External       │
│   (untrusted)   │◄────►│   (trusted)     │◄────►│   Services       │
│                 │ HTTPS│                 │      │                  │
│ • No tokens     │      │ • Holds tokens  │      │ • Gmail API      │
│ • No secrets    │      │ • Validates all │      │ • Ollama (local) │
│ • Session ID    │      │ • Sanitizes     │      │ • Fallback LLM   │
│   only          │      │ • Rate limits   │      │                  │
└─────────────────┘      └─────────────────┘      └──────────────────┘
```

## 5. Deployment Architecture (PoC)

```
Developer Machine (macOS M1 Pro)
├── Flutter App → Build APK → Install on Android device
├── FastAPI Backend → Run locally (uvicorn)
├── Ollama → Run locally (serves LLM)
├── ngrok/cloudflared → HTTPS tunnel to backend
└── SQLite → Local file for rules + history
```

## 6. Monorepo Layout

```
vina-buddy/
├── app/                          # Flutter mobile app
│   ├── android/                  # Android-specific config
│   ├── lib/
│   │   ├── main.dart
│   │   ├── config/               # App configuration, env
│   │   ├── models/               # Data models
│   │   ├── providers/            # Riverpod providers
│   │   ├── screens/              # UI screens
│   │   ├── services/             # API client, auth
│   │   ├── widgets/              # Reusable widgets
│   │   └── utils/                # Helpers, formatters
│   ├── test/                     # Widget & unit tests
│   ├── pubspec.yaml
│   └── analysis_options.yaml
├── backend/
│   ├── app/
│   │   ├── __init__.py
│   │   ├── main.py               # FastAPI app entry
│   │   ├── config.py             # Settings from env vars
│   │   ├── routers/
│   │   │   ├── auth.py
│   │   │   ├── gmail.py
│   │   │   ├── rules.py
│   │   │   └── classify.py
│   │   ├── services/
│   │   │   ├── auth_service.py
│   │   │   ├── gmail_service.py
│   │   │   ├── rules_service.py
│   │   │   └── classification_service.py
│   │   ├── llm/
│   │   │   ├── base.py           # LLMProvider protocol
│   │   │   ├── ollama.py
│   │   │   ├── external.py
│   │   │   └── fallback.py
│   │   ├── models/
│   │   │   ├── rule.py
│   │   │   ├── email.py
│   │   │   └── action.py
│   │   ├── schemas/              # Pydantic request/response
│   │   ├── middleware/           # Logging, rate-limit, auth
│   │   └── db/                   # SQLAlchemy models, migrations
│   ├── tests/
│   │   ├── test_rules.py
│   │   ├── test_classification.py
│   │   ├── test_gmail.py
│   │   └── test_auth.py
│   ├── pyproject.toml
│   ├── Dockerfile
│   └── .env.example
├── infra/
│   ├── docker-compose.yml        # Backend + Ollama
│   └── ollama/
│       └── Modelfile             # Model config
├── scripts/
│   ├── setup_env.sh              # Install all prerequisites
│   ├── run_backend.sh
│   ├── run_ollama.sh
│   ├── build_apk.sh
│   └── tunnel.sh                 # Start HTTPS tunnel
├── docs/
│   ├── PRODUCT_SPEC.md
│   ├── USER_STORIES.md
│   ├── ARCHITECTURE.md
│   ├── API_CONTRACT.md
│   ├── SECURITY.md
│   ├── TEST_PLAN.md
│   └── DECISIONS.md
├── progress.md
├── AGENTS.md
├── GEMINI.md
├── .gitignore
└── README.md
```
