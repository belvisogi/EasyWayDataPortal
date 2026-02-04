---
id: ew-archive-imported-docs-2026-01-30-wiki-azure-devops-code-wiki
title: Azure DevOps – Pubblicare la Wiki dal Repo (Code Wiki)
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# Azure DevOps – Pubblicare la Wiki dal Repo (Code Wiki)

Obiettivo: tenere la wiki nel monorepo e renderla visibile in Azure DevOps Wiki senza repo separati.

Percorso consigliato (UI):
1) Azure DevOps → Project → Wiki → `Publish code as wiki`
2) Repository: `EasyWayDataPortal`
3) Branch: `main`
4) Folder path: `Wiki/EasyWayData.wiki`
5) Name: `EasyWay Data Wiki`

Note:
- Allegati: usare `Wiki/EasyWayData.wiki/.attachments/`
- Link: usare percorsi relativi all’interno della cartella wiki
- Automazioni qualità: gli script in `Wiki/EasyWayData.wiki/scripts` possono essere lanciati da CI (vedi `azure-pipelines.yml`)

API/REST (opzionale):
- L’API per creare una Code Wiki accetta il path della cartella (Preview). In alternativa, automatizza via UI flows o CLI.

Troubleshooting:
- Se la cartella `Wiki/EasyWayData.wiki` aveva un `.git` annidato, ora è rimosso per evitare repo dentro repo.
- Se allegati > 50MB, usare Git LFS.



