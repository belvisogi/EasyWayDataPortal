---
id: documentation-quality-framework
title: Documentation Quality Framework (DQF)
summary: Framework completo per documentazione di alta qualità, ottimizzata per umani, RAG e agenti AI
tags: [domain/docs, layer/spec, audience/dev, audience/architect, privacy/internal, language/it, standard, best-practices, automation, governance]
status: active
owner: team-docs
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 400-600
entities: []
---

# 📚 Documentation Quality Framework (DQF)

**Versione**: 1.0  
**Obiettivo**: Documentazione di alta qualità, facilmente leggibile da umani, ottimizzata per RAG e manutenibile da agenti AI.

---

## 🎯 Perché Questo Framework?

La documentazione serve **3 audience**:
1. **👤 Umani** - Devono trovare informazioni velocemente e capirle facilmente
2. **🤖 RAG Systems** - Devono fare chunking efficace e retrieval preciso
3. **🔧 AI Agents** - Devono validare, fixare e mantenere automaticamente

**Problema**: La maggior parte della documentazione è ottimizzata solo per umani (se va bene).

**Soluzione**: DQF fornisce standard, strumenti e automazione per documentazione **triple-optimized**.

---

## 📐 Pilastri del Framework

### 1. **Taxonomy-Driven** (Facet + Free Tags)
- **Facet obbligatori**: `domain`, `layer`, `audience`, `privacy`, `language`
- **Free tags canonici**: Lista controllata per evitare sinonimi
- **Benefici**:
  - 👤 Umani: Navigazione per categoria
  - 🤖 RAG: Metadata filtering per retrieval preciso
  - 🔧 Agenti: Validazione automatica

### 2. **Link Integrity** (Zero Broken Links)
- **Path relativi corretti**: Calcolati con gerarchia URI
- **Obsidian-compatible**: `[[link]]` → `[link](path.md)`
- **Benefici**:
  - 👤 Umani: Navigazione fluida
  - 🤖 RAG: Graph traversal affidabile
  - 🔧 Agenti: Auto-fix con mapping

### 3. **Structured Frontmatter** (YAML Compliant)
- **Metadata ricco**: `id`, `title`, `summary`, `tags`, `status`, `owner`, `updated`
- **LLM hints**: `chunk_hint`, `pii`, `include`
- **Benefici**:
  - 👤 Umani: Overview rapido
  - 🤖 RAG: Chunking ottimale (200-600 tokens)
  - 🔧 Agenti: Parsing e validazione

### 4. **Automated Governance** (CI/CD Integration)
- **Audit automatico**: Nightly runs via n8n
- **Auto-fix**: Taxonomy + Links
- **Git trail**: Commit automatici con metriche
- **Benefici**:
  - 👤 Umani: Sempre aggiornata
  - 🤖 RAG: Qualità costante
  - 🔧 Agenti: Self-healing docs

---

## 🛠️ Componenti del Framework

### A. Tag Taxonomy (`tag-taxonomy.json`)

**Struttura**:
```json
{
  "required_facets": ["domain", "layer", "audience", "privacy", "language"],
  "facets": {
    "domain": ["db", "frontend", "api", "docs", "security", ...],
    "layer": ["howto", "reference", "spec", "runbook", ...],
    "audience": ["dev", "dba", "ops", "non-expert", ...],
    "privacy": ["internal", "public", "restricted"],
    "language": ["it", "en"]
  },
  "canonical_free_tags": {
    "preferred": ["agents", "n8n", "rag", "standard", "architecture", ...]
  }
}
```

**Best Practices**:
- ✅ Usa **facet/value** format: `domain/docs`, `layer/spec`
- ✅ Scegli free tags dalla lista `canonical_free_tags.preferred`
- ❌ Evita sinonimi: `agentic` → `agents`, `data-quality` → `dq`

**Benefici RAG**:
- Filtering: `WHERE tags CONTAINS 'domain/api' AND 'layer/howto'`
- Hybrid search: Semantic + metadata boost

---

### B. Audit Scripts

