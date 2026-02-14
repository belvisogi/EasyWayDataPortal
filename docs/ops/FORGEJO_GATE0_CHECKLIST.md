# Forgejo Gate 0 Checklist

Date: 2026-02-12  
Scope: Local/server Forgejo recovery and standardization

## Gate 0 Items (must be all `PASS`)

1. Branch created for scoped fix work (`fix-forgejo-local`).
Status: PASS

2. Canonical infra config exists in repo (`infra/forgejo/docker-compose.yml`).
Status: PASS

3. Secrets are externalized (`infra/forgejo/.env`, template committed).
Status: PASS (`.env.example` committed)

4. Runner startup mode validated (`daemon` + persistent registration).
Status: PASS (compose command updated)

5. Runner registration flow documented.
Status: PASS (`infra/forgejo/README.md`)

6. CI workflow env contract aligned with API auth vars.
Status: PASS (`AUTH_JWKS_URI` in `.forgejo/workflows/ci.yaml`)

7. Runtime verification executed on target host.
Status: PENDING (run deploy commands on server)

## Next Step (Gate 1)

Run on server:

```bash
cd ~/EasyWayDataPortal/infra/forgejo
cp .env.example .env   # if missing
# set RUNNER_TOKEN in .env
docker compose --env-file .env up -d
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs --tail 80 forgejo-runner-1
```

## Gate 0.5 - Git Branch Stability (ADO/GitHub/Forgejo)

1. Remoti migrati a SSH (`ado`, `github`, `forgejo`) con script standard.
Status: PENDING (`scripts/pwsh/set-git-remotes-ssh.ps1`)

2. Push multi-remote con verifica post-push multi-pass.
Status: PENDING (`scripts/pwsh/push-all-remotes.ps1`)

3. Monitor anti-sparizione branch attivo con log.
Status: PENDING (`scripts/pwsh/watch-branch-presence.ps1`)

4. Playbook incident branch disappearance disponibile.
Status: PASS (`docs/ops/BRANCH_DISAPPEARANCE_PLAYBOOK.md`)
