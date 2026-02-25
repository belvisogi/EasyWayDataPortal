# HANDOFF LATEST — EasyWayDataPortal

> **Documento canonico di sessione.**
> Aggiornalo in-place a fine sessione, poi archivia con:
> `cp docs/HANDOFF_LATEST.md docs/HANDOFF_SESSION_<N>.md`

---

<!-- ═══════════════════════════════════════════════════════════
     SEZIONE VARIABILE — aggiornare ad ogni sessione
     ═══════════════════════════════════════════════════════════ -->
## Sessione corrente

> **Sessione**: 20
> **Data**: 2026-02-25
> **Branch attivo**: `main`

### Completato

- Merge PR #144: Release: backoffice wiring - nav, data-list, mock data (7241da8)
- Merge PR #142: [Release] Session 23-C — OpenAPI v0.3.0 + API contracts + audit clean (e19c177)
- Merge PR #140: [Release] Session 23-B — backoffice agents slice + i18n completo (6d13f36)
- Merge PR #138: [Release] Session 23 — Valentino framework + backoffice slice 1 (fbc4f83)
- Merge PR #136: Release: agent_backend L2 + agent_frontend L2 + Caddy fix (9e04aa3)

### Stato piattaforma

| Metrica | Valore |
|---|---|
| Agenti formalizzati | **7 / 34** |
| Qdrant chunk | 121370 |
| Ultima release | PR #144 |
| Server commit | `7241da8` |

### Prossimi step

1. 1. Update agents_formalized count in HANDOFF_LATEST.md (verify from agents/ directory)
2. 2. Create new feature branch for session 20 tasks (e.g., feature/session20-docs-audit)

---

<!-- ═══════════════════════════════════════════════════════════
     SEZIONE STABILE — modifica solo se cambiano le regole
     ═══════════════════════════════════════════════════════════ -->
## File chiave

| File | Scopo |
|---|---|
| `docs/HANDOFF_LATEST.md` | **Questo file** — stato corrente + regole |
| `docs/wiki/Skills-Framework.md` | Modello ibrido global/agent-specific |
| `agents/manifest.schema.json` | Schema v2 manifest agenti |
| `agents/tests/AgentFormalizationL2.Tests.ps1` | Conformance test batch |
| `docs/skills/catalog.json` | Macro-skill layer |
| `docs/skills/catalog.generated.json` | Generato — non editare a mano |
| `apps/agent-console/index.html` | Console UI |
| `config/platform-config.json` | Config ADO Scrum + Platform Adapter SDK |
| `agents/skills/registry.json` | Runtime skills (v2.9.0, 25 skill) |

## Regole operative

- Commit: `ewctl commit` — mai `git commit` diretto
- MAI commit diretto su `main` / `develop` / `baseline`
- MAI votare o completare PR senza ok esplicito utente
- Merge strategy `develop → main`: **"Merge (no fast-forward)"** — mai Squash
- Ogni runner L2/L3: chiama `Import-AgentSecrets` al boot
- PR description: Summary + Test plan + Artefatti, titolo ≤ 70 char
- SSH remote: singoli apici per evitare espansione locale

## Gate qualità (prima di ogni PR)

1. Pester full suite
2. Conformance pass (adapters + AgentFormalizationL2)
3. Nessuna regressione su `scripts/pwsh/platform-plan.ps1`

## Accesso server

```bash
"/c/Windows/System32/OpenSSH/ssh.exe" -i "/c/old/Virtual-machine/ssh-key-2026-01-25.key" ubuntu@80.225.86.168
```

- Secrets: `/opt/easyway/.env.secrets` (DEEPSEEK_API_KEY, GITEA_API_TOKEN, QDRANT_API_KEY)
- Qdrant: `http://localhost:6333`, collection `easyway_wiki`
- Gitea: `http://localhost:3100`, admin `easywayadmin`

---

## Storico sessioni

| N | Data | Branch | Formalizzati | Qdrant | Highlight |
|---|---|---|---|---|---|
| 19 | 2026-02-24 | feature/session19-l2-batch-upgrade | 7/34 | 66,813 | Batch L2: 5 agenti, conformance test |
| 18 | 2026-02-23 | feature/skills-framework-agents | 2/34 | — | Skills Framework + discovery + backlog_planner |
| 17 | 2026-02-23 | — | 2/34 | — | Pester 45/45, PR #112-118, PBI #19/20/21 |
| 16 | 2026-02-23 | feature/platform-adapter-sdk | — | 66,813 | Platform Adapter SDK, Scrum migration |
| 15 | 2026-02-19 | — | — | 66,813 | agent_infra L3, compliance-check, E2E PASSED |

