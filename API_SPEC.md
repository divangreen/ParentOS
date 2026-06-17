# API Specification — ParentOS

Base URL: `https://api.parentos.app/v1`
Auth: Bearer JWT (Supabase Auth token) on all endpoints except `/auth/*`
Content-Type: `application/json`

---

## Auth

### POST /auth/signup

Request:
```json
{ "email": "string", "password": "string (min 8 chars)" }
```

Response 201:
```json
{ "user_id": "uuid", "access_token": "string", "refresh_token": "string" }
```

Errors:
| Code | Reason |
|------|--------|
| 400 | Validation failed (weak password, invalid email) |
| 409 | Email already registered |

---

### POST /auth/login

Request:
```json
{ "email": "string", "password": "string" }
```

Response 200:
```json
{ "user_id": "uuid", "access_token": "string", "refresh_token": "string" }
```

Errors:
| Code | Reason |
|------|--------|
| 401 | Invalid credentials |

---

### POST /auth/refresh

Request:
```json
{ "refresh_token": "string" }
```

Response 200:
```json
{ "access_token": "string", "refresh_token": "string" }
```

---

### POST /auth/logout

Headers: `Authorization: Bearer <token>`
Request: (empty)
Response 204: (empty)

---

## Children

### POST /children

Request:
```json
{
  "name": "string (required)",
  "date_of_birth": "date (YYYY-MM-DD, required)",
  "birth_weight_kg": "number (optional)"
}
```

Response 201:
```json
{
  "id": "uuid",
  "name": "string",
  "date_of_birth": "string",
  "birth_weight_kg": "number | null",
  "age_days": "integer",
  "created_at": "datetime"
}
```

Validation:
- `name`: 1–100 chars
- `date_of_birth`: not in future, not more than 366 days ago
- `birth_weight_kg`: 0.5–6.0 if provided

Errors:
| Code | Reason |
|------|--------|
| 400 | Validation failed |
| 401 | Unauthenticated |

---

### GET /children

Response 200:
```json
{
  "children": [
    {
      "id": "uuid",
      "name": "string",
      "date_of_birth": "string",
      "birth_weight_kg": "number | null",
      "age_days": "integer",
      "created_at": "datetime"
    }
  ]
}
```

---

### GET /children/{child_id}

Response 200: same shape as single child above.

Errors:
| Code | Reason |
|------|--------|
| 404 | Child not found or not owned by user |

---

### PATCH /children/{child_id}

Request: any subset of POST body fields.
Response 200: updated child object.

---

## Feedings

### POST /children/{child_id}/feedings

Request (breast):
```json
{
  "type": "breast",
  "side": "left | right | both",
  "duration_minutes": "integer (1–120)",
  "logged_at": "datetime (optional, defaults to now)"
}
```

Request (bottle):
```json
{
  "type": "bottle",
  "volume_ml": "integer (10–500)",
  "milk_type": "breast_milk | formula (optional)",
  "logged_at": "datetime (optional, defaults to now)"
}
```

Response 201:
```json
{
  "id": "uuid",
  "type": "string",
  "side": "string | null",
  "duration_minutes": "integer | null",
  "volume_ml": "integer | null",
  "milk_type": "string | null",
  "logged_at": "datetime",
  "created_at": "datetime"
}
```

Validation:
- `type = 'breast'`: `side` and `duration_minutes` required
- `type = 'bottle'`: `volume_ml` required
- `logged_at`: not more than 24h in future, not more than 7 days in past

Errors:
| Code | Reason |
|------|--------|
| 400 | Validation failed |
| 404 | Child not found |

---

### GET /children/{child_id}/feedings

Query params:
- `date` (YYYY-MM-DD, default today)
- `limit` (default 50, max 200)

Response 200:
```json
{
  "feedings": [ /* array of feeding objects */ ],
  "total": "integer"
}
```

---

### DELETE /children/{child_id}/feedings/{feeding_id}

Response 204.

---

## Sleeps

### POST /children/{child_id}/sleeps

Request:
```json
{
  "type": "nap | night",
  "started_at": "datetime",
  "ended_at": "datetime"
}
```

Response 201:
```json
{
  "id": "uuid",
  "type": "string",
  "started_at": "datetime",
  "ended_at": "datetime",
  "duration_minutes": "integer",
  "created_at": "datetime"
}
```

Validation:
- `ended_at` must be after `started_at`
- Duration must be 1–1440 minutes (max 24h)

Errors:
| Code | Reason |
|------|--------|
| 400 | `ended_at` not after `started_at` |
| 404 | Child not found |

---

### GET /children/{child_id}/sleeps

Query params: `date`, `limit` (same as feedings)

Response 200:
```json
{
  "sleeps": [ /* array of sleep objects */ ],
  "total_minutes_today": "integer"
}
```

---

### DELETE /children/{child_id}/sleeps/{sleep_id}

Response 204.

---

## Diapers

### POST /children/{child_id}/diapers

Request:
```json
{
  "type": "wet | dirty | both",
  "logged_at": "datetime (optional, defaults to now)"
}
```

Response 201:
```json
{
  "id": "uuid",
  "type": "string",
  "logged_at": "datetime",
  "created_at": "datetime"
}
```

---

### GET /children/{child_id}/diapers

Query params: `date`, `limit`

Response 200:
```json
{
  "diapers": [ /* array of diaper objects */ ],
  "wet_count": "integer",
  "dirty_count": "integer"
}
```

---

### DELETE /children/{child_id}/diapers/{diaper_id}

Response 204.

---

## AI Insights

### POST /children/{child_id}/insights/generate

Triggers on-demand summary generation. Returns existing summary if already generated today.

Request: (empty)

Response 200:
```json
{
  "id": "uuid",
  "type": "daily",
  "summary_date": "date",
  "content": "string",
  "metrics": {
    "feeding_count": "integer",
    "total_volume_ml": "integer | null",
    "total_breast_minutes": "integer | null",
    "sleep_total_minutes": "integer",
    "diaper_wet_count": "integer",
    "diaper_dirty_count": "integer"
  },
  "created_at": "datetime"
}
```

Errors:
| Code | Reason |
|------|--------|
| 400 | Fewer than 3 events logged today — not enough data |
| 503 | AI provider unavailable |

---

### GET /children/{child_id}/insights/latest

Response 200: same shape as above, or 404 if no summary exists yet.

---

## Common Error Shape

```json
{
  "error": "string (machine-readable code)",
  "message": "string (human-readable)",
  "field": "string | null (for validation errors)"
}
```
