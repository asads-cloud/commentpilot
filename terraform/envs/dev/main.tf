data "aws_caller_identity" "current" {}

#---------------- S3 BUCKETS ----------------#

locals {
  acct_id               = data.aws_caller_identity.current.account_id
  raw_bucket_name       = "${local.name_prefix}-raw-${local.env}-${local.acct_id}"
  processed_bucket_name = "${local.name_prefix}-processed-${local.env}-${local.acct_id}"
}

module "s3_raw" {
  source             = "../../modules/s3_bucket"
  bucket_name        = local.raw_bucket_name
  versioning_enabled = true
  force_destroy      = false
  tags               = merge(local.tags, { Name = local.raw_bucket_name, Purpose = "raw-ingestion" })
}

module "s3_processed" {
  source             = "../../modules/s3_bucket"
  bucket_name        = local.processed_bucket_name
  versioning_enabled = true
  force_destroy      = false
  tags               = merge(local.tags, { Name = local.processed_bucket_name, Purpose = "processed-output" })
}

#---------------- DYNAMO DB ----------------#

locals {
  messages_table_name = "commentpilot_messages_${local.env}"
}

module "dynamodb_messages" {
  source           = "../../modules/dynamodb"
  table_name       = local.messages_table_name
  billing_mode     = "PAY_PER_REQUEST" # switch to PROVISIONED later if desired
  enable_streams   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  enable_pitr      = true
  enable_ttl       = true
  ttl_attribute    = "expiresAt"
  gsi1_enabled     = true
  gsi1_name        = "gsi1"

  tags = merge(local.tags, {
    Name    = local.messages_table_name
    Purpose = "processed-messages"
  })
}

#---------------- LAMBDA ----------------#

locals {
  health_fn_name = "cp-health-${local.env}"
}

module "lambda_health" {
  source          = "../../modules/lambda"
  function_name   = local.health_fn_name
  handler         = "index.handler"
  runtime         = "nodejs20.x"
  role_arn        = module.iam_lambda_exec.role_arn
  source_dir      = "../../../backend/lambdas/health"
  memory_mb       = 128
  timeout_seconds = 5
  architecture    = "arm64"
  env_vars = {
    ENV = local.env
  }
  tags = merge(local.tags, { Name = local.health_fn_name, Purpose = "health-endpoint" })
}

#---------------- API Gateway ----------------#

locals {
  api_name   = "commentpilot-api-${local.env}"
  stage_name = local.env
}

module "apigw" {
  source              = "../../modules/api_gateway"
  api_name            = local.api_name
  stage_name          = local.stage_name
  region              = var.region

  lambda_arn_health       = module.lambda_health.function_arn
  lambda_arn_get_messages = module.lambda_get_messages.lambda_arn
  lambda_arn_post_reply   = module.lambda_post_reply.lambda_arn

  cognito_user_pool_arn   = module.cognito.user_pool_arn

  cloudwatch_role_arn = module.iam_apigw_logs.role_arn
  tags                = merge(local.tags, { Name = local.api_name, Purpose = "public-api" })
}

#---------------- Cognito ----------------#

locals {
  cognito_pool_name   = "commentpilot_userpool_${local.env}"
  cognito_client_name = "commentpilot_client_${local.env}"

  # For dev: Next.js on localhost + a placeholder Amplify domain we can swap later
  oauth_callback_urls = [
    "http://localhost:3000/api/auth/callback/cognito",
    "http://localhost:3000/auth/callback",
  ]
  oauth_logout_urls = [
    "http://localhost:3000/",
  ]

  # Domain prefix must be unique per region; tweak with a short suffix if taken
  cognito_domain_prefix = "commentpilot-${local.env}"
}

module "cognito" {
  source               = "../../modules/cognito_user_pool"
  pool_name            = local.cognito_pool_name
  domain_prefix        = local.cognito_domain_prefix
  app_client_name      = local.cognito_client_name
  callback_urls        = local.oauth_callback_urls
  logout_urls          = local.oauth_logout_urls
  allowed_oauth_scopes = ["openid", "email", "profile"]
  tags                 = merge(local.tags, { Name = local.cognito_pool_name, Purpose = "auth" })
  env                  = local.env
}

