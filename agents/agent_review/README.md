# agent_review
**Role**: Agent_Review | **Level**: L2

## Overview
Reviews PR context for quality, governance alignment, and documentation impact.

## Runner
- `agents/agent_review/review-run.ps1`

## Actions
- `review:audit-pr` → PR audit review on provided context text
- `review:static-check` → lightweight static review on provided context text

## Usage
```powershell
pwsh ./agents/agent_review/review-run.ps1 -Action audit-pr -InputPath .\out\review-input.txt
pwsh ./agents/agent_review/review-run.ps1 -Action static-check -InputPath .\out\review-input.txt
```
