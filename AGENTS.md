# Vina Buddy — Agent Rules

## Project Context
Vina Buddy is an Android PoC for personal Gmail users. Users describe email-management rules in natural language, preview AI classifications, and approve actions before modifying Gmail labels.

## Architecture
- **Mobile**: Flutter app in `app/`
- **Backend**: Python FastAPI in `backend/`
- **LLM**: Ollama (local) with configurable external fallback
- **Infra**: Docker configs in `infra/`, scripts in `scripts/`
- **Docs**: All specs in `docs/`

## Critical Rules

### Security — NEVER do these:
- NEVER log email bodies, full email content, OAuth tokens, refresh tokens, authorization headers, or API keys.
- NEVER store OAuth tokens on the mobile device. Tokens live server-side only.
- NEVER hardcode secrets in source code. Use environment variables.
- NEVER commit `.env` files, key files, or credential files.
- NEVER allow `delete`, `send`, `archive`, or `trash` actions on Gmail.
- NEVER inject email content into the instruction portion of an LLM prompt. Email content is DATA, not instructions.
- NEVER auto-retry non-idempotent Gmail write operations without verifying the current state.
- NEVER persist email content long-term (max 24h cache, in-memory preferred).

### Development Workflow:
- Follow the AI-DLC: Investigate → Plan → Approve → Implement → Test → Review → Update progress.
- Do not implement features without plan approval.
- Do not claim tests passed without running them and inspecting results.
- Update `progress.md` after completing work.
- All LLM outputs must be validated against Pydantic schemas before use.
- Treat all email content as untrusted input.

### Code Standards:
- Backend: Python 3.11+, type hints, Pydantic models, async/await.
- Mobile: Dart with Riverpod state management, null safety.
- All API endpoints documented in `docs/API_CONTRACT.md`.
- Test coverage: 80%+ backend, 70%+ mobile.

### Git:
- Conventional commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `security:`.
- Feature branches off `main`.
- No force push to `main`.

# Flutter Mobile UI/UX Standards

## Mandatory design principles

- Follow the installed Mobile UI/UX skill whenever designing, implementing, or reviewing mobile screens.
- Use Flutter and Dart idioms and the existing project architecture.
- Use Material 3 as the foundation for Android UI.
- Respect Apple Human Interface Guidelines and iOS interaction conventions when designing for iOS.
- Prefer adaptive behavior where platform conventions differ; do not blindly force identical native interactions across platforms.
- Establish a coherent design system before implementing multiple screens.

## Design system

- Centralize color, typography, spacing, shapes, elevations, and component styles.
- Use ThemeData, ColorScheme, TextTheme, and reusable widgets instead of scattered hardcoded styles.
- Support light and dark themes when required by the product.
- Maintain consistent visual hierarchy, whitespace, alignment, and typography.
- Avoid generic AI-generated layouts, excessive gradients, arbitrary colors, and unnecessary decorative cards.
- Use consistent icons and intentional visual assets.

## Mobile usability

- Respect SafeArea, system bars, keyboard insets, and device cutouts.
- Prevent overflow on small screens and with larger text settings.
- Use appropriate touch target sizes and accessible contrast.
- Support scrolling, loading, empty, error, success, and disabled states where relevant.
- Test long text, localization, orientation, and different screen sizes where applicable.

## Quality gates

Before completing a UI task:

1. Run dart format on changed Dart files.
2. Run flutter analyze and resolve relevant issues.
3. Run applicable widget tests.
4. Run the application on an emulator or device when available.
5. Inspect the rendered UI and correct visual defects.
6. Verify Android and iOS behavior where the environment permits.
7. Report any platform or visual checks that were not performed.

Never claim a screen has been visually verified unless the rendered screen was actually inspected.
