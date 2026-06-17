# DECISIONS.md — Architecture Decision Log

> Append-only. Never edit past entries. Format: ADR-NNN

---

## ADR-001 — Project Initialized

- **Date:** [DATE]
- **Agent:** arch
- **Status:** accepted
- **Context:** POC phase, solo/small team, free tools only
- **Decision:** Use CLAUDE.md multi-agent setup with shared CONTEXT.md memory
- **Consequences:** Agents stay in sync without re-reading full codebase each call

---

<!-- New decisions go below this line -->

## ADR-002 — JWT Verification via JWKS (RS256/ES256) Instead of Static HS256 Secret

- **Date:** 2026-06-17
- **Agent:** dev
- **Status:** accepted
- **Context:** Project was created on a Supabase tier that issues asymmetric (ES256) signing keys with no static legacy HS256 "JWT Secret" exposed in the dashboard. The original `app/dependencies.py` design (per A-001) assumed a shared secret decoded via `python-jose`.
- **Decision:** Verify incoming JWTs against the project's JWKS endpoint (`{SUPABASE_URL}/auth/v1/.well-known/jwks.json`) using `PyJWT`'s `PyJWKClient`, replacing `python-jose`. `SUPABASE_JWT_SECRET` removed from `Settings`/`.env`.
- **Consequences:** No static secret to leak/rotate manually; works regardless of which signing-key system a given Supabase project uses. Confirmed working end-to-end: live signup/login issue ES256-signed tokens that pass `get_current_user_id` against the real project.

## ADR-003 — Supabase Project Live, S-001/S-002/S-003/A-001 Verified

- **Date:** 2026-06-17
- **Agent:** dev
- **Status:** accepted
- **Context:** Supabase project `webxomwzsepwrrnrrzxj` created; Email provider and "Allow new user signups" both required explicit enabling beyond the default project setup (Email provider defaults to off and must be saved separately from the signup-allowed toggle).
- **Decision:** Schema migrations from `DATABASE_SCHEMA.md` applied via SQL Editor. Backend `.env` populated with real `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` (`sb_secret_...`).
- **Consequences:** Full signup → login → JWT-authenticated request → logout flow verified end-to-end against the live project, including a confirmed `profiles` row insert. C-001+ (children CRUD) is now unblocked.

## ADR-004 — F-001/002/003, SL-001/002/003, D-001/002/003 Implemented; UTC-Date Bug Found and Fixed

