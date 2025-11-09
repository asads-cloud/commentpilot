variable "bucket_name" {
  description = "Name of the S3 bucket"
  type        = string
}

variable "versioning_enabled" {
  description = "Enable object versioning"
  type        = bool
  default     = true
}

variable "force_destroy" {
  description = "Allow Terraform to delete non-empty buckets"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Resource tags"
  type        = map(string)
}

variable "lifecycle_transition_to_ia_days" {
  description = "If set, transition objects to STANDARD_IA after this many days"
  type        = number
  default     = null
}

variable "lifecycle_expiration_days" {
  description = "If set, expire objects after this many days"
  type        = number
  default     = null
}
