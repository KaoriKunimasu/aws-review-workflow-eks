locals {
  access_log_format = jsonencode({
    requestId               = "$context.requestId"
    sourceIp                = "$context.identity.sourceIp"
    requestTime             = "$context.requestTime"
    protocol                = "$context.protocol"
    httpMethod              = "$context.httpMethod"
    routeKey                = "$context.routeKey"
    status                  = "$context.status"
    responseLength          = "$context.responseLength"
    integrationErrorMessage = "$context.integrationErrorMessage"
  })

  jwt_authorizer_id = var.create_jwt_authorizer ? aws_apigatewayv2_authorizer.jwt[0].id : null
}

resource "aws_apigatewayv2_api" "this" {
  name          = var.name
  description   = var.description
  protocol_type = "HTTP"

  dynamic "cors_configuration" {
    for_each = length(var.cors_allow_origins) > 0 ? [1] : []

    content {
      allow_origins     = var.cors_allow_origins
      allow_methods     = var.cors_allow_methods
      allow_headers     = var.cors_allow_headers
      expose_headers    = var.cors_expose_headers
      allow_credentials = var.cors_allow_credentials
      max_age           = var.cors_max_age
    }
  }

  tags = var.tags
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/api-gw/${var.name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

resource "aws_apigatewayv2_stage" "this" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = var.stage_name
  auto_deploy = var.auto_deploy

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.this.arn
    format          = local.access_log_format
  }

  tags = var.tags
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.create_jwt_authorizer ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  name             = var.jwt_authorizer_name
  authorizer_type  = "JWT"
  identity_sources = var.jwt_authorizer_identity_source

  jwt_configuration {
    audience = var.jwt_authorizer_audience
    issuer   = var.jwt_authorizer_issuer
  }
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = var.routes

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = each.value.integration_uri
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "this" {
  for_each = var.routes

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"

  authorization_type = each.value.authorization_type

  authorizer_id = each.value.authorization_type == "JWT" ? (
    each.value.authorizer_id != null ? each.value.authorizer_id : local.jwt_authorizer_id
  ) : null

  authorization_scopes = each.value.authorization_type == "JWT" && length(each.value.authorization_scopes) > 0 ? each.value.authorization_scopes : null
}

resource "aws_lambda_permission" "this" {
  for_each = var.routes

  statement_id  = "AllowExecutionFromApiGateway-${substr(md5(each.key), 0, 8)}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
