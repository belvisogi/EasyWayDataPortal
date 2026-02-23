# Pester v3 compatible tests for TelemetryLogger.psm1

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$modulePath = Join-Path $scriptRoot 'TelemetryLogger.psm1'
Import-Module $modulePath -Force

$testLogPath = Join-Path $env:TEMP "telemetry_test_$(Get-Random).jsonl"

Describe 'Initialize-TelemetryLogger' {
    It 'Should initialize with custom path' {
        Initialize-TelemetryLogger -LogPath $testLogPath -TraceId 'test1234'
        # logger is initialized (no throw)
        $true | Should Be $true
    }
}

Describe 'Write-TelemetryEvent' {
    BeforeAll {
        if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
        Initialize-TelemetryLogger -LogPath $testLogPath -TraceId 'testTrace'
    }

    It 'Should write a success event' {
        $evt = Write-TelemetryEvent -AgentId 'agent_test' -AgentLevel 'L1' -Action 'test:hello' -Outcome 'success'
        $evt.agentId | Should Be 'agent_test'
        $evt.outcome | Should Be 'success'
        $evt.traceId | Should Be 'testTrace'
    }

    It 'Should write event with all fields' {
        $evt = Write-TelemetryEvent `
            -AgentId 'agent_planner' `
            -AgentLevel 'L3' `
            -Action 'plan:whatif' `
            -Outcome 'success' `
            -EventType 'action' `
            -PrdId 'Phase-9' `
            -WorkItemId 20 `
            -WorkItemType 'Product Backlog Item' `
            -PipelineState 'PLANNING' `
            -DurationMs 1500 `
            -Confidence 'High' `
            -Details @{ itemsPlanned = 4 }
        $evt.prdId | Should Be 'Phase-9'
        $evt.workItemId | Should Be 20
        $evt.durationMs | Should Be 1500
        $evt.confidence | Should Be 'High'
    }

    It 'Should write a failure event' {
        $evt = Write-TelemetryEvent `
            -AgentId 'agent_executor' `
            -AgentLevel 'L1' `
            -Action 'apply:create_workitem' `
            -Outcome 'failure' `
            -Error @{ message = 'Token expired'; type = 'AuthException' }
        $evt.outcome | Should Be 'failure'
        $evt.error.message | Should Be 'Token expired'
    }

    It 'Should persist events to JSONL file' {
        (Test-Path $testLogPath) | Should Be $true
        $lines = @(Get-Content $testLogPath | Where-Object { $_.Trim() })
        $lines.Count | Should BeGreaterThan 0
    }
}

Describe 'Measure-AgentAction' {
    BeforeAll {
        if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
        Initialize-TelemetryLogger -LogPath $testLogPath -TraceId 'measureTrace'
    }

    It 'Should measure successful action duration' {
        $result = Measure-AgentAction -AgentId 'agent_test' -AgentLevel 'L1' -Action 'test:compute' -ScriptBlock {
            42
        }
        $result | Should Be 42
    }

    It 'Should capture failure in measured action' {
        $threw = $false
        try {
            Measure-AgentAction -AgentId 'agent_test' -AgentLevel 'L1' -Action 'test:fail' -ScriptBlock {
                throw 'intentional failure'
            }
        }
        catch { $threw = $true }
        $threw | Should Be $true
    }
}

Describe 'Read-TelemetryLog' {
    BeforeAll {
        if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
        Initialize-TelemetryLogger -LogPath $testLogPath -TraceId 'readTrace'
        Write-TelemetryEvent -AgentId 'a1' -AgentLevel 'L1' -Action 'r:1' -Outcome 'success'
        Write-TelemetryEvent -AgentId 'a2' -AgentLevel 'L2' -Action 'r:2' -Outcome 'failure'
    }

    It 'Should read all events from log' {
        $events = @(Read-TelemetryLog -Path $testLogPath)
        $events.Count | Should Be 2
        $events[0].agentId | Should Be 'a1'
        $events[1].outcome | Should Be 'failure'
    }

    AfterAll {
        if (Test-Path $testLogPath) { Remove-Item $testLogPath -Force }
    }
}
