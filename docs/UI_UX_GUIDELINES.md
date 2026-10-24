# Vina Buddy — UI/UX Design Guidelines

## 1. Product Vision & Design Philosophy

Vina Buddy is a personal email management companion that bridges natural-language AI intent with safe, deterministic inbox triage. The design philosophy centers on **Transparency, Trust, Calm Productivity, and Intentionality**.

### Core Tenets
1. **Trust Over Automation**: Users never feel that AI is silently making changes behind their back. Every action is previewed, categorized, and explicitly approved.
2. **Calm, Focused Interface**: Email triage is mentally demanding. The UI must reduce cognitive fatigue through ample whitespace, muted neutral surfaces, distinct semantic colors, and refined typography.
3. **Clarity of AI Interpretation**: When an LLM interprets natural language, the structured result (conditions, actions, confidence score) must be represented with unambiguous visual tokens.
4. **Safety as a First-Class Citizen**: Destructive actions are not supported by design. Reversible actions (applying labels) must clearly display affected items before execution.

---

## 2. Information Architecture & Navigation

The mobile application follows a streamlined 3-tab hub structure optimized for thumb reach and fast context switching:

```
┌────────────────────────────────────────────────────────┐
│                      Vina Buddy                        │
├────────────────────────────────────────────────────────┤
│                                                        │
│  [1. Inbox Feed]    [2. AI Rule Builder]  [3. My Rules]│
│  - Synced emails    - Natural language    - Rule list  │
│  - Metadata cards   - Structured preview  - Toggle on/off│
│  - Manual sync      - AI confidence meter - Quick preview│
│  - Label chips      - Preset chips        - Delete rule│
│                                                        │
├────────────────────────────────────────────────────────┤
│               Bottom Navigation Bar                    │
└────────────────────────────────────────────────────────┘
                           │
                           ▼ (Contextual Sheet)
               ┌───────────────────────┐
               │ Preview & Approval    │
               │ - Matched email list  │
               │ - Checkbox selection  │
               │ - Action approval     │
               └───────────────────────┘
```

---

## 3. Visual Hierarchy & Layout Principles

### 3.1 4pt / 8pt Layout Grid
- All spacing, margins, paddings, and sizing adhere to a strict 4pt/8pt grid:
  - `4pt`: Micro-spacing (between badge text and icon).
  - `8pt`: Tight element spacing (between chips, subheaders).
  - `12pt`: Component internal padding (compact cards, list item gutters).
  - `16pt`: Standard container padding, card interior, screen margin on compact screens.
  - `20pt–24pt`: Section separation and sheet header padding.
  - `32pt–48pt`: Empty state breathing room and hero headers.

### 3.2 Visual Density & Scannability
- **Email Cards**: Scannable in under 2 seconds. The sender's name/domain and timestamp anchor the top line; subject line is bold; 2-line snippet provides context; label chips sit neatly at the base.
- **Rule Cards**: Natural-language instruction is presented in an italicized quote block; conditions and actions are visually partitioned using chip badges.
- **Preview List**: Each item features a distinct checkbox, subject, sender, and green `+ Label` badge so the user instantly understands what will change.

### 3.3 Touch Target & Ergonomics
- Interactive elements (buttons, checkboxes, switches, list tiles, icon buttons) maintain a minimum touch target of **48×48 dp** per WCAG 2.1 AA.
- Form inputs and primary CTA buttons have a comfortable height of **48dp–52dp**.

---

## 4. Typography Scale & Readability

The typography scale is designed for optimal legibility across varying Android screen sizes (5" to 6.8") and font scale settings:

| Style Role | Font Size | Line Height | Weight | Letter Spacing | Usage |
|---|---|---|---|---|---|
| **Display Large** | 28 dp | 36 dp | Bold (700) | -0.5 dp | Splash / Hero headings |
| **Headline Medium** | 22 dp | 28 dp | SemiBold (600) | -0.3 dp | Screen titles, onboarding header |
| **Title Large** | 18 dp | 24 dp | SemiBold (600) | -0.2 dp | Section headers, modal titles |
| **Title Medium** | 16 dp | 22 dp | Medium (500) | 0.0 dp | Card titles, rule names |
| **Body Large** | 15 dp | 22 dp | Regular (400) | +0.1 dp | Primary content, email subjects |
| **Body Medium** | 13 dp | 18 dp | Regular (400) | +0.1 dp | Email snippets, descriptions |
| **Body Small** | 12 dp | 16 dp | Regular (400) | +0.2 dp | Timestamps, metadata, secondary text |
| **Label Large** | 14 dp | 20 dp | SemiBold (600) | +0.1 dp | Button labels, interactive pills |
| **Label Small** | 11 dp | 14 dp | SemiBold (600) | +0.3 dp | Badges, tags, confidence indicators |

