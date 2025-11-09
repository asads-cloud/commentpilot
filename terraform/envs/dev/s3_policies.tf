# ---------- RAW BUCKET POLICY ----------

data "aws_iam_policy_document" "raw_bucket" {
  # Deny any unencrypted uploads (must use SSE-S3/AES256)
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.raw_bucket_name}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  # Allow writes ONLY to instagram/* and tiktok/* from *this* AWS account
  statement {
    sid    = "AllowWritesToApprovedPrefixes"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      "arn:aws:s3:::${local.raw_bucket_name}/instagram/*",
      "arn:aws:s3:::${local.raw_bucket_name}/tiktok/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [local.acct_id] # from your existing locals
    }
  }
}

resource "aws_s3_bucket_policy" "raw_bucket" {
  bucket = local.raw_bucket_name
  policy = data.aws_iam_policy_document.raw_bucket.json
}

# ---------- PROCESSED BUCKET POLICY ----------

data "aws_iam_policy_document" "processed_bucket" {
  # Deny any unencrypted uploads
  statement {
    sid    = "DenyUnencryptedObjectUploads"
    effect = "Deny"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${local.processed_bucket_name}/*"]

    condition {
      test     = "StringNotEquals"
      variable = "s3:x-amz-server-side-encryption"
      values   = ["AES256"]
    }
  }

  # Allow writes ONLY to normalized/* from this AWS account
  statement {
    sid    = "AllowNormalizedOnly"
    effect = "Allow"

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    actions = [
      "s3:PutObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]

    resources = [
      "arn:aws:s3:::${local.processed_bucket_name}/normalized/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalAccount"
      values   = [local.acct_id]
    }
  }
}

resource "aws_s3_bucket_policy" "processed_bucket" {
  bucket = local.processed_bucket_name
  policy = data.aws_iam_policy_document.processed_bucket.json
}
