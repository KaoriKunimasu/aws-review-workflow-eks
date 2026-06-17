variable "function_name" {
  description = "Lambda function name."
  type        = string
}

variable "description" {
  description = "Lambda function description."
  type        = string
  default     = ""
}

variable "runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "handler" {
  description = "Lambda handler entry point."
  type        = string
  default     = "app.handler"
}

variable "package_file" {
  description = "Path to the Lambda deployment package zip file."
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA-256 hash of the deployment package."
  type        = string
  default     = null
}

variable "memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240."
  }
}

variable "timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 10

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900."
  }
}

variable "architectures" {
  description = "Instruction set architectures for the Lambda function."
  type        = list(string)
  default     = ["arm64"]
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention period in days."
  type        = number
  default     = 14
}

variable "log_format" {
  description = "Lambda application log format."
  type        = string
  default     = "JSON"

  validation {
    condition     = contains(["JSON", "Text"], var.log_format)
    error_message = "log_format must be JSON or Text."
  }
}

variable "application_log_level" {
  description = "Lambda application log level."
  type        = string
  default     = "INFO"

  validation {
    condition     = contains(["TRACE", "DEBUG", "INFO", "WARN", "ERROR", "FATAL"], var.application_log_level)
    error_message = "application_log_level must be TRACE, DEBUG, INFO, WARN, ERROR, or FATAL."
  }
}

variable "system_log_level" {
  description = "Lambda system log level."
  type        = string
  default     = "WARN"

  validation {
    condition     = contains(["DEBUG", "INFO", "WARN"], var.system_log_level)
    error_message = "system_log_level must be DEBUG, INFO, or WARN."
  }
}

variable "extra_policy_statements" {
  description = "Additional IAM policy statements for the Lambda execution role."
  type = list(object({
    sid       = optional(string)
    actions   = list(string)
    resources = list(string)
    effect    = optional(string, "Allow")
  }))
  default = []
}

variable "tags" {
  description = "Tags applied to Lambda resources."
  type        = map(string)
  default     = {}
}