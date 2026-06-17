# Cognito Module

This module manages Amazon Cognito resources for the application authentication layer.

## Resources

- Amazon Cognito user pool
- Amazon Cognito user pool client
- Optional Cognito hosted UI domain

## Design Choices

- Email-based sign-in
- Public app client without a client secret
- Authorization code flow only
- Optional hosted UI domain for browser-based sign-in
- Token outputs for later API and frontend integration

## Usage

```hcl
module "cognito" {
  source = "../../modules/cognito"

  name_prefix = "review-workflow-dev"

  callback_urls = [
    "http://localhost:5173/auth/callback",
  ]

  logout_urls = [
    "http://localhost:5173/login",
  ]

  domain_prefix = "review-workflow-dev-example"

  tags = {
    Application = "review-workflow"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}
```

## Notes

- Callback URLs must be absolute URLs.
- Amazon Cognito requires HTTPS for callback URLs, except for `http://localhost` during local testing.
- `domain_prefix` must be unique for the selected AWS region.
- This module does not create identity providers other than the built-in Cognito user pool provider.
