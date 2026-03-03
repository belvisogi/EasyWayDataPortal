<#
  Publish-WikiPages.ps1 — skill wiki.publish

  End-to-end wiki publishing: detect changes, branch, commit, push, PR, reindex.
  Eliminates the 6-step manual friction that costs 15+ minutes per session.

  FLOW:
    1. Detect new/modified files under Wiki/EasyWayData.wiki/
    2. Create branch docs/wiki-<slug> from develop
    3. git add + commit (Iron Dome pre-commit)
    4. git push -u origin
    5. Create PR via ADO API (docs/* -> develop)
    6. (Optional -Reindex) SSH to server -> git fetch + Qdrant re-index

  USAGE:
    # Dry-run: show what would be committed and PR'd
    pwsh scripts/pwsh/Publish-WikiPages.ps1 -WhatIf

    # Full publish: commit, push, create PR
    pwsh scripts/pwsh/Publish-WikiPages.ps1

    # With custom slug and reindex
    pwsh scripts/pwsh/Publish-WikiPages.ps1 -Slug "hale-bopp-docs" -Reindex

    # Machine-readable output
    pwsh scripts/pwsh/Publish-WikiPages.ps1 -Json

  REGISTERED IN: agents/skills/registry.json -> wiki.publish
#>

param(
    [string] $Slug        = "",           # branch suffix; auto-generated if empty
    [string] $CommitMsg   = "",           # custom commit message; auto-generated if empty
    [string] $WikiPath    = "Wiki/EasyWayData.wiki",
    [string] $BaseBranch  = "develop",
    [string] $Pat         = ($env:ADO_PR_CREATOR_PAT ?? $env:AZURE_DEVOPS_EXT_PAT),
    [string] $SshKey      = "C:\old\Virtual-machine\ssh-key-2026-01-25.key",
    [string] $ServerHost  = "ubuntu@80.225.86.168",
    [switch] $Reindex,                    # SSH to server and re-index Qdrant after PR creation
    [switch] $WhatIf,                     # show plan without executing
    [switch] $Json                        # machine-readable output
)

$ErrorActionPreference = 'Stop'

# ── ADO constants ────────────────────────────────────────────────────────────
$OrgUrl   = 'https://dev.azure.com/EasyWayData'
$Project  = 'EasyWay-DataPortal'
$RepoId   = 'EasyWayDataPortal'

# ── Helpers ──────────────────────────────────────────────────────────────────
function Write-Step([string]$msg) {
    if (-not $Json) { Write-Host "  -> $msg" -ForegroundColor Cyan }
}
function Write-Ok([string]$msg) {
    if (-not $Json) { Write-Host "  OK $msg" -ForegroundColor Green }
}
function Write-Warn([string]$msg) {
    if (-not $Json) { Write-Host "  !! $msg" -ForegroundColor Yellow }
}

# ── Load PAT ─────────────────────────────────────────────────────────────────
if (-not $Pat) {
    $envFile = 'C:\old\.env.local'
    if (Test-Path $envFile) {
        $lines = Get-Content $envFile
        $line = $lines | Where-Object { $_ -match '^ADO_PR_CREATOR_PAT=' } | Select-Object -First 1
        if (-not $line) {
            $line = $lines | Where-Object { $_ -match '^AZURE_DEVOPS_EXT_PAT=' } | Select-Object -First 1
        }
        if ($line) { $Pat = ($line -split '=', 2)[1].Trim().Trim('"') }
    }
}
if (-not $Pat) {
    Write-Error "PAT non trovato. Impostare ADO_PR_CREATOR_PAT o AZURE_DEVOPS_EXT_PAT."
    exit 1
}

$bytes   = [System.Text.Encoding]::UTF8.GetBytes(":$Pat")
$b64     = [System.Convert]::ToBase64String($bytes)
$headers = @{ Authorization = "Basic $b64"; 'Content-Type' = 'application/json' }

# ── Repo root ────────────────────────────────────────────────────────────────
$repoRoot = git rev-parse --show-toplevel 2>$null
if (-not $repoRoot) {
    Write-Error "Non sei in un repository git."
    exit 1
}
Push-Location $repoRoot

try {
    # ── Step 1: Detect wiki changes ──────────────────────────────────────────
    Write-Step "Scanning wiki changes..."

    # Untracked files under Wiki/
    $untracked = git ls-files --others --exclude-standard -- $WikiPath 2>$null
    # Modified tracked files under Wiki/
    $modified  = git diff --name-only -- $WikiPath 2>$null
    # Staged files under Wiki/
    $staged    = git diff --cached --name-only -- $WikiPath 2>$null

    $allChanges = @()
    if ($untracked) { $allChanges += $untracked }
    if ($modified)  { $allChanges += $modified }
    if ($staged)    { $allChanges += $staged }
    $allChanges = $allChanges | Select-Object -Unique | Sort-Object

    if ($allChanges.Count -eq 0) {
        if ($Json) {
            @{ status = "no_changes"; message = "No wiki changes detected" } | ConvertTo-Json
        } else {
            Write-Host "  No wiki changes detected under $WikiPath" -ForegroundColor Yellow
        }
        exit 0
    }

    Write-Ok "Found $($allChanges.Count) wiki file(s) to publish"

    # Auto-generate slug from changed directories
    if (-not $Slug) {
        $dirs = $allChanges | ForEach-Object {
            $parts = $_ -replace '^Wiki/EasyWayData.wiki/', '' -split '/'
            if ($parts.Count -gt 1) { $parts[0] } else { 'general' }
        } | Select-Object -Unique
        $Slug = ($dirs -join '-').ToLower() -replace '[^a-z0-9-]', ''
        if ($Slug.Length -gt 30) { $Slug = $Slug.Substring(0, 30).TrimEnd('-') }
    }

    $branchName = "docs/wiki-$Slug"

    # Auto-generate commit message
    if (-not $CommitMsg) {
        $fileCount = $allChanges.Count
        $CommitMsg = "docs(wiki): publish $fileCount page(s) under $($dirs -join ', ')"
    }

    # ── Step 2: WhatIf — show plan ──────────────────────────────────────────
    if ($WhatIf) {
        if ($Json) {
            @{
                whatIf     = $true
                branch     = $branchName
                baseBranch = $BaseBranch
                commitMsg  = $CommitMsg
                files      = $allChanges
                fileCount  = $allChanges.Count
                reindex    = [bool]$Reindex
            } | ConvertTo-Json -Depth 3
        } else {
            Write-Host ""
            Write-Host "--- DRY RUN --- nessuna modifica eseguita ---" -ForegroundColor Magenta
            Write-Host "  Branch   : $branchName (from $BaseBranch)" -ForegroundColor White
            Write-Host "  Commit   : $CommitMsg" -ForegroundColor White
            Write-Host "  Files ($($allChanges.Count)):" -ForegroundColor White
            foreach ($f in $allChanges) {
                Write-Host "    + $f" -ForegroundColor Green
            }
            Write-Host "  Reindex  : $(if ($Reindex) { 'YES' } else { 'no (use -Reindex)' })" -ForegroundColor $(if ($Reindex) { 'Green' } else { 'DarkGray' })
            Write-Host ""
        }
        exit 0
    }

    # ── Step 3: Create branch from develop ───────────────────────────────────
    Write-Step "Fetching $BaseBranch and creating branch $branchName..."

    $currentBranch = git branch --show-current
    $needsStash = $false

    # Stash any non-wiki changes to avoid carrying them
    $nonWikiModified = git diff --name-only 2>$null | Where-Object { $_ -notlike "$WikiPath/*" }
    if ($nonWikiModified) {
        Write-Step "Stashing non-wiki changes..."
        git stash push -m "wiki-publish-temp" -- $nonWikiModified 2>$null
        $needsStash = $true
    }

    git fetch origin $BaseBranch --quiet 2>$null

    # Check if branch already exists
    $existing = git branch --list $branchName
    if ($existing) {
        git checkout $branchName 2>$null
    } else {
        git checkout -b $branchName "origin/$BaseBranch" 2>$null
    }

    Write-Ok "On branch $branchName"

    # ── Step 4: Stage + commit ───────────────────────────────────────────────
    Write-Step "Staging $($allChanges.Count) wiki files..."

    foreach ($f in $allChanges) {
        git add $f
    }

    Write-Step "Committing..."
    $fullMsg = "$CommitMsg`n`nCo-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
    git commit -m $fullMsg 2>&1 | ForEach-Object {
        if (-not $Json) { Write-Host "    $_" -ForegroundColor DarkGray }
    }

    Write-Ok "Committed"

    # ── Step 5: Push ─────────────────────────────────────────────────────────
    Write-Step "Pushing to origin..."
    git push -u origin $branchName 2>&1 | ForEach-Object {
        if (-not $Json) { Write-Host "    $_" -ForegroundColor DarkGray }
    }

    Write-Ok "Pushed $branchName"

    # ── Step 6: Create PR via ADO API ────────────────────────────────────────
    Write-Step "Creating PR on ADO..."

    $prBody = @{
        sourceRefName = "refs/heads/$branchName"
        targetRefName = "refs/heads/$BaseBranch"
        title         = $CommitMsg
        description   = "Auto-published wiki pages:`n`n$($allChanges | ForEach-Object { "- $_" } | Out-String)"
    } | ConvertTo-Json -Depth 3

    $prUrl  = $null
    $prId   = $null

    try {
        $apiUrl = "$OrgUrl/$Project/_apis/git/repositories/$RepoId/pullrequests?api-version=7.1"
        $resp   = Invoke-RestMethod -Uri $apiUrl -Method Post -Body $prBody -Headers $headers
        $prId   = $resp.pullRequestId
        $prUrl  = "$OrgUrl/$Project/_git/$RepoId/pullrequest/$prId"
        Write-Ok "PR #$prId created: $prUrl"
    } catch {
        Write-Warn "PR creation failed: $($_.Exception.Message)"
        Write-Warn "Branch pushed — create PR manually on ADO."
    }

    # ── Step 7 (optional): Reindex Qdrant ────────────────────────────────────
    $reindexResult = $null
    if ($Reindex) {
        Write-Step "SSH to server for Qdrant re-index..."
        Write-Warn "Note: re-index reads from main branch. Merge PR first for new content."

        $sshCmd = "source /opt/easyway/.env.secrets && cd ~/EasyWayDataPortal && QDRANT_API_KEY=`$QDRANT_API_KEY WIKI_PATH=Wiki node scripts/ingest_wiki.js 2>&1 | tail -3"
        try {
            $sshExe = "C:\Windows\System32\OpenSSH\ssh.exe"
            $output = & $sshExe -i $SshKey -o StrictHostKeyChecking=no $ServerHost $sshCmd 2>&1
            $reindexResult = $output -join "`n"
            Write-Ok "Qdrant re-index output: $reindexResult"
        } catch {
            Write-Warn "Reindex failed: $($_.Exception.Message)"
            $reindexResult = "FAILED: $($_.Exception.Message)"
        }
    }

    # ── Restore previous state ───────────────────────────────────────────────
    if ($needsStash) {
        Write-Step "Restoring stashed changes..."
        git stash pop 2>$null
    }

    # ── Output ───────────────────────────────────────────────────────────────
    $result = @{
        status       = "published"
        branch       = $branchName
        baseBranch   = $BaseBranch
        commitMsg    = $CommitMsg
        files        = $allChanges
        fileCount    = $allChanges.Count
        prId         = $prId
        prUrl        = $prUrl
        reindex      = $reindexResult
    }

    if ($Json) {
        $result | ConvertTo-Json -Depth 5
    } else {
        Write-Host ""
        Write-Host "--- Wiki Published ---" -ForegroundColor Green
        Write-Host "  Branch : $branchName" -ForegroundColor White
        Write-Host "  Files  : $($allChanges.Count)" -ForegroundColor White
        if ($prUrl) {
            Write-Host "  PR     : $prUrl" -ForegroundColor Cyan
        }
        if ($Reindex) {
            Write-Host "  Reindex: $reindexResult" -ForegroundColor White
        }
        Write-Host ""
    }

} finally {
    Pop-Location
}
