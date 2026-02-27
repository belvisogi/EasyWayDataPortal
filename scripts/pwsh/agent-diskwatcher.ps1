<#
  agent-diskwatcher.ps1 — The Sentinel

  Monitora l'utilizzo del disco sul server OCI e Docker.
  Principio antifragile: warn-only per default, nessuna azione distruttiva automatica.
  Cleanup richiede flag esplicito + conferma interattiva.

  Uso:
    pwsh scripts/pwsh/agent-diskwatcher.ps1
    pwsh scripts/pwsh/agent-diskwatcher.ps1 -Json
    pwsh scripts/pwsh/agent-diskwatcher.ps1 -WarnAt 75 -CritAt 85
    pwsh scripts/pwsh/agent-diskwatcher.ps1 -Cleanup   # solo su server, con conferma

  Cron (server OCI, ogni 6h):
    0 */6 * * * pwsh /home/ubuntu/EasyWayDataPortal/scripts/pwsh/agent-diskwatcher.ps1 >> /tmp/diskwatcher.log 2>&1

  Manifest: agents/agent_diskwatcher/manifest.json
#>

Param(
    [int]    $WarnAt  = 80,
    [int]    $CritAt  = 90,
    [switch] $Json,
    [switch] $Cleanup
)

$ErrorActionPreference = 'Continue'

$reportPath = Join-Path $PSScriptRoot '../../agents/agent_diskwatcher/memory/last-report.json'
$reportPath = [System.IO.Path]::GetFullPath($reportPath)

# ── Helper: parse df output ───────────────────────────────────────────────────
function Get-DiskUsage {
    $lines = df -h --output=target,pcent,used,avail,size 2>/dev/null | Select-Object -Skip 1
    $result = @()
    foreach ($line in $lines) {
        $parts = $line.Trim() -split '\s+'
        if ($parts.Count -lt 5) { continue }
        $pct = [int]($parts[1] -replace '%', '')
        $result += [ordered]@{
            mount  = $parts[0]
            pctUsed = $pct
            used   = $parts[2]
            avail  = $parts[3]
            size   = $parts[4]
        }
    }
    return $result
}

# ── Helper: Docker disk usage ─────────────────────────────────────────────────
function Get-DockerUsage {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        return $null
    }
    $lines = docker system df 2>/dev/null
    if (-not $lines) { return $null }

    $result = [ordered]@{ raw = ($lines -join "`n"); items = @() }
    foreach ($line in $lines | Select-Object -Skip 1) {
        $parts = $line -split '\s{2,}'
        if ($parts.Count -ge 4) {
            $result.items += [ordered]@{
                type      = $parts[0]
                total     = $parts[1]
                active    = $parts[2]
                reclaimable = $parts[3]
            }
        }
    }
    return $result
}

