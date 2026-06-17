"""
SEC-003 — live RLS verification. Skipped automatically unless real Supabase
credentials are present in .env (separate from the dummy values conftest.py
sets for the rest of the mocked test suite).

Run explicitly: poetry run pytest tests/test_rls.py -v
"""
from pathlib import Path

import httpx
import pytest
from dotenv import dotenv_values

_ENV_PATH = Path(__file__).parent.parent / ".env"
_env = dotenv_values(_ENV_PATH) if _ENV_PATH.exists() else {}

SUPABASE_URL = _env.get("SUPABASE_URL", "")
ANON_KEY = _env.get("SUPABASE_ANON_KEY", "")

_live_credentials_present = (
    SUPABASE_URL
    and ANON_KEY
    and "your-project" not in SUPABASE_URL
    and "your-anon" not in ANON_KEY
)

pytestmark = pytest.mark.skipif(
    not _live_credentials_present,
    reason="Live Supabase credentials not found in .env — SEC-003 RLS test only runs against a real project",
)

TABLES = ["profiles", "children", "feedings", "sleeps", "diapers", "ai_insights"]


@pytest.mark.parametrize("table", TABLES)
def test_rls_blocks_anonymous_read(table: str):
    resp = httpx.get(
        f"{SUPABASE_URL}/rest/v1/{table}",
        params={"select": "id"},
        headers={"apikey": ANON_KEY},
        timeout=10,
    )
    assert resp.status_code == 200, f"{table}: unexpected status {resp.status_code} — {resp.text}"
    assert resp.json() == [], f"{table}: RLS did not block anonymous read, got {resp.json()}"
