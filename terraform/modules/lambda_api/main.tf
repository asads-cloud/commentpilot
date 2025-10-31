#locals {
#  src_dir = "${path.module}/../../backend/src/api/${var.entry}"
#  build_dir = "${path.module}/.build/${var.name}"
#  out_file  = "${local.build_dir}/index.mjs"
#  # Rebuild when any source file changes
#  src_hash = sha256(join(",", [
#    for f in fileset(local.src_dir, "**/*") : filesha256("${local.src_dir}/${f}")
#  ]))
#}

# Build step: bundle TypeScript -> single ESM file for Node.js 20
#resource "null_resource" "esbuild" {
#  triggers = { src_hash = local.src_hash }
#
#  provisioner "local-exec" {
#    interpreter = ["bash", "-lc"]
#    command = <<-CMD
#      set -euo pipefail
#      mkdir -p "${local.build_dir}"
#      # Build with npx esbuild (no global install required)
#      npx --yes esbuild "${local.src_dir}/index.ts" \
#        --bundle --platform=node --target=node20 \
#        --format=esm --outfile="${local.out_file}"
#   CMD
#  }
#}

#locals {
#  # from terraform/modules/lambda_api to CommentPilot/backend/... is ../../../
#  src_dir   = "${path.module}/../../../backend/src/api/${var.entry}"
#  build_dir = "${path.module}/.build/${var.name}"
#  out_file  = "${local.build_dir}/index.mjs"
#
#  src_hash = sha256(join(",", [
#    for f in fileset(local.src_dir, "**/*") : filesha256("${local.src_dir}/${f}")
#  ]))
#}

#resource "null_resource" "esbuild" {
#  triggers = { src_hash = local.src_hash }
#
#  provisioner "local-exec" {
#    working_dir = "${path.module}"
#    interpreter = ["PowerShell", "-NoProfile", "-NonInteractive", "-Command"]
#    command = <<-POWERSHELL
#      $ErrorActionPreference = "Stop"
#
#      $srcDirRel   = "${local.src_dir}"
#      $buildDirRel = "${local.build_dir}"
#      $outFileRel  = "${local.out_file}"
#
#      New-Item -ItemType Directory -Force -Path $buildDirRel | Out-Null
#
#      $srcDir   = (Resolve-Path $srcDirRel).Path
#      $buildDir = (Resolve-Path $buildDirRel).Path
#      $outFile  = Join-Path $buildDir "index.mjs"
#
#      npx --yes esbuild (Join-Path $srcDir "index.ts") `
#        --bundle --platform=node --target=node20 `
#        --format=esm --outfile=$outFile
#    POWERSHELL
#  }
#}
locals {
  # endpoint code dir (e.g. getMessages or postReply)
  src_dir   = "${path.module}/../../../backend/src/api/${var.entry}"
  # shared auth/lib code dir
  common_dir = "${path.module}/../../../backend/src/api/_lib"
  # package.json that controls deps (jsonwebtoken -> jose)
  pkg_json   = "${path.module}/../../../backend/src/api/package.json"

  build_dir = "${path.module}/.build/${var.name}"
  out_file  = "${local.build_dir}/index.mjs"

  # IMPORTANT: include endpoint, shared lib, and package.json in the hash
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
      $outFileRel  = "${local.out_file}"

      New-Item -ItemType Directory -Force -Path $buildDirRel | Out-Null

      $srcDir   = (Resolve-Path $srcDirRel).Path
      $buildDir = (Resolve-Path $buildDirRel).Path
      $outFile  = (Resolve-Path $outFileRel -ErrorAction SilentlyContinue)
      if (-not $outFile) { $outFile = Join-Path $buildDir "index.mjs" }

      # ESM build (works with jose)
      npx --yes esbuild (Join-Path $srcDir "index.ts") `
        --bundle --platform=node --target=node20 `
        --format=esm --outfile=$outFile
    POWERSHELL
  }
}



# Zip the built artifact
data "archive_file" "zip" {
  type        = "zip"
  source_dir  = local.build_dir
  output_path = "${path.module}/../../.artifacts/${var.name}.zip"

  depends_on = [null_resource.esbuild]
}

resource "aws_lambda_function" "fn" {
  function_name    = var.name
  role             = var.role_arn
  runtime          = "nodejs20.x"
  architectures    = [var.architecture]
  handler          = "index.handler"            # uses named export 'handler' from index.mjs
  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256
  timeout          = var.timeout
  memory_size      = var.memory_size

  environment {
    variables = merge({
      NODE_OPTIONS       = "--enable-source-maps"
      COGNITO_ISSUER     = try(var.env["COGNITO_ISSUER"], null)
      COGNITO_AUDIENCE   = try(var.env["COGNITO_APP_CLIENT_ID"], null)
      DDB_TABLE          = try(var.env["DDB_TABLE"], null)
    }, var.env)
  }
}