#---------------- LAMBDA API ----------------#

locals {
  api_env = {
    COGNITO_ISSUER        = "https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_cnU947fEq"
    COGNITO_APP_CLIENT_ID = "3rjegck7s8kmirac79hajqg99d"
    DDB_TABLE             = "commentpilot_messages_dev"
  }
}

# --- Lambdas (built via esbuild by the module) ---
module "lambda_get_messages" {
  source   = "../../modules/lambda_api"
  name     = "cp_api_get_messages_dev"
  entry    = "getMessages"
  role_arn = module.iam_lambda_exec.role_arn
  env      = local.api_env
}

module "lambda_post_reply" {
  source   = "../../modules/lambda_api"
  name     = "cp_api_post_reply_dev"
  entry    = "postReply"
  role_arn = module.iam_lambda_exec.role_arn
  env      = local.api_env
}

#---------------- LAMBDA ETL ----------------#

# Reuse the lambda exec role cleanly
data "aws_iam_role" "cp_lambda_exec_dev" {
  name = "cp_lambda_exec_dev"
}

# S3 write permissions for RAW bucket
data "aws_iam_policy_document" "s3_put_raw" {
  statement {
    actions   = ["s3:PutObject","s3:AbortMultipartUpload","s3:PutObjectAcl"]
    resources = ["arn:aws:s3:::${local.raw_bucket_name}/*"]
  }
}
resource "aws_iam_policy" "s3_put_raw" {
  name   = "cp_lambda_raw_write_dev"
  policy = data.aws_iam_policy_document.s3_put_raw.json
}
resource "aws_iam_role_policy_attachment" "attach_s3_put_raw" {
  role       = data.aws_iam_role.cp_lambda_exec_dev.name
  policy_arn = aws_iam_policy.s3_put_raw.arn
}

# Instagram ETL
module "lambda_fetch_instagram_dm" {
  source    = "../../modules/lambda_basic"
  name      = "cp_fetch_instagram_dm_dev"
  entry_dir = "etl/fetch_instagram_dm"
  role_arn  = data.aws_iam_role.cp_lambda_exec_dev.arn
  env       = { RAW_BUCKET = local.raw_bucket_name }
  depends_on = [aws_iam_role_policy_attachment.attach_s3_put_raw]
}

# TikTok ETL
module "lambda_fetch_tiktok_dm" {
  source    = "../../modules/lambda_basic"
  name      = "cp_fetch_tiktok_dm_dev"
  entry_dir = "etl/fetch_tiktok_dm"
  role_arn  = data.aws_iam_role.cp_lambda_exec_dev.arn
  env       = { RAW_BUCKET = local.raw_bucket_name }
  depends_on = [aws_iam_role_policy_attachment.attach_s3_put_raw]
}

# EventBridge schedules (cron or rate both fine)
resource "aws_cloudwatch_event_rule" "ig_schedule" {
  name                = "cp_fetch_schedule_instagram_dev"
  schedule_expression = "rate(5 minutes)"
}
resource "aws_cloudwatch_event_rule" "tt_schedule" {
  name                = "cp_fetch_schedule_tiktok_dev"
  schedule_expression = "rate(5 minutes)"
}
resource "aws_cloudwatch_event_target" "ig_target" {
  rule      = aws_cloudwatch_event_rule.ig_schedule.name
  target_id = "ig"
  arn       = module.lambda_fetch_instagram_dm.lambda_arn
}
resource "aws_cloudwatch_event_target" "tt_target" {
  rule      = aws_cloudwatch_event_rule.tt_schedule.name
  target_id = "tt"
  arn       = module.lambda_fetch_tiktok_dm.lambda_arn
}
resource "aws_lambda_permission" "allow_events_ig" {
  statement_id  = "AllowEventsInvokeIG"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_fetch_instagram_dm.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.ig_schedule.arn
}
resource "aws_lambda_permission" "allow_events_tt" {
  statement_id  = "AllowEventsInvokeTT"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_fetch_tiktok_dm.lambda_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.tt_schedule.arn
}

#---------------- IAM ----------------#

