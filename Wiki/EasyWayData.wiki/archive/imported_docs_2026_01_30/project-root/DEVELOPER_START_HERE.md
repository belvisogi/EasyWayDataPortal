---
id: ew-archive-imported-docs-2026-01-30-project-root-developer-start-here
title: Developer Start Here (The Sacred Path)
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
# Developer Start Here (The Sacred Path)

> [!IMPORTANT]
> **Benvenuto.** Qui non si tirano a indovinare i comandi. Esistono 3 comandi sacri per governare tutto.

## I 3 Comandi Sacri (ewctl)

Usa la CLI `ewctl.ps1` (PowerShell) dalla root del progetto.

### 1. `.\ewctl.ps1 check` (Diagnosi)
**Risponde alla domanda:** *"Cosa c'è che non va?"* / *"Perché la CI è rossa?"*
Esegue tutti i controlli (Gates) rilevanti per i file che hai toccato.
- Se tocchi il DB -> Esegue lint e drift check.
- Se tocchi Docs -> Esegue controlli link e frontmatter.

### 2. `.\ewctl.ps1 plan` (Prescrizione)
**Risponde alla domanda:** *"Cosa devo fare per finire?"*
Analizza lo stato attuale e ti dà la "Definition of Done".
- Ti dice se manca una migrazione.
- Ti dice se manca la documentazione per una nuova tabella.

### 3. `.\ewctl.ps1 fix` (Cura)
**Risponde alla domanda:** *"Sistemalo per me."*
Applica **solamente** fix sicuri e deterministici.
- Normalizza i frontmatter della Wiki.
- Corregge l'indentazione o i tag mancanti.
- **Non** cancella dati né fa drop di tabelle senza conferma esplicita.

---

## Le 10 Regole Non Negoziabili

1.  **Prima il WHAT, poi il HOW**: Non scrivere codice se non hai scritto l'Intent (WHAT) e il Piano.
2.  **Governance as Code**: Le regole sono script (`ewctl check`), non policy su Wiki. Se lo script passa, la regola è rispettata.
3.  **Mai bypassare i Gate**: Se `ewctl check` fallisce, non pushare. La CI fallirà comunque.
4.  **Database Sacro**: Nessuna modifica manuale al DB. Tutto passa da migrazioni Flyway o Agenti DBA.
5.  **Docs-Driven Development**: Se non è documentato nella Wiki, non esiste.
6.  **Agent-Ready**: Ogni output deve essere parsabile da una macchina (JSON). Non usare screenshot o log non strutturati.
7.  **Idempotenza**: Ogni script di fix deve poter girare 100 volte senza rompere nulla.
8.  **Sicurezza "Zero Trust"**: Non committare secret. Usa KeyVault.
9.  **Logga o Muori**: Se il tuo script non lascia traccia in `events.jsonl`, non è mai successo.
10. **Single Entrypoint**: Non chiamare script a caso in `scripts/pwsh/`. Usa `ewctl`.

## Troubleshooting

- **"Non so cosa fare"**: Lancia `.\ewctl.ps1 plan`.
- **"Ho rotto la pipeline"**: Lancia `.\ewctl.ps1 check` in locale.
- **"Voglio aggiungere un nuovo controllo"**: Aggiungi un modulo Lego in `scripts/pwsh/modules/ewctl/`.
- **"Dubbi sulla sicurezza?"**: Leggi [SECURITY_AUDIT.md](../../../../../scripts/docs/architecture/SECURITY_AUDIT.md).



