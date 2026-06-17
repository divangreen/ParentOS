# Tasks — ParentOS Phase 1

Each task is completable in under 4 hours. Dependencies listed as Task IDs.

---

## SETUP

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| S-001 | ✅ Create Supabase project, enable Auth + Storage | — | 1h | P0 |
| S-002 | ✅ Run DATABASE_SCHEMA.md migrations in Supabase | S-001 | 1h | P0 |
| S-003 | ✅ Initialise FastAPI project in `/apps/backend` with Uvicorn, Poetry, `.env` | — | 2h | P0 |
| S-004 | ✅ Initialise Flutter project in `/apps/mobile` with Riverpod, GoRouter, Material 3 | — | 2h | P0 |
| S-005 | ✅ Configure GitHub Actions CI: lint + test on PR | S-003, S-004 | 2h | P0 |
| S-006 | ✅ Deploy backend to Render (staging env) | S-003 | 1h | P0 |

---

## AUTHENTICATION (Epic 1)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| A-001 | ✅ Backend: Supabase JWT validation FastAPI dependency (JWKS/RS256, see ADR-002) | S-003, S-001 | 2h | P0 |
| A-002 | ✅ Backend: POST /auth/signup — proxy to Supabase Auth + create profile row | A-001 | 2h | P0 |
| A-003 | ✅ Backend: POST /auth/login — proxy to Supabase Auth | A-001 | 1h | P0 |
| A-004 | ✅ Backend: POST /auth/refresh | A-001 | 1h | P0 |
| A-005 | ✅ Backend: POST /auth/logout + rate limiting middleware | A-001 | 2h | P0 |
| A-006 | ✅ Frontend: Backend API client + `flutter_secure_storage` token service | S-004 | 2h | P0 |
| A-007 | ✅ Frontend: Sign Up screen (email, password, validation) | A-006 | 3h | P0 |
| A-008 | ✅ Frontend: Log In screen | A-006 | 2h | P0 |
| A-009 | ✅ Frontend: Auth state via Riverpod (persist session, redirect guard) | A-006, A-007, A-008 | 3h | P0 |
| A-010 | ✅ Frontend: Log out action (AppBar icon, not yet a dedicated Settings screen) | A-009 | 1h | P0 |

---

## CHILD PROFILE (Epic 2)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| C-001 | ✅ Backend: POST /children | A-001, S-002 | 2h | P0 |
| C-002 | ✅ Backend: GET /children, GET /children/{id}, PATCH /children/{id} | C-001 | 2h | P0 |
| C-003 | ✅ Frontend: Add Child screen (name, DOB picker, birth weight) | A-009 | 3h | P0 |
| C-004 | ✅ Frontend: Riverpod child provider (load + cache active child) | C-003 | 2h | P0 |
| C-005 | ✅ Frontend: Home screen header (child name + age) | C-004 | 1h | P0 |
| C-006 | ✅ Frontend: Child Profile view screen | C-004 | 2h | P1 |

---

