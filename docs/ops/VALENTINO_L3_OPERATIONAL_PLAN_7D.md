# Valentino L3 - Piano Operativo 7 Giorni

Versione: 1.0  
Data di avvio proposta: 2026-02-25  
Ambiente target test: `http://80.225.86.168/`

## Obiettivo
Validare in produzione controllata che l'agente `Valentino L3`:
- rispetti i guardrail (`OPS` vs `PRODUCT`)
- produca review utili e patch minime
- non introduca regressioni evitabili

## Scope
- `apps/agent-console` (primario)
- `apps/portal-frontend` (solo verifica boundary, no espansione scope)

## Prerequisiti (Day 0)
- [ ] Skill nel repo disponibili:
  - `.agents/skills/valentino-web-guardrails`
  - `.agents/skills/web-design-guidelines`
- [ ] Documenti presenti:
  - `docs/ops/VALENTINO_L3_AGENT_PROFILE.md`
  - `docs/ops/VALENTINO_ANTIFRAGILE_GUARDRAILS.md`
  - `docs/ops/VALENTINO_SITE_APP_CONSOLE_PLAYBOOK.md`
- [ ] URL test raggiungibile (`HTTP 200` su `http://80.225.86.168/`)

## Piano 7 Giorni

## Giorno 1 (2026-02-25) - Baseline Audit
- Eseguire audit su `apps/agent-console/index.html` con `valentino-web-guardrails`.
- Classificare findings: `high`, `medium`, `low`.
- Aprire backlog azioni minime.

Done:
- [ ] Report findings con `file:line`
- [ ] Lista fix ordinata per severita

## Giorno 2 (2026-02-26) - Hardcoded & Data Contract
- Rimuovere/isolare metriche hardcoded runtime.
- Validare schema dati agenti (`schemaVersion`, `status`, `lastHeartbeat`, ecc.).

Done:
- [ ] Nessun hardcoded runtime critico
- [ ] Contratto dati documentato o verificato

## Giorno 3 (2026-02-27) - Boundary Check
- Applicare `FRONTEND_FEATURE_BOUNDARY_TEMPLATE.md` su 1 feature reale.
- Verificare assenza overlap tra `agent-console` e `portal-frontend`.

Done:
- [ ] Feature classificata `OPS` o `PRODUCT`
- [ ] Nessuna duplicazione funzionale aperta

## Giorno 4 (2026-02-28) - Affidabilita UI Ops
- Verificare segnali di affidabilita: `health state`, error fallback, correlation context.
- Eseguire smoke test su ambiente target.

Done:
- [ ] Flow operativo minimo stabile (`overview/agents/logs`)
- [ ] Error handling verificato

## Giorno 5 (2026-03-01) - Test Reale su EasyWay
- Test manuale guidato su `http://80.225.86.168/`.
- Eseguire checklist rapida:
  1. pagina raggiungibile
  2. dati caricati
  3. navigazione principali viste
  4. nessun blocco UI critico

Done:
- [ ] Report test reale con esito `PASS/FAIL`
- [ ] Evidenze issue con priorita

## Giorno 6 (2026-03-02) - Stabilizzazione
- Correggere solo `high` e `medium`.
- Rieseguire audit con skill mista.

Done:
- [ ] Nessun `high` aperto
- [ ] `medium` con piano o fix

## Giorno 7 (2026-03-03) - Go/No-Go
- Review finale con guardrail L3.
- Decisione:
  - `GO`: agente pronto per uso operativo standard
  - `NO-GO`: tenere in modalità assistita con remediation plan

Done:
- [ ] Decisione finale documentata
- [ ] Prossimi 14 giorni pianificati

## Prompt Operativi Consigliati
1. `Usa valentino-web-guardrails e fai audit di apps/agent-console/index.html`
2. `Applica FRONTEND_FEATURE_BOUNDARY_TEMPLATE a questa feature: <feature>`
3. `Pre-merge check: segnala solo high/medium con fix minimo`

## KPI di Successo
- `0` finding `high` aperti a fine Giorno 7
- >= `90%` smoke test pass
- Tempo medio di review agente <= `15` minuti per task standard

## Regola di Pragmatismo
Se il piano genera overhead senza ridurre rischio reale entro 7 giorni:
- ridurre rituali
- mantenere solo gate che trovano difetti reali
