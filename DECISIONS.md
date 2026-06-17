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
