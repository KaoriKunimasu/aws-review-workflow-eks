import logging
import os
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

from shared.request_context import parse_json_body
from shared.responses import error_response, json_response

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

dynamodb = boto3.resource("dynamodb")

ALLOWED_STATUSES = {
    "OPEN",
    "IN_REVIEW",
    "APPROVED",
    "REJECTED",
}


def get_request_id(event: dict) -> str:
    path_parameters = event.get("pathParameters") or {}
    request_id = path_parameters.get("requestId")

    if not isinstance(request_id, str) or not request_id.strip():
        raise ValueError("Path parameter 'requestId' is required.")

    return request_id.strip()


def validate_payload(payload: dict) -> dict:
    errors = {}

    status = payload.get("status")
    reviewer_note = payload.get("reviewerNote")

    if not isinstance(status, str) or not status.strip():
        errors["status"] = "Status is required."
    elif status.strip() not in ALLOWED_STATUSES:
        errors["status"] = (
            f"Status must be one of: {', '.join(sorted(ALLOWED_STATUSES))}."
        )

    if reviewer_note is not None and not isinstance(reviewer_note, str):
        errors["reviewerNote"] = "Reviewer note must be a string."

    return errors


def build_response_item(item: dict) -> dict:
    return {
        "requestId": item.get("requestId", ""),
        "title": item.get("title", ""),
        "requestType": item.get("requestType", ""),
        "sourceLanguage": item.get("sourceLanguage", ""),
        "targetLanguage": item.get("targetLanguage", ""),
        "sourceText": item.get("sourceText", ""),
        "targetText": item.get("targetText", ""),
        "category": item.get("category", ""),
        "status": item.get("status", ""),
        "reviewerNote": item.get("reviewerNote", ""),
        "createdBy": item.get("createdBy", ""),
        "createdAt": item.get("createdAt", ""),
        "updatedAt": item.get("updatedAt", ""),
    }


def lambda_handler(event, context):
    table_name = os.environ.get("WORKFLOW_TABLE_NAME")

    if not table_name:
        logger.error("Missing required environment variable: WORKFLOW_TABLE_NAME")
        return error_response(500, "Server configuration is incomplete.")

    try:
        request_id = get_request_id(event)
    except ValueError as exc:
        return error_response(400, str(exc))

    try:
        payload = parse_json_body(event)
    except ValueError as exc:
        return error_response(400, str(exc))

    validation_errors = validate_payload(payload)
    if validation_errors:
        return error_response(400, "Validation failed.", validation_errors)

    status = payload["status"].strip()
    reviewer_note = (payload.get("reviewerNote") or "").strip()
    timestamp = datetime.now(timezone.utc).isoformat()

    table = dynamodb.Table(table_name)

    try:
        response = table.update_item(
            Key={
                "PK": f"REQUEST#{request_id}",
                "SK": "METADATA",
            },
            UpdateExpression=(
                "SET #status = :status, "
                "#reviewerNote = :reviewerNote, "
                "#updatedAt = :updatedAt"
            ),
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
        logger.warning("Workflow request not found for requestId=%s", request_id)
        return error_response(404, "Workflow request was not found.")
    except ClientError:
        logger.exception("Failed to update workflow request status.")
        return error_response(500, "Failed to update workflow request status.")

    item = response.get("Attributes", {})

    return json_response(
        200,
        {
            "message": "Workflow request status updated successfully.",
            "item": build_response_item(item),
        },
    )
