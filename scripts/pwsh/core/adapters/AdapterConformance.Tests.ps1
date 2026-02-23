# Pester v3 compatible — Adapter Conformance Test Suite
# Runs the same contract assertions against ALL platform adapters.
# Goal: ensure new adapters pass the canonical IPlatformAdapter interface.
# See: EASYWAY_AGENTIC_SDLC_MASTER.md §11 (Platform Adapter Pattern)
# PBI #19 — Adapter Conformance Test Suite

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot 'IPlatformAdapter.psm1'
Import-Module $modulePath -Force

# ── Load platform config ─────────────────────────────────────────────────────
$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = (Get-Item $scriptRoot).Parent.Parent.Parent.FullName }
$coreDir = Join-Path $repoRoot 'scripts' 'pwsh' 'core'
Import-Module (Join-Path $coreDir 'PlatformCommon.psm1') -Force
$configPath = Join-Path $repoRoot 'config' 'platform-config.json'
$config = Read-PlatformConfig -ConfigPath $configPath

# ── Dummy headers for instantiation ──────────────────────────────────────────
$dummyHeaders = @{ Authorization = 'Basic dGVzdDp0ZXN0' }

# ═══════════════════════════════════════════════════════════════════════════════
# Contract: Every adapter MUST implement these 4 methods:
#   1. GetApiUrl([string])          → [string]
#   2. QueryWorkItemByTitle([string],[string],[string]) → [object]
#   3. CreateWorkItem([string],[array]) → [object]
#   4. LinkParentChild([int],[int]) → [void]
# ═══════════════════════════════════════════════════════════════════════════════

# ── ADO Adapter Conformance ───────────────────────────────────────────────────

Describe 'AdoAdapter Conformance' {
    $adapter = New-PlatformAdapter -Config $config -Headers $dummyHeaders

    It 'Should instantiate via factory' {
        $adapter | Should Not Be $null
    }

    It 'Should implement GetApiUrl' {
        $url = $adapter.GetApiUrl('/_apis/wit/wiql?api-version=7.0')
        $url | Should Match 'dev\.azure\.com'
        $url | Should Match '_apis/wit/wiql'
    }

    It 'Should implement QueryWorkItemByTitle (returns null for nonexistent)' {
        # Without real token, WIQL will fail gracefully → $null
        $result = $adapter.QueryWorkItemByTitle('Epic', 'NONEXISTENT_TITLE_12345', 'test-prd')
        $result | Should Be $null
    }

    It 'Should implement CreateWorkItem method signature' {
        $method = $adapter.GetType().GetMethod('CreateWorkItem')
        $method | Should Not Be $null
        $method.GetParameters().Count | Should Be 2
    }

    It 'Should implement LinkParentChild method signature' {
        $method = $adapter.GetType().GetMethod('LinkParentChild')
        $method | Should Not Be $null
        $method.GetParameters().Count | Should Be 2
    }
}

# ── GitHub Adapter Conformance (Stub) ────────────────────────────────────────

Describe 'GitHubAdapter Conformance (Stub)' {
    $ghConfig = [PSCustomObject]@{
        platform   = 'github'
        connection = @{ baseUrl = 'https://api.github.com'; project = 'test-repo' }
    }
    $adapter = New-PlatformAdapter -Config $ghConfig -Headers $dummyHeaders

    It 'Should instantiate' {
        $adapter | Should Not Be $null
    }

    It 'GetApiUrl should throw NotImplemented' {
        $threw = $false
        try { $adapter.GetApiUrl('/test') } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'QueryWorkItemByTitle should throw NotImplemented' {
        $threw = $false
        try { $adapter.QueryWorkItemByTitle('Issue', 'test', 'prd') } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'CreateWorkItem should throw NotImplemented' {
        $threw = $false
        try { $adapter.CreateWorkItem('Issue', @()) } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'LinkParentChild should throw NotImplemented' {
        $threw = $false
        try { $adapter.LinkParentChild(1, 2) } catch { $threw = $true }
        $threw | Should Be $true
    }
}

# ── BusinessMap Adapter Conformance (Stub) ───────────────────────────────────

Describe 'BusinessMapAdapter Conformance (Stub)' {
    $bmConfig = [PSCustomObject]@{
        platform   = 'businessmap'
        connection = @{ baseUrl = 'https://api.businessmap.io'; project = 'test' }
    }
    $adapter = New-PlatformAdapter -Config $bmConfig -Headers $dummyHeaders

    It 'Should instantiate' {
        $adapter | Should Not Be $null
    }

    It 'GetApiUrl should throw NotImplemented' {
        $threw = $false
        try { $adapter.GetApiUrl('/test') } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'QueryWorkItemByTitle should throw NotImplemented' {
        $threw = $false
        try { $adapter.QueryWorkItemByTitle('Card', 'test', 'prd') } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'CreateWorkItem should throw NotImplemented' {
        $threw = $false
        try { $adapter.CreateWorkItem('Card', @()) } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'LinkParentChild should throw NotImplemented' {
        $threw = $false
        try { $adapter.LinkParentChild(1, 2) } catch { $threw = $true }
        $threw | Should Be $true
    }
}

# ── Factory Conformance ──────────────────────────────────────────────────────

Describe 'Factory Pattern Conformance' {
    It 'Should create AdoAdapter for ado platform' {
        $a = New-PlatformAdapter -Config $config -Headers $dummyHeaders
        $a.GetType().Name | Should Be 'AdoAdapter'
    }

    It 'Should throw for unknown platform' {
        $badConfig = [PSCustomObject]@{ platform = 'nonexistent' }
        $threw = $false
        try { New-PlatformAdapter -Config $badConfig -Headers $dummyHeaders } catch { $threw = $true }
        $threw | Should Be $true
    }
}

# ── Build-AdoJsonPatch Conformance ───────────────────────────────────────────

Describe 'Build-AdoJsonPatch Conformance' {
    It 'Should always include Title field' {
        $patch = @(Build-AdoJsonPatch -Title 'Test')
        ($patch | Where-Object { $_.path -eq '/fields/System.Title' }).value | Should Be 'Test'
    }

    It 'Should include all optional fields when provided' {
        $patch = @(Build-AdoJsonPatch `
                -Title 'Full Test' `
                -Description 'Desc' `
                -AcceptanceCriteria 'AC' `
                -AreaPath '\TestProject' `
                -IterationPath '\TestProject\Sprint 1' `
                -Tags @('Tag1', 'Tag2') `
                -Effort 5 `
                -Priority 2 `
                -BusinessValue 'High' `
                -TargetDate '2026-04-01')

        $patch.Count | Should Be 10
        ($patch | Where-Object { $_.path -eq '/fields/Microsoft.VSTS.Scheduling.Effort' }).value | Should Be 5
        ($patch | Where-Object { $_.path -eq '/fields/Microsoft.VSTS.Common.Priority' }).value | Should Be 2
        ($patch | Where-Object { $_.path -eq '/fields/Microsoft.VSTS.Common.BusinessValue' }).value | Should Be 'High'
        ($patch | Where-Object { $_.path -eq '/fields/Microsoft.VSTS.Scheduling.TargetDate' }).value | Should Be '2026-04-01'
    }

    It 'Should omit empty optional fields' {
        $patch = @(Build-AdoJsonPatch -Title 'Minimal')
        $patch.Count | Should Be 1
    }
}
