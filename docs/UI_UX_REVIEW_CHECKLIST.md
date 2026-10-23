# Smart Inbox AI — UI/UX Review Checklist

This checklist is used to evaluate every screen, modal, and interactive state in the Smart Inbox AI application to maintain production-grade quality, accessibility, and visual harmony.

---

## 1. Visual Hierarchy & Typography
- [ ] **One Primary Action**: Does the screen have exactly one visually prominent primary call-to-action?
- [ ] **Type Scale Integrity**: Are all text elements using centralized typography styles (`AppTypography` or `Theme.of(context).textTheme`) rather than ad-hoc inline sizes?
- [ ] **Line Heights & Truncation**: Do multiline texts (email snippets, rule descriptions) use appropriate line heights without awkward clipping or ellipsis overflows?
- [ ] **Visual Weight**: Are key anchors (sender name, email subject, rule title) clearly distinguishable from secondary metadata (timestamps, email addresses)?

---

## 2. Color, Theme & Contrast
- [ ] **WCAG AA Compliance**: Does all text meet the minimum 4.5:1 contrast ratio against its surrounding background in both Light and Dark modes?
- [ ] **Dark Mode Fidelity**: Does the dark theme preserve depth without harsh saturated blocks or unreadable grey-on-black text?
- [ ] **Semantic Color Accuracy**:
  - [ ] Emerald green for successful actions and added labels (`add_label`).
  - [ ] Amber/yellow for uncertainty and confidence < 70%.
  - [ ] Rose/red for destructive actions and sync errors.
  - [ ] Violet/indigo for AI actions and presets.
- [ ] **No Hardcoded Hex Colors**: Are all colors derived from `AppColors` or `Theme.of(context).colorScheme`?

---

## 3. Spacing, Alignment & Layout
- [ ] **Grid Consistency**: Are all margins and paddings multiples of 4dp/8dp per `AppSpacing`?
- [ ] **Safe Area Coverage**: Are headers, navigation bars, and bottom sheets protected from system cutouts, home indicators, and status bars using `SafeArea`?
- [ ] **Touch Target Sizing**: Do all tappable elements (buttons, chips, checkboxes, icon buttons) span at least 48×48 dp?
- [ ] **Screen Responsiveness**: Does the layout flex gracefully across compact devices (e.g. 360dp width) without horizontal overflow or text overlapping?

---

## 4. Component Usability & States
- [ ] **Loading States**: Are async actions (email sync, rule analysis, action execution) clearly indicated with spinners or disabled buttons?
- [ ] **Empty States**: Do empty lists (empty inbox, no rules configured, no match results) display friendly illustrations, descriptive guidance, and a direct CTA?
- [ ] **Error Handling**: Are error messages human-readable, contextual, and paired with a clear "Retry" or recovery option?
- [ ] **Form & Input Behavior**:
  - [ ] Does tapping on input focus properly without covering the primary CTA?
  - [ ] Does dragging the scroll view dismiss the virtual keyboard?
  - [ ] Are input hints intuitive and actionable?

---

## 5. Gmail Safety & Privacy Safeguards
- [ ] **Zero Unapproved Writes**: Are Gmail label modifications strictly gated behind preview inspection and secondary approval dialog?
- [ ] **Count Verification**: Does the approval dialog explicitly announce the exact count of emails to be altered?
- [ ] **Destructive Action Prevention**: Are `delete`, `send`, `archive`, and `trash` strictly absent from all UI controls?
- [ ] **PII Protection**: Are email bodies kept out of UI logs and hidden from raw preview lists (only sender, subject, and snippet shown)?
- [ ] **Sandbox Visibility**: Is the user clearly aware when running in mock/sandbox mode versus live Google OAuth?

---

## 6. Motion & Feedback
- [ ] **Feedback Immediacy**: Do button taps provide instant tactile/visual ripple feedback?
- [ ] **Transitions**: Are modal sheets and navigation changes smooth (300ms ease-out) without jarring jumps or frame stutter?
- [ ] **No Gimmicky Animations**: Are animations purposeful (status changes, pull-to-refresh) rather than purely decorative?
