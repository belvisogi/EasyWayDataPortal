param(
    [string]$Path = "Wiki/EasyWayData.wiki",
    [string]$Action = "analyze",
    [string]$OllamaUrl = "http://localhost:11434",
    [string]$Model = "deepseek-r1:7b",
    [int]$Limit = 3
)

# --- Harvester Function ---
function Get-WikiPages {
    param($Root)
    Write-Host "🚜 Harvester starting on: $Root" -ForegroundColor Cyan
    
    $files = Get-ChildItem -Path $Root -Recurse -Filter "*.md" | 
    Where-Object { $_.FullName -notmatch "logs|node_modules|\.git|\.obsidian" }
    
    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName -Raw
        
        # Simple Frontmatter Extraction (Regex)
        $fm = @{}
        if ($content -match '(?ms)^---\r?\n(.*?)\r?\n---') {
            $yaml = $Matches[1]
            # Naive parsing of type/status (for demonstration)
            if ($yaml -match 'type:\s*(.+)') { $fm['type'] = $Matches[1].Trim() }
            if ($yaml -match 'status:\s*(.+)') { $fm['status'] = $Matches[1].Trim() }
        }

        [PSCustomObject]@{
            Path        = $file.FullName
            RelPath     = $file.FullName.Replace((Convert-Path $Root), "").Trim("\")
            Content     = $content
            Frontmatter = $fm
        }
    }
}

# --- AI Client Function ---
function Invoke-Ollama {
    param($Url, $Model, $Prompt, $System)
    
    $payload = @{
        model  = $Model
        prompt = $Prompt
        system = $System
        stream = $false
    }
    
    try {
        $response = Invoke-RestMethod -Uri "$Url/api/generate" -Method Post -Body ($payload | ConvertTo-Json) -ContentType "application/json" -TimeoutSec 600
        return $response.response
    }
    catch {
        Write-Error "❌ AI Connection Failed: $($_.Exception.Message)"
        return $null
    }
}

# --- Main Logic ---

$pages = Get-WikiPages -Root $Path
Write-Host "✅ Harvested $($pages.Count) pages." -ForegroundColor Green

if ($Action -eq "analyze") {
    Write-Host "🧠 Connecting to DeepSeek ($Model) at $OllamaUrl..." -ForegroundColor Magenta

    # Mock Taxonomy (should load from JSON)
    $taxonomy = @{
        domain = @('db', 'api', 'docs', 'control-plane')
        layer  = @('spec', 'howto', 'runbook')
    }
    $taxJson = $taxonomy | ConvertTo-Json -Depth 2 -Compress

    # 1. Build Global Index (The 'World View')
    Write-Host "🌍 Building World Index..." -ForegroundColor Cyan
    $worldIndex = $pages | ForEach-Object { "- $($_.RelPath)" }
    $worldIndexText = $worldIndex -join "`n"
    
    # 2. Analyze Pages with Context
    $counter = 0
    foreach ($page in $pages) {
        if ($counter -ge $Limit) { break }
        $counter++

        Write-Host "`n📄 Analyzing: $($page.RelPath)" -ForegroundColor Yellow
        
        $systemPrompt = @"
You are a strict Data Quality Architect.
Your goal is to organize this documentation into a perfect Knowledge Graph.

TAXONOMY RULESET:
$taxJson

WORLD VIEW (Existing Pages):
$worldIndexText

INSTRUCTIONS:
1. Assign strictly valid tags from Taxonomy.
2. Identify 3-5 relevant Cross-Links to EXISTING pages from the World View.
3. Suggest a 'Parent' page if this page is part of a hierarchy.

Output pure JSON:
{
  "tags": ["domain/db", ...],
  "links": ["architecture/db-spec.md", ...],
  "parent": "architecture/index.md"
}
"@

        $userPrompt = "Analyze this content:`n$($page.Content.Substring(0, [Math]::Min($page.Content.Length, 3000)))..."

        $aiResponse = Invoke-Ollama -Url $OllamaUrl -Model $Model -Prompt $userPrompt -System $systemPrompt
        
        if ($aiResponse) {
            # Extract JSON from think output if present
            # DeepSeek outputs <think>...</think> then response. We probably just want the JSON.
            Write-Host "🤖 AI Suggestion:" -ForegroundColor Gray
            Write-Host $aiResponse.Trim() -ForegroundColor White
        }
    }
}
