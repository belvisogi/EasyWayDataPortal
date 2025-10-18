---
id: activity-log
title: Activity Log – CSV friendly (delimiter: ¦)
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - layer/reference
  - privacy/internal
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
---
# Activity Log – CSV friendly (delimiter: ¦)

Columns: `timestampUTC¦type¦scope¦status¦owner¦message`
Notes: timestamp in UTC (yyyyMMddHHmmssZ). One action per line.

20251018100000Z¦SCAN¦wiki¦success¦team-docs¦Scansione H1–H3 e rilevamento nomi problematici in EasyWayData.wiki (percent-encoding, backtick, maiuscole, char non-ASCII)
20251018100500Z¦DOC¦conventions¦success¦team-docs¦Creata guida regole: EasyWayData.wiki/DOCS_CONVENTIONS.md
20251018101000Z¦DOC¦checklist¦success¦team-docs¦Creata checklist LLM: EasyWayData.wiki/LLM_READINESS_CHECKLIST.md
20251018101500Z¦DATA¦entities¦success¦team-docs¦Creato dizionario entità: EasyWayData.wiki/entities.yaml (endpoint, SP, sequence, policy, flussi, standard)
20251018102000Z¦RENAME¦endpoint¦success¦team-api¦Rinomina pilota endpoint con schema type-nnn-slug e aggiunta front matter YAML
20251018102100Z¦ADD¦endpoint¦success¦team-api¦Aggiunto endpoint: .../ENDPOINT/endp-001-get-api-config.md
20251018102200Z¦ADD¦endpoint¦success¦team-api¦Aggiunto endpoint: .../ENDPOINT/endp-002-get-api-branding.md
20251018102300Z¦ADD¦endpoint¦success¦team-api¦Aggiunto endpoint: .../ENDPOINT/endp-003-get-crud-api-users.md
20251018102500Z¦UPDATE¦entities¦success¦team-api¦Aggiornato entities.yaml con nuovi percorsi endpoint
20251018103000Z¦INDEX¦endpoint¦success¦team-api¦Creato indice endpoint: .../ENDPOINT/INDEX.md
20251018103500Z¦CHECK¦links¦success¦team-docs¦Verificati link interni ai vecchi nomi: nessun aggiornamento necessario (esempi didattici ok in DOCS_CONVENTIONS.md)
20251018104000Z¦DOC¦project¦success¦team-docs¦Creati file progetto: EasyWayData.wiki/TODO_CHECKLIST.md e EasyWayData.wiki/ACTIVITY_LOG.md
20251018105000Z¦DOC¦conventions¦success¦team-docs¦Aggiunta sezione script helper al DOCS_CONVENTIONS (scripts/add-log.ps1)
20251018105100Z¦ADD¦scripts¦success¦team-docs¦Creato helper PowerShell: EasyWayData.wiki/scripts/add-log.ps1
20251018110000Z¦MOVE¦endpoint¦success¦team-api¦Estratto doc da subfolder GET-'api%2Dconfig' in endp-001a-get-api-config-da-db.md
20251018110100Z¦INDEX¦endpoint¦success¦team-api¦Aggiornato INDEX endpoint con voce endp-001a
20251018110200Z¦DOC¦conventions¦success¦team-docs¦Integrata guida kebab-case vs snake_case in DOCS_CONVENTIONS.md
20251018111500Z¦UPDATE¦scripts¦success¦team-docs¦Esteso scripts/add-log.ps1 con -Split (monthly|scope) e -MirrorToMaster
20251018111600Z¦DOC¦conventions¦success¦team-docs¦Aggiornata sezione log con opzioni split/mirror ed esempi
20251018113000Z¦INIT¦logs¦success¦team-docs¦Creata struttura cartelle logs con README (logs/README.md)
20251018113100Z¦INIT¦logs¦success¦team-docs¦Aggiunti README per logs/date (mensili) e logs/scope (per ambito)
20251018002721Z¦TEST¦verify-logs¦success¦team-docs¦Esempio log mensile (verifica import)
20251018002721Z¦TEST¦endpoint¦success¦team-api¦Esempio log per ambito endpoint (verifica import)
20251018003753Z¦RENAME¦endpoint¦success¦team-api¦Rinominati file e cartelle ENDPOINT/Template, Policy, Gestione Log, Steps 1-5, frontend e QA
20251018003753Z¦UPDATE¦links¦success¦team-docs¦Aggiornati riferimenti markdown ai nuovi nomi
20251018004355Z¦RENAME¦02_logiche_easyway¦success¦team-docs¦Rinominati file e cartelle in 02_logiche_easyway (kebab-case, ASCII)
20251018004355Z¦RENAME¦03_datalake_dev¦success¦team-docs¦Rinominati file in 03_datalake_dev (kebab-case, ASCII)
20251018004355Z¦UPDATE¦links¦success¦team-docs¦Aggiornati tutti i link markdown ai nuovi nomi (02/03)
20251018004355Z¦DOC¦front-matter¦success¦team-docs¦Aggiunto front matter minimo a pagine chiave in 02/03
20251018050133Z¦DOC¦conventions¦success¦team-docs¦Aggiornato regex: slug, file, path + note iterative (DOCS_CONVENTIONS.md)
20251018050502Z¦DOC¦conventions¦success¦team-docs¦Aggiunta sezione \ Script revisione doc\ con snippet PowerShell (DOCS_CONVENTIONS.md)
20251018050859Z¦ADD¦scripts¦success¦team-docs¦Aggiunto scripts/review-examples.ps1 (funzioni di revisione consolidate)
20251018051239Z¦ADD¦scripts¦success¦team-docs¦Aggiunto scripts/review-run.ps1 (orchestratore revisione doc)
20251018051436Z¦ADD¦scripts¦success¦team-docs¦Aggiunti CSV di esempio: scripts/examples/fm.csv e scripts/examples/links.csv
20251018051812Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=4, indices=0, report=naming-20251018051812.txt, dry-run=True
20251018051955Z¦DOC¦02_logiche_easyway¦success¦team-docs¦Front matter aggiunto dove mancava e creati INDEX.md per cartelle principali
20251018052220Z¦DOC¦03_datalake_dev¦success¦team-docs¦Front matter verificato/aggiunto e creato INDEX.md (03_datalake_dev)
20251018052641Z¦RENAME¦programmability¦success¦team-db¦Rinominati PROGRAMBILITY→programmability e STOREPROCESS→stored-procedure, file in kebab-case
20251018052641Z¦DOC¦programmability¦success¦team-db¦Front matter aggiunto e creati INDEX.md (programmability)
20251018052706Z¦UPDATE¦entities¦success¦team-docs¦Aggiornati path programmability in entities.yaml (programmability, stored-procedure)
20251018052935Z¦INDEX¦root¦success¦team-docs¦Generato INDEX.md globale (H1/H2) per tutta la wiki
20251018053013Z¦DOC¦conventions¦success¦team-docs¦Documentato indice globale e come generarlo (New-RootIndex)
20251018053332Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=4, indices=0, report=naming-20251018053331.txt, dry-run=True, global-index=True
20251018053505Z¦DOC¦conventions¦success¦team-docs¦Documentato flag -NoGlobalIndex nel task runner con esempio
20251018060615Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=106, fm=0, links=4, indices=3, report=naming-20251018060615.txt, dry-run=False, global-index=True
20251018061425Z¦RENAME¦db¦success¦team-db¦Rinominati PORTAL.md→portal.md e programmability/INDEX.md→index.md
20251018061425Z¦UPDATE¦linter¦success¦team-docs¦Linter: whitelist (.gitignore/.order/.attachments, root meta UPPERCASE, path legacy) + documentazione
20251018061509Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=33, fm=0, links=0, indices=3, report=naming-20251018061509.txt, dry-run=False, global-index=False
20251018061910Z¦ANALYZE¦linter¦success¦team-docs¦Analisi naming: creato report classificato azione→file (logs/reports/*-analysis.md)
20251018062141Z¦RENAME¦wiki¦success¦team-docs¦Batch rinomine top-level + index.md + easyway-portal-api + cleanup duplicati legacy
20251018062153Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=10, fm=0, links=0, indices=3, report=naming-20251018062153.txt, dry-run=False, global-index=False
20251018062340Z¦CLEAN¦wiki¦success¦team-docs¦Rimossi duplicati residuali post-rinomina (02_logiche_easyway, api steps/policy)
20251018062341Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=13, fm=0, links=0, indices=3, report=naming-20251018062340.txt, dry-run=False, global-index=True
20251018062508Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=10, fm=0, links=0, indices=3, report=naming-20251018062508.txt, dry-run=False, global-index=False
20251018062650Z¦RENAME¦wiki¦success¦team-docs¦Rinominati file residui (02_logiche_easyway e easyway_portal_api: policy/step/raccomandazione/best-practice)
20251018062650Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=10, fm=0, links=0, indices=3, report=naming-20251018062650.txt, dry-run=False, global-index=False
20251018062748Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=2, fm=0, links=0, indices=3, report=naming-20251018062747.txt, dry-run=False, global-index=False
20251018062846Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=2, fm=0, links=0, indices=3, report=naming-20251018062845.txt, dry-run=False, global-index=False
20251018062954Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=2, fm=0, links=0, indices=3, report=naming-20251018062954.txt, dry-run=False, global-index=False
20251018063042Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=2, fm=0, links=0, indices=3, report=naming-20251018063041.txt, dry-run=False, global-index=False
20251018063315Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018063315.txt, dry-run=False, global-index=False
20251018064203Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018064200.txt, anchors=0, dry-run=False, global-index=True
20251018064511Z¦DOC¦checklist¦success¦team-docs¦Integrato controllo ancore in LLM_READINESS_CHECKLIST.md (con comando di esecuzione)
20251018064604Z¦DOC¦top-level¦success¦team-docs¦Front matter aggiunto ai file top-level mancanti
20251018065008Z¦UPDATE¦entities¦success¦team-docs¦Esteso entities.yaml: paths normalizzati + standards, guides, architectures
20251018065131Z¦INDEX¦entities¦success¦team-docs¦Creato ENTITIES_INDEX.md da entities.yaml
20251018091452Z¦UPDATE¦index¦success¦team-docs¦Aggiunti link a ENTITIES_INDEX.md in DOCS_CONVENTIONS e INDEX.md
20251018093206Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=1, fm=0, links=0, indices=8, report=naming-20251018093204.txt, anchors=0, dry-run=False, global-index=True
20251018102953Z¦RENAME¦entities¦success¦team-docs¦ENTITIES_INDEX.md → entities_index.md
20251018103020Z¦UPDATE¦index¦success¦team-docs¦Aggiornato INDEX.md per nuovo nome entities_index.md
20251018103044Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=1, fm=0, links=0, indices=8, report=naming-20251018103043.txt, anchors=0, dry-run=False, global-index=False
20251018103124Z¦RENAME¦entities¦success¦team-docs¦entities_index.md → entities-index.md
20251018103138Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018103138.txt, anchors=0, dry-run=False, global-index=False
20251018103206Z¦ANALYZE¦llm-readiness¦success¦team-docs¦Generato mini-report LLM readiness (20251018103206)
20251018103742Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018103741.txt, anchors=91, dry-run=False, global-index=False
20251018103742Z¦DOC¦sprint-1-wrapup¦success¦team-docs¦FM/Q&A aggiornati secondo mini-report; estese entities (db_tables); anchor check eseguito
20251018104125Z¦UPDATE¦index¦success¦team-docs¦Rigenerato INDEX.md con link relativi puliti (GetRelativePath)
20251018104140Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018104139.txt, anchors=5, dry-run=False, global-index=False
20251018104418Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018104417.txt, anchors=3, dry-run=False, global-index=False
20251018104748Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018104747.txt, anchors=0, dry-run=False, global-index=False
20251018105948Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018105947.txt, anchors=11, dry-run=False, global-index=False
20251018110026Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018110025.txt, anchors=11, dry-run=False, global-index=False
20251018110253Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018110252.txt, anchors=0, dry-run=False, global-index=False
20251018124247Z¦DOC¦wiki¦success¦team-docs¦Aggiunta roadmap uniformamento wiki; link in INDEX.md
20251018124451Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018124450.txt, anchors=0, dry-run=False, global-index=True
20251018124502Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018124458.txt, anchors=0, dry-run=False, global-index=True
20251018124707Z¦DOC¦wiki¦success¦team-docs¦Corretto link a docs-conventions in INDEX.md; naming+anchors=0; INDEX rigenerato

20251018124927Z¦DOC¦front-matter¦success¦team-docs¦Front matter aggiunto dove mancante
20251018125004Z¦INDEX¦entities¦success¦team-docs¦Rigenerato entities-index.md da entities.yaml
20251018125020Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018125018.txt, anchors=0, dry-run=False, global-index=True
20251018125409Z¦INDEX¦master¦success¦team-docs¦Generato index_master.csv per EasyWayData.wiki
20251018130019Z¦INDEX¦master¦success¦team-docs¦Rigenerati index_master.csv, index_master.jsonl, anchors_master.csv
20251018130156Z¦DOC¦agents¦success¦team-docs¦Aggiunta guida agenti e aggiornata roadmap con manifest JSONL/CSV e anchors
20251018130542Z¦EXPORT¦chunks¦success¦team-docs¦Generato chunks_master.jsonl (H2/H3, 1600-2400 chars)
20251018130632Z¦EXPORT¦chunks¦success¦team-docs¦Rigenerato chunks_master.jsonl dopo fix Trim()
20251018130715Z¦EXPORT¦chunks¦success¦team-docs¦Rigenerato chunks_master.jsonl con parser sezioni robusto
20251018131339Z¦LINT¦atomicity¦success¦team-docs¦Atomicity lint eseguito: front matter, Q&A, code fences
20251018131426Z¦INDEX¦multi-root¦success¦team-docs¦Generati index_master_all.csv/jsonl e anchors_master_all.csv via aggregazione
20251018131956Z¦INDEX¦multi-root¦success¦team-docs¦Aggiunta OtherWiki e rigenerati artefatti aggregati
20251018132404Z¦LINT¦normalize¦success¦team-docs¦Normalizzati code fence senza lingua in docs-conventions.md -> text
20251018132417Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018132416.txt, anchors=0, dry-run=False, global-index=True
20251018132436Z¦REVIEW¦full-rebuild¦success¦team-docs¦Full rebuild + lint (min Q&A >=3, lang allowed: sql, sh, powershell, json, text)

## Domande a cui risponde
- Come è strutturato il log attività del progetto?
- Qual è il formato esatto delle righe e il timestamp?
- Dove trovo log aggregati per mese o per ambito?

20251018134028Z¦REVIEW¦wiki¦success¦team-docs¦review-run: issues=0, fm=0, links=0, indices=3, report=naming-20251018134026.txt, anchors=0, dry-run=False, global-index=True
20251018135945Z¦LINT¦programmability¦success¦team-docs¦Normalize code fences in programmability subtree (default sql)
20251018140712Z¦LINT¦normalize-project¦success¦team-docs¦Normalize project (fences sql via glob fallback)
20251018141055Z¦LINT¦normalize-project¦success¦team-docs¦Scan only: report=normalize-20251018161054.md
20251018141142Z¦LINT¦normalize-project¦success¦team-docs¦Apply done; scan report=normalize-20251018161134.md
20251018141531Z¦LINT¦normalize-project¦success¦team-docs¦Scan only: report=normalize-20251018161530-EasyWayData.wiki.md
20251018141531Z¦LINT¦normalize-project¦success¦team-docs¦Scan only: report=normalize-20251018141531Z-OtherWiki.md
20251018141531Z¦LINT¦normalize-project¦success¦team-docs¦Multi-root scan: normalize-all-20251018161530.md
20251018141538Z¦LINT¦normalize-project¦success¦team-docs¦Apply done; scan report=normalize-20251018161531-EasyWayData.wiki.md
20251018141538Z¦LINT¦normalize-project¦success¦team-docs¦Apply done; scan report=normalize-20251018141538Z-OtherWiki.md
20251018141538Z¦LINT¦normalize-project¦success¦team-docs¦Multi-root apply: normalize-all-20251018161531.md
