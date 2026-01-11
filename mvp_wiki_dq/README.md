# mvp_wiki_dq

MVP riusabile per trattare la documentazione come **dataset**:
- check DQ (link/anchor, gap metadata, connettivita' grafo)
- scorecard + backlog Kanban
- (opz.) update board file-based con blocco `AUTO` (HITL + backup)
- (opz.) Confluence Cloud: export read-only + pagina Kanban dedicata (HITL, `-WhatIf` di default)

## Quickstart (Wiki file-based)

Da `mvp_wiki_dq/`:
```powershell
pwsh scripts/docs-dq-scorecard.ps1 -WikiPath "wiki"
```

## Entrypoint (guidato): Azure DevOps o Confluence
```powershell
pwsh scripts/mvpctl.ps1 -Mode plan
```

## KB (tool standalone)

Ricette operative (machine-readable, lette dall'agente):
- Canonico: `mvp_wiki_dq/agents/kb/recipes.jsonl`
- Copia legacy (tenuta allineata): `mvp_wiki_dq/kb/recipes.jsonl`

Nota: Obsidian e' opzionale. Se non lo usi, il MVP funziona comunque tramite gli script di lint/scorecard e le convenzioni di link.

## Graph view (offline, stile Obsidian)
```powershell
pwsh scripts/wiki-graph-view.ps1 -WikiPath "wiki" -Open
```

Update board locale (scrittura, reversibile):
```powershell
pwsh scripts/docs-dq-scorecard.ps1 -WikiPath "wiki" -UpdateBoard -WhatIf:$false
```

## Tags (taxonomy + facets)

Taxonomy: `config/tag-taxonomy.json`

Lint:
```powershell
pwsh scripts/wiki-tags.ps1 -Path "wiki" -TaxonomyPath "config/tag-taxonomy.json"
pwsh scripts/wiki-tags.ps1 -Path "wiki" -TaxonomyPath "config/tag-taxonomy.json" -RequireFacets -FailOnError
```

## Confluence Cloud (read-only di default)

1) Compila `intents/confluence.params.json`.
2) Imposta env:
- `CONFLUENCE_EMAIL`
- `CONFLUENCE_API_TOKEN`

Plan (no network):
```powershell
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -PlanOnly
```

Export:
```powershell
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export
```

Write-back Kanban (HITL):
```powershell
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export -UpdateBoard -WhatIf
pwsh scripts/confluence-board.ps1 -IntentPath "intents/confluence.params.json" -Export -UpdateBoard -WhatIf:$false
```
