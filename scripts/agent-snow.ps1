Param(
    [ValidateSet('snow:incident.list', 'snow:check')]
    [string]$Action,
    [string]$IntentPath,
    [switch]$NonInteractive,
    [switch]$WhatIf,
    [switch]$LogEvent
)

$ErrorActionPreference = 'Stop'
$now = (Get-Date).ToUniversalTime().ToString('o')

function Read-Intent($path) {
    if (-not $path) { return $null }
    if (-not (Test-Path $path)) { throw "Intent file not found: $path" }
    (Get-Content -Raw -Path $path) | ConvertFrom-Json
}

function Get-AxetConfig($Name) {
    $confPath = "$PSScriptRoot/../../config/connections.json"
    $secPath = "$PSScriptRoot/../../config/secrets.json"
    if (-not (Test-Path $confPath)) { return $null }
    $confJson = Get-Content $confPath -Raw | ConvertFrom-Json
    $conns = if ($confJson.connections) { $confJson.connections } else { $confJson }
    if (-not $conns.$Name) { return $null }
    
    $sec = $null
    if (Test-Path $secPath) {
        $secJson = Get-Content $secPath -Raw | ConvertFrom-Json
        $sec = if ($secJson.secrets) { $secJson.secrets } else { $secJson }
    }
    return @{ Config = $conns.$Name; Secret = $sec.$Name }
}

function Out-Result($obj) { 
    $obj | ConvertTo-Json -Depth 8 | Write-Output 
}

try {
    $intent = Read-Intent $IntentPath
    
    # 1. Resolve Connection
    $ConnectionName = $intent?.params?.connectionName
    if (-not $ConnectionName) {
        # Auto-discovery
        $confPath = "$PSScriptRoot/../config/connections.json"
        if (Test-Path $confPath) {
            $allConf = Get-Content $confPath -Raw | ConvertFrom-Json
            $conns = if ($allConf.connections) { $allConf.connections } else { $allConf }
            foreach ($key in $conns.PSObject.Properties.Name) {
                if ($conns.$key.type -eq 'snow' -or $conns.$key.type -eq 'servicenow') {
                    $ConnectionName = $key
                    break
                }
            }
        }
    }

    $InstanceUrl = $intent?.params?.instanceUrl
    $UserName = $null
    $Password = $null

    if ($ConnectionName) {
        $cfg = Get-AxetConfig -Name $ConnectionName
        if (-not $InstanceUrl) { $InstanceUrl = $cfg.Config.instanceUrl }
        $UserName = $cfg.Secret.username
        $Password = $cfg.Secret.password
    }

    if (-not $InstanceUrl) { throw "Missing ServiceNow Instance URL." }

    # 2. Basic Auth
    if ($UserName -and $Password) {
        $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($UserName):$($Password)"))
        $headers = @{ Authorization = ("Basic {0}" -f $base64AuthInfo); Accept = "application/json" }
    }
    else {
        throw "Missing credentials for ServiceNow."
    }

    $output = [ordered]@{ instance = $InstanceUrl }

    switch ($Action) {
        'snow:check' {
            $uri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/incident?sysparm_limit=1"
            $resp = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
            $output.status = "Connection successful"
            $output.testResult = $resp.result
        }
        'snow:incident.list' {
            $limit = if ($intent?.params?.limit) { $intent.params.limit } else { 5 }
            $active = if ($null -ne $intent?.params?.active) { $intent.params.active } else { $true }
            
            $uri = "$($InstanceUrl.TrimEnd('/'))/api/now/table/incident?sysparm_limit=$limit"
            if ($active) { $uri += "&active=true" }
            
            if ($WhatIf) {
                $output.summary = "Would fetch $limit incidents from $InstanceUrl"
                $output.incidents = @()
            }
            else {
                $resp = Invoke-RestMethod -Uri $uri -Method Get -Headers $headers
                $output.incidents = $resp.result | ForEach-Object {
                    [ordered]@{
                        number            = $_.number
                        short_description = $_.short_description
                        state             = $_.state
                        priority          = $_.priority
                        sys_id            = $_.sys_id
                    }
                }
                $output.count = $output.incidents.Count
                $output.summary = "Retrieved $($output.count) incidents"
            }
        }
    }

    $result = [ordered]@{
        action         = $Action
        ok             = $true
        whatIf         = [bool]$WhatIf
        nonInteractive = [bool]$NonInteractive
        correlationId  = $intent?.correlationId
        startedAt      = $now
        finishedAt     = (Get-Date).ToUniversalTime().ToString('o')
        output         = $output
    }
    $result.contractId = 'action-result'
    $result.contractVersion = '1.0'
    Out-Result $result

}
catch {
    $result = [ordered]@{
        action     = $Action
        ok         = $false
        error      = $_.Exception.Message
        startedAt  = $now
        finishedAt = (Get-Date).ToUniversalTime().ToString('o')
    }
    Out-Result $result
}
