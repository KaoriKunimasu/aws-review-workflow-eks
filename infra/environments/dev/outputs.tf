output "name_prefix" {
  description = "Common name prefix used in the dev environment."
  value       = local.name_prefix
}

output "aws_region" {
  description = "AWS region used by the dev environment."
  value       = var.aws_region
}

output "common_tags" {
  description = "Common tags applied to dev environment resources."
  value       = local.common_tags
}

output "cognito_user_pool_id" {
  description = "Cognito user pool ID."
  value       = module.cognito.user_pool_id
}

output "cognito_arn" {
  description = "Cognito user pool ARN."
  value       = module.cognito.user_pool_arn
}

output "cognito_client_id" {
  description = "Cognito app client ID."
  value       = module.cognito.user_pool_client_id
}

output "cognito_issuer_url" {
  description = "Cognito issuer URL."
  value       = module.cognito.issuer_url
}

output "cognito_hosted_ui_domain" {
  description = "Cognito hosted UI domain."
  value       = module.cognito.hosted_ui_domain
}

output "cognito_base_url" {
  description = "Cognito hosted UI base URL."
  value       = module.cognito.hosted_ui_base_url
}

output "cognito_authorization_endpoint" {
  description = "Cognito authorization endpoint."
  value       = module.cognito.authorization_endpoint
}

output "cognito_token_endpoint" {
  description = "Cognito token endpoint."
  value       = module.cognito.token_endpoint
}

output "workflow_table_name" {
  description = "DynamoDB workflow table name."
  value       = module.dynamodb.table_name
}

output "workflow_table_arn" {
  description = "DynamoDB workflow table ARN."
  value       = module.dynamodb.table_arn
}

output "list_requests_function_name" {
  description = "Lambda function name for listing workflow requests."
  value       = module.list_requests_function.function_name
}

output "list_requests_function_arn" {
  description = "Lambda function ARN for listing workflow requests."
  value       = module.list_requests_function.function_arn
}

output "list_requests_invoke_arn" {
  description = "Lambda invoke ARN for listing workflow requests."
  value       = module.list_requests_function.invoke_arn
}

output "create_request_function_name" {
  description = "Lambda function name for creating workflow requests."
  value       = module.create_request_function.function_name
}

output "create_request_function_arn" {
  description = "Lambda function ARN for creating workflow requests."
  value       = module.create_request_function.function_arn
}

output "create_request_invoke_arn" {
  description = "Lambda invoke ARN for creating workflow requests."
  value       = module.create_request_function.invoke_arn
}

output "api_id" {
  description = "HTTP API ID for the dev environment."
  value       = module.api.api_id
}

output "api_endpoint" {
  description = "HTTP API endpoint for the dev environment."
  value       = module.api.api_endpoint
}

output "api_execution_arn" {
  description = "HTTP API execution ARN for the dev environment."
  value       = module.api.api_execution_arn
}

output "api_stage_name" {
  description = "HTTP API stage name for the dev environment."
  value       = module.api.stage_name
}

output "api_stage_invoke_url" {
  description = "HTTP API invoke URL for the dev environment."
  value       = module.api.stage_invoke_url
}

output "api_log_group_name" {
  description = "CloudWatch log group name for API access logs."
  value       = module.api.log_group_name
}

output "api_log_group_arn" {
  description = "CloudWatch log group ARN for API access logs."
  value       = module.api.log_group_arn
}

output "api_jwt_authorizer_id" {
  description = "JWT authorizer ID for the dev HTTP API."
  value       = module.api.jwt_authorizer_id
}

output "api_route_ids" {
  description = "Map of API route IDs keyed by route key."
  value       = module.api.route_ids
}

output "api_integration_ids" {
  description = "Map of API integration IDs keyed by route key."
  value       = module.api.integration_ids
}
output "eks_cluster_name" {
  description = "EKS cluster name."
  value       = module.eks.cluster_name
}

output "ecr_repository_url" {
  description = "ECR repository URL for the review API image."
  value       = aws_ecr_repository.review_api.repository_url
}

output "configure_kubectl" {
  description = "Command to update local kubeconfig for this cluster."
  value       = "aws eks update-kubeconfig --region ${var.aws_region} --name ${module.eks.cluster_name}"
}
