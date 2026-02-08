<#
.SYNOPSIS
    Execute a script block with retry and exponential backoff

.DESCRIPTION
    Wraps any operation with configurable retry logic and exponential backoff.
    Useful for network calls, API requests, and flaky operations.

.PARAMETER ScriptBlock
    The operation to retry

.PARAMETER MaxRetries
    Maximum number of retries (default: 3)

.PARAMETER InitialDelay
    Initial delay in seconds (default: 2)

.PARAMETER MaxDelay
    Maximum delay in seconds (default: 60)

.PARAMETER RetryableErrors
    Array of error patterns that should trigger retry

.EXAMPLE
    Invoke-RetryBackoff -ScriptBlock { curl https://api.example.com/data } -MaxRetries 3

.EXAMPLE
    Invoke-RetryBackoff -ScriptBlock { az keyvault secret list } -MaxRetries 5 -InitialDelay 5
#>
function Invoke-RetryBackoff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory = $false)]
        [int]$InitialDelay = 2,

        [Parameter(Mandatory = $false)]
        [int]$MaxDelay = 60,

        [Parameter(Mandatory = $false)]
        [string[]]$RetryableErrors = @("timeout", "503", "429", "connection refused", "ECONNRESET")
    )

    $attempt = 0
    $delay = $InitialDelay
    $lastError = $null

    while ($attempt -le $MaxRetries) {
        try {
            $result = & $ScriptBlock

            if ($attempt -gt 0) {
                Write-Verbose "Succeeded on attempt $($attempt + 1) after $attempt retries"
            }

            return [PSCustomObject]@{
                Success = $true
                Result = $result
                Attempts = $attempt + 1
                TotalRetries = $attempt
            }

        } catch {
            $lastError = $_
            $errorMsg = $_.Exception.Message

            # Check if error is retryable
            $isRetryable = $false
            foreach ($pattern in $RetryableErrors) {
                if ($errorMsg -match $pattern) {
                    $isRetryable = $true
                    break
                }
            }

            if (-not $isRetryable -or $attempt -ge $MaxRetries) {
                Write-Warning "Failed after $($attempt + 1) attempts: $errorMsg"
                return [PSCustomObject]@{
                    Success = $false
                    Result = $null
                    Error = $errorMsg
                    Attempts = $attempt + 1
                    TotalRetries = $attempt
                }
            }

            $attempt++
            $jitter = Get-Random -Minimum 0 -Maximum ($delay / 2)
            $actualDelay = [Math]::Min($delay + $jitter, $MaxDelay)

            Write-Verbose "Attempt $attempt failed: $errorMsg. Retrying in ${actualDelay}s..."
            Start-Sleep -Seconds $actualDelay

            $delay = [Math]::Min($delay * 2, $MaxDelay)
        }
    }
}
