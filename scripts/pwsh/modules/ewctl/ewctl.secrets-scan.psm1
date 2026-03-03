<#
  ewctl.secrets-scan — Iron Dome pre-commit secrets guard.
  Lightweight check on staged files only. Blocks commit on CRITICAL findings.
  Full scan: pwsh agents/skills/security/Invoke-SecretsScan.ps1
#>

function Test-StagedFilesForSecrets {
    [CmdletBinding()]
    param()

    $criticalPatterns = @(
        @{ Name = 'Private Key';       Pattern = '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----' }
        @{ Name = 'GitHub PAT';        Pattern = 'ghp_[A-Za-z0-9]{36}|github_pat_[A-Za-z0-9_]{60,}' }
        @{ Name = 'OpenRouter Key';    Pattern = 'sk-or-v1-[a-f0-9]{64}' }
        @{ Name = 'DeepSeek Key';      Pattern = 'sk-[a-f0-9]{32,}' }
        @{ Name = 'Hardcoded Password'; Pattern = '(?i)(password|passwd)\s*[:=]\s*["\x27][^"\x27$]{8,}["\x27]' }
    )

    # Safe patterns that indicate variable references, not actual leaks
    $safePatterns = @(
        '\$\{[A-Z_]+\}',
        '\$env:[A-Z_]+',
        'ChangeMe',
        'placeholder',
        '<PASTE_',
        '<REDACTED>',
        'UNKNOWN_PLEASE',
        '\*\*\*REDACTED\*\*\*',
        'vedi .*/\.env',
        '\.env\.example'
    )

    $stagedFiles = git diff --name-only --cached 2>$null
    if (-not $stagedFiles) { return @{ Passed = $true; Findings = @() } }

    $findings = @()

    foreach ($file in $stagedFiles) {
        if (-not (Test-Path $file -PathType Leaf)) { continue }

        # Skip binary and example files
        if ($file -match '\.(png|jpg|gif|ico|woff|zip|gz|exe|dll|pdf)$') { continue }
        if ($file -match '\.env\.(example|.*\.example)$') { continue }
        if ($file -match 'package-lock\.json$') { continue }

        # Skip files > 500KB
        $info = Get-Item $file
        if ($info.Length -gt 524288) { continue }

        try {
            $lines = Get-Content $file -ErrorAction SilentlyContinue
        }
        catch { continue }
        if (-not $lines) { continue }

        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i]
            if (-not $line -or $line.Length -lt 10) { continue }

            foreach ($cp in $criticalPatterns) {
                if ($line -match $cp.Pattern) {
                    # Check safe patterns
                    $isSafe = $false
                    foreach ($sp in $safePatterns) {
                        if ($line -match $sp) { $isSafe = $true; break }
                    }
                    if ($isSafe) { continue }

                    $findings += @{
                        Pattern = $cp.Name
                        File    = $file
                        Line    = $i + 1
                    }
                }
            }
        }
    }

    if ($findings.Count -gt 0) {
        return @{ Passed = $false; Findings = $findings }
    }
    return @{ Passed = $true; Findings = @() }
}

Export-ModuleMember -Function Test-StagedFilesForSecrets