# Convenience locals
locals {
  lambda_role_name = "cp_lambda_exec_${local.env}"
  glue_role_name   = "cp_glue_job_${local.env}"
  apigw_role_name  = "cp_apigw_logs_${local.env}"

  raw_arn       = "arn:aws:s3:::${module.s3_raw.bucket_name}"
  raw_objs_arn  = "${local.raw_arn}/*"
  proc_arn      = "arn:aws:s3:::${module.s3_processed.bucket_name}"
  proc_objs_arn = "${local.proc_arn}/*"
}

# Assume-role policies
data "aws_iam_policy_document" "assume_lambda" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "assume_glue" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["glue.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "assume_apigw" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# Inline policies
# CloudWatch Logs write (Lambda/API GW)
data "aws_iam_policy_document" "cw_logs_write" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = ["arn:aws:logs:${var.region != null ? var.region : "eu-west-1"}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

# Lambda S3 access: read raw, write processed
data "aws_iam_policy_document" "lambda_s3_rw" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:GetObjectAttributes", "s3:ListBucket"]
    resources = [local.raw_arn, local.raw_objs_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:AbortMultipartUpload", "s3:ListBucket", "s3:GetObject"]
    resources = [local.proc_arn, local.proc_objs_arn]
  }
}

# Lambda DynamoDB CRUD on main table + read the stream
data "aws_iam_policy_document" "lambda_dynamodb" {
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:DeleteItem",
      "dynamodb:BatchWriteItem", "dynamodb:Query", "dynamodb:Scan"
    ]
    resources = [module.dynamodb_messages.table_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["dynamodb:DescribeStream", "dynamodb:GetRecords", "dynamodb:GetShardIterator", "dynamodb:ListStreams"]
    resources = [module.dynamodb_messages.table_stream_arn]
  }
}

# Glue: S3 raw/processed read/write + logs + Glue service calls
data "aws_iam_policy_document" "glue_rw" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:ListBucket"]
    resources = [local.raw_arn, local.raw_objs_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket", "s3:DeleteObject"]
    resources = [local.proc_arn, local.proc_objs_arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["arn:aws:logs:${var.region != null ? var.region : "eu-west-1"}:${data.aws_caller_identity.current.account_id}:*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "glue:GetJob", "glue:StartJobRun", "glue:GetJobRun", "glue:GetTable", "glue:GetDatabase",
      "glue:CreateDatabase", "glue:CreateTable", "glue:UpdateTable", "glue:GetPartitions", "glue:BatchGetPartition"
    ]
    resources = ["*"] # Glue API often needs wide scope.
  }
}

# API Gateway execution logging
data "aws_iam_policy_document" "apigw_logs" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup", "logs:CreateLogStream", "logs:DescribeLogGroups", "logs:DescribeLogStreams", "logs:PutLogEvents"
    ]
    resources = ["arn:aws:logs:${var.region != null ? var.region : "eu-west-1"}:${data.aws_caller_identity.current.account_id}:*"]
  }
}

# Roles--------------------------

module "iam_lambda_exec" {
  source             = "../../modules/iam_role"
  name               = local.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_lambda.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" # redundant to cw policy, but good default
  ]
  inline_policies = {
    "lambda-s3-rw" = data.aws_iam_policy_document.lambda_s3_rw.json
    "lambda-ddb"   = data.aws_iam_policy_document.lambda_dynamodb.json
  }
  tags = merge(local.tags, { Name = local.lambda_role_name, Purpose = "lambda-exec" })
}

module "iam_glue_job" {
  source             = "../../modules/iam_role"
  name               = local.glue_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_glue.json
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
  ]
  inline_policies = {
    "glue-s3-rw" = data.aws_iam_policy_document.glue_rw.json
  }
  tags = merge(local.tags, { Name = local.glue_role_name, Purpose = "glue-job" })
}

module "iam_apigw_logs" {
  source             = "../../modules/iam_role"
  name               = local.apigw_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_apigw.json
  inline_policies = {
    "apigw-cw-logs" = data.aws_iam_policy_document.apigw_logs.json
  }
  tags = merge(local.tags, { Name = local.apigw_role_name, Purpose = "apigw-logs" })
}




