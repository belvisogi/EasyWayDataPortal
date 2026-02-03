---
id: ew-archive-imported-docs-2026-01-30-architecture-ewctl-specs
title: ewctl Architecture Specification & Future Proofing
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
# ewctl Architecture Specification & Future Proofing

> "The implementation is ephemeral. The Contract is eternal."

This document defines the architecture of the **EasyWay Control (ewctl)** system.
Currently implemented in **PowerShell Core (pwsh)**, this architecture is designed to be language-agnostic.
**Python** is the designated "Plan B" / Next-Gen language if performance or AI-native integration becomes a priority.

## 1. Core Concepts

### The "Lego Kernel" Pattern
The system is divided into two distinct layers:
1.  **The Kernel** (`ewctl`): A lightweight, dumb executor. It knows nothing about the business logic. Its only jobs are:
    *   **Discovery**: Find "Lego" modules in a specific folder.
    *   **Isolation**: Capture all stdout/stderr noise ("The Silencer").
    *   **Serialization**: Guarantee that the final output is valid compacted JSON.
2.  **The Legos** (Modules): Self-contained domain logic (Governance, Docs, DB). They leverage the "Sacred Interface".

### The Sacred Interface (Abstract)
Any module, in any language, must expose three capabilities:

| Verb | Question | Output Schema (JSON) | Side Effects? |
| :--- | :--- | :--- | :--- |
| **Check** | *"What is wrong?"* | `[{ "Status": "Error|Ok", "Message": "...", "Context": "..." }]` | 🔒 Read-Only |
| **Plan** | *"What must be done?"* | `[{ "Step": 1, "Description": "...", "Automated": true }]` | 🔒 Read-Only |
| **Fix** | *"Do it for me."* | `[{ "Action": "...", "Result": "Success|Fail" }]` | ✏️ Write Allowed |

## 2. Implementation Specs

### Current Implementation: PowerShell (v1)
- **Kernel**: `scripts/pwsh/ewctl.ps1`
- **Modules**: `scripts/pwsh/modules/ewctl/*.psm1`
- **Discovery**: `Get-ChildItem` + Duck Typing (`Get-Command ...`).
- **Isolation**: `6>$null 4>$null 3>$null` redirection.

### Backup Strategy: Python (v2)
If PowerShell "Cold Start" (>200ms) becomes a bottleneck, or if deep integration with Python libraries (Pandas/LangChain) is required, the system can be ported 1:1.

#### Python Kernel Blueprint (`ewctl.py`)
```python
import argparse
import json
import importlib
import pkgutil
import sys
from io import StringIO
import contextlib

@contextlib.contextmanager
def capture_output():
    # The "Silencer" in Python
    new_out, new_err = StringIO(), StringIO()
    old_out, old_err = sys.stdout, sys.stderr
    try:
        sys.stdout, sys.stderr = new_out, new_err
        yield sys.stdout
    finally:
        sys.stdout, sys.stderr = old_out, old_err

def main():
    # Discovery
    modules = []
    for finder, name, ispkg in pkgutil.iter_modules(["modules/ewctl"]):
        mod = importlib.import_module(f"modules.ewctl.{name}")
        if hasattr(mod, "get_diagnosis"):
            modules.append(mod)

    # Execution (Check Example)
    results = []
    with capture_output():
        for m in modules:
            results.extend(m.get_diagnosis())
    
    # Render
    print(json.dumps(results))
```

#### Python Module Blueprint (`modules/ewctl/governance.py`)
```python
def get_diagnosis():
    return [
        {"Status": "Ok", "Message": "Python Governance Check Passed", "Context": "Governance"}
    ]

def get_prescription():
    return []

def invoke_treatment():
    pass
```

## 3. The Contract (JSON)
The output MUST always follow this schema to ensure compatibility with **n8n** and **AI Agents**.

```json
[
  {
    "Status": "Error",   // Enum: Error, Warn, Ok, Info
    "Module": "docs",    // Source of the signal
    "Message": "...",    // Human readable description
    "Context": "Wiki",   // Category tag
    "Details": { ... }   // Optional payload
  }
]
```

## 4. Decision Log
- **Why PowerShell first?** Existing codebase was 90% PowerShell. Azure DevOps tasks are native PowerShell. Lowest friction to migrate the "Governance" logic.
- **When to switch to Python?**
    1.  If startup time exceeds 2 seconds.
    2.  If we need to use complex AI logic inside a check (e.g., "Semantic Diff" using LLM embeddings).
    3.  If we deploy to a Linux-only container where installing PowerShell is a burden.

## 5. The Polyglot Router (Future "Bilanciatore")

To transparently support both PowerShell and Python modules, a thin **Router** layer (e.g., a Rust or Go binary, or a lightweight wrapper script) will be introduced.

### Routing Logic
1.  **Discovery**: The Router scans both `scripts/pwsh/modules/ewctl` and `scripts/python/modules/ewctl`.
2.  **Dispatch**:
    *   Command: `ewctl check`
    *   Router:
        *   Invokes `pwsh ewctl.ps1 check --json` -> Gets `[ { "Module": "docs" ... } ]`
        *   Invokes `python ewctl.py check --json` -> Gets `[ { "Module": "ai-semantic" ... } ]`
    *   **Aggregation**: Merges the two JSON arrays into one.
3.  **Result**: The user (or n8n) sees a single unified report.

### Implementation Phases
- **Phase 1 (Manual)**: User calls `ewctl.ps1` or `ewctl.py` manually.
- **Phase 2 (Aggregation Script)**: `ewctl-all.ps1` calls both and joins JSON.
- **Phase 3 (Compiled Router)**: A single binary `ewctl` that manages runtimes.


