# Lambda Function Module

This module manages a single AWS Lambda function and its supporting resources.

## Resources

- AWS Lambda function
- IAM execution role
- Inline IAM policy for CloudWatch Logs and optional extra permissions
- CloudWatch log group

## Design Choices

- One module instance per function
- Zip package deployment
- Explicit log group creation with configurable retention
- Optional environment variables
- Optional extra IAM policy statements for service access

## Usage

```hcl
module "list_requests_function" {
  source = "../../modules/lambda-function"

  function_name = "review-workflow-dev-list-requests"
  description   = "Lists workflow requests."
  handler       = "app.handler"
  runtime       = "python3.12"

  package_file     = "${path.root}/../../app/functions/list-requests/function.zip"
  source_code_hash = filebase64sha256("${path.root}/../../app/functions/list-requests/function.zip")

  environment_variables = {
    LOG_LEVEL  = "INFO"
    TABLE_NAME = "review-workflow-dev-workflow"
  }

  extra_policy_statements = [
    {
      sid = "DynamoDBReadAccess"
      actions = [
        "dynamodb:GetItem",
        "dynamodb:Query",
        "dynamodb:Scan",
      ]
      resources = [
        "arn:aws:dynamodb:ap-southeast-2:123456789012:table/review-workflow-dev-workflow",
      ]
    }
  ]

  tags = {
    Application = "review-workflow"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- `package_file` must point to an existing zip file when the module is applied.
- `source_code_hash` should be provided so Terraform can detect deployment package changes.
- Extra IAM permissions are optional and can be added with `extra_policy_statements`.
