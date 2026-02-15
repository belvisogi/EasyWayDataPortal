@{
    # Preference Profiles (P1)
    Profiles                       = @{
        "privacy_first" = @{
            allowedTags = @("local")
            fallback    = "block"
        }
        "speed_first"   = @{
            allowedTags = @("fast", "cloud")
            fallback    = "best_effort"
        }
        "cost_balanced" = @{
            allowedTags = @("cheap", "balanced")
            fallback    = "best_effort"
        }
    }

    RequiredRagEvidence            = $true
    CriticalActionsRequireApproval = @("push", "merge", "delete", "force")

    Providers                      = @(
        @{
            name             = "openai"
            enabled          = $false
            priority         = 10
            tags             = @("cloud", "fast")
            mode             = "rest"
            apiStyle         = "openai_responses"
            endpoint         = "https://api.openai.com/v1/responses"
            apiKeyEnv        = "OPENAI_API_KEY"
            model            = "gpt-4.1-mini"
            timeoutSec       = 45
            failureThreshold = 3
            cooldownMinutes  = 5
        },
        @{
            name             = "deepseek"
            enabled          = $false
            priority         = 10
            tags             = @("cloud", "cheap", "balanced")
            mode             = "rest"
            apiStyle         = "deepseek_chat"
            endpoint         = "https://api.deepseek.com/chat/completions"
            apiKeyEnv        = "DEEPSEEK_API_KEY"
            model            = "deepseek-chat"
            timeoutSec       = 60
            failureThreshold = 3
            cooldownMinutes  = 5
            costInput        = 0.00014
            costOutput       = 0.00028
        },
        @{
            name             = "anthropic"
            enabled          = $false
            priority         = 20
            tags             = @("cloud", "smart")
            mode             = "rest"
            apiStyle         = "anthropic_messages"
            endpoint         = "https://api.anthropic.com/v1/messages"
            apiKeyEnv        = "ANTHROPIC_API_KEY"
            model            = "claude-3-5-sonnet-latest"
            timeoutSec       = 45
            failureThreshold = 3
            cooldownMinutes  = 5
        },
        @{
            name             = "levi-local"
            enabled          = $true
            priority         = 100
            tags             = @("local", "privacy")
            mode             = "mock"
            apiStyle         = "none"
            endpoint         = ""
            apiKeyEnv        = ""
            model            = "levi-local-mock"
            timeoutSec       = 10
            failureThreshold = 5
            cooldownMinutes  = 1
            costInput        = 0.0000
            costOutput       = 0.0000
        }
    )
}
