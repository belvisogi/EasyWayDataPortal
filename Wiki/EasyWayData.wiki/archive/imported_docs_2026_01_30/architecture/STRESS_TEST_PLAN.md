---
id: ew-archive-imported-docs-2026-01-30-architecture-stress-test-plan
title: Stress Test Plan: The "Iron Kernel" Torture Chamber
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
# Stress Test Plan: The "Iron Kernel" Torture Chamber

**Objective**: Verify that `ewctl` maintains its "Antifragile" properties under extreme abuse, ensuring it never traps an Agent in an undefined state.

## 1. Chaos Engineering Scenarios (The 5 Demons)

### A. The Poisoned Chalice (Output Flooding) 🧪
**Scenario**: A module goes rogue and prints 10MB of text to `stdout` (e.g., `Write-Host` in a tight loop).
**Expectation**:
*   The JSON output on stdout must remain valid and clean.
*   The rouge text must be captured in `ewctl.debug.log` or discarded.
*   The Agent must receive a valid JSON response (even if it's an error).
*   **Test Command**: `ewctl test-poison --size 10MB` (Proposed)

### B. The Heart Attack (Uncatchable Exceptions) 💔
**Scenario**: A module throws a `StackOverflowException` or terminates the process hard.
**Expectation**:
*   The Kernel might die (unavoidable in process term), BUT the exit code must be non-zero.
*   n8n must detect the failure via exit code.
*   **Test Command**: `ewctl test-crash --mode hard` (Proposed)

### C. The Race (Concurrency) 🏎️
**Scenario**: n8n triggers `ewctl fix` while a Developer runs `ewctl interactive` locally on the same file/DB.
**Expectation**:
*   File locks should prevent corruption.
*   DB transactions should handle isolation.
*   Ideally, `ewctl` should implement a PID lock file (`ewctl.lock`) to prevent dual execution.
*   **Test**: Run two parallel PowerShell consoles invoking fix.

### D. The Silent Treatment (Timeout/Latency) ⏳
**Scenario**: The Database takes 60 seconds to respond.
**Expectation**:
*   `ewctl` should not hang forever.
*   Modules should have internal timeouts (default 30s).
*   The user receives `{"Status": "Error", "Message": "Timeout"}`.

### E. The Monkey (Invalid Input) 🐒
**Scenario**: Agent passes garbage arguments: `ewctl check --json --garbage-flag`.
**Expectation**:
*   Show graceful error message.
*   Do NOT enter interactive mode (which would hang the agent).

## 2. Tools Required

1.  **`ewctl.chaos.psm1`**: A dedicated module solely for simulating failures (Panic, Sleep, Spam).
2.  **`stress.ps1`**: A harness script that calls `ewctl` in loop parallel to measure stability.

## 3. Success Metrics
*   **JSON Integrity**: 100% (Zero parse errors allowed).
*   **Exit Code Accuracy**: 100% (Error = Non-Zero).
*   **Log Completeness**: Every crash must have a stack trace in `logs/`.

## 4. Execution Plan
1.  Develop `ewctl.chaos` module.
2.  Run Battery tests.
3.  Fix identified weaknesses (e.g., define global timeouts).


