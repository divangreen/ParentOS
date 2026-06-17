# Database Schema — ParentOS

PostgreSQL via Supabase. Row Level Security (RLS) enabled on all tables.

---

## Table: users

Managed by Supabase Auth (`auth.users`). Extended via public profile.

### Table: profiles

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, FK → auth.users.id | Matches Supabase Auth user ID |
| email | text | NOT NULL | Denormalised from auth for convenience |
| created_at | timestamptz | NOT NULL, DEFAULT now() | |
| updated_at | timestamptz | NOT NULL, DEFAULT now() | |

**RLS:** Users can only SELECT/UPDATE their own row (`auth.uid() = id`).

---

## Table: children

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, DEFAULT gen_random_uuid() | |
| user_id | uuid | NOT NULL, FK → profiles.id ON DELETE CASCADE | Owner |
| name | text | NOT NULL | Display name |
| date_of_birth | date | NOT NULL | |
| birth_weight_kg | numeric(4,3) | NULLABLE | Optional |
| created_at | timestamptz | NOT NULL, DEFAULT now() | |
| updated_at | timestamptz | NOT NULL, DEFAULT now() | |

**Indexes:**
- `children_user_id_idx` ON `user_id`

**RLS:** Users can only SELECT/INSERT/UPDATE/DELETE their own children (`user_id = auth.uid()`).

---

## Table: feedings

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, DEFAULT gen_random_uuid() | |
| child_id | uuid | NOT NULL, FK → children.id ON DELETE CASCADE | |
| user_id | uuid | NOT NULL, FK → profiles.id | Denormalised for RLS |
| type | text | NOT NULL, CHECK IN ('breast', 'bottle') | |
| side | text | NULLABLE, CHECK IN ('left', 'right', 'both') | Breast only |
| duration_minutes | integer | NULLABLE | Breast only |
| volume_ml | integer | NULLABLE | Bottle only |
| milk_type | text | NULLABLE, CHECK IN ('breast_milk', 'formula') | Bottle only |
| logged_at | timestamptz | NOT NULL | Editable event time |
| created_at | timestamptz | NOT NULL, DEFAULT now() | Record creation |

**Indexes:**
- `feedings_child_id_logged_at_idx` ON `(child_id, logged_at DESC)`
- `feedings_user_id_idx` ON `user_id`

**Constraints:**
- CHECK: if `type = 'breast'` then `duration_minutes IS NOT NULL`
- CHECK: if `type = 'bottle'` then `volume_ml IS NOT NULL`

**RLS:** `user_id = auth.uid()`

---

## Table: sleeps

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, DEFAULT gen_random_uuid() | |
| child_id | uuid | NOT NULL, FK → children.id ON DELETE CASCADE | |
| user_id | uuid | NOT NULL, FK → profiles.id | Denormalised for RLS |
| type | text | NOT NULL, CHECK IN ('nap', 'night') | |
| started_at | timestamptz | NOT NULL | Sleep start |
| ended_at | timestamptz | NOT NULL | Sleep end |
| duration_minutes | integer | GENERATED ALWAYS AS (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60)::integer STORED | Calculated |
| created_at | timestamptz | NOT NULL, DEFAULT now() | |

**Indexes:**
- `sleeps_child_id_started_at_idx` ON `(child_id, started_at DESC)`

**Constraints:**
- CHECK: `ended_at > started_at`

**RLS:** `user_id = auth.uid()`

---

## Table: diapers

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, DEFAULT gen_random_uuid() | |
| child_id | uuid | NOT NULL, FK → children.id ON DELETE CASCADE | |
| user_id | uuid | NOT NULL, FK → profiles.id | Denormalised for RLS |
| type | text | NOT NULL, CHECK IN ('wet', 'dirty', 'both') | |
| logged_at | timestamptz | NOT NULL | Editable event time |
| created_at | timestamptz | NOT NULL, DEFAULT now() | |

