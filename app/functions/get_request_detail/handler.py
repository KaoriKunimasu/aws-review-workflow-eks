import logging
import os

import boto3
from botocore.exceptions import ClientError

from shared.responses import error_response, json_response

logger = logging.getLogger()
logger.setLevel(os.environ.get("LOG_LEVEL", "INFO"))

dynamodb = boto3.resource("dynamodb")


def get_request_id(event: dict) -> str:
    path_parameters = event.get("pathParameters") or {}
    request_id = path_parameters.get("requestId")

    if not isinstance(request_id, str) or not request_id.strip():
        raise ValueError("Path parameter 'requestId' is required.")

    return request_id.strip()


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

    table = dynamodb.Table(table_name)

    try:
        response = table.get_item(
            Key={
                "PK": f"REQUEST#{request_id}",
                "SK": "METADATA",
            },
            ConsistentRead=True,
        )
    except ClientError:
        logger.exception("Failed to fetch workflow request detail.")
        return error_response(500, "Failed to fetch workflow request detail.")

    item = response.get("Item")
    if not item:
        return error_response(404, "Workflow request was not found.")

    return json_response(
        200,
        {
            "item": build_response_item(item),
        },
    )
