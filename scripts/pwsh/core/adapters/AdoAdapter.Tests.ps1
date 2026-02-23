#Requires -Modules Pester
<#
.SYNOPSIS
    Pester tests for AdoAdapter.psm1 (Pester v3 + PS v5 compatible).
.DESCRIPTION
    Tests AdoAdapter URL construction and Build-AdoJsonPatch field mapping.

    DESIGN NOTE: PowerShell v5 classes defined in .psm1 modules are NOT visible
    to callers. All class-dependent code runs inside scriptblocks that import
    the modules, execute the code, and return primitive values for assertion.
.NOTES
    Run: Invoke-Pester -Path "scripts/pwsh/core/adapters/AdoAdapter.Tests.ps1" -Verbose
#>

# Absolute paths for module imports inside scriptblocks
$script:CommonModule = "$PSScriptRoot/../PlatformCommon.psm1"
$script:FactoryModule = "$PSScriptRoot/IPlatformAdapter.psm1"
$script:AdoModule = "$PSScriptRoot/AdoAdapter.psm1"

# Helper: executes code in a scope where modules and classes are available
function Invoke-InAdapterScope {
    param([scriptblock]$Code, [object[]]$Arguments)
    & {
        Import-Module $script:CommonModule  -Force
        Import-Module $script:FactoryModule -Force
        Import-Module $script:AdoModule     -Force
        & $args[0] @($args[1..($args.Count - 1)])
    } $Code @Arguments
}

Describe 'AdoAdapter URL Construction' {
    It 'Should build correct WIQL URL' {
        $url = Invoke-InAdapterScope {
            $config = [PSCustomObject]@{
                platform          = 'ado'
                connection        = [PSCustomObject]@{ baseUrl = 'https://dev.azure.com/EasyWayData'; project = 'EasyWay-DataPortal'; apiVersion = '7.0' }
                auth              = [PSCustomObject]@{ method = 'pat'; envVariable = 'X'; headerScheme = 'Basic' }
                workItemHierarchy = [PSCustomObject]@{ chain = @([PSCustomObject]@{ level = 1; type = 'Epic'; prefix = '[Epic]' }); parentChildLinkType = 'System.LinkTypes.Hierarchy-Reverse' }
            }
            $headers = @{ Authorization = 'Basic dGVzdA==' }
            $adapter = New-PlatformAdapter -Config $config -Headers $headers
            return $adapter.GetApiUrl('/_apis/wit/wiql?api-version=7.0')
        }
        $url | Should Be 'https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/wiql?api-version=7.0'
    }

    It 'Should build correct work item creation URL' {
        $url = Invoke-InAdapterScope {
            $config = [PSCustomObject]@{
                platform          = 'ado'
                connection        = [PSCustomObject]@{ baseUrl = 'https://dev.azure.com/EasyWayData'; project = 'EasyWay-DataPortal'; apiVersion = '7.0' }
                auth              = [PSCustomObject]@{ method = 'pat'; envVariable = 'X'; headerScheme = 'Basic' }
                workItemHierarchy = [PSCustomObject]@{ chain = @([PSCustomObject]@{ level = 1; type = 'Epic'; prefix = '[Epic]' }); parentChildLinkType = 'System.LinkTypes.Hierarchy-Reverse' }
            }
            $headers = @{ Authorization = 'Basic dGVzdA==' }
            $adapter = New-PlatformAdapter -Config $config -Headers $headers
            return $adapter.GetApiUrl('/_apis/wit/workitems/$Epic?api-version=7.0')
        }
        $url | Should Be 'https://dev.azure.com/EasyWayData/EasyWay-DataPortal/_apis/wit/workitems/$Epic?api-version=7.0'
    }

    It 'Should URL-encode project name with special chars' {
        $url = Invoke-InAdapterScope {
            $config = [PSCustomObject]@{
                platform          = 'ado'
                connection        = [PSCustomObject]@{ baseUrl = 'https://dev.azure.com/Org'; project = 'My Project (v2)'; apiVersion = '7.0' }
                auth              = [PSCustomObject]@{ method = 'pat'; envVariable = 'X'; headerScheme = 'Basic' }
                workItemHierarchy = [PSCustomObject]@{ chain = @([PSCustomObject]@{ level = 1; type = 'Epic'; prefix = '[Epic]' }) }
            }
            $headers = @{ Authorization = 'Basic dGVzdA==' }
            $adapter = New-PlatformAdapter -Config $config -Headers $headers
            return $adapter.GetApiUrl('/_apis/wit/workitems?api-version=7.0')
        }
        $url | Should BeLike '*My%20Project%20%28v2%29*'
    }

    It 'Should confirm adapter platform is ado' {
        $platform = Invoke-InAdapterScope {
            $config = [PSCustomObject]@{
                platform          = 'ado'
                connection        = [PSCustomObject]@{ baseUrl = 'https://dev.azure.com/Test'; project = 'Test'; apiVersion = '7.0' }
                auth              = [PSCustomObject]@{ method = 'pat'; envVariable = 'X'; headerScheme = 'Basic' }
                workItemHierarchy = [PSCustomObject]@{ chain = @([PSCustomObject]@{ level = 1; type = 'Epic'; prefix = '[Epic]' }); parentChildLinkType = 'System.LinkTypes.Hierarchy-Reverse' }
            }
            $headers = @{ Authorization = 'Basic dGVzdA==' }
            $adapter = New-PlatformAdapter -Config $config -Headers $headers
            return $adapter.Config.platform
        }
        $platform | Should Be 'ado'
    }
}

