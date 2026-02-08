<#
.SYNOPSIS
    Manage secrets in Azure Key Vault

.DESCRIPTION
    Set, get references, and rotate secrets in Azure Key Vault.
    Never returns actual secret values - only metadata and references.

.PARAMETER Operation
    Operation: "set", "reference", "list", "rotate"

.PARAMETER VaultName
    Azure Key Vault name

.PARAMETER SecretName
    Secret name (pattern: <system>--<area>--<name>)

.PARAMETER SecretValue
    Secret value (only for "set" operation, never logged)

.PARAMETER Tags
    Optional tags hashtable

.EXAMPLE
    Invoke-SecretVault -Operation "reference" -VaultName "easyway-kv" -SecretName "db--portal--connstring"

.EXAMPLE
    Invoke-SecretVault -Operation "set" -VaultName "easyway-kv" -SecretName "db--portal--password" -SecretValue $pwd
#>
function Invoke-SecretVault {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet("set", "reference", "list", "rotate")]
        [string]$Operation,

        [Parameter(Mandatory = $true)]
        [string]$VaultName,

        [Parameter(Mandatory = $false)]
        [string]$SecretName,

        [Parameter(Mandatory = $false)]
        [string]$SecretValue,

        [Parameter(Mandatory = $false)]
        [hashtable]$Tags = @{}
    )

    try {
        # Verify az CLI is available
        if (-not (Get-Command "az" -ErrorAction SilentlyContinue)) {
            throw "Azure CLI (az) not found. Install it first."
        }

        switch ($Operation) {
            "set" {
                if (-not $SecretName -or -not $SecretValue) {
                    throw "SecretName and SecretValue are required for 'set' operation"
                }

                # Validate naming convention
                if ($SecretName -notmatch '^[\w]+--[\w]+--[\w-]+$') {
                    Write-Warning "SecretName '$SecretName' doesn't follow pattern: <system>--<area>--<name>"
                }

                $result = az keyvault secret set --vault-name $VaultName --name $SecretName --value $SecretValue 2>&1
                if ($LASTEXITCODE -ne 0) { throw "Failed to set secret: $result" }

                # Add tags if provided
                if ($Tags.Count -gt 0) {
                    $tagStr = ($Tags.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join " "
                    az keyvault secret set-attributes --vault-name $VaultName --name $SecretName --tags $tagStr 2>&1 | Out-Null
                }

                return [PSCustomObject]@{
                    Operation = "set"
                    VaultName = $VaultName
                    SecretName = $SecretName
                    Status = "success"
                    Note = "Secret value NOT logged for security"
                    Timestamp = Get-Date -Format "o"
                }
            }
            "reference" {
                if (-not $SecretName) { throw "SecretName is required for 'reference' operation" }

                $ref = "@Microsoft.KeyVault(VaultName=$VaultName;SecretName=$SecretName)"

                return [PSCustomObject]@{
                    Operation = "reference"
                    VaultName = $VaultName
                    SecretName = $SecretName
                    Reference = $ref
                    Usage = "Use this in App Settings to reference the Key Vault secret"
                }
            }
            "list" {
                $secrets = az keyvault secret list --vault-name $VaultName --query "[].{name:name, enabled:attributes.enabled, updated:attributes.updated}" -o json 2>&1
                if ($LASTEXITCODE -ne 0) { throw "Failed to list secrets: $secrets" }

                return $secrets | ConvertFrom-Json
            }
            "rotate" {
                if (-not $SecretName) { throw "SecretName is required for 'rotate' operation" }

                # Generate new password
                $newPassword = -join ((65..90) + (97..122) + (48..57) + (33, 35, 36, 37, 38, 42) | Get-Random -Count 32 | ForEach-Object { [char]$_ })

                $result = az keyvault secret set --vault-name $VaultName --name $SecretName --value $newPassword 2>&1
                if ($LASTEXITCODE -ne 0) { throw "Failed to rotate secret: $result" }

                return [PSCustomObject]@{
                    Operation = "rotate"
                    VaultName = $VaultName
                    SecretName = $SecretName
                    Status = "rotated"
                    Note = "New value NOT logged. Update all consumers."
                    Timestamp = Get-Date -Format "o"
                }
            }
        }
    } catch {
        Write-Error "SecretVault operation failed: $_"
        throw
    }
}
