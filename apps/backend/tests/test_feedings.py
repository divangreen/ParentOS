from datetime import datetime, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.dependencies import get_current_user_id
from main import app

USER_ID = "user-123"
CHILD_ID = str(uuid4())
client = TestClient(app)

URL = f"/v1/children/{CHILD_ID}/feedings"


@pytest.fixture(autouse=True)
def _auth_override():
    app.dependency_overrides[get_current_user_id] = lambda: USER_ID
    yield
    app.dependency_overrides.pop(get_current_user_id, None)


def _row(**overrides) -> dict:
    row = {
        "id": str(uuid4()),
        "type": "bottle",
        "side": None,
        "duration_minutes": None,
        "volume_ml": 90,
        "milk_type": "formula",
        "logged_at": datetime.now(timezone.utc).isoformat(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    row.update(overrides)
    return row


def test_create_feeding_child_not_owned():
    from fastapi import HTTPException

    with patch("app.routers.feedings.assert_child_owned") as mock_assert, patch(
        "app.routers.feedings.get_supabase"
    ):
        mock_assert.side_effect = HTTPException(status_code=404, detail="Child not found")
        resp = client.post(URL, json={"type": "bottle", "volume_ml": 90})
    assert resp.status_code == 404


def test_create_feeding_bottle_success():
    with patch("app.routers.feedings.get_supabase") as mock_get, patch(
        "app.routers.feedings.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        sb.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[_row()])

        resp = client.post(URL, json={"type": "bottle", "volume_ml": 90})

    assert resp.status_code == 201
    assert resp.json()["volume_ml"] == 90


def test_create_feeding_breast_missing_duration_rejected():
    resp = client.post(URL, json={"type": "breast", "side": "left"})
    assert resp.status_code == 422


def test_list_feedings():
    with patch("app.routers.feedings.get_supabase") as mock_get, patch(
        "app.routers.feedings.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = (
            sb.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.order.return_value.limit.return_value
        )
        query.execute.return_value = MagicMock(data=[_row(), _row()])

        resp = client.get(URL)

    assert resp.status_code == 200
    assert resp.json()["total"] == 2


def test_delete_feeding_not_found():
    with patch("app.routers.feedings.get_supabase") as mock_get, patch(
        "app.routers.feedings.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.delete.return_value.eq.return_value.eq.return_value.eq.return_value
        query.execute.return_value = MagicMock(data=[])

        resp = client.delete(f"{URL}/{uuid4()}")

    assert resp.status_code == 404


def test_delete_feeding_success():
    feeding_id = str(uuid4())
    with patch("app.routers.feedings.get_supabase") as mock_get, patch(
        "app.routers.feedings.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.delete.return_value.eq.return_value.eq.return_value.eq.return_value
        query.execute.return_value = MagicMock(data=[{"id": feeding_id}])

        resp = client.delete(f"{URL}/{feeding_id}")

    assert resp.status_code == 204
