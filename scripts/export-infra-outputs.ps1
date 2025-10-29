param(
  [string]$EnvDir = "terraform/envs/dev",
  [string]$OutFile = "docs/infra-outputs.md"
)

Write-Host "Reading terraform outputs from $EnvDir ..."
Push-Location $EnvDir
try {
  $json = terraform output -json | ConvertFrom-Json
} finally {
  Pop-Location
}

# Resolve region (prefer TF/Cognito issuer → falls back to AWS default → eu-west-1)
$region = "eu-west-1"
if ($json.cognito_issuer.value -match 'cognito-idp\.([a-z0-9-]+)\.amazonaws\.com') { $region = $Matches[1] }
elseif ($env:AWS_REGION) { $region = $env:AWS_REGION }
elseif ($env:AWS_DEFAULT_REGION) { $region = $env:AWS_DEFAULT_REGION }
elseif ((aws configure get region) -ne "") { $region = aws configure get region }

$utcNow = (Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss 'UTC'")

$lines = @()
$lines += "# CommentPilot — Infrastructure Outputs (dev)"
$lines += ""
$lines += "**Environment:** dev  |  **Region:** $region  |  **Generated:** $utcNow"
$lines += ""
$lines += "## Core Resources"
$lines += ""
$lines += "### S3"
$lines += "- Raw bucket: ``$($json.s3_raw_bucket_name.value)``"
$lines += "- Processed bucket: ``$($json.s3_processed_bucket_name.value)``"
$lines += ""
$lines += "### DynamoDB"
$lines += "- Table name: ``$($json.dynamodb_messages_table_name.value)``"
$lines += "- Table ARN: ``$($json.dynamodb_messages_table_arn.value)``"
$lines += "- Stream ARN: ``$($json.dynamodb_messages_stream_arn.value)``"
$lines += ""
$lines += "### IAM Roles"
$lines += "- Lambda exec role ARN: ``$($json.iam_lambda_exec_role_arn.value)``"
$lines += "- Glue job role ARN: ``$($json.iam_glue_job_role_arn.value)``"
$lines += "- API GW logs role ARN: ``$($json.iam_apigw_logs_role_arn.value)``"
$lines += ""
$lines += "### Lambda"
$lines += "- Health function name: ``$($json.lambda_health_function_name.value)``"
$lines += "- Health function ARN: ``$($json.lambda_health_function_arn.value)``"
$lines += ""
$lines += "### API Gateway"
$lines += "- Invoke URL: $($json.apigw_invoke_url.value)"
$lines += "- Health endpoint: $($json.apigw_invoke_url.value)/health"
$lines += ""
$lines += "### Cognito"
$lines += "- User Pool ID: ``$($json.cognito_user_pool_id.value)``"
$lines += "- App Client ID (PKCE): ``$($json.cognito_app_client_id.value)``"
$lines += "- Issuer: ``$($json.cognito_issuer.value)``"
$lines += "- Hosted UI Base: $($json.cognito_hosted_ui_base.value)"
$lines += "- Example Authorize URL: $($json.cognito_authorize_url_example.value)"
$lines += ""
$lines += "## Tags (global)"
$lines += "- Environment = dev"
$lines += "- Project = CommentPilot"
$lines += "- Owner = you"
$lines += "- Phase = 1"
$lines += ""
$lines += "## Verification Checklist"
$lines += "- [ ] ``GET $($json.apigw_invoke_url.value)/health`` returns 200 JSON"
$lines += "- [ ] Cognito Hosted UI loads (use the Example Authorize URL)"
$lines += "- [ ] S3 buckets visible and versioning enabled"
$lines += "- [ ] DynamoDB table ACTIVE, PITR enabled, Stream ARN present"
$lines += "- [ ] CloudWatch logs receiving API GW access logs and Lambda logs"

$dir = Split-Path $OutFile
if (!(Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$lines -join "`r`n" | Out-File $OutFile -Encoding UTF8

Write-Host "Wrote $OutFile"
