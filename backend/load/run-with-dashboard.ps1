# Run BuddBull k6 load test with live charts + HTML report (PowerShell)
#
# Usage:
#   .\run-with-dashboard.ps1
#   .\run-with-dashboard.ps1 -BaseUrl http://178.105.65.91:8000 -Vus 20 -Ramp 1m -Peak 2m
#
# During the run: open http://localhost:5665
# After the run: open the HTML file under .\reports\

param(
  [string]$BaseUrl = "http://178.105.65.91:8000",
  [string]$Vus = "20",
  [string]$Ramp = "1m",
  [string]$Peak = "2m",
  [string]$TokenFile = "./tokens.json",
  [string]$Script = "./k6-core-flow.js"
)

$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if (-not (Test-Path $TokenFile)) {
  Write-Error "Missing $TokenFile - copy tokens.example.json to tokens.json and add Firebase ID tokens."
}

New-Item -ItemType Directory -Force -Path ".\reports" | Out-Null
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$report = Join-Path "reports" "k6-report-$stamp.html"
$summary = Join-Path "reports" "k6-summary-$stamp.json"

$env:K6_WEB_DASHBOARD = "true"
$env:K6_WEB_DASHBOARD_OPEN = "true"
$env:K6_WEB_DASHBOARD_EXPORT = $report

Write-Host "Dashboard: http://localhost:5665 (opens automatically)"
Write-Host "HTML report will be saved to: $report"
Write-Host "JSON summary will be saved to: $summary"
Write-Host ""

k6 run `
  -e "BASE_URL=$BaseUrl" `
  -e "VUS=$Vus" `
  -e "RAMP=$Ramp" `
  -e "PEAK=$Peak" `
  -e "TOKEN_FILE=$TokenFile" `
  --summary-export="$summary" `
  $Script

Write-Host ""
Write-Host "Done. Open charts report:"
if (Test-Path $report) {
  $fullReport = (Resolve-Path $report).Path
  Write-Host "  $fullReport"
} else {
  Write-Host "  Report file was not created. Check k6 output above."
}
