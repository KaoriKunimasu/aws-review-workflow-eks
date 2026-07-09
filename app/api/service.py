import base64
import json
import uuid
from datetime import datetime, timezone

from botocore.exceptions import ClientError

from app.api.db import get_table


ALLOWED_STATUSES = {"OPEN", "IN_REVIEW", "APPROVED", "REJECTED"}


def _encode_cursor(last_evaluated_key: dict) -> str:
    encoded = json.dumps(last_evaluated_key).encode("utf-8")
    return base64.urlsafe_b64encode(encoded).decode("utf-8")


def _decode_cursor(cursor: str) -> dict:
    decoded = base64.urlsafe_b64decode(cursor.encode("utf-8"))
    return json.loads(decoded)


class ServiceError(Exception):
    """Carries an HTTP status code and optional field-level details."""

    def __init__(self, status_code: int, message: str, details: dict | None = None):
        super().__init__(message)
        self.status_code = status_code
        self.message = message
        self.details = details


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _to_item(record: dict) -> dict:
    """Normalize a DynamoDB record to the API response shape.

    Ported from the build_response_item / to_response_item helpers in the
    original list and detail handlers.
    """
    return {
        "requestId": record.get("requestId", ""),
        "title": record.get("title", ""),
        "requestType": record.get("requestType", ""),
        "sourceLanguage": record.get("sourceLanguage", ""),
        "targetLanguage": record.get("targetLanguage", ""),
        "sourceText": record.get("sourceText", ""),
        "targetText": record.get("targetText", ""),
        "category": record.get("category", ""),
        "status": record.get("status", ""),
        "reviewerNote": record.get("reviewerNote", ""),
        "createdBy": record.get("createdBy", ""),
        "createdAt": record.get("createdAt", ""),
        "updatedAt": record.get("updatedAt", ""),
    }


def create_review(payload: dict, created_by: str) -> dict:
    """Ported from create_request/handler.py (build_item + put_item)."""
    request_id = str(uuid.uuid4())
    timestamp = _now()

    item = {
        "PK": f"REQUEST#{request_id}",
        "SK": "METADATA",
        "requestId": request_id,
        "title": payload["title"].strip(),
        "requestType": payload["requestType"].strip(),
        "sourceLanguage": payload["sourceLanguage"].strip(),
        "targetLanguage": payload["targetLanguage"].strip(),
        "sourceText": payload["sourceText"].strip(),
        "targetText": (payload.get("targetText") or "").strip(),
        "category": (payload.get("category") or "").strip(),
        "status": "OPEN",
        "reviewerNote": (payload.get("reviewerNote") or "").strip(),
        "createdBy": created_by,
        "createdAt": timestamp,
        "updatedAt": timestamp,
    }

    table = get_table()
    try:
        # Guard against UUID collision, same as the original handler.
        table.put_item(Item=item, ConditionExpression="attribute_not_exists(PK)")
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        raise ServiceError(409, "A request with the same ID already exists.")
    except ClientError:
        raise ServiceError(500, "Failed to create workflow request.")

    return _to_item(item)


def list_reviews(limit: int = 20, cursor: str | None = None) -> dict:
    """Ported from list_requests/handler.py."""
    if limit < 1 or limit > 100:
        raise ServiceError(400, "limit must be between 1 and 100.")

    scan_kwargs = {"Limit": limit}
    if cursor is not None:
        try:
            scan_kwargs["ExclusiveStartKey"] = _decode_cursor(cursor)
        except (ValueError, json.JSONDecodeError):
            raise ServiceError(400, "cursor is invalid.")

    table = get_table()
    try:
        response = table.scan(**scan_kwargs)
    except ClientError:
        raise ServiceError(500, "Failed to list workflow requests.")

    items = [_to_item(r) for r in response.get("Items", [])]
    # Newest first, matching the original handler behavior.
    items.sort(key=lambda i: i.get("createdAt") or "", reverse=True)

    last_evaluated_key = response.get("LastEvaluatedKey")

    return {
        "items": items,
        "count": len(items),
        "hasMore": last_evaluated_key is not None,
        "cursor": _encode_cursor(last_evaluated_key) if last_evaluated_key else None,
    }


def get_review(request_id: str) -> dict:
    """Ported from get_request_detail/handler.py."""
    table = get_table()
    try:
        response = table.get_item(
            Key={"PK": f"REQUEST#{request_id}", "SK": "METADATA"},
            ConsistentRead=True,
        )
    except ClientError:
        raise ServiceError(500, "Failed to fetch workflow request detail.")

    item = response.get("Item")
    if not item:
        raise ServiceError(404, "Workflow request was not found.")

    return _to_item(item)


def update_status(request_id: str, payload: dict) -> dict:
    """Ported from update_request_status/handler.py."""
    status = (payload.get("status") or "").strip()
    if status not in ALLOWED_STATUSES:
        raise ServiceError(
            400,
            "Validation failed.",
            {"status": f"Status must be one of: {', '.join(sorted(ALLOWED_STATUSES))}."},
        )

    reviewer_note = (payload.get("reviewerNote") or "").strip()
    timestamp = _now()

    table = get_table()
    try:
        response = table.update_item(
            Key={"PK": f"REQUEST#{request_id}", "SK": "METADATA"},
            UpdateExpression=(
                "SET #status = :status, #reviewerNote = :reviewerNote, #updatedAt = :updatedAt"
            ),
            # Fail if the item does not exist, mapped to 404 below.
            ConditionExpression="attribute_exists(PK) AND attribute_exists(SK)",
            ExpressionAttributeNames={
                "#status": "status",
                "#reviewerNote": "reviewerNote",
                "#updatedAt": "updatedAt",
            },
            ExpressionAttributeValues={
                ":status": status,
                ":reviewerNote": reviewer_note,
                ":updatedAt": timestamp,
            },
            ReturnValues="ALL_NEW",
        )
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        raise ServiceError(404, "Workflow request was not found.")
    except ClientError:
        raise ServiceError(500, "Failed to update workflow request status.")

    return _to_item(response.get("Attributes", {}))
