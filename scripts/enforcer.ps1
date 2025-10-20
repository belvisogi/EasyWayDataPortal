Param(
  [Parameter(Mandatory=$false)][string]$Agent,
  [Parameter(Mandatory=$false)][string]$ManifestPath,
  [Parameter(Mandatory=$false)][string[]]$CheckPaths,
  [switch]$GitDiff,
  [switch]$Quiet
)

$ErrorActionPreference = 'Stop'

function Load-Manifest {
  param([string]$agent,[string]$manifestPath)
  if ($manifestPath) { return Get-Content $manifestPath -Raw | ConvertFrom-Json }
  if (-not $agent) { throw 'Specify -Agent or -ManifestPath' }
  $p = Join-Path (Join-Path 'agents' $agent) 'manifest.json'
  if (-not (Test-Path $p)) { throw "Manifest not found: $p" }
  return Get-Content $p -Raw | ConvertFrom-Json
}

function PatternToRegex {
  param([string]$pattern)
  $pat = ($pattern -replace '\\','/')
  $pat = [Regex]::Escape($pat)
  # restore wildcards: ** => .*, * => [^/]*
  $pat = $pat -replace '\*\*', '.*'
  $pat = $pat -replace '(?<!\.)\*', '[^/]*'
  return "^$pat$"
}

function IsAllowed {
  param([string]$path,[string[]]$allowed)
  $n = ($path -replace '\\','/')
  foreach ($p in $allowed) {
    $rx = PatternToRegex $p
    if ($n -match $rx) { return $true }
  }
  return $false
}

function Get-GitChangedPaths {
  try {
    $null = git rev-parse --is-inside-work-tree 2>$null
    if ($LASTEXITCODE -ne 0) { return @() }
    $base = (git rev-parse HEAD~1 2>$null)
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($base)) {
      # Fallback: modified + untracked
      $files = git ls-files -m -o --exclude-standard
      return $files
    }
    return (git diff --name-only $base HEAD)
  } catch { return @() }
}

try {
  $manifest = Load-Manifest -agent $Agent -manifestPath $ManifestPath
  $allowed = @($manifest.allowed_paths)
  if (-not $allowed -or $allowed.Count -eq 0) { throw 'Manifest has no allowed_paths' }

  $paths = @()
  if ($GitDiff) { $paths = Get-GitChangedPaths }
  if ($CheckPaths) { $paths += $CheckPaths }
  $paths = $paths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

  if (-not $paths -or $paths.Count -eq 0) { if (-not $Quiet) { Write-Host 'No paths to check.' }; exit 0 }

  $violations = @()
  foreach ($p in $paths) { if (-not (IsAllowed -path $p -allowed $allowed)) { $violations += $p } }

  if ($violations.Count -gt 0) {
    Write-Error ("Enforcer: disallowed paths detected for agent '{0}':`n - {1}" -f ($Agent ?? $ManifestPath), ($violations -join "`n - "))
    exit 2
  } else {
    if (-not $Quiet) { Write-Host 'Enforcer: all paths allowed.' -ForegroundColor Green }
    exit 0
  }
} catch {
  Write-Error $_
  exit 1
}

