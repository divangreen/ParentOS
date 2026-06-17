from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.dependencies import get_current_user_id
from main import app

USER_ID = "user-123"
CHILD_ID = str(uuid4())
client = TestClient(app)

URL = f"/v1/children/{CHILD_ID}/sleeps"


@pytest.fixture(autouse=True)
def _auth_override():
    app.dependency_overrides[get_current_user_id] = lambda: USER_ID
    yield
    app.dependency_overrides.pop(get_current_user_id, None)


def _row(**overrides) -> dict:
    started = datetime.now(timezone.utc)
    row = {
        "id": str(uuid4()),
        "type": "nap",
        "started_at": started.isoformat(),
        "ended_at": (started + timedelta(minutes=45)).isoformat(),
        "duration_minutes": 45,
        "created_at": started.isoformat(),
    }
    row.update(overrides)
    return row


def test_create_sleep_success():
    with patch("app.routers.sleeps.get_supabase") as mock_get, patch(
        "app.routers.sleeps.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        sb.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[_row()])

        started = datetime.now(timezone.utc)
        ended = started + timedelta(minutes=30)
        resp = client.post(
            URL,
            json={"type": "nap", "started_at": started.isoformat(), "ended_at": ended.isoformat()},
        )

    assert resp.status_code == 201
    assert resp.json()["duration_minutes"] == 45


def test_create_sleep_ended_before_started_rejected():
    started = datetime.now(timezone.utc)
    ended = started - timedelta(minutes=10)
    resp = client.post(
        URL, json={"type": "nap", "started_at": started.isoformat(), "ended_at": ended.isoformat()}
    )
    assert resp.status_code == 422


def test_list_sleeps_totals_minutes():
    with patch("app.routers.sleeps.get_supabase") as mock_get, patch(
        "app.routers.sleeps.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = (
            sb.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.order.return_value.limit.return_value
        )
        query.execute.return_value = MagicMock(data=[_row(duration_minutes=45), _row(duration_minutes=30)])

        resp = client.get(URL)

    assert resp.status_code == 200
    assert resp.json()["total_minutes_today"] == 75


def test_delete_sleep_not_found():
    with patch("app.routers.sleeps.get_supabase") as mock_get, patch(
        "app.routers.sleeps.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.delete.return_value.eq.return_value.eq.return_value.eq.return_value
        query.execute.return_value = MagicMock(data=[])

        resp = client.delete(f"{URL}/{uuid4()}")

    assert resp.status_code == 404
