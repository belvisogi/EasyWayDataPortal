@{
    RequireRagEvidence = $true
    CriticalActionsRequireApproval = @("push", "merge", "delete", "force")
    Providers = @(
        @{
            name = "openai"
            enabled = $false
            priority = 10
            mode = "rest"
            apiStyle = "openai_responses"
            endpoint = "https://api.openai.com/v1/responses"
            apiKeyEnv = "OPENAI_API_KEY"
            model = "gpt-4.1-mini"
            timeoutSec = 45
            failureThreshold = 3
            cooldownMinutes = 5
        },
        @{
            name = "anthropic"
            enabled = $false
            priority = 20
            mode = "rest"
            apiStyle = "anthropic_messages"
            endpoint = "https://api.anthropic.com/v1/messages"
            apiKeyEnv = "ANTHROPIC_API_KEY"
            model = "claude-3-5-sonnet-latest"
            timeoutSec = 45
            failureThreshold = 3
            cooldownMinutes = 5
        },
        @{
            name = "levi-local"
            enabled = $true
            priority = 100
            mode = "mock"
            apiStyle = "none"
            endpoint = ""
            apiKeyEnv = ""
            model = "levi-local-mock"
            timeoutSec = 10
            failureThreshold = 5
            cooldownMinutes = 1
        }
    )
}
