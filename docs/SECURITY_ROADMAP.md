# Security Roadmap & Tech Debt

**Tag**: `#security` `#hardening` `#roadmap`

This document tracks security improvements and penetration testing needs identified during the development of `TenantGuard` and `Agent Backend`.

## 🚨 Immediate Priorities (P1)
- [ ] **Context Injection**: Updates to `agent_backend` to inject the real `tenantId` from the request context (currently hardcoded as `system-fallback` in `fileStore.ts`).
- [ ] **Rate Limiting**: Enforce strict IO rate limits per tenant to prevent DoS via disk exhaustion.

## 🛡️ Penetration Testing Reminders
- [ ] **Symlink Attacks**: Verify behavior when paths contain symlinks resolving outside the tenant scope.
- [ ] **Race Conditions**: Test `check-then-act` vulnerabilities in file operations under high concurrency.
- [ ] **Large Payloads**: Fuzzing with multi-MB files to test memory exhaustion in `readJsonFile`.
- [ ] **Polynomial ReDoS**: Audit Regex used in input validation for ReDoS vulnerabilities.

## 🔧 Infrastructure Hardening
- [ ] **Secrets Management**: Move away from `.env` files for production secrets; integrate with Azure Key Vault.
- [ ] **Container Isolation**: Ensure each agent runs in a container with restricted syscalls (gVisor/Kata).
