param(
    [string]$AgentsDir = 'agents',
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Write-Host "🧠 Enabling Memory Cortex for Agents in $AgentsDir..." -ForegroundColor Cyan

$agentDirs = Get-ChildItem $AgentsDir -Directory | Where-Object { $_.Name -notin @('kb','logs','core') }

foreach ($dir in $agentDirs) {
    $memDir = Join-Path $dir.FullName "memory"
    $ctxFile = Join-Path $memDir "context.json"

    # 1. Create Memory Directory
    if (-not (Test-Path $memDir)) {
        New-Item -ItemType Directory -Path $memDir -Force | Out-Null
        Write-Host "  [$($dir.Name)] + Created memory/" -ForegroundColor Green
    }

    # 2. Create Context File
    if (-not (Test-Path $ctxFile) -or $Force) {
        $defaultCtx = @{
            created = (Get-Date).ToString("o")
            first_run = $true
            preferences = @{}
            stats = @{
                runs = 0
                errors = 0
                last_active = $null
            }
        }
        
        # Specific fields for known Brains
        if ($dir.Name -in @('agent_governance', 'agent_scrummaster', 'agent_cartographer', 'agent_chronicler')) {
            $defaultCtx.Add("brain_context", @{
                focus_state = "idle"
                long_term_goals = @()
            })
        }

        $defaultCtx | ConvertTo-Json -Depth 5 | Set-Content -Path $ctxFile -Encoding UTF8
        Write-Host "  [$($dir.Name)] + Created context.json" -ForegroundColor Green
    } else {
        Write-Host "  [$($dir.Name)] . Memory already exists." -ForegroundColor Gray
    }
}
Write-Host "Done." -ForegroundColor Cyan
