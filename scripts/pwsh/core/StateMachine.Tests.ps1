# Pester v3 compatible tests for StateMachine.psm1

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot 'StateMachine.psm1'
Import-Module $modulePath -Force

$repoRoot = (git rev-parse --show-toplevel 2>$null)
if (-not $repoRoot) { $repoRoot = (Get-Item $scriptRoot).Parent.Parent.Parent.FullName }
$smPath = Join-Path $repoRoot 'config' 'state-machine.json'

Describe 'Read-StateMachine' {
    It 'Should load the default state machine' {
        $sm = Read-StateMachine -Path $smPath
        $sm.id | Should Be 'sdlc-default-v1'
        $sm.initialState | Should Be 'DISCOVERY'
    }

    It 'Should throw on missing file' {
        $threw = $false
        try { Read-StateMachine -Path 'C:\nonexistent\sm.json' } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'Should have 11 states' {
        $sm = Read-StateMachine -Path $smPath
        @($sm.states.PSObject.Properties).Count | Should Be 11
    }

    It 'Should have 16 transitions' {
        $sm = Read-StateMachine -Path $smPath
        $sm.transitions.Count | Should Be 16
    }
}

Describe 'New-PipelineContext' {
    $sm = Read-StateMachine -Path $smPath

    It 'Should create context with initial state' {
        $ctx = New-PipelineContext -PrdId 'test-prd' -StateMachine $sm
        $ctx.currentState | Should Be 'DISCOVERY'
        $ctx.prdId | Should Be 'test-prd'
        $ctx.status | Should Be 'running'
    }

    It 'Should have a history entry' {
        $ctx = New-PipelineContext -PrdId 'test-prd' -StateMachine $sm
        $ctx.history.Count | Should Be 1
        $ctx.history[0].trigger | Should Be 'init'
    }

    It 'Should generate unique pipeline IDs' {
        $ctx1 = New-PipelineContext -PrdId 'a' -StateMachine $sm
        $ctx2 = New-PipelineContext -PrdId 'b' -StateMachine $sm
        $ctx1.pipelineId | Should Not Be $ctx2.pipelineId
    }
}

Describe 'Get-AvailableTransitions' {
    $sm = Read-StateMachine -Path $smPath

    It 'DISCOVERY should have 2 transitions' {
        $t = @(Get-AvailableTransitions -StateMachine $sm -CurrentState 'DISCOVERY')
        $t.Count | Should Be 2
    }

    It 'PRD_REVIEW should have 3 transitions' {
        $t = @(Get-AvailableTransitions -StateMachine $sm -CurrentState 'PRD_REVIEW')
        $t.Count | Should Be 3
    }

    It 'DONE should have 0 transitions' {
        $t = @(Get-AvailableTransitions -StateMachine $sm -CurrentState 'DONE')
        $t.Count | Should Be 0
    }
}

Describe 'Invoke-StateTransition' {
    $sm = Read-StateMachine -Path $smPath

    It 'Should transition DISCOVERY to PRD_REVIEW on auto' {
        $ctx = New-PipelineContext -PrdId 'x' -StateMachine $sm
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx.currentState | Should Be 'PRD_REVIEW'
        $ctx.history.Count | Should Be 2
    }

    It 'Should enforce human gate on PRD_REVIEW' {
        $ctx = New-PipelineContext -PrdId 'x' -StateMachine $sm
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        # Now at PRD_REVIEW - auto should fail (requires human gate)
        $threw = $false
        try { Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto' } catch { $threw = $true }
        $threw | Should Be $true
    }

    It 'Should allow human_approve on PRD_REVIEW' {
        $ctx = New-PipelineContext -PrdId 'x' -StateMachine $sm
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_approve'
        $ctx.currentState | Should Be 'PLANNING'
    }

    It 'Should allow human_reject on PRD_REVIEW back to DISCOVERY' {
        $ctx = New-PipelineContext -PrdId 'x' -StateMachine $sm
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_reject'
        $ctx.currentState | Should Be 'DISCOVERY'
    }

    It 'Should reach DONE and set status completed' {
        $ctx = New-PipelineContext -PrdId 'x' -StateMachine $sm
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_approve'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_approve'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_approve'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'human_approve'
        $ctx = Invoke-StateTransition -StateMachine $sm -Context $ctx -Trigger 'auto'
        $ctx.currentState | Should Be 'DONE'
        $ctx.status | Should Be 'completed'
    }
}

Describe 'Get-StateInfo' {
    $sm = Read-StateMachine -Path $smPath

    It 'Should return state details' {
        $info = Get-StateInfo -StateMachine $sm -StateName 'PRD_REVIEW'
        $info.displayName | Should Be 'PRD Human Review'
        $info.phase | Should Be 'discovery'
        $info.requiresHumanGate | Should Be $true
    }

    It 'Should throw on unknown state' {
        $threw = $false
        try { Get-StateInfo -StateMachine $sm -StateName 'NONEXISTENT' } catch { $threw = $true }
        $threw | Should Be $true
    }
}
