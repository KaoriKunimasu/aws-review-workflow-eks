# API Gateway HTTP API Module

This module creates an Amazon API Gateway HTTP API for Lambda-based serverless applications.

## Resources

- HTTP API
- Stage with access logging
- CloudWatch log group for API access logs
- Lambda proxy integrations
- Routes
- Lambda invoke permissions for API Gateway
- Optional JWT authorizer

## Design

- Uses API Gateway v2 HTTP API
- Uses Lambda proxy integrations (`AWS_PROXY`)
- Creates one integration and one permission per route
- Supports optional JWT authorizer creation
- Supports optional CORS configuration
- Exposes route and integration IDs for environment-level wiring

## Example

```hcl
module "api" {
  source = "../../modules/api"

  name        = "review-workflow-dev-api"
  description = "HTTP API for the dev environment."
  stage_name  = "$default"

  cors_allow_origins = [
    "http://localhost:5173",
  ]

  cors_allow_methods = [
    "GET",
    "POST",
    "OPTIONS",
  ]

  cors_allow_headers = [
    "authorization",
    "content-type",
  ]

  routes = {
    "GET /requests" = {
      integration_uri      = module.list_requests_function.invoke_arn
      function_name        = module.list_requests_function.function_name
      authorization_type   = "NONE"
      authorization_scopes = []
    }

    "POST /requests" = {
      integration_uri      = module.create_request_function.invoke_arn
      function_name        = module.create_request_function.function_name
      authorization_type   = "NONE"
      authorization_scopes = []
    }
  }

  tags = {
    Application = "review-workflow"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## JWT Authorizer

If you want the module to create a JWT authorizer, set the following variables:

- `create_jwt_authorizer = true`
- `jwt_authorizer_issuer`
- `jwt_authorizer_audience`

Then set route-level authorization to `JWT`.

## Route Input Shape

The `routes` variable is a map keyed by route key, for example `GET /requests`, `POST /requests`, or `GET /requests/{requestId}`.

Each route object must include:

- `integration_uri`
- `function_name`

Optional route fields:

- `authorization_type`
- `authorizer_id`
- `authorization_scopes`

## Notes

- This module does not create Lambda functions.
- This module does not create Cognito resources.
- This module is intended to be wired from an environment root module.
