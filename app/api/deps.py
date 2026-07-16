from fastapi import Header, HTTPException

from app.api.auth import AuthError, verify_token
from app.api.config import settings


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Resolve the calling user's identity.

    AUTH_MODE=cognito verifies a real Cognito access token from the
    Authorization header and returns its `sub` claim. AUTH_MODE=none
    (local development only) returns a fixed placeholder identity and
    performs no verification — unlike the previous X-User-Id stub, there
    is no way to pass an arbitrary identity in this mode.
    """
    if settings.auth_mode == "none":
        return "local-dev-user"

    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token.")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        claims = verify_token(token)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc

    return claims["sub"]