def test_health(client):
    res = client.get("/health")
    assert res.status_code == 200
    assert res.json() == {"status": "ok"}


def test_create_validation_error(client):
    # Missing 'title' must be rejected by Pydantic with 422.
    res = client.post("/reviews", json={"requestType": "x"})
    assert res.status_code == 422
