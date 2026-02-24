# Agent tiering conformance tests (RBAC + manifest alignment)

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = (Resolve-Path '.').Path }

$rbacPath = 'C:\old\rbac-master.json'

$expected = @(
    @{ Id = 'agent_scrummaster'; Tier = 'L2'; Manifest = 'agents/agent_scrummaster/manifest.json' },
    @{ Id = 'agent_governance'; Tier = 'L3'; Manifest = 'agents/agent_governance/manifest.json' },
    @{ Id = 'agent_infra'; Tier = 'L2'; Manifest = 'agents/agent_infra/manifest.json' },
    @{ Id = 'agent_security'; Tier = 'L3'; Manifest = 'agents/agent_security/manifest.json' },
    @{ Id = 'agent_review'; Tier = 'L3'; Manifest = 'agents/agent_review/manifest.json' }
)

Describe 'Agent Tiering RBAC Conformance' {
    It 'Should have RBAC registry available' {
        (Test-Path $rbacPath) | Should Be $true
    }

    $rbac = Get-Content $rbacPath -Raw | ConvertFrom-Json

    foreach ($entry in $expected) {
        Context $entry.Id {
            It 'Should be registered in RBAC' {
                ($rbac.agents.PSObject.Properties.Name -contains $entry.Id) | Should Be $true
            }

            It 'Should declare tier, allowed_actions, and human_gate_required' {
                $agent = $rbac.agents.($entry.Id)
                $agent.tier | Should Be $entry.Tier
                $agent.allowed_actions | Should Not Be $null
                @($agent.allowed_actions).Count | Should BeGreaterThan 0
                $agent.human_gate_required | Should Not Be $null
            }

            It 'Manifest level should match RBAC tier' {
                $manifestPath = Join-Path $repoRoot $entry.Manifest
                (Test-Path $manifestPath) | Should Be $true
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                $manifest.level | Should Be $entry.Tier
            }
        }
    }
}
