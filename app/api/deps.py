from fastapi import Header, HTTPException

from app.api.auth import AuthError, verify_token
from app.api.config import settings

REVIEWER_GROUP = "reviewer"


def _resolve_claims(authorization: str | None) -> dict:
    """Resolve the calling user's verified claims.

    AUTH_MODE=cognito verifies a real Cognito access token from the
    Authorization header. The token's `groups` claim is populated by a
    Pre Token Generation Lambda trigger from the user's Cognito group
    membership (see infra/modules/cognito). AUTH_MODE=none (local
    development only) returns a fixed placeholder identity in the
    reviewer group and performs no verification — unlike the previous
    X-User-Id stub, there is no way to pass an arbitrary identity in
    this mode.
    """
    if settings.auth_mode == "none":
        return {"sub": "local-dev-user", "groups": REVIEWER_GROUP}

    if authorization is None or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing bearer token.")

    token = authorization.removeprefix("Bearer ").strip()
    try:
        claims = verify_token(token)
    except AuthError as exc:
        raise HTTPException(status_code=exc.status_code, detail=exc.message) from exc

    return claims


def get_current_user_id(authorization: str | None = Header(default=None)) -> str:
    """Resolve the calling user's identity. Any authenticated caller passes."""
    return _resolve_claims(authorization)["sub"]


def require_reviewer(authorization: str | None = Header(default=None)) -> str:
    """Resolve identity and require membership in the reviewer group.

    Authentication alone (a valid token) is not enough here: the caller
    must also belong to the `reviewer` Cognito group, so that submitting
    a request and approving/rejecting one are not the same permission —
    a requester cannot review their own submission just by having an
    account.
    """
    claims = _resolve_claims(authorization)
    groups = (claims.get("groups") or "").split(",")
    if REVIEWER_GROUP not in groups:
        raise HTTPException(status_code=403, detail="Reviewer role required.")
    return claims["sub"]