---

## 5. Color Strategy & Semantic Tokens

The color palette is built on deep slate neutrals combined with intentional semantic accents.

### Light Theme
- **Primary / Brand**: `#3B5CE6` (Slate Indigo) — represents intelligence and trust.
- **On Primary**: `#FFFFFF`.
- **Primary Container**: `#EEF2FF` with text `#1E3A8A`.
- **Background**: `#F8FAFC` (Slate 50) — soft, glare-free background.
- **Surface**: `#FFFFFF` (Pure white card surfaces).
- **Surface Variant / Container**: `#F1F5F9` (Slate 100).
- **Outline / Border**: `#E2E8F0` (Slate 200).
- **Text Primary**: `#0F172A` (Slate 900) — high-contrast text (> 12:1 ratio).
- **Text Secondary**: `#475569` (Slate 600) — legible metadata (> 4.5:1 ratio).
- **Text Muted**: `#94A3B8` (Slate 400).

### Dark Theme
- **Primary / Brand**: `#6366F1` (Indigo 500) — high visibility on dark surfaces.
- **On Primary**: `#090D16`.
- **Primary Container**: `#1E1B4B` with text `#C7D2FE`.
- **Background**: `#090D16` (Deep Midnight Slate).
- **Surface**: `#111827` (Slate 900).
- **Surface Variant / Container**: `#1E293B` (Slate 800).
- **Outline / Border**: `#334155` (Slate 700).
- **Text Primary**: `#F8FAFC` (Slate 50).
- **Text Secondary**: `#94A3B8` (Slate 400).
- **Text Muted**: `#64748B` (Slate 500).

### Semantic Accents
- **Success / Apply (`#10B981` / `#059669`)**: Used for approved actions, successful label application, active switches.
- **Warning / Uncertainty (`#F59E0B` / `#D97706`)**: Used when AI confidence is < 70% or when attention is advised.
- **Error / Destructive (`#EF4444` / `#DC2626`)**: Used for sync errors, network timeouts, delete rule confirmation.
- **AI Intelligence (`#8B5CF6` / `#7C3AED`)**: Used for AI generation highlights, preset prompt chips.

---

## 6. Feedback & Interaction States

Every asynchronous or consequential action provides immediate visual feedback:

1. **Loading States**:
   - Initial load: Clean circular spinner centered in view with descriptive label.
   - Syncing: Refresh indicator animation on pull + progress spinner on AppBar icon.
   - Rule generation: Pulsing AI indicator and disabled button with "Analyzing Intent...".
   - Applying actions: Primary button shows spinner and label changes to "Applying changes...".
2. **Empty States**:
   - Feature an illustrated icon badge, clear heading, reassuring explanation, and primary action button (e.g. "Create Rule" or "Sync Emails").
3. **Error & Recovery States**:
   - Replaces generic toast popups with inline or floating `StatusBanner` containing clear root cause and an actionable **Retry** button.
4. **Uncertainty State**:
   - If AI confidence falls below 0.70, an amber banner warns the user to inspect conditions and matches before approval.

---

## 7. Safety & Privacy UX Guarantees

1. **No Silent Changes**: The app never applies changes without the user reviewing the preview sheet and pressing "Approve & Apply".
2. **Confirmation Safeguard**: A secondary system dialog confirms the exact count of affected emails and clarifies: *"No emails will be deleted or sent."*
3. **Zero Private Content Display**: Previews show only sender, subject, and date. Email bodies are never fetched or displayed in full.
4. **Sandbox / Dev Mode Clarity**: When testing without real credentials, a clear dev mode indicator informs the tester that mock data is active.
