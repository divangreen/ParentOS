# PRD — ParentOS Newborn Copilot

## Problem

New parents are overwhelmed. They track feeding, sleep, and diapers across notebooks, apps, and memory — yet still lack confidence in whether their baby is on track.

## Solution

ParentOS: a mobile copilot that logs parenting events in 2 taps and turns that data into daily AI-powered summaries and recommendations.

## Target User

Primary: First-time parent with a 0–12 month baby, sleep-deprived, phone in one hand.
Secondary: Co-parent or caregiver sharing child care.

## Success Metric

100 active parents using the product and providing qualitative feedback.

## UX Principles

- One-handed operation
- Maximum 2 taps to log any event
- Large touch targets (min 48dp)
- Readable at 3am (high contrast, large text option)

---

## Epic 1: Authentication

**Goal:** A parent can create an account and securely access their data across sessions and devices.

### Story 1.1 — Sign Up

**As a** new parent
**I want to** create an account with my email and password
**So that** my parenting data is saved and private

**Acceptance Criteria:**
- [ ] Email + password sign up form with validation
- [ ] Error shown for duplicate email
- [ ] Error shown for weak password (< 8 chars)
- [ ] On success: redirected to Add Child screen
- [ ] Supabase Auth creates user record

**Dependencies:** None
**Risks:** Email deliverability for verification

---

### Story 1.2 — Log In

**As a** returning parent
**I want to** log in with my email and password
**So that** I can access my existing data

**Acceptance Criteria:**
- [ ] Email + password login form
- [ ] Error shown for wrong credentials
- [ ] Session persists after app close (secure storage)
- [ ] On success: redirected to Home screen

**Dependencies:** Story 1.1
**Risks:** Password reset flow (defer to Phase 2)

---

### Story 1.3 — Log Out

**As a** parent
**I want to** log out of my account
**So that** my data is protected on shared devices

**Acceptance Criteria:**
- [ ] Log out option accessible from settings
- [ ] Session cleared from device on log out
- [ ] Redirected to Log In screen

**Dependencies:** Story 1.2
**Risks:** None

---

## Epic 2: Child Profile

**Goal:** A parent can set up a profile for their baby so all logs are linked to the correct child.

### Story 2.1 — Add Child

**As a** parent
**I want to** add my baby's profile
**So that** all my logs are linked to my child

**Acceptance Criteria:**
- [ ] Form: name (required), date of birth (required), birth weight (optional)
- [ ] Date picker for DOB
- [ ] Child created in database linked to authenticated user
- [ ] On success: redirected to Home screen
- [ ] Child name shown on Home screen header

**Dependencies:** Story 1.1
**Risks:** Parents may want to add multiple children (defer to Phase 2)

---

### Story 2.2 — View Child Profile

**As a** parent
**I want to** view my child's profile
**So that** I can confirm their details are correct

**Acceptance Criteria:**
- [ ] Profile screen shows name, DOB, birth weight, age (calculated)
- [ ] Accessible from Home screen settings icon

**Dependencies:** Story 2.1
**Risks:** None

---

## Epic 3: Feeding Log

**Goal:** A parent can log feeding events in under 10 seconds using one hand.

### Story 3.1 — Log Breast Feed

**As a** parent
**I want to** log a breastfeeding session
**So that** ParentOS can track feeding frequency and duration

**Acceptance Criteria:**
- [ ] Accessible from Home screen in 1 tap
- [ ] Select: Breast feed
- [ ] Select side: Left / Right / Both
- [ ] Enter duration (minutes) — default: 15
- [ ] Timestamp auto-filled to now, editable
- [ ] Log saved and appears in today's feed list
- [ ] Success feedback (haptic + visual)

**Dependencies:** Story 2.1
**Risks:** Parents may forget to log — remind flow (Phase 2)

---

### Story 3.2 — Log Bottle Feed

**As a** parent
**I want to** log a bottle feeding
**So that** ParentOS can track volume consumed

**Acceptance Criteria:**
- [ ] Select: Bottle feed
- [ ] Enter volume in ml (default: 120ml) with +/- stepper
- [ ] Optional: select milk type (breast milk / formula)
- [ ] Timestamp auto-filled to now, editable
- [ ] Log saved and appears in today's feed list

