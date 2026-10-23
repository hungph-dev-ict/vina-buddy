# Smart Inbox AI — Gemini Configuration

## Project Overview
Smart Inbox AI: Android PoC for AI-assisted Gmail inbox management with natural language rules.

## Key Files
- `progress.md` — Current status and next actions
- `docs/PRODUCT_SPEC.md` — Product specification
- `docs/ARCHITECTURE.md` — System architecture and monorepo layout
- `docs/API_CONTRACT.md` — API endpoints and schemas
- `docs/SECURITY.md` — Security plan and threat model
- `docs/TEST_PLAN.md` — Test strategy and commands
- `docs/DECISIONS.md` — Architecture Decision Records
- `docs/USER_STORIES.md` — User stories and acceptance criteria
- `docs/HANDOFF_REPORT.md` — Final PoC handoff report, test evidence, and execution guide

## Tech Stack
- **Mobile**: Flutter (Dart), Riverpod, Dio, google_sign_in
- **Backend**: Python 3.11+, FastAPI, Pydantic, SQLAlchemy, httpx
- **LLM**: Ollama (local), configurable external API fallback
- **Database**: SQLite (PoC)
- **Infra**: Docker, ngrok/cloudflared for HTTPS tunneling

## Important Constraints
- Never log tokens, email bodies, or secrets
- Never allow delete/send Gmail actions
- Validate all LLM outputs before use
- User must approve all Gmail modifications
- Follow AI-DLC workflow phases
- Update progress.md after each phase
