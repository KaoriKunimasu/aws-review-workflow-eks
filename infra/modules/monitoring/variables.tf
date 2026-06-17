variable "name_prefix" {
  description = "Prefix used for monitoring resource names."
  type        = string
}

variable "notification_email" {
  description = "Optional email address for alarm notifications."
  type        = string
  default     = ""
}

variable "lambda_error_threshold" {
  description = "Threshold for Lambda error alarms."
  type        = number
  default     = 1
}

variable "api_5xx_threshold" {
  description = "Threshold for API 5XX alarms."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Tags applied to monitoring resources."
  type        = map(string)
  default     = {}
}
