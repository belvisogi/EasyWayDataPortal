<#
.SYNOPSIS
    Send a message to Slack channel via webhook

.DESCRIPTION
    Sends formatted messages to Slack using incoming webhooks.
    Supports markdown formatting and severity-based colors.

.PARAMETER WebhookUrl
    Slack incoming webhook URL (or use env var SLACK_WEBHOOK_URL)

.PARAMETER Message
    Message text (supports Slack markdown)

.PARAMETER Channel
    Channel override (optional)

.PARAMETER Severity
    Message severity for color coding: info, warning, error, critical

.EXAMPLE
    Send-SlackMessage -Message "Deployment completed" -Severity "info"

.EXAMPLE
    Send-SlackMessage -Message "CVE found in n8n" -Severity "critical" -WebhookUrl $url
#>
function Send-SlackMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$WebhookUrl = $env:SLACK_WEBHOOK_URL,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Channel,

        [Parameter(Mandatory = $false)]
        [ValidateSet("info", "warning", "error", "critical")]
        [string]$Severity = "info"
    )

    try {
        if (-not $WebhookUrl) {
            throw "No webhook URL provided. Set SLACK_WEBHOOK_URL env var or pass -WebhookUrl"
        }

        # Security: only allow Slack's official webhook domain to prevent data exfiltration
        $allowedHosts = @('hooks.slack.com')
        try {
            $parsedUri = [System.Uri]$WebhookUrl
            if ($parsedUri.Host -notin $allowedHosts) {
                throw "SECURITY_VIOLATION: WebhookUrl host '$($parsedUri.Host)' is not in the allowlist ($($allowedHosts -join ', '))"
            }
            if ($parsedUri.Scheme -ne 'https') {
                throw "SECURITY_VIOLATION: WebhookUrl must use HTTPS"
            }
        }
        catch [System.UriFormatException] {
            throw "Invalid WebhookUrl format: $WebhookUrl"
        }

        $color = switch ($Severity) {
            "info"     { "#36a64f" }  # green
            "warning"  { "#ffc107" }  # yellow
            "error"    { "#ff5722" }  # orange
            "critical" { "#dc3545" }  # red
        }

        $emoji = switch ($Severity) {
            "info"     { ":white_check_mark:" }
            "warning"  { ":warning:" }
            "error"    { ":x:" }
            "critical" { ":rotating_light:" }
        }

        $payload = @{
            attachments = @(
                @{
                    color = $color
                    text = "$emoji $Message"
                    footer = "EasyWay Agent Framework | $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
                }
            )
        }

        if ($Channel) {
            $payload.channel = $Channel
        }

        $json = $payload | ConvertTo-Json -Depth 5 -Compress
        $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $json -ContentType "application/json"

        return [PSCustomObject]@{
            Success = $true
            Severity = $Severity
            Channel = if ($Channel) { $Channel } else { "default" }
            Timestamp = Get-Date -Format "o"
        }

    } catch {
        Write-Warning "Slack notification failed: $_"
        return [PSCustomObject]@{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "o"
        }
    }
}
