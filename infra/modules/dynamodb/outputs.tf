output "module_name" {
  description = "Module identifier."
  value       = local.module_name
}

output "table_name" {
  description = "DynamoDB table name."
  value       = aws_dynamodb_table.this.name
}

output "table_arn" {
  description = "DynamoDB table ARN."
  value       = aws_dynamodb_table.this.arn
}

output "billing_mode" {
  description = "Configured billing mode."
  value       = aws_dynamodb_table.this.billing_mode
}

output "hash_key" {
  description = "Primary partition key name."
  value       = var.hash_key
}

output "range_key" {
  description = "Primary sort key name."
  value       = var.range_key
}

output "gsi1_name" {
  description = "First global secondary index name."
  value       = var.gsi1_name
}

output "gsi1_hash_key" {
  description = "First global secondary index partition key name."
  value       = var.gsi1_hash_key
}

output "gsi1_range_key" {
  description = "First global secondary index sort key name."
  value       = var.gsi1_range_key
}

output "stream_enabled" {
  description = "Whether DynamoDB Streams are enabled."
  value       = aws_dynamodb_table.this.stream_enabled
}

output "stream_arn" {
  description = "DynamoDB stream ARN, if streams are enabled."
  value       = aws_dynamodb_table.this.stream_arn
}
