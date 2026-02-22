<#
.SYNOPSIS
  L2 Analyzer: Parsa il PRD in Markdown e produce un payload deterministico `backlog.json`
.DESCRIPTION
  Secondo l'architettura Enterprise (AGENTIC_ARCHITECTURE_ENTERPRISE_PRD.md), 
  questo script agisce come L2 (Analyzer). Trasforma testo non strutturato
  in una gerarchia rigida di dati, pronta per essere inoltrata al Validator (L3).
  NON esegue chiamate di rete.
#>

Param(
    [Parameter(Mandatory = $true)]
    [string]$PrdPath,
  
    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'out/backlog.json'
)

$ErrorActionPreference = 'Stop'

function Parse-Prd([string]$path) {
    if (-not (Test-Path $path)) { throw "PRD file not found: $path" }
    $lines = Get-Content -Path $path -Encoding UTF8

    $title = [IO.Path]::GetFileNameWithoutExtension($path)
    $prdId = $null
    $epics = New-Object System.Collections.Generic.List[object]
    $currentEpic = $null
    $currentFeature = $null

    foreach ($raw in $lines) {
        $line = $raw.Trim()
        if (-not $line) { continue }

        if ($line -match '^#\s+(.+)$') {
            $title = $Matches[1].Trim()
            continue
        }

        if ($line -match '^PRD-ID:\s*(.+)$') {
            $prdId = $Matches[1].Trim()
            continue
        }

        if ($line -match '^##\s*(Epic|EPIC)\s*:\s*(.+)$') {
            $currentEpic = [ordered]@{
                title       = $Matches[2].Trim()
                description = ""
                features    = New-Object System.Collections.Generic.List[object]
            }
            $epics.Add($currentEpic)
            $currentFeature = $null
            continue
        }

        if ($line -match '^###\s*(Feature|FEATURE)\s*:\s*(.+)$') {
            if ($null -eq $currentEpic) {
                $currentEpic = [ordered]@{
                    title       = "Auto Epic"
                    description = ""
                    features    = New-Object System.Collections.Generic.List[object]
                }
                $epics.Add($currentEpic)
            }
            $currentFeature = [ordered]@{
                title       = $Matches[2].Trim()
                description = ""
                pbis        = New-Object System.Collections.Generic.List[object]
            }
            $currentEpic.features.Add($currentFeature)
            continue
        }

        if ($line -match '^-+\s*(PBI|Story|User Story)\s*:\s*(.+)$') {
            $pbiTitle = $Matches[2].Trim()
            if ($null -eq $currentEpic) {
                $currentEpic = [ordered]@{
                    title       = "Auto Epic"
                    description = ""
                    features    = New-Object System.Collections.Generic.List[object]
                }
                $epics.Add($currentEpic)
            }
            if ($null -eq $currentFeature) {
                $currentFeature = [ordered]@{
                    title       = "Auto Feature"
                    description = ""
                    pbis        = New-Object System.Collections.Generic.List[object]
                }
                $currentEpic.features.Add($currentFeature)
            }
            $currentFeature.pbis.Add([ordered]@{
                    title              = $pbiTitle
                    acceptanceCriteria = "Given PRD requirement, when implemented, then expected behavior is met."
                })
            continue
        }

        if ($null -ne $currentFeature) {
            if (-not $currentFeature.description) { $currentFeature.description = $line }
            continue
        }
        if ($null -ne $currentEpic) {
            if (-not $currentEpic.description) { $currentEpic.description = $line }
            continue
        }
    }

    if ($epics.Count -eq 0) {
        $fallbackEpic = [ordered]@{
            title       = $title
            description = "Generated from PRD fallback parsing."
            features    = @(
                [ordered]@{
                    title       = "Core Delivery"
                    description = "Auto-generated feature."
                    pbis        = @(
                        [ordered]@{
                            title              = "Implement core scope from PRD"
                            acceptanceCriteria = "Given PRD, when scope is implemented, then acceptance criteria are satisfied."
                        }
                    )
                }
            )
        }
        $epics.Add($fallbackEpic)
    }

    return [ordered]@{
        prdTitle = $title
        prdId    = if (-not $prdId -or $prdId -eq '[AUTO]') { [IO.Path]::GetFileNameWithoutExtension($path) } else { $prdId }
        epics    = $epics
    }
}

Write-Host "Analyzing PRD: $PrdPath"
$model = Parse-Prd -path $PrdPath

$outDir = [IO.Path]::GetDirectoryName($OutputPath)
if ($outDir -and -not (Test-Path $outDir)) { New-Item -ItemType Directory -Force -Path $outDir | Out-Null }

$model | ConvertTo-Json -Depth 30 -Compress | Out-File -FilePath $OutputPath -Encoding utf8
Write-Host "L2 Analysis Complete. Backlog saved to $OutputPath"
