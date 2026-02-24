# Agent L2 formalization conformance tests
# Validates manifest/runners for the currently formalized agent set.

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = (Resolve-Path '.').Path }

$expected = @(
    @{ Id = 'agent_discovery'; Runner = 'discovery-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_backlog_planner'; Runner = 'backlog-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_review'; Runner = 'review-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_release'; Runner = 'release-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_pr_manager'; Runner = 'pr-manager-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_developer'; Runner = 'developer-run.ps1'; Level = 'L2' },
    @{ Id = 'agent_observability'; Runner = 'observability-run.ps1'; Level = 'L2' }
)

Describe 'L2 Agent Formalization Conformance' {
    It 'Should track 7 formalized agents' {
        $expected.Count | Should Be 7
    }

    foreach ($entry in $expected) {
        Context $entry.Id {
            $agentDir = Join-Path $repoRoot 'agents' $entry.Id
            $manifestPath = Join-Path $agentDir 'manifest.json'
            $runnerPath = Join-Path $agentDir $entry.Runner

            It 'Should have manifest.json' {
                (Test-Path $manifestPath) | Should Be $true
            }

            It 'Should have a L2 runner script' {
                (Test-Path $runnerPath) | Should Be $true
            }

            It 'Manifest should declare level L2 and at least one action' {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                $manifest.level | Should Be $entry.Level
                $manifest.actions | Should Not Be $null
            }

            It 'Each declared action should reference an existing runner file' {
                $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
                $actions = $manifest.actions.PSObject.Properties
                $actions.Count | Should Not Be 0

                foreach ($a in $actions) {
                    $runner = $a.Value.runner
                    $runner | Should Not BeNullOrEmpty
                    (Test-Path (Join-Path $agentDir $runner)) | Should Be $true
                }
            }
        }
    }
}
