# CommentPilot — Infrastructure Outputs (dev)

**Environment:** dev  |  **Region:** eu-west-1  |  **Generated:** 2025-10-29 17:34:23 UTC

## Core Resources

### S3
- Raw bucket: `commentpilot-raw-dev-155186308102`
- Processed bucket: `commentpilot-processed-dev-155186308102`

### DynamoDB
- Table name: `commentpilot_messages_dev`
- Table ARN: `arn:aws:dynamodb:eu-west-1:155186308102:table/commentpilot_messages_dev`
- Stream ARN: `arn:aws:dynamodb:eu-west-1:155186308102:table/commentpilot_messages_dev/stream/2025-10-29T05:02:29.014`

### IAM Roles
- Lambda exec role ARN: `arn:aws:iam::155186308102:role/cp_lambda_exec_dev`
- Glue job role ARN: `arn:aws:iam::155186308102:role/cp_glue_job_dev`
- API GW logs role ARN: `arn:aws:iam::155186308102:role/cp_apigw_logs_dev`

### Lambda
- Health function name: `cp-health-dev`
- Health function ARN: `arn:aws:lambda:eu-west-1:155186308102:function:cp-health-dev`

### API Gateway
- Invoke URL: https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev
- Health endpoint: https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev/health

### Cognito
- User Pool ID: `eu-west-1_cnU947fEq`
- App Client ID (PKCE): `3rjegck7s8kmirac79hajqg99d`
- Issuer: `https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_cnU947fEq`
- Hosted UI Base: https://commentpilot-dev-86308102.auth.eu-west-1.amazoncognito.com
- Example Authorize URL: https://commentpilot-dev-86308102.auth.eu-west-1.amazoncognito.com/oauth2/authorize?client_id=3rjegck7s8kmirac79hajqg99d&response_type=code&scope=openid+email+profile&redirect_uri=http%3A%2F%2Flocalhost%3A3000%2Fapi%2Fauth%2Fcallback%2Fcognito

## Tags (global)
- Environment = dev
- Project = CommentPilot
- Owner = you
- Phase = 1

## Verification Checklist
- [ ] `GET https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev/health` returns 200 JSON
- [ ] Cognito Hosted UI loads (use the Example Authorize URL)
- [ ] S3 buckets visible and versioning enabled
- [ ] DynamoDB table ACTIVE, PITR enabled, Stream ARN present
- [ ] CloudWatch logs receiving API GW access logs and Lambda logs
