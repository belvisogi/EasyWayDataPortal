---
id: mvp-graph-view
title: Graph view (offline) - HOW
summary: Come generare e aprire un graph view in stile Obsidian, senza Obsidian (solo HTML offline).
status: draft
owner: team-platform
updated: '2026-01-09'
tags: [domain/docs, layer/howto, audience/dev, privacy/internal, language/it, dq, links, graph]
---

# Graph view (offline) - HOW

## Scopo
Visualizzare la connettivita' della wiki (link tra pagine) con un grafo interattivo simile al "Graph view" di Obsidian, senza dipendenze esterne.

## Comando
Da `mvp_wiki_dq/`:
```powershell
pwsh scripts/wiki-graph-view.ps1 -WikiPath "wiki" -Open
```

Output:
- HTML: `out/graph-view.html`
- Dati grafo: `out/graph-view.json` (derivato da `scripts/wiki-orphans.ps1`)

## Note
- Se non usi `-Open`, apri manualmente `out/graph-view.html` con il browser.
- Filtri disponibili nella pagina: search (path contiene...), `Min degree` per isolare cluster e orfani.
- Hover su un nodo: evidenzia i legami (vicini). Click: blocca/sblocca la selezione.
- All'avvio c'e' una mini "timelapse" (fade-in) mentre il layout si stabilizza; puoi rifarla con `Replay animazione` o tasto `R`.
