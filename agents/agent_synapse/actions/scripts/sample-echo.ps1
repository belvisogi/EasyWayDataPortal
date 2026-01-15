param(
    [string]$IntentJson
)

Write-Host "Echo Action: $IntentJson"

if ($IntentJson) {
    $intent = $IntentJson | ConvertFrom-Json
    return @{
        status    = "ok"
        output    = "Echo: " + $intent.message
        timestamp = (Get-Date).ToString("o")
    }
}
else {
    return @{ status = "error"; message = "No input" }
}