# ── Helper: top directories by size under a path ─────────────────────────────
function Get-TopDirs {
    param([string]$Path, [int]$Top = 5)
    if (-not (Test-Path $Path)) { return @() }
    $lines = du -sh "$Path"/* 2>/dev/null | Sort-Object | Select-Object -Last $Top
    $result = @()
    foreach ($line in $lines) {
        $parts = $line -split '\t'
        if ($parts.Count -ge 2) {
            $result += [ordered]@{ size = $parts[0]; path = $parts[1] }
        }
    }
    return $result
}

# ── Collect data ──────────────────────────────────────────────────────────────
$timestamp  = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
$disks      = Get-DiskUsage
$docker     = Get-DockerUsage
$projectTop = Get-TopDirs -Path "$HOME/EasyWayDataPortal" -Top 5
$dockerTop  = Get-TopDirs -Path '/var/lib/docker' -Top 3

# ── Evaluate alerts ───────────────────────────────────────────────────────────
$alerts = @()
$rootDisk = $disks | Where-Object { $_.mount -eq '/' } | Select-Object -First 1

foreach ($disk in $disks | Where-Object { $_.mount -in ('/', '/home', '/var') }) {
    if ($disk.pctUsed -ge $CritAt) {
        $alerts += [ordered]@{
            level   = 'CRITICAL'
            message = "Disco $($disk.mount): $($disk.pctUsed)% usato ($($disk.used) / $($disk.size))"
            mount   = $disk.mount
            pct     = $disk.pctUsed
        }
    } elseif ($disk.pctUsed -ge $WarnAt) {
        $alerts += [ordered]@{
            level   = 'WARNING'
            message = "Disco $($disk.mount): $($disk.pctUsed)% usato ($($disk.used) / $($disk.size))"
            mount   = $disk.mount
            pct     = $disk.pctUsed
        }
    }
}

$overallStatus = if ($alerts | Where-Object { $_.level -eq 'CRITICAL' }) { 'CRITICAL' }
                 elseif ($alerts | Where-Object { $_.level -eq 'WARNING' }) { 'WARNING' }
                 else { 'OK' }

# ── Build report ──────────────────────────────────────────────────────────────
$report = [ordered]@{
    generatedAt    = $timestamp
    status         = $overallStatus
    thresholds     = [ordered]@{ warn = $WarnAt; crit = $CritAt }
    alerts         = $alerts
    disks          = $disks
    docker         = $docker
    projectTopDirs = $projectTop
    dockerTopDirs  = $dockerTop
}

# Salva last-report.json
$reportDir = Split-Path $reportPath
if (-not (Test-Path $reportDir)) { New-Item -ItemType Directory -Force -Path $reportDir | Out-Null }
$report | ConvertTo-Json -Depth 5 | Set-Content $reportPath -Encoding UTF8

# ── JSON output ───────────────────────────────────────────────────────────────
if ($Json) {
    $report | ConvertTo-Json -Depth 5
    exit 0
}

# ── Human-readable output ─────────────────────────────────────────────────────
$SEP = '=' * 60
$statusColor = switch ($overallStatus) {
    'CRITICAL' { 'Red' }
    'WARNING'  { 'Yellow' }
    default    { 'Green' }
}

Write-Host ""
Write-Host $SEP
Write-Host "  DISK WATCHER  --  $timestamp" -ForegroundColor Cyan
Write-Host "  Status: $overallStatus" -ForegroundColor $statusColor
Write-Host $SEP

# Alerts
if ($alerts.Count -gt 0) {
    Write-Host ""
    Write-Host "ALERTS" -ForegroundColor $statusColor
    foreach ($a in $alerts) {
        $c = if ($a.level -eq 'CRITICAL') { 'Red' } else { 'Yellow' }
        Write-Host "  [$($a.level)] $($a.message)" -ForegroundColor $c
    }
}

# Disk usage
Write-Host ""
Write-Host "DISK USAGE" -ForegroundColor Cyan
foreach ($d in $disks | Where-Object { $_.mount -notmatch 'loop|tmpfs|udev' }) {
    $c = if ($d.pctUsed -ge $CritAt) { 'Red' }
         elseif ($d.pctUsed -ge $WarnAt) { 'Yellow' }
         else { 'White' }
    $bar = '#' * [math]::Floor($d.pctUsed / 5)
    $empty = '.' * (20 - $bar.Length)
    Write-Host ("  {0,-20} [{1}{2}] {3,3}%  {4,6} / {5}" -f `
        $d.mount, $bar, $empty, $d.pctUsed, $d.used, $d.size) -ForegroundColor $c
}

# Docker
if ($docker -and $docker.items.Count -gt 0) {
    Write-Host ""
    Write-Host "DOCKER DISK" -ForegroundColor Cyan
    foreach ($item in $docker.items) {
        Write-Host ("  {0,-20} total:{1,-8} reclaimable:{2}" -f `
            $item.type, $item.total, $item.reclaimable)
    }
}

# Top dirs
if ($projectTop.Count -gt 0) {
    Write-Host ""
    Write-Host "TOP DIRS ~/EasyWayDataPortal" -ForegroundColor Cyan
    foreach ($d in $projectTop) {
        Write-Host ("  {0,-8} {1}" -f $d.size, $d.path)
    }
}

Write-Host ""
Write-Host $SEP

# Azioni suggerite (solo suggerimenti, mai automatiche)
if ($overallStatus -ne 'OK') {
    Write-Host ""
    Write-Host "AZIONI SUGGERITE (eseguire manualmente dopo verifica):" -ForegroundColor Yellow
    Write-Host "  docker system prune -f          # rimuove container/immagini dangling"
    Write-Host "  docker system prune -af         # rimuove TUTTO il non-usato (attenzione)"
    Write-Host "  docker volume prune -f           # rimuove volumi non attaccati"
    Write-Host "  journalctl --vacuum-size=100M   # riduce log di sistema"
    Write-Host ""
    Write-Host "  Rieseguire con -Json per output machine-readable." -ForegroundColor DarkGray
}
Write-Host ""

# ── Cleanup (richiede flag esplicito) ─────────────────────────────────────────
if ($Cleanup) {
    Write-Host "CLEANUP MODE" -ForegroundColor Red
    Write-Host "Questo rimuovera' container fermati, immagini dangling, build cache." -ForegroundColor Yellow
    Write-Host "Volumi NON vengono toccati." -ForegroundColor Yellow
    Write-Host ""
    $confirm = Read-Host "Confermi? (digita 'yes' per procedere)"
    if ($confirm -eq 'yes') {
        Write-Host "Eseguendo docker system prune -f ..." -ForegroundColor Yellow
        docker system prune -f
        Write-Host "Cleanup completato." -ForegroundColor Green
        # Riesegui check post-cleanup
        Write-Host ""
        Write-Host "Stato post-cleanup:" -ForegroundColor Cyan
        Get-DiskUsage | Where-Object { $_.mount -eq '/' } | ForEach-Object {
            Write-Host "  /: $($_.pctUsed)% ($($_.used) / $($_.size))"
        }
    } else {
        Write-Host "Cleanup annullato." -ForegroundColor Green
    }
}

# Exit code utile per cron/pipeline
exit $(if ($overallStatus -eq 'CRITICAL') { 2 } elseif ($overallStatus -eq 'WARNING') { 1 } else { 0 })
