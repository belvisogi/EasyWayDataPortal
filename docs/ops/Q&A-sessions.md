# Q&A Sessioni Agentiche — Errori Ricorrenti

Tracciamento errori commessi durante sessioni agentiche per prevenire ricorrenze.

## Template Entry

| Campo | Valore |
|-------|--------|
| **Data** | YYYY-MM-DD |
| **Sessione** | P1/P2/P3/... |
| **Errore** | Descrizione breve |
| **Impatto** | Cosa è successo |
| **Fix applicato** | Cosa è stato fatto per correggere |
| **Prevenzione** | Regola/guardrail aggiunto |

---

## Registro

### 2026-02-16 — Lavoro diretto su develop senza feature branch

| Campo | Valore |
|-------|--------|
| **Data** | 2026-02-16 |
| **Sessione** | P3 — Workflow Intelligence |
| **Errore** | L'agente ha iniziato a lavorare direttamente su `develop` invece di creare un feature branch |
| **Impatto** | Commit su branch protetto, rischio di merge non governato |
| **Fix applicato** | Creato `feature/p3-workflow-intelligence`, cherry-pick dei commit, reset di develop |
| **Prevenzione** | Aggiunta regola PRD §22.19 (Agent Pre-Flight Branch Check) + workflow `.agent/workflows/start-feature.md` |
