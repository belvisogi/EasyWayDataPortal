# Indice OLD

Aggiornato: 2026-01-04 09:02

Questa cartella contiene file spostati per ridurre rumore nel repo. Nessun file viene cancellato.

## Contenuti (attuali)

| Old Path | Da (path originale) | SizeKB | Descrizione |
|---|---|---:|---|
| `old/artifacts/last60.txt` | `last60.txt` | 7.2 | 20251018063315Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018063315.txt, dry-run=False, global-index=False |
| `old/artifacts/tail_kb.txt` | `tail_kb.txt` | 4.4 | {"id":"kb-test-mock-jwt-024","intent":"test-mock-jwt","question":"Come eseguo un test positivo con JWT mockato?","tags":["test","jwt","supertest"],"steps":["Eseguire 'npm test' in EasyWay-DataPortal/easyway-portal-api","Il test __tests__/auth_positive.test.ts genera una coppia di chiavi e imposta AUTH_TEST_JWKS in env per validare localmente","Il token include il claim 'ew_tenant_id' e consente di accedere a /api/health"],"verify":["I test passano (200 su /api/health con token valido)"],"references":["EasyWay-DataPortal/easyway-portal-api/src/middleware/auth.ts","EasyWay-DataPortal/easyway-portal-api/__tests__/auth_positive.test.ts"],"updated":"2025-10-19T00:00:00Z"} |
| `old/artifacts/tmp_last4.txt` | `tmp_last4.txt` | 3.8 | {"id":"kb-starter-appsettings-026","intent":"apply-appsettings-starter","question":"Come applico lo starter JSON degli App Settings via Azure CLI e REST ARM?","tags":["deploy","appsettings","azure","cli","rest"],"preconditions":["az login","Permessi su Resource Group/WebApp"],"steps":["# Azure CLI (singole chiavi):","az webapp config appsettings set -g <RESOURCE_GROUP> -n <WEBAPP_NAME> --settings AUTH_ISSUER=https://login.microsoftonline.com/<TENANT_ID>/v2.0 AUTH_JWKS_URI=https://login.microsoftonline.com/<TENANT_ID>/discovery/v2.0/keys DEFAULT_TENANT_ID=tenant01 PORTAL_BASE_PATH=/portal","# Azure CLI (da file JSON key=value): creare appsettings.json con { \"name\":\"KEY\",\"value\":\"VAL\" } in array, quindi:","az webapp config appsettings set -g <RESOURCE_GROUP> -n <WEBAPP_NAME> --settings @appsettings.json","# REST ARM (via az rest):","az rest --method POST --uri https://management.azure.com/subscriptions/<SUB_ID>/resourceGroups/<RESOURCE_GROUP>/providers/Microsoft.Web/sites/<WEBAPP_NAME>/config/appsettings?api-version=2022-03-01 --body '{"properties": {"AUTH_ISSUER": "https://login.microsoftonline.com/<TENANT_ID>/v2.0", "AUTH_JWKS_URI": "https://login.microsoftonline.com/<TENANT_ID>/discovery/v2.0/keys", "DEFAULT_TENANT_ID": "tenant01", "PORTAL_BASE_PATH": "/portal"}}'"],"verify":["In Azure Portal → Configuration compaiono le nuove chiavi","L'app usa i valori aggiornati (riavvio automatico o forzato)"],"references":["Wiki/EasyWayData.wiki/DEPLOY_APP_SERVICE.md","azure-pipelines.yml"],"updated":"2025-10-19T00:00:00Z"} |
| `old/artifacts/tmp_tail.txt` | `tmp_tail.txt` | 0.5 | - DB Drift Check: oggetti richiesti presenti |
| `old/backups/agents/agent_scrummaster/README.md.bak` | `` | 1.7 |  |
| `old/backups/docs/agentic/AGENTIC_READINESS.md.bak` | `` | 5.6 |  |
| `old/backups/docs/ci/ewctl-gates.md.bak` | `` | 3.5 |  |
| `old/backups/Wiki/EasyWayData.wiki/.order.bak` | `` | 0 |  |
| `old/backups/Wiki/EasyWayData.wiki/agent-first-method.md.bak` | `` | 3 |  |
| `old/backups/Wiki/EasyWayData.wiki/agent-priority-and-checklists.md.bak` | `` | 1.9 |  |
| `old/backups/Wiki/EasyWayData.wiki/agents/agent-dq-blueprint.md.bak` | `` | 3.4 |  |
| `old/backups/Wiki/EasyWayData.wiki/agents/desktop.ini` | `` | 0 |  |
| `old/backups/Wiki/EasyWayData.wiki/argos/argos-overview.md.bak` | `` | 2.2 |  |
| `old/backups/Wiki/EasyWayData.wiki/docs-conventions.md.bak` | `` | 2.3 |  |
| `old/backups/Wiki/EasyWayData.wiki/easyway-webapp/01_database_architecture/db-studio.md.bak` | `` | 1 |  |
| `old/backups/Wiki/EasyWayData.wiki/enforcer-guardrail.md.bak` | `` | 1.2 |  |
| `old/backups/Wiki/EasyWayData.wiki/etl/atomic-flows-agentic.md.bak` | `` | 3.5 |  |
| `old/backups/Wiki/EasyWayData.wiki/howto-what-first-team.md.bak` | `` | 3.4 |  |
| `old/backups/Wiki/EasyWayData.wiki/index.md.bak` | `` | 35.6 |  |
| `old/backups/Wiki/EasyWayData.wiki/orchestrations/mapping-matrix.md.bak` | `` | 1.5 |  |
| `old/backups/Wiki/EasyWayData.wiki/start-here.md.bak` | `` | 1.1 |  |
| `old/backups/Wiki/EasyWayData.wiki/todo-checklist.md.bak` | `` | 7.7 |  |
| `old/backups/Wiki/EasyWayData.wiki/wiki-uniformamento-roadmap.md.bak` | `` | 6.9 |  |
| `old/duplicates/anchors_master_all.csv` | `anchors_master_all.csv` | 132.5 | path,level,slug,text |
| `old/duplicates/index_master_all.csv` | `index_master_all.csv` | 23.4 | path,id,title,summary,owner,tag_groups,tags,llm_include,llm_pii,entities |
| `old/duplicates/index_master_all.jsonl` | `index_master_all.jsonl` | 128.3 | {"id":"activity-log","title":"Activity Log – CSV friendly (delimiter: ¦)","summary":"Breve descrizione del documento.","path":"ACTIVITY_LOG.md","format":"md","owner":"team-docs","tags":["layer/reference","privacy/internal","language/it"],"entities":[],"llm.include":"","llm.pii":"","chunk_hint":"","updated":"2025-10-19T22:31:54+02:00","questions_answered":["Come è strutturato il log attività del progetto?","Qual è il formato esatto delle righe e il timestamp?","Dove trovo log aggregati per mese o per ambito?"],"anchors":[{"level":2,"text":"Domande a cui risponde","slug":"domande-a-cui-risponde"},{"level":2,"text":"API – Eventi approvati","slug":"api-eventi-approvati"}]} |
| `old/wiki-loose/Wiki/anchors_master_all.csv` | `Wiki/anchors_master_all.csv` | 128.1 | path,level,slug,text |
| `old/wiki-loose/Wiki/easyway-webapp.md` | `Wiki/easyway-webapp.md` | 1.2 | 🎯 **EasyWay Data Portal – Start With Why** |
| `old/wiki-loose/Wiki/Gestione-Accesso,-Registrazione,-Notifiche-e-Data-Quality-Flow.md` | `Wiki/Gestione-Accesso,-Registrazione,-Notifiche-e-Data-Quality-Flow.md` | 3.9 | EasyWay Data Portal - Documentazione Funzionale Completa |
| `old/wiki-loose/Wiki/index_master_all.csv` | `Wiki/index_master_all.csv` | 19 | path,id,title,summary,owner,tag_groups,tags,llm_include,llm_pii,entities |
| `old/wiki-loose/Wiki/index_master_all.jsonl` | `Wiki/index_master_all.jsonl` | 114.4 | {"id":"activity-log","title":"Activity Log – CSV friendly (delimiter: ¦)","summary":"Breve descrizione del documento.","path":"ACTIVITY_LOG.md","format":"md","owner":"team-docs","tags":["layer/reference","privacy/internal","language/it"],"entities":[],"llm.include":"","llm.pii":"","chunk_hint":"","updated":"2025-10-18T14:54:09+02:00","questions_answered":null,"anchors":null} |
| `old/wiki-loose/Wiki/normalize-all-20251018161530.md` | `Wiki/normalize-all-20251018161530.md` | 0.5 | Normalize Multi-Root Summary |
| `old/wiki-loose/Wiki/normalize-all-20251018161531.md` | `Wiki/normalize-all-20251018161531.md` | 0.5 | Normalize Multi-Root Summary |
| `old/wiki-loose/Wiki/OtherWiki/anchors_master.csv` | `` | 0.1 | path,level,slug,text |
| `old/wiki-loose/Wiki/OtherWiki/index_master.csv` | `` | 0.3 | "path","id","title","summary","owner","tag_groups","tags","llm_include","llm_pii","entities" |
| `old/wiki-loose/Wiki/OtherWiki/index_master.jsonl` | `` | 0.6 | {"id":"other-readme","title":"OtherWiki - Readme","summary":"Esempio di root secondaria per test multi‑root e manifest.","path":"README.md","format":"md","owner":"team-docs","tags":["layer/reference","language/it"],"entities":[],"llm.include":"","llm.pii":"","chunk_hint":"","updated":"2025-10-18T15:19:39+02:00","questions_answered":["Cos'è questa root di esempio?","Come viene inclusa nel manifest multi‑root?","Dove trovare gli artefatti generati?"],"anchors":[{"level":2,"text":"Esempio codice","slug":"esempio-codice"},{"level":2,"text":"Domande a cui risponde","slug":"domande-a-cui-risponde"}]} |
| `old/wiki-loose/Wiki/OtherWiki/logs/reports/normalize-20251018141531Z-OtherWiki.md` | `` | 0.5 | Normalize Scan Report |
| `old/wiki-loose/Wiki/OtherWiki/logs/reports/normalize-20251018141538Z-OtherWiki.md` | `` | 0.6 | Normalize Scan Report |
| `old/wiki-loose/Wiki/OtherWiki/README.md` | `` | 0.6 | OtherWiki - Readme |
| `old/wiki-loose/Wiki/START_HOW_TO_START.md` | `Wiki/START_HOW_TO_START.md` | 4.2 | Da dove iniziare — Piano operativo per l'MVP agentico |
| `old/wiki-loose/Wiki/Untitled.canvas` | `Wiki/Untitled.canvas` | 0 |  |
| `old/wiki-loose/Wiki/UX/agentic-ux-guidelines.md` | `` | 5.5 | Linee guida UX per agenti e LLM — formato leggibile dalle macchine |
| `old/wiki-loose/Wiki/UX/agentic-ux.md` | `` | 9.5 | UX & API Spec — Plan Viewer, Wizard e WhatIf (bozza) |

## Log mosse

## Moved batches
- Batch 1 executed: 2026-01-04 08:43
- last60.txt -> old/artifacts/last60.txt [moved]
- tail_kb.txt -> old/artifacts/tail_kb.txt [moved]
- tmp_last4.txt -> old/artifacts/tmp_last4.txt [moved]
- tmp_tail.txt -> old/artifacts/tmp_tail.txt [moved]
- anchors_master_all.csv -> old/duplicates/anchors_master_all.csv [moved]
- index_master_all.csv -> old/duplicates/index_master_all.csv [moved]
- index_master_all.jsonl -> old/duplicates/index_master_all.jsonl [moved]
- Wiki/easyway-webapp.md -> old/wiki-loose/Wiki/easyway-webapp.md [moved]
- Wiki/Gestione-Accesso,-Registrazione,-Notifiche-e-Data-Quality-Flow.md -> old/wiki-loose/Wiki/Gestione-Accesso,-Registrazione,-Notifiche-e-Data-Quality-Flow.md [moved]
- Wiki/START_HOW_TO_START.md -> old/wiki-loose/Wiki/START_HOW_TO_START.md [moved]
- Wiki/normalize-all-20251018161530.md -> old/wiki-loose/Wiki/normalize-all-20251018161530.md [moved]
- Wiki/normalize-all-20251018161531.md -> old/wiki-loose/Wiki/normalize-all-20251018161531.md [moved]
- Wiki/Untitled.canvas -> old/wiki-loose/Wiki/Untitled.canvas [moved]
- Wiki/anchors_master_all.csv -> old/wiki-loose/Wiki/anchors_master_all.csv [moved]
- Wiki/index_master_all.csv -> old/wiki-loose/Wiki/index_master_all.csv [moved]
- Wiki/index_master_all.jsonl -> old/wiki-loose/Wiki/index_master_all.jsonl [moved]
- Wiki/UX -> old/wiki-loose/Wiki/UX [moved]
- Wiki/OtherWiki -> old/wiki-loose/Wiki/OtherWiki [moved]





## Candidati (non ancora spostati)

Nessun candidato al momento: i file in root sono stati **agganciati** (README/Wiki) e/o sono **runtime asset**.
---
## Root file status


Snapshot: 2026-01-04 09:02

| File | SizeKB | RefCount | Action |
|---|---:|---:|---|
| `home_easyway.html` | 8.2 | 3 | KEEP (runtime asset: /portal/home) |
| `palette_EasyWay.html` | 3.9 | 3 | KEEP (runtime asset: /portal/palette) |
| `logo.png` | 2 | 7 | KEEP (runtime asset: /portal/logo.png) |
| `ADA Reference Architecture.pdf` | 3406.6 | 1 | KEEP (linked in Wiki legacy reference) |
| `ADA Reference Architecture.pptx` | 1571.2 | 4 | KEEP (linked + used by scripts) |
| `ADA_Reference_Architecture_text.txt` | 0.8 | 2 | KEEP (generated support text + linked) |
| `DR_Plan_ADA.docx` | 4850.7 | 2 | KEEP (linked in Wiki DR notes) |
| `DEVELOPER_ONBOARDING.md` | 2.5 | 2 | KEEP (linked from README + Wiki) |
| `Sintesi_EasyWayDataPortal.md` | 2.2 | 2 | KEEP (linked from README + Wiki) |
| `VALUTAZIONE_EasyWayDataPortal.md` | 7.8 | 5 | KEEP (linked from README + Wiki) |
