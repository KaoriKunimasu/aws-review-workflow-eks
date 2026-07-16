locals {
  name_prefix = "${var.project_name}-${var.environment}"

  common_tags = {
    Application = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "aws-serverless-review-workflow"
  }

  repo_root          = abspath("${path.root}/../../..")
  function_dist_root = "${local.repo_root}/app/functions/.dist"

  lambda_environment_base = {
    LOG_LEVEL           = var.lambda_log_level
    WORKFLOW_TABLE_NAME = module.dynamodb.table_name
  }

  monitored_lambda_function_names = {
    list_requests         = module.list_requests_function.function_name
    create_request        = module.create_request_function.function_name
    get_request_detail    = module.get_request_detail_function.function_name
    update_request_status = module.update_request_status_function.function_name
    pre_token_generation  = module.pre_token_generation_function.function_name
  }
}

module "cognito" {
  source = "../../modules/cognito"

  name_prefix                     = local.name_prefix
  callback_urls                   = var.cognito_callback_urls
  logout_urls                     = var.cognito_logout_urls
  domain_prefix                   = var.cognito_domain_prefix
  pre_token_generation_lambda_arn = module.pre_token_generation_function.function_arn
  tags                            = local.common_tags
}

module "dynamodb" {
  source = "../../modules/dynamodb"

  name_prefix                    = local.name_prefix
  billing_mode                   = var.dynamodb_billing_mode
  point_in_time_recovery_enabled = var.dynamodb_point_in_time_recovery_enabled
  deletion_protection_enabled    = var.dynamodb_deletion_protection_enabled
  table_class                    = var.dynamodb_table_class
  stream_enabled                 = var.dynamodb_stream_enabled
  stream_view_type               = var.dynamodb_stream_view_type
  ttl_enabled                    = var.dynamodb_ttl_enabled
  ttl_attribute_name             = var.dynamodb_ttl_attribute_name
  tags                           = local.common_tags
}

data "archive_file" "list_requests" {
  type        = "zip"
  source_dir  = "${local.function_dist_root}/list_requests"
  output_path = "${path.module}/list_requests.zip"
}

data "archive_file" "create_request" {
  type        = "zip"
  source_dir  = "${local.function_dist_root}/create_request"
  output_path = "${path.module}/create_request.zip"
}

data "archive_file" "get_request_detail" {
  type        = "zip"
  source_dir  = "${local.function_dist_root}/get_request_detail"
  output_path = "${path.module}/get_request_detail.zip"
}

data "archive_file" "update_request_status" {
  type        = "zip"
  source_dir  = "${local.function_dist_root}/update_request_status"
  output_path = "${path.module}/update_request_status.zip"
}

data "archive_file" "pre_token_generation" {
  type        = "zip"
  source_dir  = "${local.function_dist_root}/pre_token_generation"
  output_path = "${path.module}/pre_token_generation.zip"
}

module "list_requests_function" {
  source = "../../modules/lambda-function"

  function_name    = "${local.name_prefix}-list-requests"
  description      = "Lists workflow requests in the dev environment."
  runtime          = var.lambda_runtime
  handler          = "handler.lambda_handler"
  package_file     = data.archive_file.list_requests.output_path
  source_code_hash = data.archive_file.list_requests.output_base64sha256

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  architectures = var.lambda_architectures

  environment_variables = local.lambda_environment_base

  log_retention_in_days = var.lambda_log_retention_in_days
  log_format            = "JSON"
  application_log_level = var.lambda_log_level
  system_log_level      = "INFO"

  extra_policy_statements = [
    {
      sid    = "ReadWorkflowTable"
      effect = "Allow"
      actions = [
        "dynamodb:Scan"
      ]
      resources = [
        module.dynamodb.table_arn
      ]
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Component = "list-requests"
    }
  )
}

module "create_request_function" {
  source = "../../modules/lambda-function"

  function_name    = "${local.name_prefix}-create-request"
  description      = "Creates workflow requests in the dev environment."
  runtime          = var.lambda_runtime
  handler          = "handler.lambda_handler"
  package_file     = data.archive_file.create_request.output_path
  source_code_hash = data.archive_file.create_request.output_base64sha256

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  architectures = var.lambda_architectures

  environment_variables = local.lambda_environment_base

  log_retention_in_days = var.lambda_log_retention_in_days
  log_format            = "JSON"
  application_log_level = var.lambda_log_level
  system_log_level      = "INFO"

  extra_policy_statements = [
    {
      sid    = "WriteWorkflowTable"
      effect = "Allow"
      actions = [
        "dynamodb:PutItem"
      ]
      resources = [
        module.dynamodb.table_arn
      ]
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Component = "create-request"
    }
  )
}

module "get_request_detail_function" {
  source = "../../modules/lambda-function"

  function_name    = "${local.name_prefix}-get-request-detail"
  description      = "Gets a single workflow request in the dev environment."
  runtime          = var.lambda_runtime
  handler          = "handler.lambda_handler"
  package_file     = data.archive_file.get_request_detail.output_path
  source_code_hash = data.archive_file.get_request_detail.output_base64sha256

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  architectures = var.lambda_architectures

  environment_variables = local.lambda_environment_base

  log_retention_in_days = var.lambda_log_retention_in_days
  log_format            = "JSON"
  application_log_level = var.lambda_log_level
  system_log_level      = "INFO"

