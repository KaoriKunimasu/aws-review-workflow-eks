import boto3

from app.api.config import settings

_resource = None


def get_table():
    """Return the DynamoDB Table resource (lazy singleton)."""
    global _resource
    if _resource is None:
        kwargs = {"region_name": settings.aws_region}
        if settings.dynamodb_endpoint_url:
            # Point boto3 at DynamoDB Local during development.
            kwargs["endpoint_url"] = settings.dynamodb_endpoint_url
        _resource = boto3.resource("dynamodb", **kwargs)
    return _resource.Table(settings.table_name)
