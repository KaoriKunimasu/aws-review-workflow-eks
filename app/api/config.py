import os


class Settings:
    # Table name carried over from the original Lambda env var.
    table_name: str = os.environ.get("WORKFLOW_TABLE_NAME", "review-workflow-local")
    aws_region: str = os.environ.get("AWS_REGION", "ap-southeast-2")
    log_level: str = os.environ.get("LOG_LEVEL", "INFO")
    # Set only when using DynamoDB Local. Leave empty on EKS to hit real DynamoDB.
    dynamodb_endpoint_url: str | None = os.environ.get("DYNAMODB_ENDPOINT_URL") or None

    # "none": no verification, fixed identity. Local development only.
    # "cognito": verify a real Cognito access token on every request.
    auth_mode: str = os.environ.get("AUTH_MODE", "none")
    cognito_user_pool_id: str | None = os.environ.get("COGNITO_USER_POOL_ID")
    cognito_region: str = os.environ.get("COGNITO_REGION", aws_region)
    cognito_client_id: str | None = os.environ.get("COGNITO_CLIENT_ID")


settings = Settings()

if settings.auth_mode == "cognito" and not (
    settings.cognito_user_pool_id and settings.cognito_client_id
):
    # Fail at startup, not on the first request. An EKS deployment missing
    # these values should not silently fall back to trusting callers.
    raise RuntimeError(
        "AUTH_MODE=cognito requires COGNITO_USER_POOL_ID and COGNITO_CLIENT_ID."
    )