# Multi-VCS agent config example
# Copy as scripts/pwsh/multi-vcs.config.ps1 and customize.

@{
    Remotes = @("ado", "github", "forgejo")

    Providers = @{
        ado = @{
            Enabled      = $true
            Organization = "https://dev.azure.com/ORG"
            Project      = "PROJECT"
            Repository   = "REPO"
            TargetBranch = "develop"
        }
        github = @{
            Enabled      = $true
            Repo         = "owner/repo"
            TargetBranch = "main"
        }
        forgejo = @{
            Enabled      = $true
            Url          = "https://forgejo.example.com"
            Repo         = "owner/repo"
            TargetBranch = "main"
        }
    }
}
