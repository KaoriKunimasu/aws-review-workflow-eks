terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  module_name = "dynamodb"
  table_name  = "${var.name_prefix}-workflow"
}

resource "aws_dynamodb_table" "this" {
  name         = local.table_name
  billing_mode = var.billing_mode
  hash_key     = var.hash_key
  range_key    = var.range_key

  deletion_protection_enabled = var.deletion_protection_enabled
  table_class                 = var.table_class

  stream_enabled   = var.stream_enabled
  stream_view_type = var.stream_enabled ? var.stream_view_type : null

  attribute {
    name = var.hash_key
    type = "S"
  }

  attribute {
    name = var.range_key
    type = "S"
  }

  attribute {
    name = var.gsi1_hash_key
    type = "S"
  }

  attribute {
    name = var.gsi1_range_key
    type = "S"
  }

  global_secondary_index {
    name            = var.gsi1_name
    hash_key        = var.gsi1_hash_key
    range_key       = var.gsi1_range_key
    projection_type = var.gsi1_projection_type
  }

  point_in_time_recovery {
    enabled = var.point_in_time_recovery_enabled
  }

  server_side_encryption {
    enabled = true
  }

  dynamic "ttl" {
    for_each = var.ttl_enabled ? [1] : []

    content {
      attribute_name = var.ttl_attribute_name
      enabled        = true
    }
  }

  tags = var.tags
}
