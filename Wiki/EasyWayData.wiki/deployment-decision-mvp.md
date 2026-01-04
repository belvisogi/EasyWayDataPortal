---
id: ew-deployment-decision-mvp
title: Deployment decision (MVP) — EasyWay Data Portal
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [docs, domain/control-plane, layer/spec, audience/ops, audience/dev, privacy/internal, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# Deployment decision (MVP) — EasyWay Data Portal

Sintesi breve
- Decisione operativa per il rilascio MVP: usare una soluzione PaaS basata su Azure App Service (container) o Azure Container Apps.
- Motivazione: velocità di delivery, costi controllati per ambienti di sviluppo/poC, integrazione semplice con pipeline Azure DevOps e le policy di governance già presenti nel repository.

Cosa significa nella pratica
- Ambiente di sviluppo e ricerca: esecuzione locale o su risorse temporanee per ridurre costi (datalake-sample, .env.local, run locale).
- Ambiente di produzione (go‑live): App Service o Container Apps con pipeline automatizzata, Managed Identity, Key Vault, Private Endpoint dove necessario.

Documentazione di riferimento (link interni)
- Guida operativa deploy su App Service: Wiki/EasyWayData.wiki/deploy-app-service.md
- Architettura infra: docs/infra/azure-architecture.md
- Raccomandazione architetturale (App Service vs Container Apps vs AKS): easyway-webapp/02_logiche_easyway/raccomandazione-architetturale-easyway-data-portal.md
- Pipeline & toggles: azure-pipelines.yml (root) e relative note in Wiki/EasyWayData.wiki/blueprints/replicate-easyway-dataportal.md
- Esempi/appsettings: scripts/generate-appsettings.ps1 e Wiki/EasyWayData.wiki/kb-starter-appsettings-026 (KB)

Flag e controlli CI/CD (pratici)
- ENABLE_DEPLOY: toggle che abilita la fase di deploy nella pipeline.
- ENABLE_SWAP: abilita lo swap di slot (staging → production) se previsto.
- GOV_APPROVED: approvazione di governance richiesta per deploy su branch `main` o ambiente `prod`.
- USE_EWCTL_GATES / ENABLE_CHECKLIST / ENABLE_DB_DRIFT / ENABLE_KB_CONSISTENCY: gates opzionali previsti nella pipeline.

Best practice consigliate
- Mantieni il codice e le pipeline nel repository (easyway-portal-api/*); carica su Datalake solo le configurazioni runtime (branding YAML, file prodotti).
- Gestione segreti: Azure Key Vault + Managed Identity (mai segreti in chiaro).
- Provisioning infra tramite Terraform (infra/terraform) in pipeline (stage Infra).
- Test smoke post-deploy: health endpoint, smoke tests e verifica OpenAPI/documentazione.
- Logging e osservabilità: Application Insights / OTel; esportare i log su Datalake per audit se richiesto.

Quando valutare AKS
- Requisiti enterprise avanzati: multi-region, service mesh, altissime richieste di concurrency o necessità di federazione.
- Se si decide AKS: migrazione graduale dei container; riuso pipeline e immagini.

Prossimi step raccomandati
1. Aggiungere questo file come riferimento canonico (fatto).
2. Se vuoi, posso aggiornare `deploy-app-service.md` con una sezione esplicita "Local run for research/cost saving" che rimandi a questa pagina — confermi che lo faccia?

Note finali
- La scelta App Service è già documentata nel repo; questo file rende esplicita la decisione MVP e centralizza i link utili per dev/ops.






