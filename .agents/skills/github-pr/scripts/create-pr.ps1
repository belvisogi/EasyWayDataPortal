param(
    [Parameter(Mandatory = $true)] [string]$SourceBranch,
    [Parameter(Mandatory = $true)] [string]$TargetBranch,
    [Parameter(Mandatory = $true)] [string]$Title,
    [Parameter(Mandatory = $true)] [string]$Description,
    [Parameter(Mandatory = $true)] [string]$SecurityChecklist,
    [switch]$Draft
)

$token = $env:GITHUB_TOKEN

# Automatically extract owner and repo from the git origin URL
try {
    $remote = git config --get remote.origin.url
    if (-not $remote) { throw "No origin remote found." }

    if ($remote -match "github\.com[:/]([^/]+)/([^/.]+)(?:\.git)?$") {
        $owner = $matches[1]
        $repo = $matches[2]
    }
    else {
        throw "Could not parse GitHub owner and repository from URL: $remote"
    }
}
catch {
    Write-Error "Failed to determine GitHub repository information: $_"
    exit 1
}

if (-not $token) {
    Write-Host "⚠️ GITHUB_TOKEN not found. Falling back to Local Link Mode." -ForegroundColor Yellow
    [System.Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null
    $encodedTitle = [System.Web.HttpUtility]::UrlEncode($Title)
    $encodedBody = [System.Web.HttpUtility]::UrlEncode("$Description`n`n$SecurityChecklist")
    
    $link = "https://github.com/$owner/$repo/compare/$TargetBranch...$SourceBranch`?expand=1&title=$encodedTitle&body=$encodedBody"
    Write-Host "✅ Pull Request link generated successfully!" -ForegroundColor Green
    Write-Host "👉 Automatically Pre-filled URL: $link" -ForegroundColor Cyan
    exit 0
}

$url = "https://api.github.com/repos/$owner/$repo/pulls"

$headers = @{
    "Authorization" = "Bearer $token"
    "Accept"        = "application/vnd.github.v3+json"
}

$bodyObj = @{
    title = $Title
    body  = "$Description`n`n$SecurityChecklist"
    head  = $SourceBranch
    base  = $TargetBranch
    draft = [bool]$Draft
}

$bodyJson = $bodyObj | ConvertTo-Json -Depth 5 -Compress

try {
    $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -Body $bodyJson -ContentType "application/json"
    Write-Host "✅ Pull Request created successfully!" -ForegroundColor Green
    Write-Host "👉 URL: $($response.html_url)" -ForegroundColor Cyan
}
catch {
    Write-Error "❌ API Exception: $_"
    
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $apiError = $reader.ReadToEnd()
        Write-Error "GitHub API Details: $apiError"
    }
    exit 1
}
