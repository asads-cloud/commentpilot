# CommentPilot — Phase 1 Handoff (dev)
**Date:** 2025-10-30 01:21:19 UTC  
**Region:** eu-west-1  
**IaC:** Terraform (remote state: commentpilot-tfstate / commentpilot-tflock)

## Created Resources (dev)
- **S3**
  - raw: commentpilot-raw-dev-155186308102
  - processed: commentpilot-processed-dev-155186308102
- **DynamoDB**
  - table: commentpilot_messages_dev
  - arn: arn:aws:dynamodb:eu-west-1:155186308102:table/commentpilot_messages_dev
  - stream arn: arn:aws:dynamodb:eu-west-1:155186308102:table/commentpilot_messages_dev/stream/2025-10-29T05:02:29.014
- **IAM Roles**
  - lambda exec: arn:aws:iam::155186308102:role/cp_lambda_exec_dev
  - glue job: arn:aws:iam::155186308102:role/cp_glue_job_dev
  - apigw logs: arn:aws:iam::155186308102:role/cp_apigw_logs_dev
- **Lambda**
  - health fn: cp-health-dev
  - arn: arn:aws:lambda:eu-west-1:155186308102:function:cp-health-dev
- **API Gateway**
  - invoke url: https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev (/health)
- **Cognito**
  - user pool id: eu-west-1_cnU947fEq
  - app client id (PKCE): 3rjegck7s8kmirac79hajqg99d
  - issuer: https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_cnU947fEq
  - hosted ui: https://commentpilot-dev-86308102.auth.eu-west-1.amazoncognito.com

## Verification (completed)
- GET https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev/health → 200 JSON from Lambda ✅
- S3 buckets exist, versioning enabled, public access blocked ✅
- DynamoDB table ACTIVE, PITR ON, Stream ARN present ✅
- CloudWatch has Lambda and API GW access logs ✅
- Cognito Hosted UI reachable, app client has no secret (PKCE) ✅

## Artifacts
- docs/infra-outputs.md — machine-generated outputs snapshot
- docs/phase1-handoff.md — this handoff
- Terraform modules under terraform/modules/*
- Environment stack under terraform/envs/dev/*

## Next-Phase Inputs (for Phase 2: Lambdas + Glue)
- **Env/Config:**  
  - ENV=dev, REGION=eu-west-1, RAW_BUCKET=commentpilot-raw-dev-155186308102, PROCESSED_BUCKET=commentpilot-processed-dev-155186308102
  - DDB_TABLE=commentpilot_messages_dev, DDB_STREAM_ARN=arn:aws:dynamodb:eu-west-1:155186308102:table/commentpilot_messages_dev/stream/2025-10-29T05:02:29.014
- **Auth (frontend/backend):**  
  - COGNITO_POOL_ID=eu-west-1_cnU947fEq
  - COGNITO_CLIENT_ID=3rjegck7s8kmirac79hajqg99d
  - COGNITO_ISSUER=https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_cnU947fEq (JWKS: https://cognito-idp.eu-west-1.amazonaws.com/eu-west-1_cnU947fEq/.well-known/jwks.json)
- **Service Roles:**  
  - LAMBDA_ROLE_ARN=arn:aws:iam::155186308102:role/cp_lambda_exec_dev
  - GLUE_ROLE_ARN=arn:aws:iam::155186308102:role/cp_glue_job_dev
- **Healthcheck:**  
  - API_HEALTH_URL=https://o4yb8vt8i0.execute-api.eu-west-1.amazonaws.com/dev/health

## Done Criteria
- All resources applied via Terraform; no manual config required beyond verification.
- Outputs recorded and versioned; repo tagged phase1-complete.
