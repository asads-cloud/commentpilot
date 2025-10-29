variable "pool_name"          { type = string }

variable "domain_prefix"      { type = string } # must be globally unique per region

variable "app_client_name"    { type = string }

variable "callback_urls"      { type = list(string) }

variable "logout_urls"        { type = list(string) }

variable "allowed_oauth_scopes"{ 
    type = list(string) 
    default = ["openid","email","profile"] 
}

variable "tags"               { type = map(string) }

variable "env" {
  description = "Environment name (dev, stage, prod, etc.)"
  type        = string
}

variable "oauth_callback_urls" { 
    type = list(string) 
    default = [] 
}

variable "oauth_logout_urls"   { 
    type = list(string) 
    default = [] 
}