  extra_policy_statements = [
    {
      sid    = "ReadWorkflowTable"
      effect = "Allow"
      actions = [
        "dynamodb:GetItem"
      ]
      resources = [
        module.dynamodb.table_arn
      ]
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Component = "get-request-detail"
    }
  )
}

module "update_request_status_function" {
  source = "../../modules/lambda-function"

  function_name    = "${local.name_prefix}-update-request-status"
  description      = "Updates workflow request status in the dev environment."
  runtime          = var.lambda_runtime
  handler          = "handler.lambda_handler"
  package_file     = data.archive_file.update_request_status.output_path
  source_code_hash = data.archive_file.update_request_status.output_base64sha256

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  architectures = var.lambda_architectures

  environment_variables = local.lambda_environment_base

  log_retention_in_days = var.lambda_log_retention_in_days
  log_format            = "JSON"
  application_log_level = var.lambda_log_level
  system_log_level      = "INFO"

  extra_policy_statements = [
    {
      sid    = "UpdateWorkflowTable"
      effect = "Allow"
      actions = [
        "dynamodb:UpdateItem"
      ]
      resources = [
        module.dynamodb.table_arn
      ]
    }
  ]

  tags = merge(
    local.common_tags,
    {
      Component = "update-request-status"
    }
  )
}

module "pre_token_generation_function" {
  source = "../../modules/lambda-function"

  function_name    = "${local.name_prefix}-pre-token-generation"
  description      = "Copies Cognito group membership onto the access token."
  runtime          = var.lambda_runtime
  handler          = "handler.lambda_handler"
  package_file     = data.archive_file.pre_token_generation.output_path
  source_code_hash = data.archive_file.pre_token_generation.output_base64sha256

  memory_size   = var.lambda_memory_size
  timeout       = var.lambda_timeout_seconds
  architectures = var.lambda_architectures

  log_retention_in_days = var.lambda_log_retention_in_days
  log_format            = "JSON"
  application_log_level = var.lambda_log_level
  system_log_level      = "INFO"

  tags = merge(
    local.common_tags,
    {
      Component = "pre-token-generation"
    }
  )
}

module "api" {
  source = "../../modules/api"

  name        = "${local.name_prefix}-api"
  description = "HTTP API for the dev environment."
  stage_name  = var.api_stage_name
  auto_deploy = var.api_auto_deploy

  log_retention_in_days = var.api_log_retention_in_days

  cors_allow_origins     = var.api_cors_allow_origins
  cors_allow_methods     = var.api_cors_allow_methods
  cors_allow_headers     = var.api_cors_allow_headers
  cors_expose_headers    = var.api_cors_expose_headers
  cors_allow_credentials = var.api_cors_allow_credentials
  cors_max_age           = var.api_cors_max_age

  create_jwt_authorizer          = var.api_enable_jwt_authorizer
  jwt_authorizer_name            = var.api_jwt_authorizer_name
  jwt_authorizer_identity_source = var.api_jwt_identity_source
  jwt_authorizer_audience        = [module.cognito.user_pool_client_id]
  jwt_authorizer_issuer          = module.cognito.issuer_url

  routes = {
    "GET /requests" = {
      integration_uri      = module.list_requests_function.invoke_arn
      function_name        = module.list_requests_function.function_name
      authorization_type   = var.api_enable_jwt_authorizer ? "JWT" : "NONE"
      authorization_scopes = []
    }

    "POST /requests" = {
      integration_uri      = module.create_request_function.invoke_arn
      function_name        = module.create_request_function.function_name
      authorization_type   = var.api_enable_jwt_authorizer ? "JWT" : "NONE"
      authorization_scopes = []
    }

    "GET /requests/{requestId}" = {
      integration_uri      = module.get_request_detail_function.invoke_arn
      function_name        = module.get_request_detail_function.function_name
      authorization_type   = var.api_enable_jwt_authorizer ? "JWT" : "NONE"
      authorization_scopes = []
    }

    "PATCH /requests/{requestId}/status" = {
      integration_uri      = module.update_request_status_function.invoke_arn
      function_name        = module.update_request_status_function.function_name
      authorization_type   = var.api_enable_jwt_authorizer ? "JWT" : "NONE"
      authorization_scopes = []
    }
  }

  tags = merge(
    local.common_tags,
    {
      Component = "api"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "api_5xx_errors" {
  alarm_name          = "${local.name_prefix}-api-5xx-errors"
  alarm_description   = "Alarm when the dev HTTP API returns 5xx responses."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.api_5xx_alarm_threshold
  period              = var.alarm_period_seconds
  namespace           = "AWS/ApiGateway"
  metric_name         = "5xx"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  dimensions = {
    ApiId = module.api.api_id
    Stage = var.api_stage_name
  }

  tags = merge(
    local.common_tags,
    {
      Component = "monitoring"
    }
  )
}

resource "aws_cloudwatch_metric_alarm" "lambda_errors" {
  for_each = local.monitored_lambda_function_names

  alarm_name          = "${local.name_prefix}-${each.key}-errors"
  alarm_description   = "Alarm when the ${each.key} Lambda function returns errors."
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.lambda_error_alarm_threshold
  period              = var.alarm_period_seconds
  namespace           = "AWS/Lambda"
  metric_name         = "Errors"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  dimensions = {
    FunctionName = each.value
  }

  tags = merge(
    local.common_tags,
    {
      Component = "monitoring"
      Function  = each.key
    }
  )
}