#### 1. **Taxonomy Lint** (`wiki-tags-lint.ps1`)
```powershell
pwsh scripts/pwsh/wiki-tags-lint.ps1 \
  -Path "Wiki/EasyWayData.wiki" \
  -ExcludePaths logs/reports,archive \
  -RequireFacets \
  -RequireFacetsScope core
```

**Output**: `wiki-tags-lint.json` con errori per file

#### 2. **Link Integrity** (`wiki-links-anchors-lint.ps1`)
```powershell
pwsh scripts/pwsh/wiki-links-anchors-lint.ps1 \
  -Path "Wiki/EasyWayData.wiki" \
  -ExcludePaths logs/reports,archive
```

**Output**: `wiki-links-anchors-lint.json` con broken links

---

### C. Auto-Fix Scripts

#### 1. **Frontmatter Patch** (`wiki-frontmatter-patch.ps1`)
- Inietta facet mancanti basandosi su path
- Esempio: `standards/` → `domain/docs`, `layer/spec`

#### 2. **Smart Link Fix** (`smart-fix-links.ps1`)
- Mappa vecchi path a nuovi
- Calcola path relativi con gerarchia URI
- Converte Obsidian links

---

### D. Workflow Completo (`/audit-wiki`)

**6 Fasi**:
1. **Baseline Audit** - Conta errori iniziali
2. **Fix Taxonomy** - 3 livelli iterativi
3. **Fix Links** - Hierarchy-aware
4. **Report** - Metriche di miglioramento
5. **Cleanup** - Interventi manuali
6. **Git Commit/Push** - Audit trail

**Esecuzione**:
```bash
# Manuale
/audit-wiki

# Automatico (n8n)
Schedule: Daily 2AM
Trigger: POST /webhook/audit-wiki
```

---

## 📖 Best Practices per Autori

### Frontmatter Template
```yaml
---
id: unique-kebab-case-id
title: Human-Readable Title
summary: One-line description (max 150 chars)
tags: [domain/X, layer/Y, audience/Z, privacy/W, language/L, free-tag1, free-tag2]
status: draft|active|deprecated
owner: team-name
updated: YYYY-MM-DD
llm:
  include: true|false
  pii: none|low|high
  chunk_hint: 200-600  # tokens per chunk
entities: [entity1, entity2]  # Named entities for RAG
---
```

### Content Structure

**Per Umani**:
- ✅ Headers gerarchici (`#`, `##`, `###`)
- ✅ TOC per doc >500 righe
- ✅ Code blocks con syntax highlighting
- ✅ Esempi concreti

**Per RAG**:
- ✅ Chunk hint: 200-600 tokens (1-3 paragrafi)
- ✅ Self-contained sections (ogni `##` deve avere senso standalone)
- ✅ Entities esplicite nel frontmatter
- ✅ Evita riferimenti vaghi ("come visto sopra" → link esplicito)

**Per Agenti**:
- ✅ Link relativi corretti
- ✅ Facet completi
- ✅ Status aggiornato
- ✅ YAML valido

---

## 🚀 Adoption Roadmap

### Fase 1: Setup (1 giorno)
1. ✅ Copia `tag-taxonomy.json` nel tuo repo
2. ✅ Adatta facets al tuo dominio
3. ✅ Aggiungi free tags specifici
4. ✅ Copia script di audit (`scripts/pwsh/`)

### Fase 2: Baseline (1 giorno)
1. ✅ Esegui audit iniziale
2. ✅ Documenta metriche baseline
3. ✅ Identifica top 10 errori

### Fase 3: Fix Iterativo (1 settimana)
1. ✅ Esegui auto-fix (taxonomy + links)
2. ✅ Fix manuale dei rimanenti
3. ✅ Verifica miglioramento (target: >95% compliance)

### Fase 4: Automation (1 giorno)
1. ✅ Integra in CI/CD (GitHub Actions / n8n)
2. ✅ Schedule nightly audit
3. ✅ Notifiche su Slack/Teams

### Fase 5: Governance (ongoing)
1. ✅ Review mensile taxonomy (nuovi tag?)
2. ✅ Update link mappings (nuovi file?)
3. ✅ Evoluzione standard (feedback team)

