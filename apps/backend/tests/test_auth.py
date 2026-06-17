"""
Auth endpoint tests — requires a live Supabase project with email confirmation disabled.
Run with: pytest tests/test_auth.py -v
"""
from unittest.mock import MagicMock, patch

from fastapi.testclient import TestClient

from main import app

client = TestClient(app)

SIGNUP_URL = "/v1/auth/signup"
LOGIN_URL = "/v1/auth/login"
REFRESH_URL = "/v1/auth/refresh"
LOGOUT_URL = "/v1/auth/logout"


def _mock_auth_result(user_id: str = "user-123") -> MagicMock:
    session = MagicMock(access_token="access-token", refresh_token="refresh-token")
    user = MagicMock(id=user_id)
    return MagicMock(user=user, session=session)


# --- signup ---

def test_signup_validation_short_password():
    resp = client.post(SIGNUP_URL, json={"email": "a@b.com", "password": "short"})
    assert resp.status_code == 422


def test_signup_validation_invalid_email():
    resp = client.post(SIGNUP_URL, json={"email": "not-an-email", "password": "password123"})
    assert resp.status_code == 422


def test_signup_duplicate_email():
    from supabase_auth.errors import AuthApiError

    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.sign_up.side_effect = AuthApiError("User already registered", 422, {})

        resp = client.post(SIGNUP_URL, json={"email": "taken@b.com", "password": "password123"})

    assert resp.status_code == 409


def test_signup_success():
    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.sign_up.return_value = _mock_auth_result("uid-1")
        sb.table.return_value.upsert.return_value.execute.return_value = MagicMock()

        resp = client.post(SIGNUP_URL, json={"email": "new@b.com", "password": "password123"})

    assert resp.status_code == 201
    body = resp.json()
    assert body["user_id"] == "uid-1"
    assert body["access_token"] == "access-token"
    assert body["refresh_token"] == "refresh-token"


# --- login ---

def test_login_invalid_credentials():
    from supabase_auth.errors import AuthApiError

    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.sign_in_with_password.side_effect = AuthApiError("Invalid login credentials", 400, {})

        resp = client.post(LOGIN_URL, json={"email": "a@b.com", "password": "wrongpass"})

    assert resp.status_code == 401
    # Must not reveal whether the email exists
    assert resp.json()["detail"] == "Invalid credentials"


def test_login_success():
    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.sign_in_with_password.return_value = _mock_auth_result("uid-2")

        resp = client.post(LOGIN_URL, json={"email": "a@b.com", "password": "password123"})

    assert resp.status_code == 200
    assert resp.json()["user_id"] == "uid-2"


# --- refresh ---

def test_refresh_invalid_token():
    from supabase_auth.errors import AuthApiError

    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.refresh_session.side_effect = AuthApiError("Invalid refresh token", 400, {})

        resp = client.post(REFRESH_URL, json={"refresh_token": "bad-token"})

    assert resp.status_code == 401


def test_refresh_success():
    with patch("app.routers.auth.get_supabase") as mock_get:
        sb = MagicMock()
        mock_get.return_value = sb
        sb.auth.refresh_session.return_value = _mock_auth_result()

        resp = client.post(REFRESH_URL, json={"refresh_token": "valid-token"})

    assert resp.status_code == 200
    body = resp.json()
    assert "access_token" in body
    assert "refresh_token" in body


# --- logout ---

def test_logout_no_token():
    resp = client.post(LOGOUT_URL)
    assert resp.status_code in (401, 403)  # HTTPBearer returns 403 pre-0.99, 401 after


def test_logout_invalid_token():
    resp = client.post(LOGOUT_URL, headers={"Authorization": "Bearer bad.token.here"})
    assert resp.status_code == 401
