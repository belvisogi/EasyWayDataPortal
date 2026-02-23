#Requires -Version 5.1
<#
.SYNOPSIS
    BusinessMap adapter — DOCUMENTATION REFERENCE / STUB.
.DESCRIPTION
    Placeholder for future BusinessMap (ex Kanbanize) integration.
    The stub class implementation lives in IPlatformAdapter.psm1
    (consolidated module) due to PowerShell v5 cross-module class
    inheritance limitations.

    When implementing for real, update the BusinessMapAdapter class in
    IPlatformAdapter.psm1. This file serves as documentation.

    Planned integration points:
    - BusinessMap REST API V2 for Cards/Boards/Initiatives
    - Board-level hierarchy (Initiative -> Epic -> Story -> Task)
    - WIP limits and Business Rules for gate enforcement
    - Custom fields for traceability (PRD_ID, InitiativeId)

    See: EASYWAY_AGENTIC_SDLC_MASTER.md §11.4 (BusinessMap Integration)
    See: IPlatformAdapter.psm1 for the operational code
.NOTES
    Part of Phase 9 Feature 17 — Platform Adapter SDK.
    Operational Module: scripts/pwsh/core/adapters/IPlatformAdapter.psm1
#>
Write-Verbose "[BusinessMapAdapter] Documentation reference file. Operational code is in IPlatformAdapter.psm1"
