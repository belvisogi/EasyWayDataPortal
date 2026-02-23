#Requires -Version 5.1
<#
.SYNOPSIS
    Azure DevOps adapter — DOCUMENTATION REFERENCE ONLY.
.DESCRIPTION
    The operational AdoAdapter class implementation lives in IPlatformAdapter.psm1
    (consolidated module) due to PowerShell v5 cross-module class inheritance
    limitations.

    This file documents the ADO-specific logic for reference:
    - WIQL queries for work item dedup by title + PRD tag
    - JSON-Patch operations for work item creation
    - System.LinkTypes.Hierarchy-Reverse for parent-child linking
    - All values driven by platform-config.json, no hardcoded constants

    See: EASYWAY_AGENTIC_SDLC_MASTER.md §11.7 (ADO Capability Matrix)
    See: IPlatformAdapter.psm1 for the operational code

.NOTES
    Part of Phase 9 Feature 17 — Platform Adapter SDK.
    Migrated from: ado-plan-apply.ps1 + ado-apply.ps1
    Operational Module: scripts/pwsh/core/adapters/IPlatformAdapter.psm1
#>
Write-Verbose "[AdoAdapter] Documentation reference file. Operational code is in IPlatformAdapter.psm1"
