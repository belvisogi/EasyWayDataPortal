# Best Practice: The Grandma Test (AI-Safe Middleware)

> "If Grandma can't use it safely via chat, the backend isn't robust enough."

## 1. The Principle
We do not build CLI tools for unsuspecting humans. We build them for **AI Agents**.
The end-user (e.g., "The Grandma" or a Junior Dev) should never touch the raw Shell. They interact via natural language.

## 2. The Agent's Dilemma
An AI Agent is like a "clumsy nephew": smart but potentially destructive if connected directly to raw APIs or fragile scripts.
*   **Risk**: If an Agent tries to parse a messy log file, it hallucinates.
*   **Risk**: If an Agent runs a script that hangs, the chat freezes.

## 3. The Solution: The Iron Kernel Pattern
To pass the Grandma Test, the middleware (`ewctl`) must be:

1.  **Muted (The Silencer)**: Never output text/logs to stdout. Only pure JSON.
    *   *Why*: LLMs ingest text. Debug logs confuse them ("Is this an error or just info?").
2.  **Transactional**: Operations must be `Check`, `Plan`, `Fix`.
    *   *Why*: Grandma asks "Is everything okay?". The Agent runs `Check`. If red, the Agent asks Grandma "Do you want me to fix it?". Only then runs `Fix`.
3.  **Atomic**: It either works 100% or returns a structured error.
    *   *Why*: Partial failures require debugging. Grandma doesn't debug.

## 4. Implementation Standard
When building new tools for EasyWay:
*   ❌ **Don't**: Write a script that asks `Read-Host "Are you sure?"`. Agents hang on interactive prompts.
*   ✅ **Do**: Write a module that accepts `--force` or `--plan` and returns JSON.

## 5. The Flow
`User (Grandma)` 🗣️ "Fix the database!" 
   ⬇️
`Agent (The Face)` 🤖 Parses intent, calls tool.
   ⬇️
`ewctl (The Iron Hands)` 🛡️ Executes `Invoke-SqlCmd`. Silences noise. Catches errors.
   ⬇️
`Agent` 🤖 Receives `{"Status": "Ok"}`.
   ⬇️
`User` 🗣️ "It is done."

**Result**: Safety is handled by the Kernel, Simplicity is handled by the Agent.
