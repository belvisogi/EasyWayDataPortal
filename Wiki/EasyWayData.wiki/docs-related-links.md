---
id: ew-docs-related-links
title: Suggerimenti Link Correlati (Affinità)
summary: Come generare suggerimenti di pagine correlate (affinità) per collegare la Wiki e ridurre nodi isolati nel grafo Obsidian.
status: draft
owner: team-platform
tags: [domain/docs, layer/howto, audience/dev, privacy/internal, language/it, obsidian, docs]
llm:
  redaction: [email, phone]
  include: true
  pii: none
  chunk_hint: 250-400
entities: []
updated: '2026-01-08'
type: guide
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > [[Layer - Howto|Howto]]

# Suggerimenti Link Correlati (Affinità)

Obiettivo: proporre (senza modificare file) link “Vedi anche” tra pagine affini, per migliorare navigazione e grafo Obsidian.

## Come funziona
- Segnale principale: similarità TF‑IDF (coseno) su `title/summary/tags` + contenuto (senza code fences).
- Piccoli boost: tag in comune, stessa cartella, stessa cartella top‑level.
- Output: report JSON con top‑K suggerimenti per ogni pagina.

## Comando
```powershell
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -OutJson "out/wiki-related-links.suggestions.json"
```sql

## Come usarlo (Human-in-the-loop)
1. Apri `out/wiki-related-links.suggestions.json`.
2. Per le pagine più isolate/critiche, aggiungi manualmente 3–7 link in una sezione `## Vedi anche`.
3. In alternativa, aggiorna gli `index.md` di sezione (miglior “link in ingresso”).

Nota: i suggerimenti sono euristici; vanno sempre validati da un umano.

## Apply (opzionale, reversibile)
Per applicare automaticamente una sezione `## Vedi anche` su un sottoinsieme di pagine, con conferma umana e backup:

```powershell
# Preview (default)
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -Apply -WhatIf -ApplyScope orphans-only -MinScore 0.35 -MaxLinksToAdd 5

# Apply reale (scrive i .md)
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -Apply -WhatIf:$false -ApplyScope orphans-only -MinScore 0.35 -MaxLinksToAdd 5
```sql

Rollback:
- Ogni run crea backup in `out/wiki-related-links-apply/<runId>/` e un `apply-summary.json` con i file da ripristinare.




