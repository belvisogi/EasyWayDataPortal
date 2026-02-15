# generate-agent-roster.ps1
# Generates a "Visual Card" style roster for all agents in the Wiki.

$ErrorActionPreference = 'Stop'

$agentsDir = Join-Path $PSScriptRoot '../../agents'
$wikiDir = Join-Path $PSScriptRoot '../../Wiki/EasyWayData.wiki/agents'
if (-not (Test-Path $wikiDir)) { New-Item -ItemType Directory -Force -Path $wikiDir | Out-Null }

$outFile = Join-Path $wikiDir 'agent-roster.md'

$md = @()
$md += "# 🤖 Agent Marketplace & Roster"
$md += ""
$md += "Discover the comprehensive collection of EasyWay agents. Classified by **Strategic Role (Brains)** and **Executive Function (Arms)**."
$md += ""
$md += "---"
$md += ""

$brains = @()
$arms = @()

$agents = Get-ChildItem $agentsDir -Directory | Sort-Object Name
foreach ($agent in $agents) {
    $manifestPath = Join-Path $agent.FullName 'manifest.json'
    if (Test-Path $manifestPath) {
        try {
            $m = Get-Content $manifestPath -Raw | ConvertFrom-Json
            
            # Parse LLM Config
            $model = "Default"
            if ($m.llm_config -and $m.llm_config.model) { $model = $m.llm_config.model }
            
            # Parse Context
            $contextCount = 0
            if ($m.context_config -and $m.context_config.memory_files) { $contextCount = $m.context_config.memory_files.Count }

            # Parse Tools
            $llmTools = @()
            if ($m.llm_config -and $m.llm_config.tools) { $llmTools = $m.llm_config.tools }
            
            $osTools = @()
            if ($m.allowed_tools) { $osTools = $m.allowed_tools }

            $info = [ordered]@{
                Id = $agent.Name
                Name = ($m.name ?? $agent.Name)
                Role = ($m.role ?? "Specialist")
                Class = ($m.classification ?? "arm").ToLower()
                Desc = ($m.description ?? "No description provided.")
                ActionsList = ($m.actions)
                Owner = ($m.owner ?? "Platform Team")
                Model = $model
                ContextSize = $contextCount
                LlmTools = $llmTools
                OsTools = $osTools
            }
            if ($info.Class -eq 'brain') { $brains += $info } else { $arms += $info }
        } catch {
            Write-Warning "Failed to parse manifest for $($agent.Name)"
        }
    }
}

function Render-Cards($list, $icon) {
    if ($list.Count -eq 0) { return "_No agents here yet._" }
    $out = @()
    
    # Grid Layout using HTML Table for better "Card" alignment
    $out += "<table>"
    $out += "<tr>"
    
    $col = 0
    foreach ($a in $list) {
        if ($col -eq 2) { 
            $out += "</tr><tr>" 
            $col = 0
        }
        
        $card = "<td>"
        $card += "<h3>$icon $($a.Name)</h3>"
        $card += "<p><b>$($a.Role)</b></p>"
        $card += "<p><i>$($a.Desc)</i></p>"
        $card += "<br/>"
        
        # Tags/Badges
        $card += "<p>"
        $card += "🏷️ <code>$($a.Class)</code> "
        $card += "🧠 <code>$($a.Model)</code> "
        if ($a.ContextSize -gt 0) { $card += "📚 <code>$($a.ContextSize) docs</code>" }
        $card += "</p>"
        
        # Tools Icons
        if ($a.LlmTools.Count -gt 0 -or $a.OsTools.Count -gt 0) {
            $card += "<p><small><b>Tools:</b> "
            foreach ($t in $a.LlmTools) {
                $icon = "🔧"
                if ($t -match 'web') { $icon = "🌐" }
                if ($t -match 'code|python') { $icon = "🐍" }
                $card += "<span title='GenAI: $t'>$icon</span> "
            }
            foreach ($t in $a.OsTools) {
                $icon = "💻"
                if ($t -match 'az') { $icon = "☁️" }
                if ($t -match 'git') { $icon = "🐙" }
                $card += "<span title='OS: $t'>$icon</span> "
            }
            $card += "</small></p>"
        }
        
        # Skills
        $card += "<hr/>"
        $card += "<b>Key Skills:</b><ul>"
        if ($a.ActionsList) {
            foreach ($act in $a.ActionsList) {
                $actName = if ($act -is [string]) { $act } else { $act.name }
                $card += "<li>$actName</li>"
            }
        } else {
            $card += "<li><i>Specialist Task</i></li>"
        }
        $card += "</ul>"
        
        $card += "<p><small>Owner: $($a.Owner) | ID: $($a.Id)</small></p>"
        $card += "</td>"
        
        $out += $card
        $col++
    }
    
    # Fill remaining cells if row incomplete
    while ($col -lt 2 -and $col -gt 0) {
        $out += "<td></td>"
        $col++
    }
    
    $out += "</tr>"
    $out += "</table>"
    return $out
}

$md += "## 🧠 Brains (Strategic Agents)"
$md += "> *High autonomy, OODA Loop enabled, Principles-driven.*"
$md += ""
$md += Render-Cards $brains "🔬"

$md += ""
$md += "## 💪 Arms (Executive Agents)"
$md += "> *High speed, Deterministic, Task-oriented.*"
$md += ""
$md += Render-Cards $arms "🛠️"

$md += ""
$md += "## 📊 Ecosystem Stats"
$md += "- **Total Agents**: $($brains.Count + $arms.Count)"
$md += "- **Strategic Brains**: $($brains.Count)"
$md += "- **Executive Arms**: $($arms.Count)"
$md += ""
$md += "_(Generated via `scripts/pwsh/generate-agent-roster.ps1`)_"

$md | Out-File -FilePath $outFile -Encoding utf8
Write-Host "Visual Roster generated at: $outFile" -ForegroundColor Green
