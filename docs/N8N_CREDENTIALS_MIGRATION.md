# N8N Environment Variable Migration Guide

## Security Change Summary

As of **2026-02-07**, the environment variable `N8N_BLOCK_ENV_ACCESS_IN_NODE` has been set to `true` for security.

**Why?** When set to `false`, n8n workflows can access ALL environment variables via `process.env`, including:
- Database passwords (`SQL_SA_PASSWORD`, `POSTGRES_PASSWORD`)
- API keys (`OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, `DEEPSEEK_API_KEY`)
- Cloud credentials (`MINIO_ROOT_PASSWORD`, `QDRANT_API_KEY`)
- Authentication tokens

This represents a **critical security vulnerability** if:
- Untrusted users can create workflows
- Workflows are imported from external sources
- A workflow is compromised

## Impact Assessment

### Files Affected
- `docker-compose.yaml` (Mac Mini configuration) - **UPDATED**

### Other Files
- `docker-compose.yml`, `docker-compose.prod.yml`, `docker-compose.apps.yml` - Already use default `true` ✅

### Workflows That May Break
Any n8n workflow using `process.env` to access environment variables will fail after this change.

**Search Syntax to Find Affected Workflows:**
```javascript
process.env
```

## Migration Options

### Option 1: N8N Credentials (Recommended) ⭐

Use n8n's built-in credentials system for secure secret management.

**Steps:**
1. Go to n8n UI → **Settings** → **Credentials**
2. Click **Add Credential**
3. Create credential for each service (OpenAI, Qdrant, etc.)
4. Reference credentials in workflow nodes

**Advantages:**
- Encrypted at rest
- Access control per credential
- Audit logging
- Best practice

**Example:**
```javascript
// OLD (blocked):
const apiKey = process.env.OPENAI_API_KEY;

// NEW (credentials):
// Use the OpenAI credential in the node configuration
// n8n automatically injects the API key
```

---

### Option 2: Workflow Environment Variables (Whitelist Approach)

Explicitly pass specific variables to n8n (whitelist instead of allowing all).

**docker-compose configuration:**
```yaml
n8n:
  environment:
    # Only expose what's needed
    - N8N_OPENAI_API_KEY=${OPENAI_API_KEY}
    - N8N_QDRANT_HOST=qdrant
    - N8N_QDRANT_API_KEY=${QDRANT_API_KEY}
```

**Workflow access:**
```javascript
// Access via $env (not process.env)
const apiKey = $env.N8N_OPENAI_API_KEY;
```

**Advantages:**
- Explicit control over exposed variables
- Easy to audit
- Works for simple use cases

**Disadvantages:**
- Requires container restart to change variables
- Less flexible than credentials

---

### Option 3: N8N Variables

Use n8n's built-in Variables feature for configuration.

**Steps:**
1. Go to n8n UI → **Settings** → **Variables**
2. Add key-value pairs (e.g., `QDRANT_HOST=qdrant`)
3. Reference in workflows: `$vars.QDRANT_HOST`

**Advantages:**
- Centralized configuration
- No container restart needed
- UI-based management

**Disadvantages:**
- Not suitable for secrets (stored in plaintext in database)
- Use only for non-sensitive configuration

---

## Migration Checklist

### Pre-Migration
- [ ] Export all n8n workflows (backup)
  ```bash
  # Via n8n CLI
  n8n export:workflow --all --output=./backup/workflows.json

  # Or via UI: Settings → Workflows → Export All
  ```
- [ ] Search workflows for `process.env` usage
  ```bash
  grep -r "process\.env" ./n8n-data/workflows/
  ```
- [ ] Document affected workflows

### Migration Steps
- [ ] For each affected workflow:
  - [ ] Identify which environment variables are used
  - [ ] Choose migration option (Credentials, Env Vars, or Variables)
  - [ ] Update workflow nodes to use new method
  - [ ] Test workflow execution
- [ ] Enable `N8N_BLOCK_ENV_ACCESS_IN_NODE=true`
- [ ] Restart n8n container
  ```bash
  docker-compose restart n8n
  ```
- [ ] Test all workflows
- [ ] Monitor logs for errors
  ```bash
  docker-compose logs n8n -f
  ```

### Post-Migration
- [ ] Verify all critical workflows execute successfully
- [ ] Update workflow documentation
- [ ] Train team on new credential management
- [ ] Remove old `process.env` references from workflow templates

---

## Troubleshooting

### Workflow Fails After Migration

**Error:**
```
TypeError: Cannot read property 'OPENAI_API_KEY' of undefined
```

**Solution:**
The workflow is still trying to access `process.env`. Update to use:
- n8n Credentials (recommended)
- `$env.N8N_VARIABLE_NAME` (if using Option 2)
- `$vars.VARIABLE_NAME` (if using Option 3)

### n8n Won't Start After Enabling Block

**Error:**
```
n8n container exits immediately
```

**Solution:**
Check for syntax errors in docker-compose.yaml:
```bash
docker-compose config
```

### Credential Not Found in Workflow

**Error:**
```
Credential "OpenAI" not found
```

**Solution:**
1. Go to n8n UI → Settings → Credentials
2. Verify credential exists and is named exactly as referenced in workflow
3. Check credential has correct permissions (user/workflow access)

---

## Security Best Practices

### Do's ✅
- **Use n8n Credentials** for secrets (API keys, passwords)
- **Use n8n Variables** for non-sensitive config (hostnames, ports)
- **Whitelist environment variables** if using Option 2 (only expose what's needed)
- **Audit workflow imports** from external sources

### Don'ts ❌
- **Never disable `N8N_BLOCK_ENV_ACCESS_IN_NODE`** in production
- **Never store secrets in n8n Variables** (use Credentials instead)
- **Never commit** `.env` files with real secrets to git
- **Never share** n8n credentials across environments (dev/staging/prod)

---

## Additional Resources

- [n8n Security Best Practices](https://docs.n8n.io/hosting/security/)
- [n8n Credentials Documentation](https://docs.n8n.io/credentials/)
- [n8n Variables Documentation](https://docs.n8n.io/hosting/environment-variables/)

---

## Support

If you encounter issues during migration:
1. Check n8n logs: `docker-compose logs n8n -f`
2. Verify workflow syntax in n8n editor
3. Test with minimal workflow first
4. Consult team lead for complex workflows

---

**Last Updated:** 2026-02-07
**Security Change Reference:** Security Hardening - Task 4
