output "lambda_arn" { value = aws_lambda_function.fn.arn }

output "zip_path"   { value = data.archive_file.zip.output_path }

output "invoke_arn" { value = aws_lambda_function.fn.invoke_arn }