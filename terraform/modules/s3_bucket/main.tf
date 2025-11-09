resource "aws_s3_bucket" "this" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}


# Ownership controls always recommended before ACLs
resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Default encryption (SSE-S3)
resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Versioning
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id
  versioning_configuration {
    status = var.versioning_enabled ? "Enabled" : "Suspended"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  # Rule 1: abort incomplete multipart uploads
  rule {
    id     = "abort-incomplete-mpu-7d"
    status = "Enabled"

    filter { prefix = "" }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # Rule 2: transition to STANDARD_IA (for raw)
  dynamic "rule" {
    for_each = var.lifecycle_transition_to_ia_days != null ? [1] : []
    content {
      id     = "transition-to-ia"
      status = "Enabled"

      filter { prefix = "" }

      transition {
        days          = var.lifecycle_transition_to_ia_days
        storage_class = "STANDARD_IA"
      }
    }
  }

  # Rule 3: expire objects (for processed)
  dynamic "rule" {
    for_each = var.lifecycle_expiration_days != null ? [1] : []
    content {
      id     = "expire-objects"
      status = "Enabled"

      filter { prefix = "" }

      expiration {
        days = var.lifecycle_expiration_days
      }
    }
  }
}



