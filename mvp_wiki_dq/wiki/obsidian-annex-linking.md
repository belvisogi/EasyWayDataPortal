---
id: mvp-obsidian-annex-linking
title: Obsidian - Best practice link (Annex)
summary: Regole pratiche per linkare in Obsidian tra pagine e riferimenti (Annex) senza rompere path/anchor e senza introdurre rumore.
status: draft
owner: team-platform
updated: '2026-01-09'
tags: [domain/docs, layer/howto, audience/dev, privacy/internal, language/it, obsidian, links, annex, dq]
---

# Obsidian - Best practice link (Annex)

## Questo e' un modello (non l'unico)
Questa pagina usa **Obsidian** come modello perche' rende visibili (e gestibili) le dipendenze tra pagine (grafo, backlink, rename con update link).

Esistono anche altri modi validi per gestire una wiki Markdown (es. VS Code, GitHub/GitLab, Docusaurus, Confluence export). L'importante, per la DQ, e' applicare la stessa metodologia:
- link Markdown relativi
- path stabili
- anchor verificabili
- riferimenti strutturati (Annex)

## Scopo
Tenere una wiki navigabile in Obsidian, con link stabili e verificabili (DQ link/anchor), usando gli "Annex" come semplici pagine di riferimento.

## Setup Obsidian (minimo)
- Disattiva wikilinks: `Use [[Wikilinks]] = OFF`.
- Link relativi: `New link format = Relative path to file`.
- Aggiornamento link: `Automatically update internal links = ON`.
- (Opz.) Attachment folder: `.attachments` (se presente nel vault).

## Regole di link (canoniche)
1) Usa solo link Markdown relativi:
- OK: `Spec DQ -> ./orch/wiki-dq-audit.md`
- OK (con anchor): `Domande -> ./orch/wiki-dq-audit.md#domande-a-cui-risponde`
- Evita `[[wikilinks]]` e path assoluti (fragili fuori dal tuo PC).

2) Mantieni i path stabili:
- Non rinominare file "canonici" senza una ragione forte (e aggiornare i link).
- Preferisci filename kebab-case (nuovi contenuti), anche sotto `annex/`.

3) Linka per responsabilita':
- Ogni pagina operativa (runbook/howto/orch) deve avere una sezione `## Vedi anche` con 3-7 link utili.
- Ogni pagina "Annex" deve avere `Source` e almeno 1 backlink (dove viene usata).

## Struttura consigliata: `annex/`
Usa una cartella dedicata per i riferimenti:

- `annex/index.md` (indice dei riferimenti)
- `annex/<tema>/<riferimento>.md` (una pagina per riferimento)

Template suggerito per una pagina Annex:
```markdown
---
id: annex-<slug>
title: <Titolo breve>
summary: <Perche' esiste questo riferimento e quando serve>
status: draft
owner: team-<...>
tags: [annex, domain/docs, ...]
---

# <Titolo breve>

## Source
- URL:
- Owner:
- Data/Versione:

## Usato in
- <Pagina>: ../path/pagina.md
```

## Allegati (se servono)
- Se il vault ha `.attachments/`, salva gli allegati sotto `.attachments/annex/` (anche con sottocartelle per tema).
- Link agli allegati con path relativo (es. `schema -> ../.attachments/annex/dq/schema.png`), evitando riferimenti locali fuori repo.

## Mini-checklist (prima del merge)
- I link sono relativi e funzionano anche dopo rename/move (Obsidian aggiorna i link).
- Gli anchor (`#...`) puntano a heading esistenti.
- Ogni Annex ha `Source` + backlink.

## Se non hai Obsidian
Va benissimo: la wiki resta **solo Markdown**.

- Scrivi e naviga con qualsiasi editor (VS Code, Notepad++, GitHub preview).
- Per il controllo periodico usa i comandi del MVP (sono l'alternativa "agentic" al grafo Obsidian):
  - `pwsh scripts/wiki-links.ps1 -Path "wiki" -FailOnError`
  - `pwsh scripts/wiki-orphans.ps1 -WikiPath "wiki" -FailOnError`
- Applica comunque la struttura `annex/` e le regole di link: e' questo che rende la wiki robusta e verificabile.

## Vedi anche
- `Wiki/EasyWayData.wiki/OBSIDIAN.md` (setup completo vault)
- `Wiki/EasyWayData.wiki/docs-conventions.md` (convenzioni link/anchor)
