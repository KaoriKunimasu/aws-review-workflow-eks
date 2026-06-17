from fastapi import Header


def get_current_user_id(x_user_id: str | None = Header(default=None)) -> str:
    """Interim stub for the Cognito JWT 'sub' claim used by the original Lambda.

    Replaced by real Cognito JWT verification once the app runs on EKS. Keeping
    it isolated here makes that a one-file change.
    """
    return x_user_id or "anonymous"