## FEEDING LOG (Epic 3)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| F-001 | ✅ Backend: POST /children/{id}/feedings with validation | C-001 | 2h | P0 |
| F-002 | ✅ Backend: GET /children/{id}/feedings?date=&limit= | F-001 | 1h | P0 |
| F-003 | ✅ Backend: DELETE /children/{id}/feedings/{id} | F-001 | 1h | P1 |
| F-004 | ✅ Frontend: Log Feed bottom sheet (breast/bottle, side, duration/volume, time) | C-004 | 4h | P0 |
| F-005 | ✅ Frontend: Feeding Riverpod provider (optimistic update on POST) | F-004 | 2h | P0 |
| F-006 | ✅ Frontend: Feeding list on Home screen (last feed time, today's count) | F-005 | 2h | P0 |

---

## SLEEP LOG (Epic 4)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| SL-001 | ✅ Backend: POST /children/{id}/sleeps with validation (ended_at > started_at) | C-001 | 2h | P0 |
| SL-002 | ✅ Backend: GET /children/{id}/sleeps?date= (includes total_minutes_today) | SL-001 | 1h | P0 |
| SL-003 | ✅ Backend: DELETE /children/{id}/sleeps/{id} | SL-001 | 1h | P1 |
| SL-004 | ✅ Frontend: Log Sleep bottom sheet (type, start time, end time, duration calculated) | C-004 | 3h | P0 |
| SL-005 | ✅ Frontend: Sleep Riverpod provider | SL-004 | 2h | P0 |
| SL-006 | ✅ Frontend: Sleep summary on Home screen (last sleep, total today) | SL-005 | 1h | P0 |

---

## DIAPER LOG (Epic 5)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| D-001 | ✅ Backend: POST /children/{id}/diapers | C-001 | 1h | P0 |
| D-002 | ✅ Backend: GET /children/{id}/diapers?date= (includes wet/dirty counts) | D-001 | 1h | P0 |
| D-003 | ✅ Backend: DELETE /children/{id}/diapers/{id} | D-001 | 1h | P1 |
| D-004 | ✅ Frontend: Log Diaper bottom sheet (type tap = auto-save; time-edit not yet implemented, always logs "now") | C-004 | 2h | P0 |
| D-005 | ✅ Frontend: Diaper Riverpod provider | D-004 | 1h | P0 |
| D-006 | ✅ Frontend: Diaper count on Home screen (wet X, dirty Y) | D-005 | 1h | P0 |

---

## AI DAILY SUMMARY (Epic 6)

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| AI-001 | ✅ Backend: Metrics aggregation queries (feedings, sleeps, diapers per day) | F-001, SL-001, D-001 | 2h | P0 |
| AI-002 | ✅ Backend: Anomaly detection rules (Python, pre-AI) | AI-001 | 2h | P0 |
| AI-003 | Backend: OpenAI integration (prompt template, call, parse response) | AI-001 | 3h | P0 |
| AI-004 | Backend: Ollama fallback provider (same interface as OpenAI client) | AI-003 | 2h | P1 |
| AI-005 | Backend: POST /children/{id}/insights/generate | AI-003 | 2h | P0 |
| AI-006 | Backend: GET /children/{id}/insights/latest | AI-005 | 1h | P0 |
| AI-007 | Backend: Nightly cron job (Railway Cron, 10pm user timezone) | AI-005 | 2h | P0 |
| AI-008 | Backend: Firebase FCM push notification after summary generation | AI-007 | 2h | P1 |
| AI-009 | Frontend: AI Summary card on Home screen (collapsed + expandable) | AI-006 | 3h | P0 |
| AI-010 | Frontend: "Generate Summary" on-demand button | AI-009 | 1h | P1 |

---

## SECURITY

| ID | Description | Dependencies | Estimate | Priority |
|----|-------------|-------------|----------|---------|
| SEC-001 | ✅ Backend: API request logging middleware (IP, endpoint, user_id) | S-003 | 2h | P0 |
| SEC-002 | ✅ Backend: Rate limiting on /auth/login (5 req/min/IP, slowapi) | A-003 | 1h | P0 |
| SEC-003 | ✅ Supabase: Confirm RLS active on all 6 tables, write integration test | S-002 | 2h | P0 |
| SEC-004 | ✅ Frontend: Confirm flutter_secure_storage for all tokens (no SharedPreferences) | A-006 | 1h | P0 |

---

## Priority Order (P0 critical path)

S-001 → S-002 → S-003/S-004 (parallel) → A-001 → A-002/A-003 → A-006 → A-007/A-008 → A-009 →
C-001 → C-003 → C-004 → C-005 →
F-001/SL-001/D-001 (parallel) → F-004/SL-004/D-004 (parallel) →
AI-001 → AI-002 → AI-003 → AI-005/AI-006 → AI-007 → AI-009

Total P0 estimate: ~60–70 hours of focused implementation.
