param(
    [string]$WikiRoot = "Wiki/EasyWayData.wiki",
    [switch]$Apply
)

# Rules for moved files. Order matters (specific first).
$rules = @(
    @{ Pattern = 'ADA Reference Architecture\.pdf'; Replace = 'docs/architecture/ADA Reference Architecture.pdf' },
    @{ Pattern = 'ADA Reference Architecture\.pptx'; Replace = 'docs/architecture/ADA Reference Architecture.pptx' },
    @{ Pattern = 'ADA_Reference_Architecture_text\.txt'; Replace = 'docs/architecture/ADA_Reference_Architecture_text.txt' },
    
    @{ Pattern = 'DR_Plan_ADA\.docx'; Replace = 'docs/disaster-recovery/DR_Plan_ADA.docx' },
    
    @{ Pattern = 'AGENTS\.md'; Replace = 'docs/project-root/AGENTS.md' },
    @{ Pattern = 'ANTI_PHILOSOPHY_STARTER_KIT\.md'; Replace = 'docs/project-root/ANTI_PHILOSOPHY_STARTER_KIT.md' },
    @{ Pattern = 'DEVELOPER_ONBOARDING\.md'; Replace = 'docs/project-root/DEVELOPER_ONBOARDING.md' },
    @{ Pattern = 'DEVELOPER_START_HERE\.md'; Replace = 'docs/project-root/DEVELOPER_START_HERE.md' },
    @{ Pattern = 'Sintesi_EasyWayDataPortal\.md'; Replace = 'docs/project-root/Sintesi_EasyWayDataPortal.md' },
    @{ Pattern = 'VALUTAZIONE_EasyWayDataPortal\.md'; Replace = 'docs/project-root/VALUTAZIONE_EasyWayDataPortal.md' },
    
    @{ Pattern = 'home_easyway\.html'; Replace = 'docs/assets/home_easyway.html' },
    @{ Pattern = 'palette_EasyWay\.html'; Replace = 'docs/assets/palette_EasyWay.html' },
    @{ Pattern = 'logo\.png'; Replace = 'docs/assets/logo.png' }
)

$files = Get-ChildItem -Path $WikiRoot -Recurse -Filter *.md

foreach ($file in $files) {
    $content = Get-Content -LiteralPath $file.FullName -Raw -Encoding UTF8
    $newContent = $content
    $fileChanged = $false

    foreach ($rule in $rules) {
        # Regex to match relative links like ../../FILE or just FILE inside []()
        # Capturing group 1: any ../ prefix
        # We need to make sure we don't double-replace already fixed paths
        
        $p = $rule.Pattern
        $r = $rule.Replace
        
        # Pattern A: Standard links [Label](path/FILE)
        # We look for the filename in the link part
        # Avoid matching if it already contains the target folder
        $regex = "(?<!docs/architecture/)(?<!docs/disaster-recovery/)(?<!docs/project-root/)(?<!docs/assets/)((\.\./)*$p)"
        
        if ($newContent -match $regex) {
            # Replacement: 
            # We want to replace paths like "../../ADA..." with "../../docs/architecture/ADA..."
            # BUT we need to be careful with depth. 
            # A simple safe approach for Root moves: replace "filename" with "docs/sub/filename" globally in links
            # and let the existing ../.. handle the root navigation if present?
            # Problem: if previously it was local "../../ADA" (from 2 levels deep to root),
            # now root is clean, so it must be "../../docs/architecture/ADA".
            # So effectively we just insert the subfolder before the filename.
            
            $newContent = $newContent -replace $regex, "$1".Replace($p.Replace('\.', '.'), $r)
            
            # Fix double slashes if any happened (simple cleanup)
            $newContent = $newContent.Replace("//", "/")
            $fileChanged = $true
        }
    }
    
    # Special Fix for [[start-here|Home]] which is broken because start-here doesn't exist?
    # Actually DEVELOPER_START_HERE.md is the file. 
    # If wiki has [[start-here]], it might expect a file named start-here.md.
    # We should fix these to point to [[DEVELOPER_START_HERE]] if that's the intent.
    
    if ($fileChanged) {
        Write-Host "MODIFIED: $($file.Name)" -ForegroundColor Green
        if ($Apply) {
            Set-Content -LiteralPath $file.FullName -Value $newContent -Encoding UTF8
        }
    }
}
