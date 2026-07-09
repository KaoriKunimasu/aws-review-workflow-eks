variable "project_name" {
  description = "Project name used for naming and tags."
  type        = string
  default     = "review-workflow"
}

variable "environment" {
  description = "Deployment environment name."
  type        = string
  default     = "dev"

  validation {
    condition     = var.environment == "dev"
    error_message = "The dev environment configuration only supports environment = \"dev\"."
  }
}

variable "aws_region" {
  description = "AWS region for the dev environment."
  type        = string
  default     = "ap-southeast-2"
}

variable "allowed_account_ids" {
  description = "AWS account IDs allowed for provider authentication."
  type        = list(string)
  default     = ["123456789012"]
}

variable "cognito_callback_urls" {
  description = "Allowed Cognito callback URLs."
  type        = list(string)
  default     = ["http://localhost:5173/auth/callback"]
}

variable "cognito_logout_urls" {
  description = "Allowed Cognito logout URLs."
  type        = list(string)
  default     = ["http://localhost:5173/login"]
}

variable "cognito_domain_prefix" {
  description = "Cognito hosted UI domain prefix for the dev environment."
  type        = string
  default     = "review-workflow-dev-123456789012"
}

variable "dynamodb_billing_mode" {
  description = "DynamoDB billing mode."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = contains(["PAY_PER_REQUEST", "PROVISIONED"], var.dynamodb_billing_mode)
    error_message = "dynamodb_billing_mode must be PAY_PER_REQUEST or PROVISIONED."
  }
}

variable "dynamodb_point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery is enabled for the workflow table."
  type        = bool
  default     = true
}

variable "dynamodb_deletion_protection_enabled" {
  description = "Whether deletion protection is enabled for the workflow table."
  type        = bool
  default     = false
}

variable "dynamodb_table_class" {
  description = "DynamoDB table class."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.dynamodb_table_class)
    error_message = "dynamodb_table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "dynamodb_stream_enabled" {
  description = "Whether DynamoDB Streams are enabled."
  type        = bool
  default     = false
}

variable "dynamodb_stream_view_type" {
  description = "DynamoDB stream view type when streams are enabled."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains(
      [
        "KEYS_ONLY",
        "NEW_IMAGE",
        "OLD_IMAGE",
        "NEW_AND_OLD_IMAGES"
      ],
      var.dynamodb_stream_view_type
    )
    error_message = "dynamodb_stream_view_type must be a valid DynamoDB stream view type."
  }
}

variable "dynamodb_ttl_enabled" {
  description = "Whether TTL is enabled for the workflow table."
  type        = bool
  default     = false
}

variable "dynamodb_ttl_attribute_name" {
  description = "TTL attribute name for the workflow table."
  type        = string
  default     = "expiresAt"
}

variable "lambda_runtime" {
  description = "Lambda runtime used for request functions."
  type        = string
  default     = "python3.12"
}

variable "lambda_architectures" {
  description = "Lambda instruction set architectures."
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition = alltrue([
      for architecture in var.lambda_architectures :
      contains(["x86_64", "arm64"], architecture)
    ])
    error_message = "lambda_architectures may contain only x86_64 or arm64."
  }
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10

  validation {
    condition     = var.lambda_timeout_seconds >= 1 && var.lambda_timeout_seconds <= 900
    error_message = "lambda_timeout_seconds must be between 1 and 900."
  }
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256

  validation {
    condition     = var.lambda_memory_size >= 128 && var.lambda_memory_size <= 10240
    error_message = "lambda_memory_size must be between 128 and 10240."
  }
}

variable "lambda_log_retention_in_days" {
  description = "CloudWatch log retention in days for Lambda log groups."
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.lambda_log_retention_in_days
    )
    error_message = "lambda_log_retention_in_days must be a supported CloudWatch Logs retention value."
  }
}

variable "lambda_log_level" {
  description = "Application log level passed to Lambda functions."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"], var.lambda_log_level)
    error_message = "lambda_log_level must be DEBUG, INFO, WARNING, ERROR, or CRITICAL."
  }
}

variable "api_stage_name" {
  description = "Stage name for the dev HTTP API."
  type        = string
  default     = "$default"
}

variable "api_auto_deploy" {
  description = "Whether the dev HTTP API stage auto-deploys."
  type        = bool
  default     = true
}

variable "api_log_retention_in_days" {
  description = "CloudWatch log retention in days for API access logs."
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.api_log_retention_in_days
    )
    error_message = "api_log_retention_in_days must be a supported CloudWatch Logs retention value."
  }
}

variable "api_cors_allow_origins" {
  description = "Allowed origins for API CORS."
  type        = list(string)
  default     = ["http://localhost:5173"]
}

variable "api_cors_allow_methods" {
  description = "Allowed methods for API CORS."
  type        = list(string)
  default     = ["GET", "POST", "PATCH", "OPTIONS"]
}

variable "api_cors_allow_headers" {
  description = "Allowed headers for API CORS."
  type        = list(string)
  default     = ["authorization", "content-type"]
}

variable "api_cors_expose_headers" {
  description = "Headers exposed by API CORS."
  type        = list(string)
  default     = []
}

variable "api_cors_allow_credentials" {
  description = "Whether API CORS allows credentials."
  type        = bool
  default     = false
}

variable "api_cors_max_age" {
  description = "API CORS max age in seconds."
  type        = number
  default     = 0

  validation {
    condition     = var.api_cors_max_age >= 0
    error_message = "api_cors_max_age must be greater than or equal to 0."
  }
}

variable "api_enable_jwt_authorizer" {
  description = "Whether the dev API enables a JWT authorizer."
  type        = bool
  default     = true
}

variable "api_jwt_authorizer_name" {
  description = "Name of the JWT authorizer for the dev API."
  type        = string
  default     = "cognito-jwt-authorizer"
}

variable "api_jwt_identity_source" {
  description = "Identity source list for the dev API JWT authorizer."
  type        = list(string)
  default     = ["$request.header.Authorization"]
}

variable "api_5xx_alarm_threshold" {
  description = "Threshold for API Gateway 5xx alarm in dev."
  type        = number
  default     = 1
}

variable "lambda_error_alarm_threshold" {
  description = "Threshold for Lambda Errors alarms in dev."
  type        = number
  default     = 1
}

variable "alarm_period_seconds" {
  description = "CloudWatch alarm period in seconds."
  type        = number
  default     = 60
}

variable "alarm_evaluation_periods" {
  description = "Number of evaluation periods for CloudWatch alarms."
  type        = number
  default     = 1
}

variable "eks_cluster_endpoint_public_access_cidrs" {
  description = <<-EOT
    CIDR blocks allowed to reach the EKS public API endpoint. Must be set
    explicitly (e.g. your workstation's IP as a /32) before applying;
    there is no permissive default so the endpoint is never left open to
    0.0.0.0/0 by accident.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.eks_cluster_endpoint_public_access_cidrs) > 0
    error_message = "eks_cluster_endpoint_public_access_cidrs must list at least one CIDR block; do not default this to 0.0.0.0/0."
  }
}
