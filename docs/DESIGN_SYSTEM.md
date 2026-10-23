# Smart Inbox AI — Flutter Design System

## 1. Overview & Architecture

The Smart Inbox AI Design System provides a centralized, reusable set of design tokens and UI components built on Material 3 principles. It ensures visual consistency, accessibility compliance, and coherent dark/light mode switching across the entire application.

### Directory Structure
```
app/lib/
├── theme/
│   ├── app_colors.dart         # Semantic color tokens (Light & Dark)
│   ├── app_spacing.dart        # 4pt/8pt spacing, border radius, elevation tokens
│   ├── app_typography.dart     # Responsive TextTheme definitions
│   └── app_theme.dart          # Light and Dark ThemeData constructors
└── widgets/
    ├── app_badge.dart          # Label, status, and confidence chips
    ├── app_button.dart         # Primary, secondary, outline, and text buttons
    ├── app_card.dart           # Polished card with borders and soft shadows
    ├── email_card.dart         # High-density, scannable email preview item
    ├── rule_card.dart          # Structured rule card with toggle and actions
    ├── status_banner.dart      # Semantic info, warning, and error banners
    └── empty_state_view.dart   # Illustrated empty state layout
```

---

## 2. Design Tokens

### 2.1 Spacing Scale (`AppSpacing`)
```dart
class AppSpacing {
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
}
```

### 2.2 Corner Radii (`AppRadius`)
```dart
class AppRadius {
  static const double xs = 6.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double pill = 999.0;
}
```

### 2.3 Shadows & Elevation (`AppShadows`)
```dart
class AppShadows {
  static List<BoxShadow> subtle(BuildContext context); // 0px 2px 6px rgba(0,0,0,0.04)
  static List<BoxShadow> card(BuildContext context);   // 0px 4px 14px rgba(0,0,0,0.06)
  static List<BoxShadow> modal(BuildContext context);  // 0px 10px 30px rgba(0,0,0,0.12)
}
```

### 2.4 Color Tokens (`AppColors`)

| Token | Light Value | Dark Value | Usage |
|---|---|---|---|
| `primary` | `#3B5CE6` | `#6366F1` | Brand actions, primary CTA |
| `primaryContainer` | `#EEF2FF` | `#1E1B4B` | Selected navigation items, badge backgrounds |
| `onPrimaryContainer` | `#1E3A8A` | `#C7D2FE` | Text within primary containers |
| `background` | `#F8FAFC` | `#090D16` | Scaffold background |
| `surface` | `#FFFFFF` | `#111827` | Cards, bottom sheets, dialogs |
| `surfaceContainer` | `#F1F5F9` | `#1E293B` | Input fills, subtle backgrounds |
| `outline` | `#E2E8F0` | `#334155` | Card borders, dividers |
| `textPrimary` | `#0F172A` | `#F8FAFC` | Main headings, email subjects |
| `textSecondary` | `#475569` | `#94A3B8` | Body text, email snippets, subtitles |
| `textMuted` | `#94A3B8` | `#64748B` | Timestamps, helper hints |
| `success` | `#059669` | `#10B981` | Approved status, add-label chips |
| `successContainer` | `#ECFDF5` | `#064E3B` | Success banner background |
| `warning` | `#D97706` | `#F59E0B` | Low confidence alert, uncertainty warning |
| `warningContainer` | `#FFFBEB` | `#451A03` | Warning banner background |
| `error` | `#DC2626` | `#EF4444` | Sync failure, delete action |
| `errorContainer` | `#FEF2F2` | `#450A0A` | Error banner background |
| `aiAccent` | `#7C3AED` | `#A78BFA` | Natural language processing badge |
| `aiAccentContainer` | `#F5F3FF` | `#2E1065` | AI prompt preset chip background |

---

## 3. Component Specifications

### 3.1 `AppBadge`
- **Purpose**: Compact visual tag representing email labels, confidence scores, or condition tokens.
- **Variants**:
  - `label`: Neutral slate chip with `#` prefix or label icon.
  - `addLabel`: Emerald green tinted pill with `+` icon indicating an incoming label action.
  - `removeLabel`: Rose tinted pill with `-` icon indicating a removal action.
  - `aiConfidence`: Dynamic color pill (Emerald if >= 70%, Amber if < 70%).
  - `provider`: Violet pill denoting LLM engine (e.g. `Ollama (Local)` or `External Fallback`).

### 3.2 `AppButton`
- **Purpose**: Unified interactive button system ensuring consistent touch targets and loading animations.
- **Variants**:
  - `primary`: Filled button with primary brand color, bold label, optional leading icon, and built-in loading spinner.
  - `secondary`: Tonal container button for secondary actions.
  - `outlined`: Clean 1dp bordered button for neutral actions (e.g. "Dev Mode").
  - `destructive`: Red-tinted button for irreversible actions (e.g. "Delete Rule").
- **Height**: 48dp min, 12dp horizontal padding, 12dp border radius.

### 3.3 `AppCard`
- **Purpose**: Elevated content container with subtle border and rounded corners.
- **Properties**:
  - Background: `Theme.of(context).colorScheme.surface`.
  - Border: 1dp solid `Theme.of(context).colorScheme.outlineVariant`.
  - Radius: `AppRadius.md` (12dp) or `AppRadius.lg` (16dp).
  - Padding: `AppSpacing.lg` (16dp).

### 3.4 `EmailCard`
- **Purpose**: Displays an individual email with high information density and zero visual clutter.
- **Structure**:
  - Header: CircleAvatar with sender initial in gradient container, sender name, sender email, and formatted date (`10:42 AM` or `Oct 23`).
  - Body: Bold 14dp subject, 2-line snippet in muted slate.
  - Footer: Wrap row of `AppBadge` label chips.

### 3.5 `StatusBanner`
- **Purpose**: Non-intrusive feedback container for error, warning, success, and info states.
- **Structure**:
  - Leading status icon (Error outline, Warning amber, Info blue, or Check green).
  - Expanded message text.
  - Optional trailing action button (e.g. "Retry").

### 3.6 `EmptyStateView`
- **Purpose**: Informative, welcoming visual displayed when lists have no content.
- **Structure**:
  - Centered circular icon container with subtle primary accent.
  - Title in `titleLarge` font weight.
  - Descriptive explanation in `bodyMedium` font.
  - Optional CTA button.

---

## 4. Theme Configuration & Accessibility

### 4.1 Contrast Ratios
- All primary text achieves at least **7:1** contrast against surface backgrounds.
- All secondary metadata text achieves at least **4.5:1** contrast.
- Border outlines provide distinct visual boundaries without creating high visual friction.

### 4.2 Safe Area & Keyboard Handling
- All screens wrap content in `SafeArea`.
- Scroll views utilize `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
- Modal bottom sheets resize automatically when the virtual keyboard opens using `MediaQuery.of(context).viewInsets.bottom`.
