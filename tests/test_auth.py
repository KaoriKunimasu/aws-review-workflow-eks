import time

import jwt
import pytest
from cryptography.hazmat.primitives.asymmetric import rsa

from app.api.auth import AuthError, verify_token
from app.api import auth as auth_module
from app.api.config import settings


@pytest.fixture
def rsa_key_pair():
    private_key = rsa.generate_private_key(public_exponent=65537, key_size=2048)
    return private_key, private_key.public_key()


@pytest.fixture
def configure_cognito(monkeypatch):
    monkeypatch.setattr(settings, "cognito_user_pool_id", "ap-southeast-2_testpool")
    monkeypatch.setattr(settings, "cognito_region", "ap-southeast-2")
    monkeypatch.setattr(settings, "cognito_client_id", "test-client-id")


def _make_token(private_key, **claim_overrides):
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
    return jwt.encode(claims, private_key, algorithm="RS256", headers={"kid": "test-key"})


def test_verify_token_rejects_wrong_client_id(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair

    class FakeSigningKey:
        key = public_key

    monkeypatch.setattr(
        auth_module,
        "_get_jwks_client",
        lambda: type("C", (), {"get_signing_key_from_jwt": staticmethod(lambda t: FakeSigningKey())})(),
    )

    token = _make_token(private_key, client_id="a-different-client")
    with pytest.raises(AuthError) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_token_rejects_expired_token(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair

    class FakeSigningKey:
        key = public_key

    monkeypatch.setattr(
        auth_module,
        "_get_jwks_client",
        lambda: type("C", (), {"get_signing_key_from_jwt": staticmethod(lambda t: FakeSigningKey())})(),
    )

    now = int(time.time())
    token = _make_token(private_key, exp=now - 10)
    with pytest.raises(AuthError) as exc_info:
        verify_token(token)
    assert exc_info.value.status_code == 401


def test_verify_token_accepts_valid_token(configure_cognito, rsa_key_pair, monkeypatch):
    private_key, public_key = rsa_key_pair

    class FakeSigningKey:
        key = public_key

    monkeypatch.setattr(
        auth_module,
        "_get_jwks_client",
        lambda: type("C", (), {"get_signing_key_from_jwt": staticmethod(lambda t: FakeSigningKey())})(),
    )

    token = _make_token(private_key)
    claims = verify_token(token)
    assert claims["sub"] == "user-123"