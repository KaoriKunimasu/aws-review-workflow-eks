output "module_name" {
  description = "Module identifier."
  value       = local.module_name
}

output "lambda_error_threshold" {
  description = "Configured Lambda error threshold."
  value       = var.lambda_error_threshold
}

output "api_5xx_threshold" {
  description = "Configured API 5XX threshold."
  value       = var.api_5xx_threshold
}
