#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Apre un tunnel SSH verso Qdrant (porta 6333) per RAG locale nel SDLC Orchestrator.
.DESCRIPTION
    Qdrant (porta 6333) e' bloccato esternamente dal DOCKER-USER chain.
    Questo tunnel mappa localhost:6333 -> server:6333 in modo sicuro via SSH.

    Una volta attivo, il SDLC Orchestrator v3 puo' eseguire RAG pre-Brief:
      QDRANT_URL=http://localhost:6333 in C:\old\.env.local

    Modalita':
      - Default (-Background): avvia il tunnel in background (ssh -f -N) e ritorna subito
      - Con -Wait: blocca la finestra finche' Ctrl+C (come gli altri tunnel scripts)
.EXAMPLE
    # Background (default) — tunnel parte e script esce
    pwsh scripts/connect-qdrant-tunnel.ps1

    # Verifica connettivita' Qdrant dopo tunnel
    pwsh scripts/connect-qdrant-tunnel.ps1 -Verify

    # Foreground — lascia la finestra aperta
    pwsh scripts/connect-qdrant-tunnel.ps1 -Wait
#>

param(
    [string] $TargetIP  = '80.225.86.168',
    [string] $KeyPath   = 'C:\old\Virtual-machine\ssh-key-2026-01-25.key',
    [int]    $LocalPort = 6333,
    [switch] $Wait,     # blocca la finestra (come altri tunnel scripts)
    [switch] $Verify    # testa Qdrant dopo l'avvio
)

$ErrorActionPreference = 'Stop'
$SSH = 'C:\Windows\System32\OpenSSH\ssh.exe'

# ─── check porta gia' in uso ──────────────────────────────────────────────────

function Test-PortListening([int]$port) {
    try {
        $conn = New-Object System.Net.Sockets.TcpClient
        $conn.Connect('127.0.0.1', $port)
        $conn.Close()
        return $true
    } catch { return $false }
}

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║   EasyWay — Qdrant SSH Tunnel (port $LocalPort)  ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

if (Test-PortListening $LocalPort) {
    Write-Host "  ✓ Porta $LocalPort gia' in ascolto — tunnel probabilmente gia' attivo." -ForegroundColor Green
    if (-not $Verify) {
        Write-Host "  (Usa -Verify per testare Qdrant, o -Wait per aprire una nuova sessione)" -ForegroundColor Gray
        Write-Host ""
        exit 0
    }
} else {
    # verifica prerequisiti
    if (-not (Test-Path $SSH)) {
        Write-Error "OpenSSH non trovato: $SSH"
    }
    if (-not (Test-Path $KeyPath)) {
        Write-Error "SSH key non trovata: $KeyPath"
    }

    Write-Host "  Server : ubuntu@$TargetIP" -ForegroundColor Gray
    Write-Host "  Tunnel : localhost:$LocalPort -> server:$LocalPort (Qdrant)" -ForegroundColor Gray
    Write-Host ""

    if ($Wait) {
        # Foreground — blocca la finestra (come connect-n8n-tunnel.ps1)
        Write-Host "  Avvio tunnel in foreground (Ctrl+C per chiudere)..." -ForegroundColor Yellow
        Write-Host ""
        & $SSH -i $KeyPath -o StrictHostKeyChecking=no `
            -L "${LocalPort}:127.0.0.1:${LocalPort}" `
            "ubuntu@$TargetIP" -N
        Write-Host ""
        Write-Host "  Tunnel chiuso." -ForegroundColor Red
        Read-Host "  Premi Invio per uscire"
        exit 0
    } else {
        # Background — ssh -f -N (default)
        Write-Host "  Avvio tunnel in background..." -ForegroundColor White
        & $SSH -i $KeyPath -o StrictHostKeyChecking=no `
            -L "${LocalPort}:127.0.0.1:${LocalPort}" `
            "ubuntu@$TargetIP" -f -N
        Write-Host "  ✓ Tunnel avviato (background). Porta locale: $LocalPort" -ForegroundColor Green
    }
}

# ─── verifica connettivita' Qdrant ───────────────────────────────────────────

if ($Verify -or (-not $Wait)) {
    Write-Host ""
    Write-Host "  Verifica Qdrant su localhost:$LocalPort..." -ForegroundColor White

    # leggi API key da .env.local
    $qdrantKey = ''
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $line = Get-Content $envFile | Where-Object { $_ -match '^QDRANT_API_KEY=' } | Select-Object -First 1
        if ($line) { $qdrantKey = ($line -split '=', 2)[1].Trim().Trim('"') }
    }

    $maxWait = 5
    $ok = $false
    for ($i = 1; $i -le $maxWait; $i++) {
        Start-Sleep -Milliseconds 600
        if (Test-PortListening $LocalPort) { $ok = $true; break }
        Write-Host "  ... attendo porta $LocalPort ($i/$maxWait)" -ForegroundColor DarkGray
    }

    if (-not $ok) {
        Write-Host "  ✗ Porta $LocalPort non raggiungibile dopo ${maxWait}s." -ForegroundColor Red
        Write-Host "  Controlla: ssh non ha aperto il tunnel (errori di auth/key?)." -ForegroundColor Gray
        exit 1
    }

    try {
        $hdrs = @{ 'Content-Type' = 'application/json' }
        if ($qdrantKey) { $hdrs['api-key'] = $qdrantKey }
        $resp = Invoke-RestMethod -Uri "http://localhost:$LocalPort/collections/easyway_wiki" `
            -Headers $hdrs -TimeoutSec 8
        $count = $resp.result.points_count
        Write-Host "  ✓ Qdrant OK — collection easyway_wiki: $count vettori" -ForegroundColor Green
    } catch {
        Write-Host "  ✓ Porta aperta, ma Qdrant REST ha risposto con errore: $_" -ForegroundColor Yellow
        Write-Host "  (Verifica QDRANT_API_KEY in C:\old\.env.local)" -ForegroundColor Gray
    }
}

# ─── istruzioni .env.local ───────────────────────────────────────────────────

Write-Host ""

$envFile = 'C:\old\.env.local'
$qdrantUrlSet = $false
if (Test-Path $envFile) {
    $qdrantUrlSet = (Get-Content $envFile | Where-Object { $_ -match '^QDRANT_URL=' }).Count -gt 0
}

if ($qdrantUrlSet) {
    Write-Host "  ✓ QDRANT_URL gia' configurato in .env.local" -ForegroundColor Green
} else {
    Write-Host "  ┌─ .env.local — aggiungi questa riga per attivare il RAG nel SDLC Orchestrator:" -ForegroundColor Yellow
    Write-Host "  │  QDRANT_URL=http://localhost:$LocalPort" -ForegroundColor White
    Write-Host "  └─────────────────────────────────────────" -ForegroundColor Yellow

    $ans = Read-Host "  Aggiungere QDRANT_URL=http://localhost:$LocalPort a .env.local? [S/n]"
    if ($ans -notmatch '^[nN]') {
        Add-Content -Path $envFile -Value "`nQDRANT_URL=http://localhost:$LocalPort"
        Write-Host "  ✓ Aggiunto a $envFile" -ForegroundColor Green
    }
}

Write-Host ""
Write-Host "  Pronto. Avvia l'orchestratore:" -ForegroundColor Cyan
Write-Host "  pwsh agents/skills/planning/Invoke-SDLCOrchestrator.ps1" -ForegroundColor White
Write-Host ""
