# Smart Inbox AI — User Stories & Acceptance Criteria

## Epic 1: Gmail Connection

### US-1.1: Sign in with Google
**As a** user, **I want to** sign in with my Google account **so that** the app can access my Gmail.

**Acceptance Criteria:**
- [ ] Tapping "Connect Gmail" launches the Google OAuth consent screen.
- [ ] After granting permission, the app shows a "Connected" status with the user's email.
- [ ] OAuth tokens are exchanged server-side; the mobile app never sees raw tokens.
- [ ] If the user denies permission, the app shows a clear error and allows retry.
- [ ] No token values appear in application logs.

### US-1.2: Disconnect Gmail
**As a** user, **I want to** disconnect my Gmail account **so that** the app no longer has access.

**Acceptance Criteria:**
- [ ] Tapping "Disconnect" revokes the OAuth token and clears all cached data.
- [ ] The app returns to the unauthenticated state.
- [ ] Confirmation dialog appears before disconnecting.

---

## Epic 2: Email Sync & Analysis

### US-2.1: Manually sync recent emails
**As a** user, **I want to** sync my recent emails on demand **so that** I can see what's in my inbox.

**Acceptance Criteria:**
- [ ] Tapping "Sync" fetches the most recent 50 emails (configurable up to 200).
- [ ] A loading indicator is shown during sync.
- [ ] Each email displays: sender, subject, date, snippet (first ~100 chars).
- [ ] Full email bodies are not stored on the device or server.
- [ ] Sync completes within 5 seconds for 50 emails.
- [ ] Error states (network failure, expired token) show clear messages.

### US-2.2: View email list
**As a** user, **I want to** browse my synced emails **so that** I can understand what rules might help.

**Acceptance Criteria:**
- [ ] Emails are displayed in reverse chronological order.
- [ ] Each item shows sender, subject, date, and a short snippet.
- [ ] Tapping an email shows metadata detail (not full body).
- [ ] A badge shows total email count.

---

## Epic 3: Natural Language Rules

### US-3.1: Create a rule from natural language
**As a** user, **I want to** describe an email management rule in plain English **so that** the app creates it for me.

**Acceptance Criteria:**
- [ ] A text input field allows typing rules like "Label emails from amazon.com as Shopping".
- [ ] Tapping "Create Rule" sends the text to the backend.
- [ ] The backend returns a structured rule (name, conditions, actions).
- [ ] The structured rule is displayed for review before saving.
- [ ] If the LLM produces invalid output, a clear error is shown.
- [ ] Response time is under 10 seconds; a loading state is shown.

### US-3.2: Edit a rule
**As a** user, **I want to** edit an existing rule **so that** I can refine its behavior.

**Acceptance Criteria:**
- [ ] Tapping "Edit" on a rule opens it with the original natural language text.
- [ ] User can modify the text and re-submit for LLM conversion.
- [ ] The new structured rule replaces the old one after confirmation.
- [ ] The rule version history is preserved (at least previous version).

### US-3.3: Enable/disable a rule
**As a** user, **I want to** enable or disable a rule **so that** I can control which rules are active.

**Acceptance Criteria:**
- [ ] Each rule has a toggle switch (enabled/disabled).
- [ ] Disabled rules are visually distinct (grayed out).
- [ ] Disabled rules are skipped during classification.
- [ ] Toggling does not delete the rule.

### US-3.4: Delete a rule
**As a** user, **I want to** delete a rule I no longer need.

**Acceptance Criteria:**
- [ ] A "Delete" action is available with confirmation dialog.
- [ ] Deleted rules are removed from the list permanently.
- [ ] Action history for the deleted rule remains accessible for 24 hours.

---

## Epic 4: Preview & Approve

### US-4.1: Preview rule matches
**As a** user, **I want to** see which emails a rule would match **so that** I can verify before applying.

**Acceptance Criteria:**
- [ ] After creating/editing a rule, a preview screen shows matching emails.
- [ ] Each match shows: email subject, sender, and the proposed action.
- [ ] The count of matching emails is displayed.
- [ ] No Gmail changes are made at this stage.

### US-4.2: Approve and apply actions
**As a** user, **I want to** approve the proposed actions **so that** labels are applied to my Gmail.

**Acceptance Criteria:**
- [ ] An "Apply" button is only enabled after preview.
- [ ] Tapping "Apply" sends the approved actions to the backend.
- [ ] The backend applies Gmail label changes.
- [ ] A success/failure summary is shown after completion.
- [ ] Each applied action is recorded in the action history.
- [ ] If a label doesn't exist in Gmail, it is created automatically.
- [ ] Failed individual actions don't block the remaining actions.
- [ ] No retries on non-idempotent actions without checking current state.

### US-4.3: View action history
**As a** user, **I want to** see a log of actions taken **so that** I can audit what the app has done.

**Acceptance Criteria:**
- [ ] Action history shows: timestamp, rule name, email subject, action taken, result.
- [ ] History is sorted by most recent first.
- [ ] History persists across app sessions (stored locally on device).

---

## Epic 5: Development & Testing Modes

### US-5.1: Development mode with mock data
**As a** developer, **I want to** run the app with mock email data **so that** I can develop without Gmail access.

**Acceptance Criteria:**
- [ ] A dev mode flag enables mock data throughout the app.
- [ ] Mock data includes 20+ sample emails with varied senders/subjects.
- [ ] All features work identically with mock data.
- [ ] Mock mode is clearly indicated in the UI.

### US-5.2: Gmail-connected test mode
**As a** tester, **I want to** test with a real Gmail account in a safe manner.

**Acceptance Criteria:**
- [ ] Test mode connects to a real Gmail account.
- [ ] Only `add_label` and `remove_label` actions are available.
- [ ] Delete and send actions are blocked at the API level.
- [ ] A test-mode banner is visible in the UI.
