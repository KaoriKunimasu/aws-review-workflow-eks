variable "name" {
  description = "Name of the HTTP API."
  type        = string
}

variable "description" {
  description = "Description of the HTTP API."
  type        = string
  default     = null
}

variable "stage_name" {
  description = "Stage name for the HTTP API."
  type        = string
  default     = "$default"
}

variable "auto_deploy" {
  description = "Whether the API Gateway stage auto-deploys changes."
  type        = bool
  default     = true
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention in days for API access logs."
  type        = number
  default     = 14

  validation {
    condition = contains(
      [1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653],
      var.log_retention_in_days
    )
    error_message = "log_retention_in_days must be a supported CloudWatch Logs retention value."
  }
}

variable "cors_allow_origins" {
  description = "Allowed origins for CORS."
  type        = list(string)
  default     = []
}

variable "cors_allow_methods" {
  description = "Allowed HTTP methods for CORS."
  type        = list(string)
  default     = []
}

variable "cors_allow_headers" {
  description = "Allowed headers for CORS."
  type        = list(string)
  default     = []
}

variable "cors_expose_headers" {
  description = "Headers exposed by CORS."
  type        = list(string)
  default     = []
}

variable "cors_allow_credentials" {
  description = "Whether credentials are allowed for CORS."
  type        = bool
  default     = false
}

variable "cors_max_age" {
  description = "CORS max age in seconds."
  type        = number
  default     = 0

  validation {
    condition     = var.cors_max_age >= 0
    error_message = "cors_max_age must be greater than or equal to 0."
  }
}

variable "create_jwt_authorizer" {
  description = "Whether the module creates a JWT authorizer."
  type        = bool
  default     = false
}

variable "jwt_authorizer_name" {
  description = "Name of the JWT authorizer."
  type        = string
  default     = "jwt-authorizer"
}

variable "jwt_authorizer_identity_source" {
  description = "Identity source for the JWT authorizer."
  type        = list(string)
  default     = ["$request.header.Authorization"]
}

variable "jwt_authorizer_audience" {
  description = "Audience values for the JWT authorizer."
  type        = list(string)
  default     = []

  validation {
    condition     = var.create_jwt_authorizer ? length(var.jwt_authorizer_audience) > 0 : true
    error_message = "jwt_authorizer_audience must not be empty when create_jwt_authorizer is true."
  }
}

variable "jwt_authorizer_issuer" {
  description = "Issuer URL for the JWT authorizer."
  type        = string
  default     = null

  validation {
    condition     = var.create_jwt_authorizer ? var.jwt_authorizer_issuer != null && trimspace(var.jwt_authorizer_issuer) != "" : true
    error_message = "jwt_authorizer_issuer must be set when create_jwt_authorizer is true."
  }
}

variable "routes" {
  description = "Map of API routes keyed by route key."
  type = map(object({
    integration_uri      = string
    function_name        = string
    authorization_type   = optional(string, "NONE")
    authorizer_id        = optional(string, null)
    authorization_scopes = optional(list(string), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for route_key, route in var.routes :
      contains(["NONE", "JWT", "AWS_IAM", "CUSTOM"], route.authorization_type)
    ])
    error_message = "Each route authorization_type must be NONE, JWT, AWS_IAM, or CUSTOM."
  }

  validation {
    condition = alltrue([
      for route_key, route in var.routes :
      route.authorization_type != "JWT" || route.authorizer_id != null || var.create_jwt_authorizer
    ])
    error_message = "A JWT route must provide authorizer_id or enable create_jwt_authorizer."
  }

  validation {
    condition = alltrue([
      for route_key, route in var.routes :
      route.authorization_type == "JWT" || length(route.authorization_scopes) == 0
    ])
    error_message = "authorization_scopes may be set only for routes that use JWT authorization."
  }
}

variable "tags" {
  description = "Tags applied to API resources."
  type        = map(string)
  default     = {}
}