output "rest_api_id"       { value = aws_api_gateway_rest_api.api.id }

output "stage_name"        { value = aws_api_gateway_stage.stage.stage_name }

output "invoke_url"        { value = "https://${aws_api_gateway_rest_api.api.id}.execute-api.${var.region}.amazonaws.com/${aws_api_gateway_stage.stage.stage_name}" }

#----test

output "rest_api_execution_arn" { value = aws_api_gateway_rest_api.api.execution_arn }
