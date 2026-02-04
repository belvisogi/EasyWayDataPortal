---
id: ew-archive-imported-docs-2026-01-30-security-security-dev-checklist
title: Security Development Checklist
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/security, layer/spec, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# Security Development Checklist

> **Filosofia**: "La vittoria si ottiene prima della battaglia" - Security by design, non afterthought

---

## 🎯 When to Use

**OGNI VOLTA** che:
- ✅ Crei una nuova API endpoint
- ✅ Aggiungi feature con input utente
- ✅ Modifichi autenticazione/autorizzazione
- ✅ Aggiungi agent script
- ✅ Modifichi database schema
- ✅ Aggiungi integrazione esterna

**NON** serve per:
- ❌ Refactoring puro (no logic change)
- ❌ Fix typo documentazione
- ❌ Update README

---

## ✅ Security Checklist - Feature Development

### 1. Input Validation
- [ ] **Validazione tipo**: Input è del tipo atteso? (string/number/date)
- [ ] **Sanitizzazione**: Rimossi caratteri speciali pericolosi? (`<>'"--`)
- [ ] **Lunghezza max**: Input ha limite lunghezza ragionevole?
- [ ] **Allowlist**: Se possibile, validato contro allowlist vs blacklist?

**Esempio**:
```javascript
// ✅ Good
const schema = z.object({
  tenant_id: z.string().max(50).regex(/^[a-zA-Z0-9_-]+$/)
});

// ❌ Bad
const tenant_id = req.body.tenant_id; // No validation!
```

---

### 2. Authentication & Authorization
- [ ] **Auth required**: Route richiede autenticazione?
- [ ] **RBAC**: Verificato ruolo utente prima di azione?
- [ ] **Tenant isolation**: RLS o equivalent per multi-tenancy?
- [ ] **Token expiry**: Session token ha scadenza ragionevole?

**GEDI Check**: `testudo_formation` - "C'è un punto debole dove gli scudi non si toccano?"

---

### 3. Database Security
- [ ] **Stored procedure**: Usata invece di query dinamica?
- [ ] **Parametri tipizzati**: No string concatenation in SQL?
- [ ] **RLS**: Row-Level Security attiva se multi-tenant?
- [ ] **Least privilege**: User DB ha solo permessi necessari?

**Esempio**:
```sql
-- ✅ Good
EXEC sp_get_user @tenant_id='test', @user_id='123'

-- ❌ Bad
SELECT * FROM users WHERE tenant_id = '" + req.params.id + "'
```

---

### 4. Secrets Management
- [ ] **No hardcoded**: Nessun segreto in codice?
- [ ] **KeyVault**: Secret letto da Azure Key Vault?
- [ ] **Environment vars**: `.env` non committato in git?
- [ ] **Rotation**: Secret ha piano rotazione?

**GEDI Check**: `tangible_legacy` - "Saremmo orgogliosi di mostrarlo?" (se c'è password hardcoded = NO!)

---

### 5. AI Agent Security
- [ ] **Input validation**: Agent input passa `validate-agent-input.ps1`?
- [ ] **Allowlist script**: Solo script approvati eseguibili?
- [ ] **Output validation**: Agent output sanitizzato?
- [ ] **Egress control**: Agent non può chiamare endpoint non autorizzati?

**GEDI Check**: `victory_before_battle` - "Stiamo anticipando abusi o aspettiamo attacco?"

---

### 6. Logging & Monitoring
- [ ] **Security events**: Azioni sensibili loggati? (login, delete, admin action)
- [ ] **Immutable logs**: Log append-only (non modificabili)?
- [ ] **PII redaction**: Dati sensibili redatti da log?
- [ ] **Alert**: Anomalie triggerano alert?

**Esempio**:
```javascript
// ✅ Good
logger.info('User login attempt', { user_id: 'xxx', success: true });

// ❌ Bad
logger.info('Login: user@email.com password: secret123'); // PII leak!
```

---

### 7. Error Handling
- [ ] **No stack trace**: Error message user-friendly, no debug info?
- [ ] **Fallback sicuro**: In caso errore, sistema degrada gracefully?
- [ ] **Rate limiting**: Protezione contro brute force?

**GEDI Check**: `black_swan_resilience` - "Sistema degrada o collassa?"

---

## 🤖 GEDI Integration

**Prima di commit**, chiedi a GEDI:

```powershell
.\agents\agent_gedi\agent-gedi.ps1 -Context "Nuova API /users con endpoint DELETE" -Intent "security_review"
```

GEDI verificherà:
- ✅ `testudo_formation`: Tutte le difese coordinate?
- ✅ `victory_before_battle`: Security by design?
- ✅ `black_swan_resilience`: Sistema resiliente?

---

## 🔄 Automated Reminders

### Git Pre-commit Hook

File: `.git/hooks/pre-commit`

```bash
#!/bin/bash
# Security checklist reminder

# Check if code changes include new API or DB
if git diff --cached --name-only | grep -qE "(api|db)"; then
    echo "⚠️  SECURITY REMINDER: Did you complete security checklist?"
    echo "   📋 See: docs/security/SECURITY_DEV_CHECKLIST.md"
    echo ""
    read -p "Continue with commit? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi
```

---

### PR Template

File: `.github/pull_request_template.md`

```markdown
## Security Checklist

If this PR touches API/DB/Auth/Agents, verify:

- [ ] Input validation implemented
- [ ] RBAC/Authorization verified
- [ ] Secrets in KeyVault (not hardcoded)
- [ ] GEDI security review passed
- [ ] Threat model considered

If N/A, check here: [ ] Not applicable
```

---

## 📊 Security Review Schedule

| Frequency | Activity | Owner |
|-----------|----------|-------|
| **Every commit** | Self-check questa checklist | Developer |
| **Every PR** | Peer review security items | Reviewer |
| **Every sprint** | GEDI audit su nuove features | Agent GEDI |
| **Quarterly** | Full security audit | Team |
| **Before production** | Penetration test (war game) | Red Team |

---

## 🎓 Quick Reference Card

**Memory aid** - stampa e tieni vicino monitor:

```
╔════════════════════════════════════════╗
║   SECURITY BY DESIGN CHECKLIST        ║
╠════════════════════════════════════════╣
║ [ ] Input validato?                    ║
║ [ ] Auth/RBAC verificato?              ║
║ [ ] SQL parametrizzato?                ║
║ [ ] Secret in KeyVault?                ║
║ [ ] Error handling sicuro?             ║
║ [ ] Log eventi security?               ║
║ [ ] GEDI review fatto?                 ║
╚════════════════════════════════════════╝

"Formazione a testuggine come un solo uomo!"
```

---

## Vedi Anche

- [Threat Analysis](../Wiki/EasyWayData.wiki/security/threat-analysis-hardening.md)
- [AI Security Guardrails](../../../../../scripts/docs/agentic/ai-security-guardrails.md)
- [Security Framework](../../../../../scripts/docs/infra/SECURITY_FRAMEWORK.md)
- [Agent GEDI Manifest](../agents/agent_gedi/manifest.json)