**Indexes:**
- `diapers_child_id_logged_at_idx` ON `(child_id, logged_at DESC)`

**RLS:** `user_id = auth.uid()`

---

## Table: ai_insights

| Column | Type | Constraints | Notes |
|--------|------|-------------|-------|
| id | uuid | PK, DEFAULT gen_random_uuid() | |
| child_id | uuid | NOT NULL, FK → children.id ON DELETE CASCADE | |
| user_id | uuid | NOT NULL, FK → profiles.id | Denormalised for RLS |
| type | text | NOT NULL, CHECK IN ('daily', 'weekly') | |
| summary_date | date | NOT NULL | The day the summary covers |
| content | text | NOT NULL | Full AI-generated summary text |
| metrics | jsonb | NOT NULL | Structured data used to generate: feeds, sleep total, diapers |
| model | text | NOT NULL | e.g. 'gpt-4o-mini', 'llama3' |
| token_count | integer | NULLABLE | For cost tracking |
| created_at | timestamptz | NOT NULL, DEFAULT now() | |

**Indexes:**
- `ai_insights_child_id_summary_date_idx` ON `(child_id, summary_date DESC)`
- UNIQUE ON `(child_id, type, summary_date)` — one summary per day per type

**RLS:** `user_id = auth.uid()`

---

## Relationships

```
profiles
  └── children (1:many)
        ├── feedings (1:many)
        ├── sleeps (1:many)
        ├── diapers (1:many)
        └── ai_insights (1:many)
```

---

## Migrations

Run in order:

```sql
-- 1. profiles (extends auth.users)
CREATE TABLE profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own profile" ON profiles
  USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

-- 2. children
CREATE TABLE children (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name text NOT NULL,
  date_of_birth date NOT NULL,
  birth_weight_kg numeric(4,3),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX children_user_id_idx ON children(user_id);
ALTER TABLE children ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own children" ON children
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 3. feedings
CREATE TABLE feedings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id uuid NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  type text NOT NULL CHECK (type IN ('breast', 'bottle')),
  side text CHECK (side IN ('left', 'right', 'both')),
  duration_minutes integer,
  volume_ml integer,
  milk_type text CHECK (milk_type IN ('breast_milk', 'formula')),
  logged_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX feedings_child_id_logged_at_idx ON feedings(child_id, logged_at DESC);
ALTER TABLE feedings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own feedings" ON feedings
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 4. sleeps
CREATE TABLE sleeps (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id uuid NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  type text NOT NULL CHECK (type IN ('nap', 'night')),
  started_at timestamptz NOT NULL,
  ended_at timestamptz NOT NULL,
  duration_minutes integer GENERATED ALWAYS AS (
    (EXTRACT(EPOCH FROM (ended_at - started_at)) / 60)::integer
  ) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT sleeps_valid_duration CHECK (ended_at > started_at)
);
CREATE INDEX sleeps_child_id_started_at_idx ON sleeps(child_id, started_at DESC);
ALTER TABLE sleeps ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own sleeps" ON sleeps
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 5. diapers
CREATE TABLE diapers (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id uuid NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  type text NOT NULL CHECK (type IN ('wet', 'dirty', 'both')),
  logged_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX diapers_child_id_logged_at_idx ON diapers(child_id, logged_at DESC);
ALTER TABLE diapers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own diapers" ON diapers
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

-- 6. ai_insights
CREATE TABLE ai_insights (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  child_id uuid NOT NULL REFERENCES children(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES profiles(id),
  type text NOT NULL CHECK (type IN ('daily', 'weekly')),
  summary_date date NOT NULL,
  content text NOT NULL,
  metrics jsonb NOT NULL DEFAULT '{}',
  model text NOT NULL,
  token_count integer,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (child_id, type, summary_date)
);
CREATE INDEX ai_insights_child_id_summary_date_idx ON ai_insights(child_id, summary_date DESC);
ALTER TABLE ai_insights ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own insights" ON ai_insights
  USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
```
