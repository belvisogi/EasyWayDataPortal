---
id: ew-archive-imported-docs-2026-01-30-architecture-security-audit
title: Security Audit Report: ewctl Architecture
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# Security Audit Report: ewctl Architecture

**Date**: 2026-01-25
**Scope**: `ewctl.ps1` (Kernel), Root Wrapper, Module System.
**Focus**: Prompt Injection, Command Injection, Output Poisoning.

## Executive Summary
The `ewctl` architecture is **SECURE** against common injection vectors.
The "Kernel" acts as a robust sandbox, ensuring that individual modules cannot pollute the structured output explicitly required by AI agents and pipelines.

## Findings

### 1. Command Injection (Input)
**Risk**: User passing `; rm -rf /` as an argument.
**Status**: **MITIGATED**.
**Analysis**:
- Root wrapper uses `& $ScriptPath @args`. Accessing arguments via array `@args` prevents shell expansion of malicious strings.
- Kernel uses `[CmdletBinding()]` and validates `$Command` against a strict allowlist (`check`, `fix`, `plan`).

### 2. Output Poisoning (Prompt Injection via Stdout)
**Risk**: A malicious or buggy module printing "Ignore previous instructions" to stdout, tricking the LLM reading the output.
**Status**: **MITIGATED**.
**Analysis**:
- The Kernel's `Invoke-EwctlSafeExecution` wrapper explicitly redirects streams 3 (Warning), 4 (Verbose), and 6 (Information/Host) to `$null` when running in JSON mode.
- Verified via Red Team simulation (`ewctl.evil.psm1`): Noisy output is suppressed; only the structured JSON return value is printed.

### 3. JSON Injection (Content)
**Risk**: A module returning a check result containing unescaped quotes to break the JSON structure.
**Status**: **MITIGATED**.
**Analysis**:
- The Kernel aggregates results into a `PSCustomObject` list and uses `ConvertTo-Json` to serialize.
- `ConvertTo-Json` correctly escapes special characters (e.g., `"` becomes `\"`).
- **Residual Risk**: The *content* of the message is still user-controlled. If it contains "Ignore previous instructions", the JSON parser will read it as a string value. **Recommendation**: Agnet consumption layer must treat the "Message" field as untrusted text.

## Recommendations
1.  **Maintain Strict Kernel**: Do not allow `Invoke-Expression` to sneak back in.
2.  **Audit New Modules**: Ensure no module uses `Start-Process` with user input.
3.  **Agent Firewall**: When consuming `ewctl` output, the receiving Agent should separate "System Instructions" from "Tool Output" to prevent semantic injection.


