#Requires -Version 5.1
<#
.SYNOPSIS
    GitHub adapter — DOCUMENTATION REFERENCE / STUB.
.DESCRIPTION
    Placeholder for future GitHub Issues/Projects integration.
    The stub class implementation lives in IPlatformAdapter.psm1
    (consolidated module) due to PowerShell v5 cross-module class
    inheritance limitations.

    When implementing for real, update the GitHubAdapter class in
    IPlatformAdapter.psm1. This file serves as documentation.

    Planned integration points:
    - GitHub REST/GraphQL API for Issues + Sub-issues
    - Labels/Milestones for taxonomy mapping
    - Protected branches + required checks for gate enforcement

    See: EASYWAY_AGENTIC_SDLC_MASTER.md §11.7 (GitHub Capability Matrix)
    See: IPlatformAdapter.psm1 for the operational code
.NOTES
    Part of Phase 9 Feature 17 — Platform Adapter SDK.
    Operational Module: scripts/pwsh/core/adapters/IPlatformAdapter.psm1
#>
Write-Verbose "[GitHubAdapter] Documentation reference file. Operational code is in IPlatformAdapter.psm1"
