param(
    [string]$RepoRoot = "C:\old\EasyWayDataPortal",
    [string]$WikiRoot = "C:\old\EasyWayDataPortal\Wiki\EasyWayData.wiki",
    [switch]$Apply
)

# Map of Filename -> Relative Path from RepoRoot (Canonical Location)
$FileMap = @{
    "ADA Reference Architecture.pdf"      = "docs/architecture/ADA Reference Architecture.pdf"
    "ADA Reference Architecture.pptx"     = "docs/architecture/ADA Reference Architecture.pptx"
    "ADA_Reference_Architecture_text.txt" = "docs/architecture/ADA_Reference_Architecture_text.txt"
    "DR_Plan_ADA.docx"                    = "docs/disaster-recovery/DR_Plan_ADA.docx"
    "AGENTS.md"                           = "docs/project-root/AGENTS.md"
    "ANTI_PHILOSOPHY_STARTER_KIT.md"      = "docs/project-root/ANTI_PHILOSOPHY_STARTER_KIT.md"
    "DEVELOPER_ONBOARDING.md"             = "docs/project-root/DEVELOPER_ONBOARDING.md"
    "DEVELOPER_START_HERE.md"             = "docs/project-root/DEVELOPER_START_HERE.md"
    "Sintesi_EasyWayDataPortal.md"        = "docs/project-root/Sintesi_EasyWayDataPortal.md"
    "VALUTAZIONE_EasyWayDataPortal.md"    = "docs/project-root/VALUTAZIONE_EasyWayDataPortal.md"
    "logo.png"                            = "docs/assets/logo.png"
    "home_easyway.html"                   = "docs/assets/home_easyway.html"
    "palette_EasyWay.html"                = "docs/assets/palette_EasyWay.html"
    "SECURITY_FRAMEWORK.md"               = "docs/infra/SECURITY_FRAMEWORK.md"
    "SECURITY_AUDIT.md"                   = "docs/architecture/SECURITY_AUDIT.md"
    "SECURITY_DEV_CHECKLIST.md"           = "docs/security/SECURITY_DEV_CHECKLIST.md" # Assuming this exists
    "ai-security-guardrails.md"           = "docs/agentic/ai-security-guardrails.md"   # Explicit fix for security/ issue
    "ai-security-integration.md"          = "docs/agentic/ai-security-integration.md"
    "AI_SECURITY_STATUS.md"               = "docs/agentic/AI_SECURITY_STATUS.md"
    "SERVER_BOOTSTRAP_PROTOCOL.md"        = "docs/infra/SERVER_BOOTSTRAP_PROTOCOL.md"
    "ORACLE_CURRENT_ENV.md"               = "docs/infra/ORACLE_CURRENT_ENV.md"
    "ORACLE_QUICK_START.md"               = "docs/infra/ORACLE_QUICK_START.md"
    "ORACLE_ENV_DOC.md"                   = "docs/infra/ORACLE_ENV_DOC.md"
    "agent-security-iam.md"               = "Wiki/EasyWayData.wiki/security/agent-security-iam.md" # Relative to repo root? No, Wiki is in Wiki/EasywayData.wiki. This is tricky. Let's stick to docs/ for now.
}

# Obsidian to file map
$ObsidianMap = @{
    "start-here" = "docs/project-root/DEVELOPER_START_HERE.md"
    "Home"       = "docs/project-root/DEVELOPER_START_HERE.md" # Assuming 'Home' maps here? Or index.md?
}

function Get-RelativePath {
    param($SourceFile, $TargetRelPath)
    
    $sourceDir = [System.IO.Path]::GetDirectoryName($SourceFile)
    $targetAbs = [System.IO.Path]::Combine($RepoRoot, $TargetRelPath)
    
    # Use Uri class to compute relative URI (path)
    $sourceUri = New-Object Uri ($sourceDir + "\")
    $targetUri = New-Object Uri $targetAbs
    
    $relUri = $sourceUri.MakeRelativeUri($targetUri)
    $relPath = [System.Uri]::UnescapeDataString($relUri.ToString())
    
    return $relPath.Replace('/', '/') # Standardize slashes
}

$files = Get-ChildItem -Path $WikiRoot -Recurse -Filter *.md

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $newContent = $content
    $fileChanged = $false
    
    # 1. Fix Standard Links [Label](...filename...)
    foreach ($key in $FileMap.Keys) {
        $targetCanonical = $FileMap[$key]
        
        # Matches any markdown link containing the filename at the end of the path
        # Regex explanation:
        # \[.*?\]     = Match [Label]
        # \(          = Match (
        # (?:[^)]*/)?? = Non-capturing optional path prefix
        # $key        = The filename we are looking for
        # \)          = Match )
        
        # More robust: Find [Label](ANYTHING/Key) or [Label](Key)
        # We replace the content inside () with calculated path
        
        $escapedKey = [regex]::Escape($key)
        $pattern = "\[([^\]]*)\]\((?:[^)]*[\/])?$escapedKey\)"
        
        $matches = [regex]::Matches($newContent, $pattern)
        foreach ($m in $matches) {
            $fullMatch = $m.Value       # [Label](../../old/path/Key)
            $label = $m.Groups[1].Value # Label
            
            # Compute new correct relative path
            $correctRelPath = Get-RelativePath -SourceFile $file.FullName -TargetRelPath $targetCanonical
            
            $replacement = "[$label]($correctRelPath)"
            
            if ($fullMatch -ne $replacement) {
                # Only replace if different (avoids loop if logic is unstable, though logic yields unique path)
                # But wait, we must be careful not to break if we already fixed it locally?
                # The regex matches "anything ending in Key".
                # If "docs/architecture/Key" matches "Key", we might re-calculate. 
                # Re-calculation should yield the SAME path if correct.
                # So it is idempotent!
                
                $newContent = $newContent.Replace($fullMatch, $replacement)
                $fileChanged = $true
                Write-Host "  Fixed in $($file.Name): $key -> $correctRelPath" -ForegroundColor Gray
            }
        }
    }

    # 2. Fix Obsidian Links [[start-here]] or [[start-here|Label]]
    foreach ($k in $ObsidianMap.Keys) {
        $targetCanonical = $ObsidianMap[$k]
        
        # Regex for [[Key]] or [[Key|Label]]
        $pattern = "\[\[$k(\|([^\]]+))?\]\]"
        
        $matches = [regex]::Matches($newContent, $pattern)
        foreach ($m in $matches) {
            $fullMatch = $m.Value
            $customLabel = $m.Groups[2].Value
            $label = if ($customLabel) { $customLabel } else { $k }
            
            $correctRelPath = Get-RelativePath -SourceFile $file.FullName -TargetRelPath $targetCanonical
            
            $replacement = "[$label]($correctRelPath)"
            
            $newContent = $newContent.Replace($fullMatch, $replacement)
            $fileChanged = $true
            Write-Host "  Converted Obsidian Link in $($file.Name): [[$k]] -> $replacement" -ForegroundColor Cyan
        }
    }

    if ($fileChanged) {
        Write-Host "SAVING: $($file.Name)" -ForegroundColor Green
        if ($Apply) {
            Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8
        }
    }
}
