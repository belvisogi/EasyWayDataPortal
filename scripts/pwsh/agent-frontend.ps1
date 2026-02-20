param(
  [Parameter(Mandatory = $true)]
  [ValidateSet('build', 'deploy')]
  [string]$Action
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$frontendPath = Join-Path $repoRoot 'apps/portal-frontend'

if (-not (Test-Path $frontendPath)) {
  throw "Frontend path not found: $frontendPath"
}

Push-Location $frontendPath
try {
  switch ($Action) {
    'build' {
      Write-Host 'Running frontend build (lint + build)...' -ForegroundColor Cyan
      npm run lint
      if ($LASTEXITCODE -ne 0) { throw 'npm run lint failed' }
      npm run build
      if ($LASTEXITCODE -ne 0) { throw 'npm run build failed' }
      Write-Host 'Frontend build completed.' -ForegroundColor Green
    }
    'deploy' {
      $distPath = Join-Path $frontendPath 'dist'
      if (-not (Test-Path $distPath)) {
        throw "Missing build output at '$distPath'. Run Action=build before deploy."
      }
      Write-Host 'Deploy action placeholder: build artifact exists and is ready for CI/CD deploy.' -ForegroundColor Yellow
    }
  }
}
finally {
  Pop-Location
}
