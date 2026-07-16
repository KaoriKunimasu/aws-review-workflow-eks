output "module_name" {
  description = "Module identifier."
  value       = local.module_name
}

output "user_pool_id" {
  description = "Cognito user pool ID."
  value       = aws_cognito_user_pool.this.id
}

output "user_pool_arn" {
  description = "Cognito user pool ARN."
  value       = aws_cognito_user_pool.this.arn
}

output "user_pool_name" {
  description = "Cognito user pool name."
  value       = aws_cognito_user_pool.this.name
}

output "user_pool_client_id" {
  description = "Cognito app client ID."
  value       = aws_cognito_user_pool_client.this.id
}

output "user_pool_client_name" {
  description = "Cognito app client name."
  value       = aws_cognito_user_pool_client.this.name
}

output "issuer_url" {
  description = "JWT issuer URL for API authorization."
  value       = local.issuer_url
}

output "hosted_ui_domain" {
  description = "Hosted UI domain prefix, if created."
  value       = local.create_domain ? aws_cognito_user_pool_domain.this[0].domain : null
}

output "hosted_ui_base_url" {
  description = "Hosted UI base URL, if a domain is created."
  value       = local.hosted_ui_base_url
}

output "authorization_endpoint" {
  description = "Hosted UI authorization endpoint, if a domain is created."
  value       = local.hosted_ui_base_url != null ? "${local.hosted_ui_base_url}/oauth2/authorize" : null
}

output "token_endpoint" {
  description = "Hosted UI token endpoint, if a domain is created."
  value       = local.hosted_ui_base_url != null ? "${local.hosted_ui_base_url}/oauth2/token" : null
}

output "reviewer_group_name" {
  description = "Name of the Cognito user group required to approve/reject requests."
  value       = aws_cognito_user_group.reviewer.name
}
