import logging
import os
import uuid
from datetime import datetime, timezone

import boto3
from botocore.exceptions import ClientError

from shared.request_context import get_current_user_id, parse_json_body
from shared.responses import error_response, json_response


logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

dynamodb = boto3.resource("dynamodb")


REQUIRED_FIELDS = [
    "title",
    "requestType",
    "sourceLanguage",
    "targetLanguage",
    "sourceText",
]


def validate_payload(payload: dict) -> dict[str, str]:
    errors: dict[str, str] = {}

    for field_name in REQUIRED_FIELDS:
        value = payload.get(field_name)

        if not isinstance(value, str) or value.strip() == "":
            errors[field_name] = f"{field_name} is required."

    optional_string_fields = [
        "targetText",
        "category",
        "reviewerNote",
    ]

    for field_name in optional_string_fields:
        value = payload.get(field_name)
        if value is not None and not isinstance(value, str):
            errors[field_name] = f"{field_name} must be a string when provided."

    return errors


def build_item(payload: dict, created_by: str) -> dict:
    request_id = str(uuid.uuid4())
    timestamp = datetime.now(timezone.utc).isoformat()

    return {
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


def lambda_handler(event, context):
    table_name = os.environ.get("WORKFLOW_TABLE_NAME")

    if not table_name:
        logger.error("Missing required environment variable: WORKFLOW_TABLE_NAME")
        return error_response(500, "Server configuration is incomplete.")

    try:
        payload = parse_json_body(event)
    except ValueError as exc:
        return error_response(400, str(exc))

    validation_errors = validate_payload(payload)
    if validation_errors:
        return error_response(400, "Validation failed.", validation_errors)

    created_by = get_current_user_id(event)
    item = build_item(payload, created_by)

    table = dynamodb.Table(table_name)

    try:
        table.put_item(
            Item=item,
            ConditionExpression="attribute_not_exists(PK)",
        )
    except table.meta.client.exceptions.ConditionalCheckFailedException:
        logger.warning("Request ID collision detected for PK=%s", item["PK"])
        return error_response(409, "A request with the same ID already exists.")
    except ClientError:
        logger.exception("Failed to create workflow request.")
        return error_response(500, "Failed to create workflow request.")

    return json_response(
        201,
        {
            "message": "Workflow request created successfully.",
            "item": {
                "requestId": item["requestId"],
                "title": item["title"],
                "requestType": item["requestType"],
                "sourceLanguage": item["sourceLanguage"],
                "targetLanguage": item["targetLanguage"],
                "status": item["status"],
                "category": item["category"],
                "createdBy": item["createdBy"],
                "createdAt": item["createdAt"],
                "updatedAt": item["updatedAt"],
            },
        },
    )
