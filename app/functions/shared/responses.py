import json
from typing import Any


def json_response(status_code: int, body: Any) -> dict:
    return {
        "statusCode": status_code,
        "headers": {
            "Content-Type": "application/json",
        },
        "body": json.dumps(body),
    }


def error_response(status_code: int, message: str, details: dict | None = None) -> dict:
    payload = {
        "message": message,
    }

    if details:
        payload["details"] = details

    return json_response(status_code, payload)
