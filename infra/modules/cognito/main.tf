terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

data "aws_region" "current" {}

locals {
  module_name           = "cognito"
  user_pool_name        = "${var.name_prefix}-users"
  user_pool_client_name = "${var.name_prefix}-web"
  create_domain         = var.domain_prefix != ""

  issuer_url = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.this.id}"

  hosted_ui_base_url = local.create_domain ? "https://${aws_cognito_user_pool_domain.this[0].domain}.auth.${data.aws_region.current.name}.amazoncognito.com" : null
}

resource "aws_cognito_user_pool" "this" {
  name = local.user_pool_name

  auto_verified_attributes = ["email"]
  username_attributes      = ["email"]
  mfa_configuration        = "OFF"
  deletion_protection      = var.enable_deletion_protection ? "ACTIVE" : "INACTIVE"

  username_configuration {
    case_sensitive = false
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }

  password_policy {
    minimum_length                   = var.password_minimum_length
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }

  tags = var.tags
}

resource "aws_cognito_user_pool_client" "this" {
  name         = local.user_pool_client_name
  user_pool_id = aws_cognito_user_pool.this.id

  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = var.allowed_oauth_scopes
  supported_identity_providers         = ["COGNITO"]

  callback_urls        = var.callback_urls
  logout_urls          = var.logout_urls
  default_redirect_uri = var.callback_urls[0]

  access_token_validity  = var.access_token_validity_minutes
  id_token_validity      = var.id_token_validity_minutes
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }

  enable_token_revocation       = true
  prevent_user_existence_errors = "ENABLED"

  explicit_auth_flows = [
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_USER_SRP_AUTH",
  ]
}

resource "aws_cognito_user_pool_domain" "this" {
  count = local.create_domain ? 1 : 0

  domain       = var.domain_prefix
  user_pool_id = aws_cognito_user_pool.this.id
}
