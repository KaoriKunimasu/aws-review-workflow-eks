variable "name_prefix" {
  description = "Prefix used for DynamoDB resource names."
  type        = string
}

variable "billing_mode" {
  description = "Billing mode for the DynamoDB table."
  type        = string
  default     = "PAY_PER_REQUEST"

  validation {
    condition     = var.billing_mode == "PAY_PER_REQUEST"
    error_message = "billing_mode must be PAY_PER_REQUEST in this module version."
  }
}

variable "hash_key" {
  description = "Primary partition key name."
  type        = string
  default     = "PK"
}

variable "range_key" {
  description = "Primary sort key name."
  type        = string
  default     = "SK"
}

variable "gsi1_name" {
  description = "Name of the first global secondary index."
  type        = string
  default     = "GSI1"
}

variable "gsi1_hash_key" {
  description = "Partition key name for the first global secondary index."
  type        = string
  default     = "GSI1PK"
}

variable "gsi1_range_key" {
  description = "Sort key name for the first global secondary index."
  type        = string
  default     = "GSI1SK"
}

variable "gsi1_projection_type" {
  description = "Projection type for the first global secondary index."
  type        = string
  default     = "ALL"

  validation {
    condition     = contains(["ALL", "INCLUDE", "KEYS_ONLY"], var.gsi1_projection_type)
    error_message = "gsi1_projection_type must be ALL, INCLUDE, or KEYS_ONLY."
  }
}

variable "point_in_time_recovery_enabled" {
  description = "Whether point-in-time recovery should be enabled."
  type        = bool
  default     = true
}

variable "deletion_protection_enabled" {
  description = "Whether deletion protection should be enabled."
  type        = bool
  default     = false
}

variable "table_class" {
  description = "DynamoDB table class."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "STANDARD_INFREQUENT_ACCESS"], var.table_class)
    error_message = "table_class must be STANDARD or STANDARD_INFREQUENT_ACCESS."
  }
}

variable "stream_enabled" {
  description = "Whether DynamoDB Streams should be enabled."
  type        = bool
  default     = false
}

variable "stream_view_type" {
  description = "Stream view type when streams are enabled."
  type        = string
  default     = "NEW_AND_OLD_IMAGES"

  validation {
    condition = contains([
      "KEYS_ONLY",
      "NEW_IMAGE",
      "OLD_IMAGE",
      "NEW_AND_OLD_IMAGES",
    ], var.stream_view_type)
    error_message = "stream_view_type must be a valid DynamoDB stream view type."
  }
}

variable "ttl_enabled" {
  description = "Whether TTL should be enabled."
  type        = bool
  default     = false
}

variable "ttl_attribute_name" {
  description = "TTL attribute name when TTL is enabled."
  type        = string
  default     = "ExpiresAt"
}

variable "tags" {
  description = "Tags applied to DynamoDB resources."
  type        = map(string)
  default     = {}
}