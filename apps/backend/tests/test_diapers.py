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

URL = f"/v1/children/{CHILD_ID}/diapers"


@pytest.fixture(autouse=True)
def _auth_override():
    app.dependency_overrides[get_current_user_id] = lambda: USER_ID
    yield
    app.dependency_overrides.pop(get_current_user_id, None)


def _row(**overrides) -> dict:
    row = {
        "id": str(uuid4()),
        "type": "wet",
        "logged_at": datetime.now(timezone.utc).isoformat(),
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    row.update(overrides)
    return row


def test_create_diaper_success():
    with patch("app.routers.diapers.get_supabase") as mock_get, patch(
        "app.routers.diapers.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        sb.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[_row()])

        resp = client.post(URL, json={"type": "wet"})

    assert resp.status_code == 201
    assert resp.json()["type"] == "wet"


def test_list_diapers_counts():
    with patch("app.routers.diapers.get_supabase") as mock_get, patch(
        "app.routers.diapers.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = (
            sb.table.return_value.select.return_value.eq.return_value.gte.return_value.lt.return_value.order.return_value.limit.return_value
        )
        query.execute.return_value = MagicMock(
            data=[_row(type="wet"), _row(type="dirty"), _row(type="both")]
        )

        resp = client.get(URL)

    assert resp.status_code == 200
    body = resp.json()
    assert body["wet_count"] == 2
    assert body["dirty_count"] == 2


def test_delete_diaper_not_found():
    with patch("app.routers.diapers.get_supabase") as mock_get, patch(
        "app.routers.diapers.assert_child_owned"
    ):
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.delete.return_value.eq.return_value.eq.return_value.eq.return_value
        query.execute.return_value = MagicMock(data=[])

        resp = client.delete(f"{URL}/{uuid4()}")

    assert resp.status_code == 404
