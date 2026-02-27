<#
.SYNOPSIS
    Pubblica il branch main su tutti i target abilitati in config/publish-targets.json.
.DESCRIPTION
    Legge config/publish-targets.json e .env.publish (secrets).
    Per ogni target abilitato esegue git push autenticato.
    Aggiungere nuovi target solo in publish-targets.json — zero modifiche allo script.
.PARAMETER Targets
    Filtra i target da eseguire (es. -Targets github). Default: tutti gli abilitati.
.PARAMETER DryRun
    Mostra cosa farebbe senza eseguire push.
.EXAMPLE
    pwsh scripts/pwsh/Publish-ToTargets.ps1
    pwsh scripts/pwsh/Publish-ToTargets.ps1 -Targets github
    pwsh scripts/pwsh/Publish-ToTargets.ps1 -DryRun
#>
param(
    [string[]]$Targets = @(),
    [switch]$DryRun
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (git -C $PSScriptRoot rev-parse --show-toplevel 2>/dev/null) ?? (Resolve-Path "$PSScriptRoot/../..").Path
$configPath = Join-Path $repoRoot "config/publish-targets.json"
$envPath    = Join-Path $repoRoot ".env.publish"

# --- Carica config ---
if (-not (Test-Path $configPath)) {
    Write-Error "config/publish-targets.json non trovato in $repoRoot"
    exit 1
}
$config = Get-Content $configPath | ConvertFrom-Json

# --- Carica secrets da .env.publish ---
$secrets = @{}
if (Test-Path $envPath) {
    Get-Content $envPath | Where-Object { $_ -match '^\s*([^#][^=]+)=(.+)$' } | ForEach-Object {
        $key, $value = $_ -split '=', 2
        $secrets[$key.Trim()] = $value.Trim()
    }
}

# --- Seleziona target ---
$activeTargets = $config.targets | Where-Object {
    $_.enabled -eq $true -and
    ($Targets.Count -eq 0 -or $Targets -contains $_.id)
}

if ($activeTargets.Count -eq 0) {
    Write-Host "[publish] Nessun target attivo." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n[publish] Publish-ToTargets v1.0.0" -ForegroundColor Cyan
Write-Host "[publish] Target attivi: $($activeTargets.id -join ', ')`n"

$results = @()

foreach ($target in $activeTargets) {
    Write-Host "[publish] >> $($target.id) ($($target.name))" -ForegroundColor White

    # Costruisci remote URL con auth se necessario
    $remoteUrl = $target.remote
    if ($target.auth.type -eq 'pat') {
        $pat = $secrets[$target.auth.env_var]
        if (-not $pat) {
            Write-Host "[publish]    SKIP — $($target.auth.env_var) non trovato in .env.publish" -ForegroundColor Yellow
            $results += [PSCustomObject]@{ id = $target.id; status = 'SKIPPED'; reason = 'missing PAT' }
            continue
        }
        # Inietta PAT nell'URL HTTPS: https://<PAT>@github.com/...
        $remoteUrl = $remoteUrl -replace 'https://', "https://$pat@"
    }

    $branch = $target.branch ?? 'main'
    $pushCmd = "git push `"$remoteUrl`" ${branch}:${branch} --force-with-lease"

    if ($DryRun) {
        Write-Host "[publish]    DRY-RUN: git push $($target.remote) $branch" -ForegroundColor DarkGray
        $results += [PSCustomObject]@{ id = $target.id; status = 'DRY-RUN' }
        continue
    }

    try {
        $output = Invoke-Expression $pushCmd 2>&1
        Write-Host "[publish]    OK — $output" -ForegroundColor Green
        $results += [PSCustomObject]@{ id = $target.id; status = 'OK' }
    } catch {
        Write-Host "[publish]    FAILED — $_" -ForegroundColor Red
        $results += [PSCustomObject]@{ id = $target.id; status = 'FAILED'; reason = "$_" }
    }
}

# --- Summary ---
Write-Host "`n[publish] Summary:"
$results | Format-Table -AutoSize

$failed = $results | Where-Object { $_.status -eq 'FAILED' }
if ($failed.Count -gt 0) { exit 1 }
exit 0
