from app.api import service


def test_update_status_rejects_invalid_status():
    try:
        service.update_status("fake-id", {"status": "BOGUS"})
        assert False, "expected ServiceError"
    except service.ServiceError as exc:
        assert exc.status_code == 400
        assert "status" in (exc.details or {})


def test_allowed_statuses_match_original_handler():
    # Guard that the migration preserved the original status set.
    assert service.ALLOWED_STATUSES == {"OPEN", "IN_REVIEW", "APPROVED", "REJECTED"}
