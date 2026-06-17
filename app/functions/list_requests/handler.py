import logging
import os

import boto3
from botocore.exceptions import ClientError

from shared.responses import error_response, json_response


logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

dynamodb = boto3.resource("dynamodb")


def parse_limit(event: dict) -> int:
    raw_limit = (
        event.get("queryStringParameters", {}) or {}
    ).get("limit")

    if raw_limit is None:
        return 20

    try:
        limit = int(raw_limit)
    except (TypeError, ValueError):
        raise ValueError("limit must be an integer.")

    if limit < 1 or limit > 100:
        raise ValueError("limit must be between 1 and 100.")

    return limit


def to_response_item(item: dict) -> dict:
    return {
        "requestId": item.get("requestId"),
        "title": item.get("title"),
        "requestType": item.get("requestType"),
        "sourceLanguage": item.get("sourceLanguage"),
        "targetLanguage": item.get("targetLanguage"),
        "status": item.get("status"),
        "category": item.get("category"),
        "createdBy": item.get("createdBy"),
        "createdAt": item.get("createdAt"),
        "updatedAt": item.get("updatedAt"),
    }


def lambda_handler(event, context):
    table_name = os.environ.get("WORKFLOW_TABLE_NAME")

    if not table_name:
        logger.error("Missing required environment variable: WORKFLOW_TABLE_NAME")
        return error_response(500, "Server configuration is incomplete.")

    try:
        limit = parse_limit(event)
    except ValueError as exc:
        return error_response(400, str(exc))

    table = dynamodb.Table(table_name)

    try:
        response = table.scan(Limit=limit)
    except ClientError:
        logger.exception("Failed to list workflow requests.")
        return error_response(500, "Failed to list workflow requests.")

    items = response.get("Items", [])
    normalized_items = [to_response_item(item) for item in items]

    normalized_items.sort(
        key=lambda item: item.get("createdAt") or "",
        reverse=True,
    )

    return json_response(
        200,
        {
            "items": normalized_items,
            "count": len(normalized_items),
            "hasMore": "LastEvaluatedKey" in response,
        },
    )
