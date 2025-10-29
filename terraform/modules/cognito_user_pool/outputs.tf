output "user_pool_id"  { value = aws_cognito_user_pool.pool.id }

output "user_pool_arn" { value = aws_cognito_user_pool.pool.arn }

output "app_client_id" { value = aws_cognito_user_pool_client.client.id }

output "domain_prefix" { value = aws_cognito_user_pool_domain.domain.domain }

output "issuer"        { value = "https://cognito-idp.${data.aws_region.current.name}.amazonaws.com/${aws_cognito_user_pool.pool.id}" }

output "hosted_ui_base" { value = local.hosted_ui_base }