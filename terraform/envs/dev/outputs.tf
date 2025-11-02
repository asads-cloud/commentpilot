#---------------- S3 BUCKETS ----------------#

output "s3_raw_bucket_name" {
  value = module.s3_raw.bucket_name
}

output "s3_processed_bucket_name" {
  value = module.s3_processed.bucket_name
}

#---------------- DYNAMO DB ----------------#

output "dynamodb_messages_table_name" {
  value = module.dynamodb_messages.table_name
}
output "dynamodb_messages_table_arn" {
  value = module.dynamodb_messages.table_arn
}
output "dynamodb_messages_stream_arn" {
  value = module.dynamodb_messages.table_stream_arn
}

#---------------- LAMBDA ----------------------------------------------------------------------------------------#

output "lambda_health_function_name" {
  value = module.lambda_health.function_name
}

output "lambda_health_function_arn" {
  value = module.lambda_health.function_arn
}

output "lambda_cp_api_get_messages_arn" {
  value       = module.lambda_get_messages.lambda_arn
  description = "ARN for GET /messages Lambda"
}

output "lambda_cp_api_post_reply_arn" {
  value       = module.lambda_post_reply.lambda_arn
  description = "ARN for POST /reply Lambda"
}

output "lambda_cp_fetch_instagram_dm_arn" {
  value       = module.lambda_fetch_instagram_dm.lambda_arn
  description = "ARN for Instagram DM fetch ETL"
}

output "lambda_cp_fetch_tiktok_dm_arn" {
  value       = module.lambda_fetch_tiktok_dm.lambda_arn
  description = "ARN for TikTok DM fetch ETL"
}

#---------------- GLUE ----------------------------------------------------------------------------------------#

output "glue_normalise_job_name" {
  value       = module.glue_normalise.job_name
  description = "Glue job name"
}

#---------------- Eventbridge ----------------------------------------------------------------------------------------#

output "rule_cp_fetch_schedule_instagram_dev_arn" {
  value       = aws_cloudwatch_event_rule.ig_schedule.arn
  description = "EventBridge rule ARN for Instagram ETL schedule."
}

output "rule_cp_fetch_schedule_tiktok_dev_arn" {
  value       = aws_cloudwatch_event_rule.tt_schedule.arn
  description = "EventBridge rule ARN for TikTok ETL schedule."
}
#---------------- API Gateway ----------------#

output "apigw_invoke_url" {
  value = module.apigw.invoke_url
}

#---------------- Cognito ----------------#

# Helpful assembled URLs for quick testing (computed locally using outputs)
output "cognito_user_pool_id" {
  value = module.cognito.user_pool_id
}

output "cognito_app_client_id" {
  value = module.cognito.app_client_id
}

output "cognito_hosted_ui_base" {
  value = module.cognito.hosted_ui_base
}

output "cognito_issuer" {
  value = module.cognito.issuer
}

# Example authorize URL (uses first callback URL)
output "cognito_authorize_url_example" {
  value = format("%s/oauth2/authorize?client_id=%s&response_type=code&scope=openid+email+profile&redirect_uri=%s",
    module.cognito.hosted_ui_base,
    module.cognito.app_client_id,
    urlencode(element(local.oauth_callback_urls, 0))
  )
}

#---------------- IAM ----------------#

output "iam_lambda_exec_role_arn" {
  value = module.iam_lambda_exec.role_arn
}

output "iam_glue_job_role_arn" {
  value = module.iam_glue_job.role_arn
}

output "iam_apigw_logs_role_arn" {
  value = module.iam_apigw_logs.role_arn
}