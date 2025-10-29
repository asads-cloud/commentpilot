variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "oauth_callback_urls" {
  type    = list(string)
  default = []
}

variable "oauth_logout_urls" {
  type    = list(string)
  default = []
}
