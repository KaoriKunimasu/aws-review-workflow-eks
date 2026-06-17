import boto3

# Connects to DynamoDB Local started by docker-compose.
dynamodb = boto3.client(
    "dynamodb",
    region_name="ap-southeast-2",
    endpoint_url="http://localhost:8000",
    aws_access_key_id="local",
    aws_secret_access_key="local",
)

dynamodb.create_table(
    TableName="review-workflow-local",
    BillingMode="PAY_PER_REQUEST",
    AttributeDefinitions=[
        {"AttributeName": "PK", "AttributeType": "S"},
        {"AttributeName": "SK", "AttributeType": "S"},
    ],
    KeySchema=[
        {"AttributeName": "PK", "KeyType": "HASH"},
        {"AttributeName": "SK", "KeyType": "RANGE"},
    ],
)
print("Table created: review-workflow-local")