**Dependencies:** Story 2.1
**Risks:** Units (ml vs oz) — store as ml, display preference in settings (Phase 2)

---

### Story 3.3 — View Feeding History

**As a** parent
**I want to** see today's feeding logs
**So that** I know when the last feed was and the total for the day

**Acceptance Criteria:**
- [ ] Home screen shows last feeding time and type
- [ ] Feeding section lists all today's feeds in reverse chronological order
- [ ] Each entry shows: type, side/volume, time, duration

**Dependencies:** Story 3.1, 3.2
**Risks:** None

---

## Epic 4: Sleep Log

**Goal:** A parent can log sleep sessions to track total daily sleep and identify patterns.

### Story 4.1 — Log Sleep Session

**As a** parent
**I want to** log when my baby slept and woke up
**So that** ParentOS can track sleep duration and total

**Acceptance Criteria:**
- [ ] Accessible from Home screen in 1 tap
- [ ] Enter sleep start time (default: now)
- [ ] Enter wake time (default: now)
- [ ] Select type: Nap / Night sleep
- [ ] Duration calculated and displayed
- [ ] Log saved and appears in today's sleep list
- [ ] Validation: wake time must be after sleep time

**Dependencies:** Story 2.1
**Risks:** Parents may want a live timer (defer to Phase 2)

---

### Story 4.2 — View Sleep History

**As a** parent
**I want to** see today's sleep logs
**So that** I can track total sleep and last wake time

**Acceptance Criteria:**
- [ ] Home screen shows last sleep session and total sleep today
- [ ] Sleep section lists all today's sessions in reverse chronological order
- [ ] Each entry shows: type, start, end, duration

**Dependencies:** Story 4.1
**Risks:** None

---

## Epic 5: Diaper Log

**Goal:** A parent can log diaper changes with one tap.

### Story 5.1 — Log Diaper Change

**As a** parent
**I want to** log a diaper change
**So that** ParentOS can monitor output patterns

**Acceptance Criteria:**
- [ ] Accessible from Home in 1 tap
- [ ] Select type: Wet / Dirty / Both
- [ ] Timestamp auto-filled to now, editable
- [ ] Log saved and appears in today's diaper list
- [ ] Total wet and dirty count shown on Home screen

**Dependencies:** Story 2.1
**Risks:** None

---

### Story 5.2 — View Diaper History

**As a** parent
**I want to** see today's diaper log count
**So that** I know if my baby's output is normal

**Acceptance Criteria:**
- [ ] Home screen shows today's diaper counts: X wet, Y dirty
- [ ] Diaper section lists all changes in reverse chronological order

**Dependencies:** Story 5.1
**Risks:** None

---

## Epic 6: AI Daily Summary

**Goal:** A parent receives an AI-generated summary of their baby's day with simple recommendations.

### Story 6.1 — Generate Daily Summary

**As a** parent
**I want to** receive an AI summary of my baby's day
**So that** I can understand patterns without analysing raw data myself

**Acceptance Criteria:**
- [ ] Summary generated once per day (nightly cron) OR on-demand via button
- [ ] Summary covers: feeding totals, sleep totals, diaper count
- [ ] Summary flags anomalies (e.g. long gap between feeds, low diaper count)
- [ ] Summary includes 1–2 plain-language recommendations
- [ ] Summary stored in database with timestamp
- [ ] Summary displayed as card on Home screen

**Dependencies:** Epics 3, 4, 5
**Risks:** No data → no summary (handle gracefully: "Log more events to generate your first summary")

---

### Story 6.2 — Push Notification for Summary

**As a** parent
**I want to** receive a push notification when my daily summary is ready
**So that** I don't have to open the app to know it's available

**Acceptance Criteria:**
- [ ] Push sent via Firebase FCM after summary is generated
- [ ] Notification tapping opens app directly to summary card
- [ ] Notification only sent if at least 3 events were logged that day

**Dependencies:** Story 6.1
**Risks:** Firebase setup complexity, notification permissions on iOS

---

## Non-Goals (Phase 1)

Medication, symptoms, telehealth, wearables, payments, video calls, marketplace, multiple children, live sleep timer, password reset, units preference, caregiver sharing.
