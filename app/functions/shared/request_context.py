import base64
import json
from typing import Any


def parse_json_body(event: dict) -> dict:
    body = event.get("body")

    if body is None:
        return {}

    if isinstance(body, dict):
        return body

    if not isinstance(body, str):
        raise ValueError("Request body must be a JSON string.")

    if event.get("isBase64Encoded"):
        body = base64.b64decode(body).decode("utf-8")

    if body.strip() == "":
        return {}

    try:
        parsed = json.loads(body)
    except json.JSONDecodeError as exc:
        raise ValueError("Request body must be valid JSON.") from exc

    if not isinstance(parsed, dict):
        raise ValueError("Request body must be a JSON object.")

    return parsed


def get_jwt_claims(event: dict) -> dict:
    return (
        event.get("requestContext", {})
        .get("authorizer", {})
        .get("jwt", {})
        .get("claims", {})
    )


def get_current_user_id(event: dict) -> str:
    claims = get_jwt_claims(event)

    return (
        claims.get("sub")
        or claims.get("username")
        or claims.get("cognito:username")
        or claims.get("client_id")
        or "anonymous"
    )
