# Agent Tiering Matrix (L1-L2-L3)

Versione: 1.0 (2026-02-24)  
Scope: EasyWayDataPortal - ADO-first con estensione GitHub parity

## Obiettivo

Definire il tier operativo di ogni agente, con criteri di promozione e guardrail minimi.

## Tier Model

- `L1` = esecuzione deterministica (azioni ripetibili, basso margine decisionale)
- `L2` = orchestrazione guidata (coordina flussi con regole, no decisioni strategiche autonome)
- `L3` = decisione/governance (valutazione rischio, policy reasoning, quality gates)

## Assegnazione Corrente

| Agente | Tier target | Razionale | Gate obbligatori |
|---|---|---|---|
| `agent_developer` | L1 | branch/push/PR operativo | branch policy + no direct commit su `develop/main` |
| `agent_executor` (`svc-agent-ado-executor`) | L1 | apply ADO/work item con scope limitato | least privilege + audit log |
| `agent_discovery` | L1 | read-only context gathering | no write access |
| `agent_scrum_master` | L2 | planning/sprint/board/reporting | human checkpoint su cambi strutturali |
| `agent_infra` | L2 | drift/runbook automation | approval umano su apply critici |
| `agent_governance` | L3 | policy enforcement e decision gate | traccia decisioni + escalation |
| `agent_planner` | L3 | prioritizzazione e planning cross-domain | validazione umana piano finale |
| `agent_review` | L3 | valutazione qualità/rischio | indipendenza da autore/modifica |
| `agent_security` | L3 | threat/risk/compliance assessment | evidence obbligatoria + approver umano |

## Runlist Operativa (Prossime Attivita)

- [ ] Validare `tier` e `allowed_actions` per ogni agente nel registro RBAC.
- [ ] Formalizzare `human_gate_required` per azioni critiche (merge/release/apply infra).
- [ ] Agganciare test conformance per tier (fallimento se L1 tenta azione L3).
- [ ] Registrare audit trail di 2 cicli consecutivi senza bypass policy.
- [ ] Rieseguire scorecard e confermare mantenimento `>= 8.5`.

## Criteri di Promozione Tier

Un agente puo salire di tier solo se:

1. ha superato almeno 2 cicli consecutivi senza violazioni policy;
2. tutte le azioni del tier corrente sono auditabili end-to-end;
3. esiste rollback documentato e testato per le azioni nuove;
4. owner governance approva formalmente la promozione.

## Criteri di Demotion Tier

Un agente deve tornare al tier precedente se:

1. causa bypass policy o esecuzioni non autorizzate;
2. manca evidenza audit minima richiesta;
3. i gate umani risultano aggirati o non applicati.

## Riferimenti

- `docs/ops/GOVERNANCE_RIGOROSA_CHECKLIST.md`
- `docs/ops/SECURITY_SCORECARD.md`
- `docs/ops/MULTI_PROVIDER_SECURITY_PARITY_MATRIX.md`
