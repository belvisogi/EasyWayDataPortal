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

