# Hosted UI base + example authorize URL
data "aws_region" "current" {}
data "aws_caller_identity" "acct" {}


locals {
  oauth_callback_urls = length(var.oauth_callback_urls) > 0 ? var.oauth_callback_urls : var.callback_urls
  oauth_logout_urls   = length(var.oauth_logout_urls) > 0 ? var.oauth_logout_urls : var.logout_urls
  hosted_ui_base = "https://${aws_cognito_user_pool_domain.domain.domain}.auth.${data.aws_region.current.name}.amazoncognito.com"
  acct_suffix          = substr(data.aws_caller_identity.acct.account_id, 4, 8)
  cognito_domain_prefix = "commentpilot-${var.env}-${local.acct_suffix}"
}


resource "aws_cognito_user_pool" "pool" {
  name = var.pool_name

  username_attributes = ["email"]

  mfa_configuration = "OFF"

  password_policy {
    minimum_length    = 12
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }

  account_recovery_setting {
    recovery_mechanism { 
        name = "verified_email" 
        priority = 1 
    }
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = true
    mutable             = false
  }

  # enable advanced security later if needed
  tags = var.tags
}

resource "aws_cognito_user_pool_client" "client" {
  name                         = var.app_client_name
  user_pool_id                 = aws_cognito_user_pool.pool.id

  generate_secret              = false     # REQUIRED for PKCE
  prevent_user_existence_errors= "ENABLED"

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows  = ["code"]        # Authorization Code + PKCE
  allowed_oauth_scopes = var.allowed_oauth_scopes
  supported_identity_providers = ["COGNITO"]

  callback_urls = local.oauth_callback_urls
  logout_urls   = local.oauth_logout_urls

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  enable_token_revocation = true
  access_token_validity   = 60
  id_token_validity       = 60
  refresh_token_validity  = 30
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

resource "aws_cognito_user_pool_domain" "domain" {
  domain       = local.cognito_domain_prefix
  user_pool_id = aws_cognito_user_pool.pool.id
}




