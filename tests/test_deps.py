import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa
from fastapi import HTTPException

from app.api import auth as auth_module
from app.api import deps
from app.api.config import settings


@pytest.fixture
def rsa_key_pair():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    return private_key, private_key.public_key()


@pytest.fixture
def configure_cognito(monkeypatch):
    monkeypatch.setattr(settings, "auth_mode", "cognito")
    monkeypatch.setattr(settings, "cognito_user_pool_id", "ap-southeast-2_testpool")
    monkeypatch.setattr(settings, "cognito_region", "ap-southeast-2")
    monkeypatch.setattr(settings, "cognito_client_id", "test-client-id")


def _bearer_token(private_key, **claim_overrides):
    now = int(time.time())
    claims = {
        "sub": "user-123",
        "token_use": "access",
        "client_id": "test-client-id",
        "iss": "https://cognito-idp.ap-southeast-2.amazonaws.com/ap-southeast-2_testpool",
        "iat": now,
        "exp": now + 3600,
    }
    claims.update(claim_overrides)
    token = jwt.encode(claims, private_key, algorithm="RS256", headers={"kid": "test-key"})
    return f"Bearer {token}"


def _patch_jwks(monkeypatch, public_key):
    class FakeSigningKey:
        key = public_key

    monkeypatch.setattr(
        auth_module,
        "_get_jwks_client",
        lambda: type("C", (), {"get_signing_key_from_jwt": staticmethod(lambda t: FakeSigningKey())})(),
    )


def test_require_reviewer_accepts_reviewer_group(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair
    _patch_jwks(monkeypatch, public_key)

    authorization = _bearer_token(private_key, groups="reviewer,other-group")
    assert deps.require_reviewer(authorization) == "user-123"


def test_require_reviewer_rejects_non_reviewer(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair
    _patch_jwks(monkeypatch, public_key)

    authorization = _bearer_token(private_key, groups="some-other-group")
    with pytest.raises(HTTPException) as exc_info:
        deps.require_reviewer(authorization)
    assert exc_info.value.status_code == 403


def test_require_reviewer_rejects_missing_groups_claim(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair
    _patch_jwks(monkeypatch, public_key)

    authorization = _bearer_token(private_key)
    with pytest.raises(HTTPException) as exc_info:
        deps.require_reviewer(authorization)
    assert exc_info.value.status_code == 403


def test_get_current_user_id_ignores_group_membership(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair
    _patch_jwks(monkeypatch, public_key)

    authorization = _bearer_token(private_key, groups="")
    assert deps.get_current_user_id(authorization) == "user-123"


def test_none_auth_mode_placeholder_is_a_reviewer(monkeypatch):
    monkeypatch.setattr(settings, "auth_mode", "none")
    assert deps.require_reviewer(None) == "local-dev-user"
