# Upload the script to S3
resource "aws_s3_object" "script" {
  bucket = var.script_s3_bucket
  key    = var.script_s3_key
  source = var.script_src
  etag   = filemd5(var.script_src)
  content_type = "text/x-python"
}

resource "aws_glue_job" "job" {
  name                = var.name
  role_arn            = var.role_arn
  glue_version        = "4.0"
  number_of_workers   = 2
  worker_type         = "G.1X"
  timeout             = 10  # minutes

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.script_s3_bucket}/${var.script_s3_key}"
  }

  default_arguments = merge({
    "--job-language"                      = "python"
    "--enable-continuous-cloudwatch-log"  = "true"
    "--enable-metrics"                    = "true"
    "--TempDir"                           = "s3://${var.script_s3_bucket}/tmp/glue/"
  }, var.default_args)

  depends_on = [aws_s3_object.script]
}