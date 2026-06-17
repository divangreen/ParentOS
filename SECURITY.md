# Security Review — ParentOS

Reviewed against: DATABASE_SCHEMA.md, API_SPEC.md
Scope: Authentication, data leakage, child privacy (PDPA)

---

## Authentication

- [x] **Risk:** JWT not validated server-side on every request
  **Impact:** HIGH — attacker could access any user's data
  **Mitigation:** FastAPI dependency validates Supabase JWT on every protected route. Never trust client-supplied `user_id` in request body — derive from verified token only.

- [x] **Risk:** Weak password accepted
  **Impact:** MEDIUM — account takeover via brute force
  **Mitigation:** Enforce 8-char minimum (API + Supabase Auth). Rate-limit `/auth/login` to 5 attempts per minute per IP.

- [x] **Risk:** Refresh token stored insecurely on device
  **Impact:** HIGH — device theft exposes account
  **Mitigation:** Store tokens in Flutter `flutter_secure_storage` (iOS Keychain, Android Keystore). Never in SharedPreferences.

- [x] **Risk:** No session revocation on logout
  **Impact:** MEDIUM — stolen token remains valid after logout
  **Mitigation:** Call Supabase `signOut()` on logout, which invalidates the refresh token server-side.

---

## Data Leakage

- [x] **Risk:** User A reads User B's child data via guessed UUID
  **Impact:** CRITICAL — privacy violation
  **Mitigation:** Row Level Security on every table. Policy: `user_id = auth.uid()`. Never bypass RLS in application code.

- [x] **Risk:** `user_id` accepted in POST body, allowing impersonation
  **Impact:** HIGH — attacker logs events under another user's account
  **Mitigation:** Ignore any `user_id` in request body. Always set `user_id = auth.uid()` from verified JWT in the backend.

- [x] **Risk:** API returns data beyond the requested date range
  **Impact:** LOW — excess data exposure
  **Mitigation:** Server enforces `limit` (max 200) and `date` filter on all list endpoints. Pagination required for >200 results.

- [x] **Risk:** AI summary content stored without encryption
  **Impact:** LOW — Supabase encrypts at rest by default
  **Mitigation:** Confirm Supabase project has encryption at rest enabled (default: yes). Document in ARCHITECTURE.md.

- [x] **Risk:** AI provider (OpenAI) receives PII (baby name, DOB)
  **Impact:** MEDIUM — third-party data sharing
  **Mitigation:** Send only computed metrics to OpenAI — never baby name, DOB, or user email. Prompt uses placeholder `{name}` from our side only if explicitly needed; default to "your baby."

---

## Child Privacy (PDPA)

- [x] **Risk:** Child data retained after account deletion
  **Impact:** HIGH — PDPA compliance failure
  **Mitigation:** `ON DELETE CASCADE` on all child tables. Account deletion triggers Supabase Auth user deletion → cascade deletes all child records within 30 days.

- [x] **Risk:** No privacy policy at sign-up
  **Impact:** HIGH — legal requirement
  **Mitigation:** Sign-up screen must link to privacy policy. Policy must disclose: data stored in Singapore (Supabase), AI processing via OpenAI (USA), no data sold. Required before launch.

- [x] **Risk:** No audit log for data access
  **Impact:** MEDIUM — cannot investigate breaches
  **Mitigation:** Enable Supabase database logging. Log all API requests (IP, endpoint, user_id) via FastAPI middleware. Retain logs 90 days.

- [x] **Risk:** Firebase FCM push token stored without consent
  **Impact:** MEDIUM — PDPA requires consent for notifications
  **Mitigation:** Request notification permission explicitly before registering FCM token. Store FCM token in profiles table only after permission granted.

---

## Implementation Checklist

- [ ] JWT validation dependency on every FastAPI route
- [ ] RLS policies confirmed active on all 6 tables
- [ ] Login rate limiting (5 req/min/IP)
- [ ] `flutter_secure_storage` for token storage
- [ ] OpenAI prompt sends metrics only, no PII
- [ ] ON DELETE CASCADE tested end-to-end
- [ ] Privacy policy page live before first user
- [ ] API request logging middleware in FastAPI
- [ ] Supabase encryption at rest confirmed
