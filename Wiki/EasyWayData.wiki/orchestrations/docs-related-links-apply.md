---
id: ew-orch-docs-related-links-apply
title: Docs Related Links Apply (WHAT)
summary: Genera suggerimenti di pagine correlate e (opz.) applica cross-link 'Vedi anche' con conferma umana e rollback via backup.
status: draft
owner: team-platform
tags: [domain/docs, layer/orchestration, audience/dev, privacy/internal, language/it, obsidian, governance]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
entities: []
updated: '2026-01-08'
---

# Docs Related Links Apply (WHAT)

Contratto
- Intent: `docs/agentic/templates/intents/docs-related-links-apply.intent.json`
- Manifest: `docs/agentic/templates/orchestrations/docs-related-links-apply.manifest.json`
- HowTo: `Wiki/EasyWayData.wiki/docs-related-links.md`
- Output suggerimenti: `out/wiki-related-links.suggestions.json`

## Runtime (locale)

### 1) Suggerimenti (nessuna modifica ai .md)
```powershell
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -OutJson "out/wiki-related-links.suggestions.json"
```sql

### 2) Apply (human-in-the-loop, reversibile)
Di default è in `-WhatIf` e chiede conferma (HITL).
```powershell
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -Apply -WhatIf -ApplyScope orphans-only -MinScore 0.35 -MaxLinksToAdd 5
```sql

Per applicare davvero:
```powershell
pwsh scripts/wiki-related-links.ps1 -WikiPath "Wiki/EasyWayData.wiki" -TopK 7 -Apply -WhatIf:$false -ApplyScope orphans-only -MinScore 0.35 -MaxLinksToAdd 5
```sql

Rollback:
- Ogni run salva backup in `out/wiki-related-links-apply/<runId>/` e un `apply-summary.json` con la lista file/backup.

