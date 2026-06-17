# ParentOS Backend

FastAPI backend for ParentOS. See `/ParentOS/TASKS.md` and `/ParentOS/DATABASE_SCHEMA.md` for project context.

## Setup

```
poetry install
cp .env.example .env  # fill in Supabase credentials
poetry run uvicorn main:app --reload
```

## Tests

```
poetry run pytest
```
