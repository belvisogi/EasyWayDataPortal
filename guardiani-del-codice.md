# Guardiani del Codice (The Untouchables)

Questo documento definisce il concetto e la proposta operativa dei "Guardiani del Codice": agenti/auditor incorruttibili (stile Batman/Untouchables) che non fanno feature, ma proteggono il sistema con regole, prove e gate deterministici.

## Perche' esistono
Il problema non sono gli agenti in se'. Il problema e' l'assenza di fondamenta:
- Loop di completamento ("finche' non ho una risposta, continuo")
- Metriche su task done invece che su verita', qualita', riproducibilita'
- Poco o zero audit trail
- Zero validazione scientifica
- Sicurezza trattata come post-it mentale
- Fiducia cieca: "se funziona una volta, va bene"

I Guardiani ribaltano questa logica: AI come sistema regolato, non magia.

## Principi (coerenti con goals.json)
- Human-in-the-loop: decisioni importanti sempre confermabili
- Trasparenza: piani, esiti e log strutturati ricostruibili
- Idempotenza: check e script ripetibili, sicuri
- Documentazione viva: KB + Wiki allineate ai cambi
- Policy e gates: qualita' automatica e comprensibile
- Parametrizzazione: zero hardcode, segreti fuori dal repo
- Osservabilita': eventi e metriche (almeno eventi)

## Identita': anti-eroi, ma eroi
Sono potenti ma mai "trusted-by-default".
- Non "sanno la verita'": producono esiti misurabili + evidenze.
- Hanno confini duri: allowed_paths e perimetri espliciti.
- Non si negoziano in runtime: regole versionate e deterministiche.

## Due fasi (audit prima, assunzione dopo)

### Fase 1 - External Audit (read-only, non bloccante)
Obiettivo: far vedere la realta' a chi non li ha mai "visti".
- Scansionano repo/agents/wiki/pipeline e producono:
  - Report machine-readable (JSON)
  - Report umano (Markdown)
  - Lista issue (severita' + evidenze + next step)
- Niente auto-fix di default (solo suggerimenti / patch proposte).

Deliverable tipici:
- `out/guardians-audit.json`
- `out/guardians-audit.md`
- `out/issues.json`
- (opzionale) attestato negativo "Found Wanting" se fallisce hard-fail.

### Fase 2 - Assunzione (integrati, con potere)
Obiettivo: trasformare i guardiani in gate non bypassabili.
- Entrano nel "sacred path" (es. `ewctl check` + CI).
- Solo i guardiani assunti diventano bloccanti.
- Eccezioni solo se tracciate (decision trace).

## Hard laws (non negoziabili)
Queste regole devono portare a FAIL oggettivo.
- No secrets in repo (token/password/chiavi)
- No scope break: modifiche fuori `allowed_paths`
- No skip validation: check riproducibili (lint/test/build) mancanti o rossi
- No bypass policy/approval (quando richiesto)

## Squadra minima (proposta)
1) Guardiano Confini (Scope/Paths)
- Input: diff (git), manifest/agent
- Output: pass/fail + lista violazioni (file)

2) Guardiano Qualita' (Determinismo)
- Input: diff + comandi standard di check
- Output: pass/warn/fail + "how to reproduce" + log sintetico

3) Guardiano Sicurezza (Secrets/Injection)
- Input: diff + KB/Wiki/recipes
- Output: severita' + match + evidenza (file/linea)

4) Guardiano Tracciabilita' (Audit/Decision Trace)
- Input: PR/commit + intent dichiarato + artefatti
- Output: pass/fail + cosa manca (preciso)

5) Guardiano Coerenza Docs/KB (Living Docs)
- Input: diff su DB/API/Wiki/CI
- Output: pass/warn/fail + file richiesti mancanti

## Certificati di affidabilita'
I guardiani possono rilasciare un attestato basato su misure e prove.

### Tiers (doppia etichetta: canonico + storytelling)
- Clean (Bronze)
- Sharp (Silver)
- Untouchable (Gold)

