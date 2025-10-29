param(
  [string] = "default",
  [string] = "eu-west-1"
)

Write-Host "=== CommentPilot Env Check ==="
 = 0

function Check-Cmd([string]) {
  if (-not (Get-Command  -ErrorAction SilentlyContinue)) {
    Write-Host "Missing: " -ForegroundColor Red
    ++
  } else {
    &  --version | Select-Object -First 1
  }
}

Check-Cmd git
Check-Cmd python
Check-Cmd node
Check-Cmd npm
Check-Cmd terraform
Check-Cmd aws
Check-Cmd code

Write-Host "
AWS Identity ( @ )"
try {
   = aws sts get-caller-identity --profile  | ConvertFrom-Json
  Write-Host "Account:   UserId: "
} catch {
  Write-Host "AWS auth failed for profile ''." -ForegroundColor Red
  ++
}

Write-Host "
Terraform backend quick check"
try {
  Push-Location terraform
  terraform init -reconfigure | Out-Null
  terraform validate
  Pop-Location
} catch {
  Write-Host "Terraform validate failed." -ForegroundColor Red
  ++
}

if ( -gt 0) {
  Write-Host "
Env check completed with  issue(s)." -ForegroundColor Yellow
  exit 1
} else {
  Write-Host "
Env check OK." -ForegroundColor Green
}