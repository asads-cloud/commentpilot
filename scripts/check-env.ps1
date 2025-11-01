param(
  [string]$AwsProfile = "default",
  [string]$AwsRegion  = "eu-west-1"
)

Write-Host "=== CommentPilot Env Check ==="
$errors = 0

function Check-Cmd($cmd) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    Write-Host "Missing: $cmd" -ForegroundColor Red
    $script:errors++
  } else {
    & $cmd --version | Select-Object -First 1
  }
}

Check-Cmd git
Check-Cmd python
Check-Cmd node
Check-Cmd npm
Check-Cmd terraform
Check-Cmd aws
Check-Cmd code

Write-Host "`nAWS Identity ($AwsProfile @ $AwsRegion)"
try {
  $id = aws sts get-caller-identity --profile $AwsProfile | ConvertFrom-Json
  Write-Host "Account: $($id.Account)  UserId: $($id.UserId)"
} catch {
  Write-Host "AWS auth failed for profile '$AwsProfile'." -ForegroundColor Red
  $errors++
}

Write-Host "`nTerraform backend quick check"
try {
  Push-Location terraform
  terraform init -reconfigure | Out-Null
  terraform validate
  Pop-Location
} catch {
  Write-Host "Terraform validate failed." -ForegroundColor Red
  $errors++
}

if ($errors -gt 0) {
  Write-Host "`nEnv check completed with $errors issue(s)." -ForegroundColor Yellow
  exit 1
} else {
  Write-Host "`nEnv check OK." -ForegroundColor Green
}
