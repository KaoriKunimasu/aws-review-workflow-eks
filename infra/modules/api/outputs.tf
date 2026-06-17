output "api_id" {
  description = "HTTP API ID."
  value       = aws_apigatewayv2_api.this.id
}

output "api_endpoint" {
  description = "HTTP API endpoint."
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_execution_arn" {
  description = "HTTP API execution ARN."
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "stage_name" {
  description = "HTTP API stage name."
  value       = aws_apigatewayv2_stage.this.name
}

output "stage_invoke_url" {
  description = "HTTP API stage invoke URL."
  value       = aws_apigatewayv2_stage.this.invoke_url
}

output "log_group_name" {
  description = "CloudWatch log group name for API access logs."
  value       = aws_cloudwatch_log_group.this.name
}

output "log_group_arn" {
  description = "CloudWatch log group ARN for API access logs."
  value       = aws_cloudwatch_log_group.this.arn
}

output "jwt_authorizer_id" {
  description = "JWT authorizer ID when created by this module."
  value       = var.create_jwt_authorizer ? aws_apigatewayv2_authorizer.jwt[0].id : null
}

output "route_ids" {
  description = "Map of route IDs keyed by route key."
  value = {
    for route_key, route in aws_apigatewayv2_route.this :
    route_key => route.id
  }
}

output "integration_ids" {
  description = "Map of integration IDs keyed by route key."
  value = {
    for route_key, integration in aws_apigatewayv2_integration.this :
    route_key => integration.id
  }
}
