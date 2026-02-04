---
title: "Wiki Review & Normalize - Quick Reference"
category: wiki
domain: review
features:
  - auto-detect
  - glossary-check
  - normalize
entities: []
tags: [wiki, review, glossary, normalize]
id: ew-archive-imported-docs-2026-01-30-agent-rules-wiki-review-guide
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
type: guide
---

# 📚 Wiki Review & Normalize - Quick Reference

## 🚀 Comandi

### Auto-Detect (Consigliato)
```powershell
# Trova automaticamente Wiki/AdaDataProject.wiki
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki -NonInteractive
```

### Path Esplicito
```powershell
# Per wiki cliente specifica
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki -NonInteractive -WikiPath "Customers/Generali/Wiki/ADA-Project---Data-Strategy.wiki"
```

---

## ⚙️ Auto-Detect Logic

Lo script cerca automaticamente in quest'ordine:
1. `Wiki/*.wiki` (es. Wiki/AdaDataProject.wiki) ✅
2. Ricerca ricorsiva qualsiasi `*.wiki` directory
3. Fallback: warning + placeholder

**Benefici**:
- ✅ Zero configurazione
- ✅ Supporta wiki multiple
- ✅ Funziona out-of-the-box

---

## 📊 Output

Lo script esegue:
1. ✅ Scan wiki markdown files
2. ✅ Estrazione termini chiave (intent, agent, gate, orchestrazione)
3. ✅ Estrazione errori tipici (regex pattern)
4. ✅ Check glossario esistente
5. ✅ Report termini mancanti + errori

**Output**:
```
✅ Auto-detected wiki: Project.wiki
==> Avvio review/normalizzazione documentazione...
==> Avvio check del glossario...

=== Termini chiave non ancora documentati in glossario ===
- intent.ado-export
- agent_docs_review
...

=== Errori tipici estratti da markdown ===
- Errore connessione DB
...
```

---

## 🎯 Use Cases

### 1. Review Wiki Progetto
```powershell
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki
```

### 2. Review Wiki Cliente
```powershell
pwsh Rules.Vault/agents/agent_docs_review/agent-docs-review.ps1 -Wiki -WikiPath "Customers/Generali/Wiki/ADA-Project---Data-Strategy.wiki"
```

### 3. Via axctl (se wrapper configurato)
```powershell
axctl --intent wiki-review
```

---

## 📝 Note

- **Auto-detect** usa current working directory
- **Glossario**: cerca `<WikiPath>/glossario-errori-faq.md`
- **Safe**: Solo lettura, nessuna modifica ai file

---

**Versione**: 1.0 (Auto-Detect)  
**Data**: 2026-01-12



