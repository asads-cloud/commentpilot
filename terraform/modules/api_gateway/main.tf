resource "aws_api_gateway_rest_api" "api" {
  name = var.api_name
  endpoint_configuration { types = ["REGIONAL"] }
  tags = var.tags
}

# Ensure API Gateway has a CW logs role
resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = var.cloudwatch_role_arn
}

# /health resource
resource "aws_api_gateway_resource" "health" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "health"
}

resource "aws_api_gateway_method" "health_get" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.health.id
  http_method   = "GET"
  authorization = "NONE"
}

# Lambda proxy integration
resource "aws_api_gateway_integration" "health_integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.health.id
  http_method             = aws_api_gateway_method.health_get.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_arn_health}/invocations"
}

resource "aws_api_gateway_deployment" "deploy" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = {
    redeploy_hash = sha1(join(",", [
      aws_api_gateway_integration.health_integration.id,
      aws_api_gateway_method.health_get.id,
      aws_api_gateway_authorizer.cognito_userpools.id,
      aws_api_gateway_integration.get_messages.id,
      aws_api_gateway_method.get_messages.id,
      aws_api_gateway_integration.post_reply.id,
      aws_api_gateway_method.post_reply.id
    ]))
  }
  lifecycle { create_before_destroy = true }
}

resource "aws_cloudwatch_log_group" "stage_access" {
  name              = "/aws/apigw/${var.api_name}-${var.stage_name}-access"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_api_gateway_stage" "stage" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  deployment_id = aws_api_gateway_deployment.deploy.id
  stage_name    = var.stage_name

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.stage_access.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
      integrationStatus = "$context.integrationStatus"
      errorMessage   = "$context.error.message"
    })
  }

  tags = var.tags
  depends_on = [aws_api_gateway_account.account]
}

# Lambda permission so APIGW can invoke it
resource "aws_lambda_permission" "allow_apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn_health
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}


#----test

# --- Cognito authorizer for REST API ---
resource "aws_api_gateway_authorizer" "cognito_userpools" {
  name            = "cognito_userpools"
  rest_api_id     = aws_api_gateway_rest_api.api.id
  type            = "COGNITO_USER_POOLS"
  provider_arns   = [var.cognito_user_pool_arn]
  identity_source = "method.request.header.Authorization"
}

# --- /messages (GET) ---
resource "aws_api_gateway_resource" "messages" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "messages"
}

resource "aws_api_gateway_method" "get_messages" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.messages.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_userpools.id
}

resource "aws_api_gateway_integration" "get_messages" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.messages.id
  http_method             = aws_api_gateway_method.get_messages.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_arn_get_messages}/invocations"
}

resource "aws_lambda_permission" "allow_apigw_get_messages" {
  statement_id  = "AllowAPIGInvokeGetMessages"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn_get_messages
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/GET/messages"
}

# --- /reply (POST) ---
resource "aws_api_gateway_resource" "reply" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "reply"
}

resource "aws_api_gateway_method" "post_reply" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.reply.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_userpools.id
}

resource "aws_api_gateway_integration" "post_reply" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.reply.id
  http_method             = aws_api_gateway_method.post_reply.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${var.lambda_arn_post_reply}/invocations"
}

resource "aws_lambda_permission" "allow_apigw_post_reply" {
  statement_id  = "AllowAPIGInvokePostReply"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_arn_post_reply
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.api.execution_arn}/*/POST/reply"
}