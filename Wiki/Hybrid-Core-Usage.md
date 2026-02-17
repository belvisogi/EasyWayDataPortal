# Hybrid Core Usage Guide

## 1. What is the Hybrid Core?
The **Hybrid Core** is a set of advanced capabilities that allow the Agent to interact with the codebase more intelligently than standard tools allow. It bridges PowerShell scripts with potential AI/LLM logic (or strict deterministic logic) to perform complex tasks like:
- **Smart Diff Analysis**: Understanding code changes with context.
- **PR Description Generation**: Summarizing work automatically.
- **Code Review**: Providing automated feedback on changes.

The main entry point is `agent/core/Invoke-AgentTool.ps1`.

## 2. Why use the Pipeline (`|`)?
PowerShell is a powerful shell, but it has strict parsing rules. When you try to pass large, multi-line blocks of text (like a `git diff`) as a command-line argument using `-Target`, specific characters often break the command:
- **`---` and `+++`**: Interpreted as operators.
- **`/dev/null`**: Interpreted as paths or division operations.
- **Quote Hell**: Escaping quotes inside code blocks is error-prone.

**The Solution**: The **Pipeline Pattern**.
By piping output directly into `Invoke-AgentTool`, we bypass the shell's argument parser completely. The tool reads the raw stream of text from "Standard Input" (Stdin), which is safe, robust, and "Antifragile".

## 3. How to use it?

### A. Describing a Pull Request
Use this when you have staged your changes and want to generate a PR description.

```powershell
# 1. Stage your changes
git add .

# 2. Generate Description (Correct Way)
git diff --cached | Invoke-AgentTool -Task Describe
```

### B. Reviewing Code
Use this to get an analysis of your local working directory changes.

```powershell
# Review unstaged changes
git diff | Invoke-AgentTool -Task Review
```

### C. Debugging / Manual Use
If you need to test with a file content:

```powershell
# Read a file and pass it as target
Get-Content my-patch.diff -Raw | Invoke-AgentTool -Task Describe
```

## Summary
| Pattern | Status | Reason |
| :--- | :--- | :--- |
| `Invoke-AgentTool -Target (git diff)` | ❌ **FORBIDDEN** | Causes parsing errors. Fragile. |
| `git diff | Invoke-AgentTool` | ✅ **MANDATORY** | Robust. Standard. Antifragile. |