---

## 📊 Metriche di Successo

### Taxonomy Compliance
- **Target**: >95%
- **Calcolo**: `(files_ok / total_files) * 100`
- **Monitoring**: `wiki-tags-lint.json`

### Link Integrity
- **Target**: <5% broken
- **Calcolo**: `(broken_links / total_links) * 100`
- **Monitoring**: `wiki-links-anchors-lint.json`

### RAG Quality
- **Chunk size**: 200-600 tokens (90% dei chunk)
- **Retrieval precision**: >80% (top-3)
- **Monitoring**: RAG analytics dashboard

### Human Satisfaction
- **Time to find**: <2 min per query
- **Survey**: Quarterly NPS
- **Monitoring**: Analytics + feedback

---

## 🔧 Troubleshooting

### "Troppi errori taxonomy"
→ Evolvi taxonomy aggiungendo free tags comuni  
→ Escludi directory legacy (`archive/`, `old/`)

### "Link fix non funziona"
→ Aggiungi mapping in `smart-fix-links.ps1`  
→ Verifica path relativi con `Get-RelativePath`

### "RAG retrieval scarso"
→ Verifica `chunk_hint` (200-600 tokens)  
→ Aggiungi `entities` nel frontmatter  
→ Usa facet filtering in query

### "Agenti non fixano"
→ Verifica JSON output degli script  
→ Check exit codes (0 = success)  
→ Review n8n workflow logs

---

## 📚 Risorse

### Template & Tools
- [`tag-taxonomy.json`](../../agentic/templates/docs/tag-taxonomy.json) - Taxonomy di riferimento
- [`/audit-wiki`](../../.agent/workflows/audit-wiki.md) - Workflow completo
- [`smart-fix-links.ps1`](../../scripts/automation/smart-fix-links.ps1) - Link fixer

### Documentazione
- [Audit Guide](./docs-audit-guide.md) - Guida dettagliata
- [Tagging Howto](../../onboarding/howto-tagging.md) - Come taggare
- [RAG Best Practices](./rag-documentation-best-practices.md) - Ottimizzazione RAG

### Community
- **Slack**: `#docs-quality`
- **GitHub**: Issues & Discussions
- **Monthly Review**: Primo lunedì del mese

---

## 🎓 Esempi Reali

### Prima del Framework
```yaml
---
title: Server Setup
tags: [server, setup, linux]
---
# Server Setup
See the other doc for details...
```

**Problemi**:
- ❌ Facet mancanti
- ❌ Free tags non canonici (`linux` → `operations`?)
- ❌ Link vago ("other doc")
- ❌ No chunk hint per RAG

### Dopo il Framework
```yaml
---
id: server-bootstrap-protocol
title: Server Bootstrap Protocol
summary: Step-by-step guide for provisioning new Ubuntu servers with security hardening
tags: [domain/docs, layer/runbook, audience/ops, privacy/internal, language/it, operations, security, canonical]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 300-400
entities: [Ubuntu, SSH, UFW, fail2ban]
---

# Server Bootstrap Protocol

Complete runbook for provisioning new servers following [TESS](./easyway-server-standard.md) standard.

## Prerequisites
- Ubuntu 22.04 LTS
- SSH access with key
- See [SSH Setup](../security/ssh-key-management.md)
...
```

**Miglioramenti**:
- ✅ Tutti i facet presenti
- ✅ Free tags canonici
- ✅ Link espliciti e corretti
- ✅ Chunk hint per RAG
- ✅ Entities per retrieval

---

## 🚀 Prossimi Passi

1. **Adotta il framework** nel tuo progetto
2. **Esegui baseline audit** per capire lo stato attuale
3. **Itera sui fix** fino a >95% compliance
4. **Automatizza** con CI/CD
5. **Condividi feedback** per evolvere il framework

**Domande?** → `#docs-quality` su Slack

---

**Maintained by**: EasyWay Documentation Team  
**License**: MIT (riutilizzabile liberamente)  
**Version**: 1.0 (2026-02-03)
