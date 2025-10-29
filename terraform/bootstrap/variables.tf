variable "region" {
  type    = string
  default = "eu-west-1"
}

variable "profile" {
  type    = string
  default = "default"
}

variable "global_prefix" {
  type    = string
  default = "commentpilot"
}

# Derived names
locals {
  tf_state_bucket = "${var.global_prefix}-tfstate"
  tf_lock_table   = "${var.global_prefix}-tflock"
}
