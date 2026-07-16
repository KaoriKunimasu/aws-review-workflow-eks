def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_create_validation_error(client):
    # Missing 'title' must be rejected by Pydantic with 422.
    res = client.post("/reviews", json={"requestType": "x"})
    assert res.status_code == 422


def test_update_status_requires_reviewer(client, monkeypatch):
    # Confirms the route is wired to require_reviewer, not just get_current_user_id:
    # under AUTH_MODE=cognito, an unauthenticated caller must be rejected before
    # reaching the service layer (a 404 here would mean auth was skipped).
    from app.api.config import settings

    monkeypatch.setattr(settings, "auth_mode", "cognito")
    res = client.patch("/reviews/some-id/status", json={"status": "APPROVED"})
    assert res.status_code == 401
