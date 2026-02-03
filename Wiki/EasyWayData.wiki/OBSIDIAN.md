---
title: Obsidian Vault Setup (Wiki)
tags: [domain/docs, layer/howto, audience/non-expert, audience/dev, privacy/internal, language/it, obsidian]
status: active
updated: 2026-01-16
redaction: [email, phone]
id: ew-obsidian
chunk_hint: 200-300
entities: []
include: true
summary: Come aprire `Wiki/EasyWayData.wiki` in Obsidian mantenendo link, attachments e frontmatter coerenti.
llm: 
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
pii: none
owner: team-platform
---

[Home](../../scripts/docs/project-root/DEVELOPER_START_HERE.md) > [[domains/docs-governance|Docs]] > [[Layer - Howto|Howto]]

# Obsidian Vault Setup (Wiki)

## Scopo
Aprire la Wiki come vault Obsidian in modo che:
- i link restino stabili (markdown links relativi),
- gli allegati finiscano in una cartella unica,
- non si degradino i metadati YAML (front matter) usati dai gate.

## Setup consigliato (senza committare config personali)
1. In Obsidian: `Open folder as vault` e seleziona `Wiki/EasyWayData.wiki`.
2. Copia la cartella `Wiki/EasyWayData.wiki/.obsidian.example` in `Wiki/EasyWayData.wiki/.obsidian` (locale, non committare se non richiesto).
3. Verifica in Obsidian:
   - Files & Links:
     - `Use [[Wikilinks]]` = OFF (usiamo link markdown standard)
     - `New link format` = Relative path to file
     - `Automatically update internal links` = ON
   - Files & Links / Attachment folder path:
     - `.attachments`
   - Files & Links / Excluded files:
     - `logs/` (include report come `anchors-YYYYMMDDHHMMSS*.csv`)
     - (esempi di report rumorosi) `anchors-*`, `atomicity-*`
     - `old/`
     - facoltativo: `*.bak` e `*.tmp`

Nota: se apri come vault la cartella `Wiki/` (non `Wiki/EasyWayData.wiki`), usa gli exclude con prefisso `EasyWayData.wiki/` (es. `EasyWayData.wiki/logs/`, `EasyWayData.wiki/old/`).

## Convenzioni repository (da rispettare)
- Non rimuovere/alterare il front matter YAML (`--- ... ---`) introdotto per agent-readiness.
- Preferire link markdown relativi (esempio): `Titolo -> ./path/file.md`.
- Allegati: usare `Wiki/EasyWayData.wiki/.attachments/` (sottocartelle ammesse, es. `.attachments/ux/`).


## Domande a cui risponde
- Qual e' l'obiettivo di questa procedura e quando va usata?
- Quali prerequisiti servono (accessi, strumenti, permessi)?
- Quali sono i passi minimi e quali sono i punti di fallimento piu comuni?
- Come verifico l'esito e dove guardo log/artifact in caso di problemi?

## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.



## Vedi anche

- [Obsidian Vault Template (README)](.obsidian.example/README.md)
- [LLM READINESS CHECKLIST](./llm-readiness-checklist.md)
- [Suggerimenti Link Correlati (Affinità)](./docs-related-links.md)
- [Generare DDL+SP da mini-DSL (agent-aware)](./db-generate-artifacts-dsl.md)
- [Datalake - Set Retention (Stub)](./datalake-set-retention.md)