Describe 'Build-AdoJsonPatch' {
    # Import module in test scope for function access
    Import-Module $script:AdoModule -Force -Global

    It 'Should create patch with title only' {
        $patch = @(Build-AdoJsonPatch -Title 'Test Item')
        $patch.Count | Should Be 1
        $patch[0].path | Should Be '/fields/System.Title'
        $patch[0].value | Should Be 'Test Item'
    }

    It 'Should include description when provided' {
        $patch = Build-AdoJsonPatch -Title 'Item' -Description 'Desc'
        $descOp = $patch | Where-Object { $_.path -eq '/fields/System.Description' }
        $descOp | Should Not BeNullOrEmpty
        $descOp.value | Should Be 'Desc'
    }

    It 'Should include acceptance criteria when provided' {
        $patch = Build-AdoJsonPatch -Title 'Item' -AcceptanceCriteria 'Given/When/Then'
        $acOp = $patch | Where-Object { $_.path -eq '/fields/Microsoft.VSTS.Common.AcceptanceCriteria' }
        $acOp | Should Not BeNullOrEmpty
        $acOp.value | Should Be 'Given/When/Then'
    }

    It 'Should join tags with semicolons' {
        $patch = Build-AdoJsonPatch -Title 'Item' -Tags @('AutoPRD', 'PRD:Phase-9')
        $tagsOp = $patch | Where-Object { $_.path -eq '/fields/System.Tags' }
        $tagsOp | Should Not BeNullOrEmpty
        $tagsOp.value | Should Be 'AutoPRD; PRD:Phase-9'
    }

    It 'Should include all 6 fields when fully specified' {
        $patch = @(Build-AdoJsonPatch `
                -Title 'Full Item' `
                -Description 'Full Description' `
                -AcceptanceCriteria 'AC' `
                -AreaPath '\Project' `
                -IterationPath '\Project\Sprint 1' `
                -Tags @('Tag1', 'Tag2'))

        $patch.Count | Should Be 6
    }
}

Describe 'Adapter Factory Error Handling' {
    It 'Should throw for unsupported platform' {
        $threw = $false
        try {
            Invoke-InAdapterScope {
                $config = [PSCustomObject]@{
                    platform          = 'jira'
                    connection        = [PSCustomObject]@{ baseUrl = 'https://x'; project = 'X'; apiVersion = '3' }
                    auth              = [PSCustomObject]@{ method = 'pat'; envVariable = 'X'; headerScheme = 'Bearer' }
                    workItemHierarchy = [PSCustomObject]@{ chain = @([PSCustomObject]@{ level = 1; type = 'Epic'; prefix = '[Epic]' }) }
                }
                $headers = @{ Authorization = 'Bearer x' }
                New-PlatformAdapter -Config $config -Headers $headers
            }
        }
        catch { $threw = $true }
        $threw | Should Be $true
    }
}
