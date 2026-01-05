---
id: ew-obsidian
title: Obsidian Vault Setup (Wiki)
summary: Come aprire `Wiki/EasyWayData.wiki` in Obsidian mantenendo link, attachments e frontmatter coerenti.
status: active
owner: team-platform
tags: [domain/docs, layer/howto, audience/non-expert, audience/dev, privacy/internal, language/it, obsidian]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
---

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

## Convenzioni repository (da rispettare)
- Non rimuovere/alterare il front matter YAML (`--- ... ---`) introdotto per agent-readiness.
- Preferire link markdown relativi (esempio): `Titolo -> ./path/file.md`.
- Allegati: usare `Wiki/EasyWayData.wiki/.attachments/` (sottocartelle ammesse, es. `.attachments/ux/`).
