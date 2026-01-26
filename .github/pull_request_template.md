## Security Checklist

> ⚠️ **Complete ONLY if this PR touches**: API, Database, Auth, Agents, or External Integrations

### Security by Design Verification

- [ ] **Input Validation**: All user inputs validated and sanitized
- [ ] **Authorization**: RBAC/permissions verified for new endpoints
- [ ] **SQL Injection**: Database queries use stored procedures or parameterized queries
- [ ] **Secrets Management**: No hardcoded secrets (all in Azure KeyVault)
- [ ] **Error Handling**: User-facing errors don't expose stack traces or sensitive info
- [ ] **Logging**: Security events logged (auth, admin actions, failures)
- [ ] **GEDI Review**: Ran `agent-gedi.ps1 -Context "<feature>" -Intent "security_review"`

### Threat Model Considerations

- [ ] Considered attack vectors from [Threat Analysis](../Wiki/EasyWayData.wiki/security/threat-analysis-hardening.md)
- [ ] Verified defense-in-depth (multiple security layers)

### Not Applicable

- [ ] This PR doesn't touch security-relevant code (refactoring, docs, UI-only, etc.)

---

**If security checklist N/A**, check the box above and proceed.  
**If applicable**, verify all items before requesting review.

📋 Full checklist: [SECURITY_DEV_CHECKLIST.md](docs/security/SECURITY_DEV_CHECKLIST.md)
