---
gate_id: error_messages_ux
owner: agent_gedi
category: ux_quality
severity: warning
auto_fix: false
---

# Quality Gate: Error Messages UX

## Purpose
Ensure all error messages in the application are user-friendly, actionable, and follow Italian language best practices.

## Scope
- All frontend components that display errors
- API error responses
- Form validation messages
- Toast/alert notifications

## Rules

### Rule 1: No Technical Errors to Users
**Check**: Error messages shown to users MUST NOT contain:
- Stack traces
- SQL error messages (e.g., `sp_insert_user failed`)
- Database constraint names (e.g., `UNIQUE constraint violation`)
- Internal function names
- Error codes without translation

**Example Violation**:
```tsx
// ❌ BAD
<ErrorMessage>{error.message}</ErrorMessage>
// Shows: "Error: sp_insert_user failed"

// ✅ GOOD
<ErrorToast error={errorTranslator.translate(error)} />
// Shows: "✉️ Email già registrata. Recupera password?"
```

---

### Rule 2: Italian-First Messages
**Check**: All user-facing error messages MUST be in Italian.

**Example Violation**:
```tsx
// ❌ BAD
toast.error("User already exists");

// ✅ GOOD
toast.error("Utente già esistente");
```

---

### Rule 3: Actionable Recovery
**Check**: Errors SHOULD provide recovery action when possible.

**Example Violation**:
```tsx
// ❌ BAD
{ title: "Errore", message: "Operazione fallita" }

// ✅ GOOD
{ 
  title: "Email già registrata",
  message: "Questa email è già in uso.",
  action: { label: "Recupera password", url: "/auth/forgot" }
}
```

---

### Rule 4: Severity Appropriateness
**Check**: Error severity MUST match impact:
- `error` → Blocking issues (login failed, payment failed)
- `warning` → Recoverable issues (validation, duplicates)
- `info` → Informational (quota warnings, tips)
- `success` → Confirmations

---

### Rule 5: Use ErrorTranslator Service
**Check**: All try-catch blocks MUST use `errorTranslator.translate()`.

**Example Violation**:
```tsx
// ❌ BAD
catch (err) {
  setError(err.message);
}

// ✅ GOOD
catch (err) {
  handleError(err); // uses errorTranslator internally
}
```

---

## Automated Checks

### grep-based (CI/CD)
```bash
# Detect raw error.message usage
grep -r "error\.message" src/ --include="*.tsx" --include="*.ts"

# Detect English error messages
grep -r "toast\.error\(\"[A-Z]" src/ --include="*.tsx"

# Detect alert() usage (should use toast)
grep -r "alert\(" src/ --include="*.tsx" --include="*.ts"
```

### ESLint Rules (TODO)
```json
{
  "rules": {
    "no-raw-error-message": "error",
    "require-error-translator": "error",
    "italian-error-messages": "warning"
  }
}
```

---

## Manual Review Checklist

Before merging PR with error handling:
- [ ] All errors use `errorTranslator.translate()`
- [ ] No technical details shown to user
- [ ] Messages are in Italian
- [ ] Recovery actions provided where possible
- [ ] Severity matches impact
- [ ] Accessibility tested (screen reader)

---

## Exceptions

**Allowed**:
- Technical errors in **console.error()** (for debugging)
- Error details in monitoring/logging tools
- Admin-only technical dashboards

**Example**:
```tsx
catch (err) {
  console.error('[Technical]', err); // ✅ OK for devs
  handleError(err); // ✅ User sees friendly message
}
```

---

## Enforcement

### Pre-commit
```bash
# Run grep checks
./scripts/check-error-messages.sh
```

### CI/CD
```yaml
- name: Error Messages Quality Gate
  run: |
    grep -r "error\.message" src/ && exit 1 || echo "✅ No raw errors"
    grep -r "alert\(" src/ && exit 1 || echo "✅ No alerts"
```

### Code Review
Agent GEDI reviews all PRs touching error handling and validates against this gate.

---

## Metrics

Track in `/agents/memory/error-quality-metrics.json`:
- % of errors using errorTranslator
- % of errors with recovery actions
- Average user recovery rate after error
- Support tickets related to unclear errors

---

## References
- [Error Messages Best Practices](../Wiki/frontend/error-messages-user-friendly.md)
- [ErrorTranslator Service](../easyway-webapp/05_codice_easyway_portale/easyway-portal-frontend/src/services/errorTranslator.ts)
- [GEDI Manifest](../agents/agent_gedi/manifest.json)
