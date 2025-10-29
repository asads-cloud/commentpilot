provider "aws" {
  region = "eu-west-1"
}

locals {
  env         = "dev"
  project     = "CommentPilot"
  name_prefix = "commentpilot"

  tags = {
    Environment = local.env
    Project     = local.project
    Owner       = "you"
    Phase       = "1"
  }
}
