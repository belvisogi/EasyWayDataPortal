# Repo Scope Policy (Keep It Clean)

Versione: 1.0 (2026-02-24)  
Scope: `EasyWayDataPortal` (repo core runtime)

## Obiettivo

Tenere nel repo solo cio che serve a build, test, deploy e governance operativa del portale.

## Dentro il Repo (canonico)

- Codice applicativo (`apps/`, `portal-api/`, `packages/`)
- Script runtime e automazione (`scripts/`, `ewctl.ps1`)
- Test e conformance (`tests/`, `agents/tests/`)
- Manifest/Policy agenti (`agents/**/manifest.json`, guardrail)
- Documentazione operativa (`docs/ops/`, runbook, checklist)

## Fuori Repo (locale o repo separato)

- Segreti e token reali (`.env*` reali, registry sensibili)
- Log runtime (`logs/`, audit dump locali)
- Cartelle workbench temporanee (`New folder/`, `scratch/`, `tmp/`)
- Note strategiche non runtime (es. `#innovazione_agenti/`)
- Backup/artifact locali non riproducibili

## Regola Decisionale

Se un file non e richiesto per:

1. eseguire test/conformance,
2. rilasciare il sistema,
3. tracciare policy operative,

allora non deve stare nel repo core.

## Checklist pre-PR

- [ ] Nessun `.env` reale o segreto in stage.
- [ ] Nessun log locale o file temporaneo.
- [ ] Solo file runtime/governance necessari.
- [ ] Build/test locali eseguiti prima della PR.

## Riferimenti

- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/SECURITY_SCORECARD.md`
- `.gitignore`
