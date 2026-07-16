import jwt
from jwt import PyJWKClient

from app.api.config import settings


class AuthError(Exception):
    """Carries an HTTP status code, mirroring service.ServiceError."""

    def __init__(self, status_code: int, message: str):
        super().__init__(message)
        self.status_code = status_code
        self.message = message


_jwks_client: PyJWKClient | None = None


def _issuer() -> str:
    return f"https://cognito-idp.{settings.cognito_region}.amazonaws.com/{settings.cognito_user_pool_id}"


def _get_jwks_client() -> PyJWKClient:
    global _jwks_client
    if _jwks_client is None:
        jwks_url = f"{_issuer()}/.well-known/jwks.json"
        # PyJWKClient caches keys in-process; a 1-hour lifespan matches
        # Cognito's own signing key rotation cadence closely enough that
        # a rotated key is picked up well within a deployment's lifetime.
        _jwks_client = PyJWKClient(jwks_url, cache_keys=True, lifespan=3600)
    return _jwks_client


def verify_token(token: str) -> dict:
    """Verify a Cognito access token and return its claims.

    Checks the signature against Cognito's published JWKS, the issuer,
    and expiry. Cognito access tokens carry no `aud` claim, so the client
    ID is checked separately against `client_id` and `token_use`, per
    Cognito's own token verification guidance, rather than through
    PyJWT's built-in `audience` check.
    """
    try:
        signing_key = _get_jwks_client().get_signing_key_from_jwt(token)
    except Exception as exc:
        raise AuthError(401, "Unable to verify token signature.") from exc

    try:
        claims = jwt.decode(
            token,
            signing_key.key,
            algorithms=["RS256"],
            issuer=_issuer(),
            options={"verify_aud": False},
        )
    except jwt.ExpiredSignatureError as exc:
        raise AuthError(401, "Token has expired.") from exc
    except jwt.InvalidIssuerError as exc:
        raise AuthError(401, "Token issuer does not match this user pool.") from exc
    except jwt.InvalidTokenError as exc:
        raise AuthError(401, "Token is invalid.") from exc

    if claims.get("token_use") != "access":
        raise AuthError(401, "Token is not an access token.")
    if claims.get("client_id") != settings.cognito_client_id:
        raise AuthError(401, "Token was not issued for this app client.")

    return claims