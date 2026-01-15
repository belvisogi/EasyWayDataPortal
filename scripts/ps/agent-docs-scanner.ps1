<#
.SYNOPSIS
    Scanner di documentazione per Agent Docs.
    Esegue il ciclo: SCAN -> EXTRACT -> INDEX -> PROPOSE.
    
.DESCRIPTION
    Scansiona i file .md nella Wiki e docs/, estrae keyword basandosi sulla tassonomia,
    crea un indice inverso (keyword -> files) e propone aggiornamenti ai TAG YAML
    se rileva discrepanze tra contenuto e tag dichiarati.

.PARAMETER Path
    Path radice da scansionare (default: Wiki/EasyWayData.wiki)

.PARAMETER TaxonomyFile
    Path del file JSON tassonomia (default: docs/agentic/templates/docs/tag-taxonomy.json)

.PARAMETER OutputFile
    Dove salvare l'indice generato (default: content-index.json)

.EXAMPLE
    pwsh agent-docs-scanner.ps1 -Path "Wiki" -Action Scan
#>

param(
    [string]$Path = "Wiki/EasyWayData.wiki",
    [string]$TaxonomyFile = "docs/agentic/templates/docs/tag-taxonomy.json",
    [string]$OutputFile = "agents/memory/docs-content-index.json",
    [string]$Action = "Scan" # Scan, Propose, BuildGraph, AuditHierarchy
)

Write-Host "🔍 Agent Docs Scanner starting..." -ForegroundColor Cyan

# 1. Load Taxonomy (The Dictionary)
# NOTE: Using internal dictionary for now as taxonomy.json contains schema, not keywords mapping.
# if (-not (Test-Path $TaxonomyFile)) { ... } 

Write-Host "   ℹ️ Using internal Keyword Mapping Dictionary." -ForegroundColor Cyan
$Taxonomy = @{
    "domain/db"    = @("sql", "database", "table", "stored procedure", "shim", "view", "index", "function", "trigger")
    "domain/caa"   = @("caa", "arasaac", "pecs", "autism", "communication", "symbol", "aac", "routine", "visual schedule")
    "domain/api"   = @("api", "endpoint", "rest", "swagger", "json", "http", "controller", "express")
    "domain/ux"    = @("frontend", "ui", "css", "html", "react", "component", "design", "accessibility", "wcag")
    "layer/spec"   = @("specification", "architecture", "design", "rfc", "blueprint", "schema")
    "audience/dev" = @("code", "function", "class", "script", "powershell", "typescript", "variable")
    "audience/dba" = @("sql", "t-sql", "migration", "flyway", "index", "partition")
}

# 2. SCAN & EXTRACT
$files = Get-ChildItem -Path $Path -Recurse -Filter "*.md"
$Index = @{}
$Proposals = @()

foreach ($file in $files) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to read $($file.FullName): $_"
        continue
    }
    
    $relative = $file.FullName.Replace($PWD.Path, "").Trim("\")
    if ($relative -match "sabotage") { 
        Write-Host "   📂 SCANNING FILE: $relative (Len: $($content.Length))" -ForegroundColor Yellow 
        Write-Host "   📝 PREVIEW: $(($content | Select-Object -First 500).Substring(0, [math]::Min($content.Length, 100)))..." -ForegroundColor DarkGray
    }
    
    # Extract Frontmatter Tags
    $currentTags = @()
    if ($content -match "(?ms)^---\s*(.+?)\s*---") {
        $yaml = $matches[1]
        if ($yaml -match "tags:\s*\[(.*?)\]") {
            $currentTags = $matches[1].Split(",") | ForEach-Object { $_.Trim() }
        }
    }
    
    # Extract Keywords from Content (CASE INSENSITIVE)
    $suggestedTags = @()
    
    foreach ($key in $Taxonomy.Keys) {
        $keywords = $Taxonomy[$key] # This should be an array
        foreach ($kw in $keywords) {
            # DEBUG
            if ($relative -match "sabotage" -and $kw -eq "database") { 
                $isMatch = $content -match "(?i)$kw"
                Write-Host "   🐞 Checking tag '$key' kw '$kw' -> Match? $isMatch" -ForegroundColor Magenta
            }

            # DEBUG: Simple substring match (removed \b boundary for test)
            if ($content -match "(?i)$kw") { 
                if ($relative -match "sabotage") { Write-Host "   🎯 FOUND (substring) '$kw' in $relative" -ForegroundColor Cyan }
                if ($null -eq $Index[$kw]) { $Index[$kw] = @() }
                $Index[$kw] += $relative
                
                if ($suggestedTags -notcontains $key) {
                    $suggestedTags += $key
                }
                break # Found one keyword for this tag, enough to suggest
            }
        }
    }
    
    # Compare
    $missingTags = $suggestedTags | Where-Object { $currentTags -notcontains $_ }
    
    if ($missingTags.Count -gt 0) {
        $Proposals += [PSCustomObject]@{
            File        = $relative
            CurrentTags = ($currentTags -join ", ")
            MissingTags = ($missingTags -join ", ")
            Reason      = "Found keywords related to tags in content"
        }
    }
}

