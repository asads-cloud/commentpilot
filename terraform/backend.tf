terraform {
  backend "s3" {
    bucket         = "commentpilot-tfstate"
    key            = "envs/dev/terraform.tfstate"
    region         = "eu-west-1"
    profile        = "default"
    dynamodb_table = "commentpilot-tflock"
    encrypt        = true
  }
}