import os


class Settings:
    # Table name carried over from the original Lambda env var.
    table_name: str = os.environ.get("WORKFLOW_TABLE_NAME", "review-workflow-local")
    aws_region: str = os.environ.get("AWS_REGION", "ap-southeast-2")
    log_level: str = os.environ.get("LOG_LEVEL", "INFO")
    # Set only when using DynamoDB Local. Leave empty on EKS to hit real DynamoDB.
    dynamodb_endpoint_url: str | None = os.environ.get("DYNAMODB_ENDPOINT_URL") or None


settings = Settings()
