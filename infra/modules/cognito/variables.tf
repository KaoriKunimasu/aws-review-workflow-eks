variable "name_prefix" {
  description = "Prefix used for Cognito resource names."
  type        = string
}

variable "callback_urls" {
  description = "Allowed callback URLs for the application client."
  type        = list(string)

  validation {
    condition     = length(var.callback_urls) > 0
    error_message = "callback_urls must contain at least one URL."
  }
}

variable "logout_urls" {
  description = "Allowed logout URLs for the application client."
  type        = list(string)

  validation {
    condition     = length(var.logout_urls) > 0
    error_message = "logout_urls must contain at least one URL."
  }
}

variable "domain_prefix" {
  description = "Optional Cognito hosted UI domain prefix. Leave empty to skip domain creation."
  type        = string
  default     = ""
}

variable "allowed_oauth_scopes" {
  description = "OAuth scopes enabled for the app client."
  type        = list(string)
  default = [
    "openid",
    "email",
    "profile",
  ]

  validation {
    condition     = contains(var.allowed_oauth_scopes, "openid")
    error_message = "allowed_oauth_scopes must include openid."
  }
}

variable "access_token_validity_minutes" {
  description = "Access token validity in minutes."
  type        = number
  default     = 60
}

variable "id_token_validity_minutes" {
  description = "ID token validity in minutes."
  type        = number
  default     = 60
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity in days."
  type        = number
  default     = 30
}

variable "password_minimum_length" {
  description = "Minimum password length for local users."
  type        = number
  default     = 14
}

variable "enable_deletion_protection" {
  description = "Whether deletion protection should be enabled for the user pool."
  type        = bool
  default     = false
}

variable "pre_token_generation_lambda_arn" {
  description = "ARN of the Pre Token Generation (V2_0) Lambda trigger that copies group membership onto the access token."
  type        = string
}

variable "tags" {
  description = "Tags applied to Cognito resources."
  type        = map(string)
  default     = {}
}