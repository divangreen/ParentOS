from datetime import date, datetime, timezone
from unittest.mock import MagicMock, patch
from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.dependencies import get_current_user_id
from main import app

USER_ID = "user-123"
client = TestClient(app)

CHILDREN_URL = "/v1/children"


@pytest.fixture(autouse=True)
def _auth_override():
    app.dependency_overrides[get_current_user_id] = lambda: USER_ID
    yield
    app.dependency_overrides.pop(get_current_user_id, None)


def _row(**overrides) -> dict:
    row = {
        "id": str(uuid4()),
        "user_id": USER_ID,
        "name": "Test Child",
        "date_of_birth": date.today().isoformat(),
        "birth_weight_kg": 3.2,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    row.update(overrides)
    return row


# --- create ---


def test_create_child_success():
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.table.return_value.insert.return_value.execute.return_value = MagicMock(data=[_row()])

        resp = client.post(CHILDREN_URL, json={"name": "Test Child", "date_of_birth": date.today().isoformat()})

    assert resp.status_code == 201
    assert resp.json()["name"] == "Test Child"
    assert resp.json()["age_days"] == 0


def test_create_child_future_dob_rejected():
    resp = client.post(CHILDREN_URL, json={"name": "X", "date_of_birth": "2099-01-01"})
    assert resp.status_code == 422


def test_create_child_invalid_weight_rejected():
    resp = client.post(
        CHILDREN_URL,
        json={"name": "X", "date_of_birth": date.today().isoformat(), "birth_weight_kg": 50},
    )
    assert resp.status_code == 422


# --- list ---


def test_list_children():
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.select.return_value.eq.return_value.order.return_value
        query.execute.return_value = MagicMock(data=[_row(), _row()])

        resp = client.get(CHILDREN_URL)

    assert resp.status_code == 200
    assert len(resp.json()["children"]) == 2


# --- get one ---


def test_get_child_not_found():
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value
        query.execute.return_value = MagicMock(data=[])

        resp = client.get(f"{CHILDREN_URL}/{uuid4()}")

    assert resp.status_code == 404


def test_get_child_success():
    row = _row()
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value
        query.execute.return_value = MagicMock(data=[row])

        resp = client.get(f"{CHILDREN_URL}/{row['id']}")

    assert resp.status_code == 200
    assert resp.json()["id"] == row["id"]


# --- update ---


def test_update_child_not_found():
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        query = sb.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value
        query.execute.return_value = MagicMock(data=[])

        resp = client.patch(f"{CHILDREN_URL}/{uuid4()}", json={"name": "New Name"})

    assert resp.status_code == 404


def test_update_child_success():
    row = _row()
    updated_row = _row(id=row["id"], name="New Name")
    with patch("app.routers.children.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        select_query = sb.table.return_value.select.return_value.eq.return_value.eq.return_value.limit.return_value
        select_query.execute.return_value = MagicMock(data=[row])
        update_query = sb.table.return_value.update.return_value.eq.return_value.eq.return_value
        update_query.execute.return_value = MagicMock(data=[updated_row])

        resp = client.patch(f"{CHILDREN_URL}/{row['id']}", json={"name": "New Name"})

    assert resp.status_code == 200
    assert resp.json()["name"] == "New Name"
