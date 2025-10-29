variable "api_name"              { type = string }

variable "stage_name"            { type = string }

variable "region"                { 
    type = string  
    default = "eu-west-1" 
}

variable "lambda_arn_health"     { type = string } # Lambda to integrate

variable "cloudwatch_role_arn"   { type = string } # Role for APIGW to write logs

variable "tags"                  { type = map(string) }

