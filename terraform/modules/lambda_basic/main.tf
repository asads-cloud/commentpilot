locals {
  src_dir    = "${path.module}/../../../backend/src/${var.entry_dir}"
  common_dir = "${path.module}/../../../backend/src/etl/_lib"
  pkg_json   = "${path.module}/../../../backend/src/etl/package.json"

  build_dir  = "${path.module}/.build/${var.name}"
  # ✅ CJS output
  out_file   = "${local.build_dir}/index.cjs"

  src_hash = sha256(join(",", concat(
    [filesha256(local.pkg_json)],
    [for f in fileset(local.src_dir,   "**/*") : filesha256("${local.src_dir}/${f}")],
    [for f in fileset(local.common_dir,"**/*") : filesha256("${local.common_dir}/${f}")]
  )))
}

resource "null_resource" "esbuild" {
  triggers = { src_hash = local.src_hash }

  provisioner "local-exec" {
    working_dir = "${path.module}"
    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-Command"]
    command = <<-POWERSHELL
      $ErrorActionPreference = "Stop"

      $srcDirRel   = "${local.src_dir}"
      $buildDirRel = "${local.build_dir}"

      New-Item -ItemType Directory -Force -Path $buildDirRel | Out-Null

      $srcDir   = (Resolve-Path $srcDirRel).Path
      $buildDir = (Resolve-Path $buildDirRel).Path
      # ✅ force .cjs
      $outFile  = Join-Path $buildDir "index.cjs"

      npx --yes esbuild (Join-Path $srcDir "index.ts") `
        --bundle --platform=node --target=node20 `
        --format=cjs --outfile=$outFile
    POWERSHELL
  }
}

data "archive_file" "zip" {
  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${path.module}/../../.artifacts/${var.name}.zip"
  depends_on  = [null_resource.esbuild]
}

resource "aws_lambda_function" "fn" {
  function_name    = var.name
  role             = var.role_arn
  runtime          = "nodejs20.x"
  architectures    = ["arm64"]
  handler          = "index.handler"   # Node will load index.cjs and call exports.handler
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size
  environment { variables = var.env }
}