### WARN
`warn` non e' un tier: e' uno stato.
- `outcome`: `pass|warn|fail`
- `tier_*` valorizzato solo se `outcome != fail`

Interpretazione:
- `pass + Clean (Bronze)` = baseline ok, zero warning bloccanti
- `warn + Clean (Bronze)` = certificato rilasciato con riserve (azioni consigliate)
- `fail` = niente certificato (o attestato negativo "Found Wanting")

### Formato minimo certificato (machine-verifiable)
Campi consigliati:
- `issuer`: nome guardiani + versione regole
- `subject`: repo + branch + commit SHA
- `timestamp`
- `scope`: percorsi/ambiente
- `controls[]`: controlli eseguiti
- `results[]`: esiti per controllo (pass/warn/fail) + reason
- `evidence[]`: riferimenti a file/linee/log/artefatti
- `outcome`: pass|warn|fail
- `tier_canonical`: bronze|silver|gold (se non fail)
- `tier_label`: Clean|Sharp|Untouchable (se non fail)
- `valid_until`: scadenza (il mondo cambia)

## Contratto unico per i report (proposta)
Ogni guardiano produce output strutturato omogeneo.
- `correlation_id`
- `guardian`: id e versione
- `checks[]`: { id, outcome, reason, evidence[], next[] }
- `summary`: contatori per severita'

Issue record minimo:
- `id`
- `severity`: critical|high|medium|low
- `message`
- `evidence`: { path, line?, snippet?, tool? }
- `remediation`: azione consigliata

## Rollout per test su 2 persone
1) Shadow mode (1-2 settimane)
- Non bloccano, solo report.
- Si confronta con code review umana.
- Metriche: false positive/negative, riproducibilita', tempo risparmiato.

2) Advisory gate
- Blocca solo hard laws (secrets/scope/test rossi).
- Il resto e' warn con next steps.

3) Full gate (solo dopo tuning)
- I tier diventano requisito per merge/deploy.

## Integrazione consigliata (EasyWayDataPortal)
Opzione preferita: integrarli come gates nel "kernel" `ewctl` (sacred path) e farli girare anche in CI.
- Locale: `ewctl check --json`
- CI: job governance gates + publish artifacts (report/certificato)

Nota: in repo esistono gia' molte fondamenta:
- goals/principi: `agents/goals.json`
- workflow standard: `agents/AGENT_WORKFLOW_STANDARD.md`
- kernel ewctl: `scripts/pwsh/ewctl.ps1`
- enforcer allowed_paths: `scripts/pwsh/enforcer.ps1`
- agent audit: `scripts/pwsh/agent-audit.ps1`
- kb security scan: `scripts/python/kb-security-scan.py`
- events log: `agents/logs/events.jsonl`
- orchestrations WHAT-first in Wiki

## Primo "fix" utile (guardrail reale)
In `azure-pipelines.yml` e' presente il richiamo a `scripts/enforcer.ps1`, ma il file e' `scripts/pwsh/enforcer.ps1`.
Se non e' allineato, il gate rischia di non girare.

## Prossimi passi (scelta)
1) Definire 6-10 controlli canonici per il certificato Clean/Sharp/Untouchable.
2) Implementare la Fase 1: un comando unico che genera `guardians-audit.json` + `guardians-audit.md`.
3) Fare 2 settimane di shadow mode su voi due, raccogliere metriche e tarare le regole.
4) Assunzione: promuovere solo 1-2 guardiani a hard-gate (secrets + allowed_paths) e poi aggiungere gli altri.
## Esempi (redatti) e template
Questi file mostrano il formato standard senza includere dettagli sensibili:
- `docs/guardiani/examples/audit-report.example.redacted.md`
- `docs/guardiani/examples/remediation-plan.example.redacted.md`

Nota: report reali con IP pubblici/chiavi/credenziali devono stare fuori repo oppure essere pesantemente redatti.