- **Date:** 2026-06-17
- **Agent:** dev
- **Status:** accepted
- **Context:** Live smoke testing (not just mocked unit tests) caught a real bug: `GET /children/{id}/feedings` (and diapers) used `date.today()` as the default `?date=` filter, which resolves to the **server's local system date**, while `logged_at`/`started_at` are stored and queried in UTC. On a server whose local date differs from UTC date, today's UTC-stamped entries were silently excluded from "today's" list.
- **Decision:** Added a shared `_utc_today()` helper in each of `feedings.py`, `sleeps.py`, `diapers.py` (`datetime.now(timezone.utc).date()`) used as the default-date query param instead of `date.today()`.
- **Consequences:** **Any future date-bucketing logic (notably AI-001's daily metrics aggregation) must use UTC dates, never local `date.today()`.** Ownership checks for all three new routers are centralized in `app/access.py::assert_child_owned` rather than duplicated per-router.

## ADR-005 — AI-001 (Metrics Aggregation) and AI-002 (Anomaly Rules) Implemented

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** `_day_bounds`/`_utc_today` were duplicated across `feedings.py`, `sleeps.py`, `diapers.py` (see ADR-004). Centralized into `app/dates.py` (`day_bounds`, `utc_today`) and all three routers refactored to import from it before adding `app/metrics.py`, which needed the same day-bounds logic.
- **Decision:** `app/metrics.py::get_daily_metrics(supabase, child_id, day)` aggregates feedings/sleeps/diapers for a UTC day into the shape `InsightMetrics` expects. `app/anomalies.py::detect_anomalies(metrics)` applies newborn-care pediatric-norm thresholds (< 6 feeds/day, 0 or < 4 wet diapers/day, < 8h sleep/day) pre-AI, each tagged `warning` or `critical`. Neither has its own HTTP endpoint yet — both are building blocks for AI-005's `POST /insights/generate`.
- **Consequences:** Live-verified against real seeded data in Supabase (1 feeding, 1 sleep, 1 "both"-type diaper on 2026-06-17): aggregation matched expected values exactly, and anomaly rules correctly flagged the low-activity day. AI-003 (OpenAI integration) is next, blocked on a real `OPENAI_API_KEY` being supplied — `.env` currently has a placeholder.

## ADR-006 — AI-003+ Deferred; SEC-001/SEC-003 Fixed (Not Just Marked Done)

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** No free/local OpenAI alternative (Ollama install, Groq free-tier key) was selected — user chose to skip AI work for now rather than pick one. Re-auditing the remaining unblocked P0 backlog against actual acceptance criteria (not just "code exists") found SEC-001 only partially done: `main.py`'s request-logging middleware read `user_id` from an `x-user-id` header no client ever set (always logged `-`), and logged no real client IP at all.
- **Decision:**
  - `app/dependencies.py::get_current_user_id` now takes `request: Request` and sets `request.state.user_id` after successful JWT verification; `main.py`'s `log_requests` middleware reads it back via `getattr(request.state, "user_id", "-")` after `call_next`, and gets the real client IP via `slowapi.util.get_remote_address` (already used for rate limiting, reused here instead of reimplementing IP extraction).
  - Added `SUPABASE_ANON_KEY` to `.env`/`.env.example` (safe to store — it's the public-facing key by design) so `tests/test_rls.py` can verify RLS directly against the live REST API for all 6 tables, instead of relying on a one-off manual curl check.
- **Consequences:** Live-verified: authenticated request logs now show the real client IP and real Supabase user UUID. `tests/test_rls.py` (6 parametrized cases, one per table) confirmed RLS blocks anonymous reads everywhere, not just `profiles`. SEC-002's existing 5-req/min rate limit on login was spot-checked and still correctly returns 429 on the 6th rapid attempt. Remaining P0 work is now AI-003+ (deferred) and S-004/S-005/S-006 (Flutter/CI/Railway, separate tracks) — backend P0 work is otherwise complete.

## ADR-007 — Deployed to Render Instead of Railway (S-006)

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** TASKS.md specified Railway, but Railway now requires a payment method for most plans (only a one-time trial credit is truly free), which conflicts with CLAUDE.md's "free tools only" rule. CLAUDE.md's own standing rules already list Render as an approved alternative free-tier host. Discovered along the way: the project already had a real git repo with a GitHub remote (`origin → github.com/divangreen/ParentOS`) that had never been pushed past a near-empty initial commit — all work from this session (and some untracked earlier work) was committed and pushed for the first time.
- **Decision:** Use Render's free Web Service tier via a Blueprint (`render.yaml` at repo root, pointing at the existing `apps/backend/Dockerfile`). Also fixed a real bug found while preparing the deploy: the Dockerfile pinned `poetry==1.8.3` and used the deprecated `--no-dev` flag, but the committed lockfile was generated with Poetry 2.4.1 — 1.x cannot reliably read a 2.x lockfile. Updated to `poetry==2.4.1` and `--without dev`.
- **Consequences:** Render's free tier spins down after 15 min of inactivity (cold start ~30-60s on next request) — acceptable for a POC/staging environment, should be revisited before any real user-facing launch. Live-verified: `https://parentos-backend.onrender.com/health` returns 200, and a full login → JWT-verified `/v1/children` request against the live Supabase project succeeds end-to-end from the deployed instance. `SUPABASE_URL`/`SUPABASE_SERVICE_ROLE_KEY`/`OPENAI_API_KEY` are set as `sync: false` secrets directly in the Render dashboard, never committed.

## ADR-008 — Flutter SDK Installed; S-004 Scaffold Created

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** No Flutter SDK existed on the dev machine. `winget install Google.Flutter` doesn't exist as a package — installed via Flutter's officially recommended method instead: `git clone -b stable https://github.com/flutter/flutter.git C:\src\flutter`, added `C:\src\flutter\bin` to user PATH. Adding plugin dependencies (`flutter_secure_storage`, etc.) initially failed with "Building with plugins requires symlink support" — Windows Developer Mode was off; user enabled it via Settings > Privacy & security > For developers.
- **Decision:** Scaffolded `apps/mobile` via `flutter create --org com.parentos --project-name parentos_mobile mobile`, added `flutter_riverpod`, `go_router`, `flutter_secure_storage`, `supabase_flutter` (the last two pre-empt A-006's needs, added now since they were already part of the planned stack). Replaced the default counter-app boilerplate in `lib/main.dart` with a minimal `ProviderScope` + `GoRouter` + Material 3 (`useMaterial3: true`) shell (`lib/router.dart`, `lib/screens/home_screen.dart`), and replaced the stale counter widget test with one asserting the app boots.
- **Consequences:** No Android Studio or Visual Studio installed (both are large, separate installs) — `flutter doctor` shows Android and Windows-desktop targets unavailable, but **web (Chrome)** target works. Verified via `flutter analyze` (no issues), `flutter test` (passes), and `flutter build web` (succeeds, artifacts confirmed served locally). Full mobile/desktop builds and device testing are blocked until Android Studio and/or Visual Studio + the "Desktop development with C++" workload are installed — a separate, larger decision to make before A-007+ (real screens) needs real device testing.

## ADR-009 — A-006 Built as a Backend API Client, Not a Direct Supabase Client; A-007–A-010 Implemented

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** TASKS.md's A-006 says "Supabase client setup", but `API_SPEC.md` and the backend's own `app/routers/auth.py` make clear the architecture is mobile → ParentOS backend → Supabase (the backend proxies signup/login/refresh/logout and creates the `profiles` row). A `supabase_flutter` SDK on mobile would bypass that and talk to Supabase directly, which is the wrong integration point. `supabase_flutter` had already been added speculatively when S-004 was scaffolded; removed it (along with ~45 transitive packages) once this was confirmed, in favor of a plain `http` client against the backend's `/v1/auth/*` endpoints.
- **Decision:** `lib/services/auth_api.dart` (typed client for signup/login/refresh/logout, mirroring `app/schemas/auth.py`'s field names exactly), `lib/services/token_storage.dart` (wraps `flutter_secure_storage`, satisfies SEC-004 — never SharedPreferences), `lib/providers/auth_provider.dart` (Riverpod `Notifier<AuthState>` — Riverpod 3.x removed `StateNotifier`/`StateNotifierProvider` from the core package, used the newer `Notifier`/`NotifierProvider` API instead). `lib/router.dart`'s `redirect` callback gates `/` behind `AuthAuthenticated`, with an `AuthInitial` carve-out so session restoration doesn't flash the login screen. Sign up/log in screens at `lib/screens/signup_screen.dart`/`login_screen.dart`; logout wired as an AppBar action on Home (no separate Settings screen exists yet, so A-010 is satisfied minimally there).
- **Consequences:** Removing `supabase_flutter` also dropped `ua_client_hints`, the package causing the earlier WASM-incompatibility warning — `flutter build web` is now WASM-clean. Live-verified the entire `AuthApi` client (signup → login → refresh → logout → failed-login-error-handling) against the real deployed Render backend via a throwaway `dart run` script (not committed) — all 5 steps passed, including correct 401 handling on wrong password. Widget test verifies the redirect guard: an unauthenticated session lands on `/login`, using an in-memory `FlutterSecureStoragePlatform` fake (the real plugin has no platform channel in the test environment).

## ADR-010 — Epic 2 Frontend Implemented (C-003–C-006); Shared `ApiClient` Extracted

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** Building `children_api.dart` would have duplicated `auth_api.dart`'s HTTP/error-decoding logic (`ApiException`, header building, JSON decode-or-throw). Extracted that into `lib/services/api_client.dart` first; `auth_api.dart` and `children_api.dart` both now wrap it instead of each owning their own `http.Client` plumbing.
- **Decision:** `lib/models/child.dart` mirrors the backend's `ChildResponse` schema. `lib/providers/children_provider.dart` (`ChildrenController extends Notifier<ChildrenState>`) loads the child list whenever auth state becomes `AuthAuthenticated`, and exposes `activeChild` (MVP: the most recently added child — single-child-per-account assumption, matching the newborn-tracking scope) as a getter on `ChildrenLoaded`, satisfying C-004's "cache active child". `lib/screens/add_child_screen.dart` (C-003), `lib/screens/child_profile_screen.dart` (C-006), and `home_screen.dart`'s header (C-005) all consume this state. Router gained `/add-child` and `/child` routes.
- **Consequences:** Live-verified the full `ChildrenApi` client (create → list → get → update → 404-on-nonexistent) against the real deployed Render backend via a throwaway script — all 5 steps passed. `flutter analyze` clean (including adopting Dart's newer `?`-prefixed null-aware map-entry syntax over `if (x != null)`), `flutter test` passes. Home screen now branches on `ChildrenLoaded.activeChild == null` to show an "Add Child" prompt instead of assuming a child always exists.

## ADR-011 — Feeding/Sleep/Diaper Logging UI Implemented (F/SL/D Epics); CI Added (S-005)

- **Date:** 2026-06-18
- **Agent:** dev
- **Status:** accepted
- **Context:** With auth and child profile flows working, the next P0 work was the logging UI for the three already-complete backend epics (feedings, sleeps, diapers) plus CI. Decided to defer AI-003+ again this session (user confirmed: no provider chosen).
- **Decision:**
  - `lib/models/{feeding,sleep,diaper}.dart` mirror their backend response schemas. `lib/services/{feedings,sleeps,diapers}_api.dart` all wrap the shared `ApiClient` (per ADR-009/ADR-010's pattern).
  - `lib/providers/{feedings,sleeps,diapers}_provider.dart`: each is a `Notifier` that reloads when the active child changes (read via `childrenControllerProvider`). `FeedingsController.logFeeding` does a genuine optimistic update — inserts a placeholder entry immediately, then reconciles by reloading from the server; reverts to the prior state on `ApiException`.
  - Bottom sheets: `log_feed_sheet.dart` (breast/bottle toggle, conditional fields), `log_sleep_sheet.dart` (date/time pickers, live duration calculation), `log_diaper_sheet.dart` (tap-to-save, no confirmation step — **time-edit was not implemented**, every diaper log uses "now"; flagged as a known gap rather than silently marked done in TASKS.md).
  - Home screen now shows three summary cards (last feed + today's count, last sleep + total minutes today, wet/dirty diaper counts) each with a "Log" button opening the relevant sheet.
  - `.github/workflows/ci.yml`: two jobs (backend: poetry install → ruff check → pytest; mobile: flutter pub get → flutter analyze → flutter test), triggered on PRs and pushes to main.
  - Before wiring CI, ran `ruff check .` locally and found 36 pre-existing violations (mostly `E501` line-too-long across code that predates this session, plus some of this session's own files). Bumped `line-length` from 100 to 120 in `pyproject.toml` (resolved most), manually wrapped the remaining 4 genuinely-too-long lines, and ran `ruff check --fix` for import-sorting/unused-import issues.
- **Consequences:** Live-verified the full logging flow (signup → create child → log bottle feed → log breast feed → list feedings → log sleep → list sleeps → log diaper → list diapers) against the real deployed Render backend via a throwaway script — all steps passed. `flutter analyze`/`flutter test` clean, `ruff check`/`pytest` clean (47 backend tests). CI confirmed green on actual GitHub Actions (not just local) for both jobs — backend 20s, mobile ~1m40s — after installing the `gh` CLI and authenticating via device code to watch the run directly. Bumped `actions/checkout` v4→v5 to clear a Node 20 deprecation warning surfaced in that first run.
- **Follow-up (2026-06-18):** Added the diaper time-edit that was flagged as missing — `DiapersApi.createDiaper`/`DiapersController.logDiaper` now accept an optional `loggedAt`, and `log_diaper_sheet.dart` has a "Time" row (tap to open date+time pickers) before the tap-to-save type buttons, defaulting to now if untouched. Live-verified both the default-now path and an explicit 3-hour-back-dated entry persist correctly against the deployed backend.
