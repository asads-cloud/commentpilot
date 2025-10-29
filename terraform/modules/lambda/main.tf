data "archive_file" "zip" {
  type        = "zip"
  source_dir  = var.source_dir
  output_path = "${path.module}/${var.function_name}.zip"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = 14
  tags              = var.tags
}

resource "aws_lambda_function" "this" {
  function_name = var.function_name
  role          = var.role_arn
  filename      = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  handler = var.handler
  runtime = var.runtime
  memory_size = var.memory_mb
  timeout     = var.timeout_seconds
  architectures = [var.architecture]

  environment {
    variables = var.env_vars
  }

  tracing_config {
    mode = "PassThrough" # gonna upgrade to Active when we add X-Ray
  }

  tags = var.tags
}