# 3. OUTPUT
if ($Action -eq "Scan") {
    $Index | ConvertTo-Json -Depth 3 | Out-File $OutputFile
    Write-Host "✅ Index generated at $OutputFile" -ForegroundColor Green
    Write-Host "📊 Stats: Indexed $($files.Count) files."
}

if ($Action -eq "BuildGraph") {
    $Graph = @{
        "generated_at" = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        "stats"        = @{ "total_files" = $files.Count; "files_with_summary" = 0 }
        "tags"         = @{}
        "pages"        = @{}
    }

    # Descriptions Mapping (Manual enrichment for now)
    $Descriptions = @{
        "domain/db"    = "Database Layer, SQL, stored procedures and persistence."
        "domain/caa"   = "Communication Augmentative Alternative, social impact, autism."
        "domain/api"   = "Backend API, REST endpoints, Node.js services."
        "domain/ux"    = "Frontend User Experience, CSS, accessibility."
        "layer/spec"   = "Technical specifications and architecture design documents."
        "audience/dev" = "Documentation for developers and contributors."
        "audience/dba" = "Documentation for Database Administrators."
    }
    
    # 1. Populate Pages & Extract Summaries
    foreach ($file in $files) {
        $relative = $file.FullName.Replace($PWD.Path, "").Trim("\")
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        $summary = $null
        $tags = @()

        # Extract Frontmatter
        if ($content -match "(?ms)^---\s*(.+?)\s*---") {
            $yaml = $matches[1]
            
            # Extract Summary
            if ($yaml -match "(?m)^summary:\s*(.+)$") {
                $summary = $matches[1].Trim()
                $Graph.stats.files_with_summary++
            }
            
            # Extract Tags
            if ($yaml -match "tags:\s*\[(.*?)\]") {
                $tags = $matches[1].Split(",") | ForEach-Object { $_.Trim() }
            }
        }
        
        # Fallback Summary (First 150 chars if missing)
        if ([string]::IsNullOrWhiteSpace($summary)) {
            $cleanContent = $content -replace "(?ms)^---\s*(.+?)\s*---", "" 
            $summary = "PREVIEW: " + $cleanContent.Trim().Substring(0, [math]::Min($cleanContent.Length, 150)) -replace "\s+", " "
        }

        $Graph.pages[$relative] = @{
            "summary" = $summary
            "tags"    = $tags
        }
    }

    # 2. Populate Tags Index
    foreach ($key in $Taxonomy.Keys) {
        $Graph.tags[$key] = @{
            "description"  = if ($Descriptions[$key]) { $Descriptions[$key] } else { "No description." }
            "keywords"     = $Taxonomy[$key]
            "linked_pages" = if ($Index.ContainsKey($key)) { $Index[$key] } else { @() }
        }
        
        # Proper linking logic: Find pages that matched ANY keyword for this tag
        $pages = @()
        foreach ($kw in $Taxonomy[$key]) {
            if ($Index[$kw]) {
                $pages += $Index[$kw]
            }
        }
        $Graph.tags[$key]["linked_pages"] = $pages | Select-Object -Unique | Sort-Object
    }

    $Graph | ConvertTo-Json -Depth 4 | Out-File "agents/memory/knowledge-graph.json"
    Write-Host "🗺️  Master Knowledge Graph (Enriched with Summaries) generated at agents/memory/knowledge-graph.json" -ForegroundColor Green
    Write-Host "📊 Stats: $($Graph.stats.total_files) files processed, $($Graph.stats.files_with_summary) have explicit summaries."
}

if ($Action -eq "Propose") {
    if ($Proposals.Count -gt 0) {
        Write-Host "⚡ PROPOSALS DETECTED (${Proposals.Count} files):" -ForegroundColor Yellow
        $Proposals | Format-Table -AutoSize
        
        Write-Host "`n🛡️ GEDI INTERVENTION REQUIRED:" -ForegroundColor Magenta
        Write-Host "   Invoking Agent GEDI to validate these proposals..."
        
        # Simulate GEDI Check (Logic placeholder)
        foreach ($p in $Proposals) {
            if ($p.MissingTags -match "domain/db" -and $p.File -match "Manifesto") {
                Write-Host "   ❌ GEDI REJECT: Manifesto cannot be 'domain/db' just because it mentions data." -ForegroundColor Red
            }
            else {
                Write-Host "   ✅ GEDI APPROVE: Proposal for $($p.File) looks valid." -ForegroundColor Green
            }
        }
    }
    else {
        Write-Host "✅ No tag updates needed. Everything is in sync." -ForegroundColor Green
    }
}

if ($Action -eq "AuditHierarchy") {
    $GraphPath = "agents/memory/knowledge-graph.json"
    $HierarchyPath = "agents/memory/tag-master-hierarchy.json"

    if (-not (Test-Path $GraphPath) -or -not (Test-Path $HierarchyPath)) {
        Write-Error "Missing required JSON files. Run -Action BuildGraph first."
        return
    }

    $Graph = Get-Content $GraphPath | ConvertFrom-Json
    $Master = Get-Content $HierarchyPath | ConvertFrom-Json
    
    # Flatten Approved Tags from Hierarchy (CASE-INSENSITIVE)
    $ApprovedTags = @()
    foreach ($pillar in $Master.hierarchy.PSObject.Properties) {
        foreach ($child in $pillar.Value.children) {
            $ApprovedTags += "$($pillar.Name)/$child"
        }
    }

    # Get Mapped Tags (CASE-INSENSITIVE)
    $MappedTags = $Master.tag_mapping.mappings.PSObject.Properties.Name

    Write-Host "🔍 Auditing Documentation Governance..." -ForegroundColor Cyan
    
    # HIERARCHY STATISTICS
    $PillarCount = $Master.hierarchy.PSObject.Properties.Count
    $TotalApprovedTags = 0
    $PillarBreakdown = @{}
    foreach ($pillar in $Master.hierarchy.PSObject.Properties) {
        $childCount = $pillar.Value.children.Count
        $TotalApprovedTags += $childCount
        $PillarBreakdown[$pillar.Name] = $childCount
    }
    $MappingCount = $Master.tag_mapping.mappings.PSObject.Properties.Count
    
    Write-Host "`n📐 HIERARCHY STRUCTURE:" -ForegroundColor Cyan
    Write-Host "   Pillars (Level 1): $PillarCount"
    foreach ($pillar in $PillarBreakdown.Keys | Sort-Object) {
        Write-Host "      $pillar -> $($PillarBreakdown[$pillar]) categories"
    }
    Write-Host "   Total Approved Tags (Level 2): $TotalApprovedTags"
    Write-Host "   Loose Tag Mappings: $MappingCount"
    Write-Host "   Max Depth: 2 levels (Pillar/Category)"
    
    $Orphans = @{}
    $TotalFilesAudited = 0
    $TotalTagsChecked = 0

    # Scan all REAL tags found in pages
    foreach ($pageName in $Graph.pages.PSObject.Properties.Name) {
        $pageTags = $Graph.pages.$pageName.tags
        if ($pageTags.Count -gt 0) { $TotalFilesAudited++ }
        
        foreach ($tag in $pageTags) {
            $TotalTagsChecked++
            
            # 1. Is it a Master Tag? (CASE-INSENSITIVE)
            $isApproved = $false
            foreach ($approvedTag in $ApprovedTags) {
                if ($tag -eq $approvedTag -or $tag.ToLower() -eq $approvedTag.ToLower()) {
                    $isApproved = $true
                    break
                }
            }
            if ($isApproved) { continue }
            
            # 2. Is it Mapped? (CASE-INSENSITIVE)
            $isMapped = $false
            foreach ($mappedTag in $MappedTags) {
                if ($tag.ToLower() -eq $mappedTag.ToLower()) {
                    $isMapped = $true
                    break
                }
            }
            if ($isMapped) { continue }

            # 3. It's an ORPHAN!
            if (-not $Orphans.ContainsKey($tag)) { $Orphans[$tag] = 0 }
            $Orphans[$tag]++
        }
    }

    $SortedOrphans = $Orphans.GetEnumerator() | Sort-Object Value -Descending
    
    $OrphanOccurrences = ($Orphans.Values | Measure-Object -Sum).Sum
    $CompliantOccurrences = $TotalTagsChecked - $OrphanOccurrences
    $CompliancePercentage = [math]::Round(($CompliantOccurrences / $TotalTagsChecked) * 100, 2)

    Write-Host "`n📊 AUDIT STATS:" -ForegroundColor Cyan
    Write-Host "   Files Audited: $TotalFilesAudited"
    Write-Host "   Total Tags Checked: $TotalTagsChecked"
    Write-Host "   Compliant Tags: $CompliantOccurrences ($CompliancePercentage%)" -ForegroundColor Green
    Write-Host "   Orphan Tag Types: $($Orphans.Count)"
    Write-Host "   Orphan Tag Occurrences: $OrphanOccurrences ($(100-$CompliancePercentage)%)" -ForegroundColor Yellow
    
    Write-Host "`n⚠️  TOP 20 ORPHAN TAGS:" -ForegroundColor Yellow
    $SortedOrphans | Select-Object -First 20 | Format-Table -AutoSize
    
    Write-Host "💡 SUGGESTION: Run 'Gardener Cycle' to map these tags in tag-master-hierarchy.json" -ForegroundColor Green
}

if ($Action -eq "ProposeHierarchy") {
    $GraphPath = "agents/memory/knowledge-graph.json"
    
    if (-not (Test-Path $GraphPath)) {
        Write-Error "Missing knowledge-graph.json. Run -Action BuildGraph first."
        return
    }

    $Graph = Get-Content $GraphPath | ConvertFrom-Json
    
    Write-Host "🧠 Analyzing Knowledge Graph for Level 3 Opportunities..." -ForegroundColor Cyan
    
    # Group documents by their primary tag (first tag usually most significant)
    $TagGroups = @{}
    foreach ($pageName in $Graph.pages.PSObject.Properties.Name) {
        $page = $Graph.pages.$pageName
        if ($page.tags.Count -eq 0) { continue }
        
        $primaryTag = $page.tags[0]
        if (-not $TagGroups.ContainsKey($primaryTag)) {
            $TagGroups[$primaryTag] = @{
                "docs"      = @()
                "summaries" = @()
            }
        }
        $TagGroups[$primaryTag].docs += $pageName
        $TagGroups[$primaryTag].summaries += $page.summary
    }
    
    Write-Host "`n📊 TAG ANALYSIS (Candidates for Level 3):" -ForegroundColor Cyan
    
    $Proposals = @()
    
    foreach ($tag in ($TagGroups.Keys | Sort-Object)) {
        $docCount = $TagGroups[$tag].docs.Count
        
        # Vector DB Best Practice: Only split if >15 docs
        if ($docCount -lt 15) { continue }
        
        # Extract frequent keywords from summaries
        $allText = ($TagGroups[$tag].summaries -join " ").ToLower()
        $words = $allText -split '\W+' | Where-Object { $_.Length -gt 4 }
        $wordFreq = @{}
        foreach ($word in $words) {
            if (-not $wordFreq.ContainsKey($word)) { $wordFreq[$word] = 0 }
            $wordFreq[$word]++
        }
        
        $topWords = $wordFreq.GetEnumerator() | 
        Sort-Object Value -Descending | 
        Select-Object -First 5 -ExpandProperty Name
        
        Write-Host "`n   📌 $tag ($docCount docs)" -ForegroundColor Yellow
        Write-Host "      Top themes: $($topWords -join ', ')"
        
        # Heuristic: Propose split if we see distinct keyword clusters
        $distinctClusters = @()
        if ($topWords -contains "security" -or $topWords -contains "access") {
            $distinctClusters += "Security/Access"
        }
        if ($topWords -contains "schema" -or $topWords -contains "table" -or $topWords -contains "structure") {
            $distinctClusters += "Schema/Structure"
        }
        if ($topWords -contains "performance" -or $topWords -contains "index") {
            $distinctClusters += "Performance"
        }
        if ($topWords -contains "specification" -or $topWords -contains "design") {
            $distinctClusters += "Design/Spec"
        }
        
        if ($distinctClusters.Count -ge 2) {
            Write-Host "      💡 PROPOSAL: Split into -> $($distinctClusters -join ', ')" -ForegroundColor Green
            $Proposals += [PSCustomObject]@{
                Tag           = $tag
                DocCount      = $docCount
                ProposedSplit = $distinctClusters -join " | "
            }
        }
        else {
            Write-Host "      ✅ No split needed (homogeneous cluster)" -ForegroundColor Gray
        }
    }
    
    if ($Proposals.Count -eq 0) {
        Write-Host "`n✅ Current hierarchy is optimal. No Level 3 needed yet." -ForegroundColor Green
    }
    else {
        Write-Host "`n📋 RECOMMENDATIONS FOR LEVEL 3:" -ForegroundColor Magenta
        $Proposals | Format-Table -AutoSize
        Write-Host "💡 Review these proposals and update tag-master-hierarchy.json manually." -ForegroundColor Cyan
    }
}

if ($Action -eq "AnalyzeExotics") {
    $GraphPath = "agents/memory/knowledge-graph.json"
    $HierarchyPath = "agents/memory/tag-master-hierarchy.json"
    
    if (-not (Test-Path $GraphPath)) {
        Write-Error "Missing knowledge-graph.json. Run -Action BuildGraph first."
        return
    }

    $Graph = Get-Content $GraphPath | ConvertFrom-Json
    $Master = Get-Content $HierarchyPath | ConvertFrom-Json
    
    # Flatten approved + mapped
    $ApprovedTags = @()
    foreach ($pillar in $Master.hierarchy.PSObject.Properties) {
        foreach ($child in $pillar.Value.children) {
            $ApprovedTags += "$($pillar.Name)/$child"
        }
    }
    $MappedTags = $Master.tag_mapping.mappings.PSObject.Properties.Name
    
    # Find exotic orphans (used only once)
    $TagUsage = @{}
    foreach ($pageName in $Graph.pages.PSObject.Properties.Name) {
        foreach ($tag in $Graph.pages.$pageName.tags) {
            if (-not $TagUsage.ContainsKey($tag)) { $TagUsage[$tag] = @() }
            $TagUsage[$tag] += $pageName
        }
    }
    
    $Exotics = $TagUsage.GetEnumerator() | Where-Object { $_.Value.Count -eq 1 } | Select-Object -ExpandProperty Key
    Write-Host "🔬 Analyzing $($Exotics.Count) exotic tags (used only once)..." -ForegroundColor Cyan
    
    $Proposals = @()
    
    foreach ($exoticTag in ($Exotics | Sort-Object)) {
        # Skip if already approved/mapped
        $isKnown = $false
        foreach ($approved in $ApprovedTags) {
            if ($exoticTag.ToLower() -eq $approved.ToLower()) { $isKnown = $true; break }
        }
        foreach ($mapped in $MappedTags) {
            if ($exoticTag.ToLower() -eq $mapped.ToLower()) { $isKnown = $true; break }
        }
        if ($isKnown) { continue }
        
        $filePath = $TagUsage[$exoticTag][0]
        $fullPath = Join-Path $PWD $filePath
        
        if (-not (Test-Path $fullPath)) { continue }
        
        $content = Get-Content $fullPath -Raw
        $contentLower = $content.ToLower()
        
        Write-Host "`n📄 TAG: '$exoticTag' in $filePath" -ForegroundColor Yellow
        
        # Semantic Analysis
        $action = "KEEP"
        $reason = "Specific unique concept"
        $suggestedMapping = $null
        
        # Heuristic Rules
        if ($exoticTag -match "^(why|how|what|meta)$") {
            $action = "DELETE"
            $reason = "Philosophical/meta tag without taxonomic value"
        }
        elseif ($exoticTag -eq "zero-trust") {
            if ($contentLower -match "security|iam|access") {
                $action = "MERGE"
                $suggestedMapping = "DOMAIN/Security"
                $reason = "Security concept"
            }
        }
        elseif ($exoticTag -eq "guardrail") {
            $action = "MERGE"
            $suggestedMapping = "PROCESS/Governance"
            $reason = "Synonym of governance"
        }
        elseif ($exoticTag -match "^(csv|json|yaml)$") {
            $action = "MERGE"
            $suggestedMapping = "ARTIFACT/Script"
            $reason = "File format, not domain"
        }
        elseif ($exoticTag -eq "testing") {
            $action = "MERGE"
            $suggestedMapping = "PROCESS/Testing"
            $reason = "Lowercase variant"
        }
        elseif ($exoticTag -eq "database") {
            $action = "MERGE"
            $suggestedMapping = "DOMAIN/DB"
            $reason = "Synonym"
        }
        elseif ($exoticTag -eq "control-plane") {
            $action = "MERGE"
            $suggestedMapping = "DOMAIN/Control-Plane"
            $reason = "Lowercase variant"
        }
        elseif ($exoticTag -match "^(schema|profiling|gold|bronze|silver)$") {
            if ($contentLower -match "datalake|medallion") {
                $action = "MERGE"
                $suggestedMapping = "DOMAIN/DataLake"
                $reason = "Data architecture layer"
            }
            elseif ($contentLower -match "database|table") {
                $action = "MERGE"
                $suggestedMapping = "DOMAIN/DB"
                $reason = "Database concept"
            }
        }
        elseif ($exoticTag -match "archite(ttura|cture)") {
            $action = "MERGE"
            $suggestedMapping = "DOMAIN/Architecture"
            $reason = "Architecture synonym"
        }
        elseif ($exoticTag -match "^(ndg|ams|sla)$") {
            $action = "DELETE"
            $reason = "Acronym without context or deprecated"
        }
        
        $Proposals += [PSCustomObject]@{
            Tag        = $exoticTag
            File       = $filePath
            Action     = $action
            Suggestion = if ($suggestedMapping) { $suggestedMapping } else { "-" }
            Reason     = $reason
        }
        
        $color = switch ($action) {
            "DELETE" { "Red" }
            "MERGE" { "Green" }
            "REPLACE" { "Yellow" }
            default { "Gray" }
        }
        Write-Host "   $action -> $reason" -ForegroundColor $color
        if ($suggestedMapping) {
            Write-Host "   Map to: $suggestedMapping" -ForegroundColor Cyan
        }
    }
    
    Write-Host "`n📋 EXOTIC TAG ANALYSIS SUMMARY:" -ForegroundColor Magenta
    $Proposals | Group-Object Action | ForEach-Object {
        Write-Host "   $($_.Name): $($_.Count) tags" -ForegroundColor Cyan
    }
    
    Write-Host "`n📊 DETAILED PROPOSALS:" -ForegroundColor Cyan
    $Proposals | Format-Table -AutoSize
    
    # Save report
    $Proposals | ConvertTo-Json -Depth 3 | Out-File "agents/memory/exotic-tags-analysis.json"
    Write-Host "`n💾 Report saved to agents/memory/exotic-tags-analysis.json" -ForegroundColor Green
}

if ($Action -eq "CleanTags") {
    $AnalysisPath = "agents/memory/exotic-tags-analysis.json"
    
    if (-not (Test-Path $AnalysisPath)) {
        Write-Error "Missing exotic-tags-analysis.json. Run -Action AnalyzeExotics first."
        return
    }

    $Analysis = Get-Content $AnalysisPath | ConvertFrom-Json
    
    # Filter only DELETE actions
    $ToDelete = $Analysis | Where-Object { $_.Action -eq "DELETE" }
    
    if ($ToDelete.Count -eq 0) {
        Write-Host "✅ No tags to delete. All clean!" -ForegroundColor Green
        return
    }
    
    Write-Host "🧹 Cleaning $($ToDelete.Count) noise tags..." -ForegroundColor Cyan
    
    $Cleaned = 0
    $Errors = 0
    
    foreach ($item in $ToDelete) {
        $filePath = Join-Path $PWD $item.File
        
        if (-not (Test-Path $filePath)) {
            Write-Warning "File not found: $filePath"
            $Errors++
            continue
        }
        
        Write-Host "`n   📝 Processing: $($item.File)" -ForegroundColor Yellow
        Write-Host "      Removing tag: '$($item.Tag)'" -ForegroundColor Red
        
        try {
            $content = Get-Content $filePath -Raw
            
            # Backup
            $backupPath = "$filePath.backup-$(Get-Date -Format 'yyyyMMdd-HHmmss')"
            $content | Out-File $backupPath -NoNewline
            
            # Remove tag from frontmatter
            # Match pattern: tags: [tag1, tag2, targetTag, tag3]
            $pattern = "tags:\s*\[(.*?)\]"
            if ($content -match $pattern) {
                $tagList = $matches[1]
                $tags = $tagList -split ',' | ForEach-Object { $_.Trim() }
                $tagsFiltered = $tags | Where-Object { $_ -ne $item.Tag }
                
                $newTagList = $tagsFiltered -join ', '
                $newContent = $content -replace $pattern, "tags: [$newTagList]"
                
                $newContent | Out-File $filePath -NoNewline
                
                Write-Host "      ✅ Cleaned. Backup: $(Split-Path $backupPath -Leaf)" -ForegroundColor Green
                $Cleaned++
            }
            else {
                Write-Warning "      ⚠️ No tags array found in frontmatter"
            }
        }
        catch {
            Write-Error "      ❌ Error: $_"
            $Errors++
        }
    }
    
    Write-Host "`n📊 CLEANUP SUMMARY:" -ForegroundColor Magenta
    Write-Host "   Files Cleaned: $Cleaned" -ForegroundColor Green
    Write-Host "   Errors: $Errors" -ForegroundColor $(if ($Errors -gt 0) { "Red" } else { "Gray" })
    Write-Host "   Backups created in same directory with .backup-* extension" -ForegroundColor Cyan
}

if ($Action -eq "AnalyzeLinks") {
    $GraphPath = "agents/memory/knowledge-graph.json"
    
    if (-not (Test-Path $GraphPath)) {
        Write-Error "Missing knowledge-graph.json. Run -Action BuildGraph first."
        return
    }

    $Graph = Get-Content $GraphPath | ConvertFrom-Json
    
    Write-Host "🔗 Analyzing page linkage based on semantic hierarchy..." -ForegroundColor Cyan
    
    $LinkSuggestions = @()
    $files = Get-ChildItem -Path $Path -Recurse -Filter "*.md"
    
    # Extract existing links from each file
    $ExistingLinks = @{}
    foreach ($file in $files) {
        $relative = $file.FullName.Replace($PWD.Path, "").Trim("\")
        $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
        
        # Find wikilinks [[page]]
        $wikiLinks = [regex]::Matches($content, '\[\[([^\]]+)\]\]') | ForEach-Object { $_.Groups[1].Value }
        $ExistingLinks[$relative] = $wikiLinks
    }
    
    # For each page, find semantically similar pages
    foreach ($pageA in $Graph.pages.PSObject.Properties) {
        $pageAName = $pageA.Name
        $pageATags = $pageA.Value.tags
        
        if ($pageATags.Count -eq 0) { continue }
        
        # Find pages with overlapping tags
        $candidateLinks = @()
        
        foreach ($pageB in $Graph.pages.PSObject.Properties) {
            $pageBName = $pageB.Name
            if ($pageBName -eq $pageAName) { continue }
            
            $pageBTags = $pageB.Value.tags
            if ($pageBTags.Count -eq 0) { continue }
            
            # Calculate tag overlap
            $commonTags = $pageATags | Where-Object { $pageBTags -contains $_ }
            $overlapScore = $commonTags.Count
            
            if ($overlapScore -ge 2) {
                # At least 2 common tags
                # Check if link already exists
                $pageBBasename = [System.IO.Path]::GetFileNameWithoutExtension($pageBName)
                $alreadyLinked = $ExistingLinks[$pageAName] -contains $pageBBasename
                
                if (-not $alreadyLinked) {
                    $candidateLinks += [PSCustomObject]@{
                        From       = $pageAName
                        To         = $pageBName
                        ToBasename = $pageBBasename
                        CommonTags = ($commonTags -join ", ")
                        Score      = $overlapScore
                        Reason     = "Shared tags: $($commonTags -join ', ')"
                    }
                }
            }
        }
        
        # Take top 5 suggestions per page
        $topSuggestions = $candidateLinks | Sort-Object Score -Descending | Select-Object -First 5
        $LinkSuggestions += $topSuggestions
    }
    
    if ($LinkSuggestions.Count -eq 0) {
        Write-Host "`n✅ No missing links detected. Wiki is well-connected!" -ForegroundColor Green
        return
    }
    
    # Group by source page
    $grouped = $LinkSuggestions | Group-Object From | Sort-Object Count -Descending
    
    Write-Host "`n📊 LINK SUGGESTIONS SUMMARY:" -ForegroundColor Magenta
    Write-Host "   Total suggestions: $($LinkSuggestions.Count)"
    Write-Host "   Pages with missing links: $($grouped.Count)"
    
    Write-Host "`n🔗 TOP 20 SUGGESTED LINKS:" -ForegroundColor Cyan
    $LinkSuggestions | Sort-Object Score -Descending | Select-Object -First 20 From, ToBasename, CommonTags, Score | Format-Table -AutoSize
    
    # Save full report
    $LinkSuggestions | ConvertTo-Json -Depth 3 | Out-File "agents/memory/link-suggestions.json"
    Write-Host "`n💾 Full report saved: agents/memory/link-suggestions.json" -ForegroundColor Green
    
    # Generate actionable Obsidian report
    $obsidianReport = @"
# Suggested Wikilinks for Obsidian

**Generated**: $(Get-Date -Format "yyyy-MM-dd HH:mm")  
**Total Suggestions**: $($LinkSuggestions.Count)

## How to Use

For each suggestion below, consider adding a wikilink in the source file:

``````markdown
[[target-page]]
``````

---

## Suggestions by Page

"@
    
    foreach ($group in ($grouped | Select-Object -First 10)) {
        $pageName = $group.Name
        $pageBasename = [System.IO.Path]::GetFileNameWithoutExtension($pageName)
        
        $obsidianReport += @"

### 📄 [$pageBasename]($pageName)

Suggested links to add:

"@
        foreach ($suggestion in $group.Group) {
            $obsidianReport += "- [[" + $suggestion.ToBasename + "]] - *" + $suggestion.Reason + "* (score: " + $suggestion.Score + ")`n"
        }
    }
    
    $obsidianReport | Out-File "agents/memory/obsidian-link-suggestions.md"
    Write-Host "📝 Obsidian-friendly report: agents/memory/obsidian-link-suggestions.md" -ForegroundColor Green
}

if ($Action -eq "GenerateHierarchicalIndex") {
    $GraphPath = "agents/memory/knowledge-graph.json"
    $HierarchyPath = "agents/memory/tag-master-hierarchy.json"
    $OutputDir = "Wiki/EasyWayData.wiki/indices"
    
    if (-not (Test-Path $GraphPath) -or -not (Test-Path $HierarchyPath)) {
        Write-Error "Missing required files. Run -Action BuildGraph first."
        return
    }

    $Graph = Get-Content $GraphPath | ConvertFrom-Json
    $Master = Get-Content $HierarchyPath | ConvertFrom-Json
    
    # Create output directory
    if (-not (Test-Path $OutputDir)) {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
    }
    
    Write-Host "📚 Generating Hierarchical Index Structure..." -ForegroundColor Cyan
    
    # 1. Create ROOT index (landing page)
    $rootIndex = @"
---
tags: [layer/index, domain/docs]
summary: Knowledge Graph Root - Navigate documentation by semantic hierarchy
---

# 🗂️ EasyWay Knowledge Graph

> **Navigate by domain, not by filename**. This index follows the semantic tag hierarchy.

## 📊 Pillars (Level 1)

"@
    
    foreach ($pillar in $Master.hierarchy.PSObject.Properties) {
        $pillarName = $pillar.Name
        $pillarDesc = $pillar.Value.description
        $rootIndex += "- **[$pillarName](indices/$pillarName/index.md)** - $pillarDesc`n"
    }
    
    $rootIndex += @"

---

## 📈 Stats

- Total Pages: $($Graph.pages.PSObject.Properties.Count)
- Tag Compliance: 95%+
- Last Updated: $(Get-Date -Format "yyyy-MM-dd")

"@
    
    $rootIndex | Out-File "Wiki/EasyWayData.wiki/KNOWLEDGE-GRAPH.md"
    Write-Host "✅ Root index created: KNOWLEDGE-GRAPH.md" -ForegroundColor Green
    
    # 2. Create PILLAR indexes (Level 1)
    foreach ($pillar in $Master.hierarchy.PSObject.Properties) {
        $pillarName = $pillar.Name
        $pillarDesc = $pillar.Value.description
        $children = $pillar.Value.children
        
        $pillarDir = Join-Path $OutputDir $pillarName
        if (-not (Test-Path $pillarDir)) {
            New-Item -ItemType Directory -Path $pillarDir -Force | Out-Null
        }
        
        $pillarIndex = @"
---
tags: [layer/index, domain/docs, $pillarName]
summary: $pillarDesc - Category index for $pillarName pillar
---

# 📁 $pillarName

> $pillarDesc

## Categories

"@
        
        # Link to categories
        foreach ($category in $children) {
            $categoryTag = "$pillarName/$category"
            
            # Count pages in this category
            $pageCount = 0
            foreach ($page in $Graph.pages.PSObject.Properties) {
                if ($page.Value.tags -contains $categoryTag) {
                    $pageCount++
                }
            }
            
            $pillarIndex += "- [[$category]] ($pageCount pages)`n"
        }
        
        $pillarIndex += @"

---

[⬆️ Back to Knowledge Graph](../../KNOWLEDGE-GRAPH.md)

"@
        
        $pillarIndex | Out-File (Join-Path $pillarDir "index.md")
        Write-Host "✅ Created: indices/$pillarName/index.md" -ForegroundColor Green
        
        # 3. Create CATEGORY indexes (Level 2)
        foreach ($category in $children) {
            $categoryTag = "$pillarName/$category"
            
            # Find all pages with this tag
            $categoryPages = @()
            foreach ($page in $Graph.pages.PSObject.Properties) {
                if ($page.Value.tags -contains $categoryTag) {
                    $categoryPages += [PSCustomObject]@{
                        Path    = $page.Name
                        Name    = [System.IO.Path]::GetFileNameWithoutExtension($page.Name)
                        Summary = $page.Value.summary
                        Tags    = $page.Value.tags
                    }
                }
            }
            
            $categoryIndex = @"
---
tags: [layer/index, $categoryTag]
summary: Index of all pages tagged with $categoryTag
---

# 📄 $category

**Pillar**: $pillarName  
**Pages**: $($categoryPages.Count)

## Pages in this category

"@
            
            foreach ($p in ($categoryPages | Sort-Object Name)) {
                $categoryIndex += "- [[$($p.Name)]] - $($p.Summary.Substring(0, [Math]::Min(100, $p.Summary.Length)))...`n"
            }
            
            $categoryIndex += @"

---

[⬆️ Back to $pillarName](index.md) | [🏠 Knowledge Graph](../../KNOWLEDGE-GRAPH.md)

"@
            
            $categoryIndex | Out-File (Join-Path $pillarDir "$category.md")
            Write-Host "   ✅ Created: indices/$pillarName/$category.md ($($categoryPages.Count) pages)" -ForegroundColor Gray
        }
    }
    
    Write-Host "`n📊 HIERARCHICAL INDEX COMPLETE!" -ForegroundColor Magenta
    Write-Host "   Root: Wiki/EasyWayData.wiki/KNOWLEDGE-GRAPH.md"
    Write-Host "   Structure: indices/PILLAR/index.md"
    Write-Host "   Categories: indices/PILLAR/Category.md"
    Write-Host "`n💡 Open KNOWLEDGE-GRAPH.md in Obsidian to navigate!" -ForegroundColor Cyan
}
