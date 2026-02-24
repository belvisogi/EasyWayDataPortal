# HANDOFF LATEST — EasyWayDataPortal

> **Documento canonico di sessione.**
> Aggiornalo in-place a fine sessione, poi archivia con:
> `cp docs/HANDOFF_LATEST.md docs/HANDOFF_SESSION_<N>.md`

---

<!-- ═══════════════════════════════════════════════════════════
     SEZIONE VARIABILE — aggiornare ad ogni sessione
     ═══════════════════════════════════════════════════════════ -->

## Sessione corrente

> **Sessione**: 19
> **Data**: 2026-02-24
> **Branch attivo**: `feature/session19-l2-batch-upgrade`

### Completato

1. Merge `feature/skills-framework-agents` → `develop` (local merge completato)
2. Batch upgrade L2 — 5 agenti:
   - `agent_review`, `agent_release`, `agent_pr_manager`, `agent_developer`, `agent_observability`
   - manifest v2 (`level`, `skills`, `actions` object map)
   - runner con telemetria JSONL (`Measure-AgentAction`)
3. Nuovo test `agents/tests/AgentFormalizationL2.Tests.ps1`
4. Wiki `docs/wiki/Skills-Framework.md` aggiornata con stato formalizzazione

### Stato piattaforma

| Metrica | Valore |
|---|---|
| Agenti formalizzati | **7 / 34** |
| Qdrant chunk | 66,813 |
| Ultima release | PR #122 → main |
| Server commit | `e3fe530` |

**Set formalizzato**: agent_discovery, agent_backlog_planner, agent_review, agent_release,
agent_pr_manager, agent_developer, agent_observability

### Prossimi step

1. PR `feature/session19-l2-batch-upgrade → develop`
2. Release PR `develop → main` (merge no fast-forward)
3. Server `git pull` + Qdrant re-index se nuovi doc wiki
4. Batch successivo → target **10/34**:
   - `agent_security` (L3)
   - `agent_scrummaster` (L3)
   - `agent_dba` (L2)

### Compatibilità / Rollback

- Schema `agents/manifest.schema.json` accetta sia `actions` array (legacy) sia `actions` object map (v2)
- Runner L2 sono additivi: non rimuovono script legacy in `scripts/pwsh/`

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
