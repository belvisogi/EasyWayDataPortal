# 📚 Documentation Quality Framework (DQF)

> **Framework completo per documentazione di alta qualità, ottimizzata per umani, RAG e agenti AI**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/version-1.0-blue.svg)](docs/agentic/documentation-quality-framework.md)
[![Compliance](https://img.shields.io/badge/taxonomy-100%25-success.svg)](wiki-tags-lint.json)

---

## 🎯 Quick Start

### 1. Adotta il Framework (5 minuti)
```bash
# Copia taxonomy nel tuo repo
cp docs/agentic/templates/docs/tag-taxonomy.json your-repo/

# Copia script di audit
cp -r scripts/pwsh/ your-repo/scripts/

# Copia workflow
cp .agent/workflows/audit-wiki.md your-repo/.agent/workflows/
```

### 2. Esegui Baseline Audit
```bash
pwsh scripts/pwsh/wiki-tags-lint.ps1 -Path "docs/" -RequireFacets
pwsh scripts/pwsh/wiki-links-anchors-lint.ps1 -Path "docs/"
```

### 3. Auto-Fix
```bash
# Fix taxonomy
pwsh scripts/pwsh/wiki-frontmatter-patch.ps1 -Path "docs/" -Apply

# Fix links
pwsh scripts/automation/smart-fix-links.ps1 -Apply
```

### 4. Verifica Miglioramento
```bash
# Re-run audit
pwsh scripts/pwsh/wiki-tags-lint.ps1 -Path "docs/" -RequireFacets

# Target: >95% compliance
```

---

## 📖 Documentazione Completa

- **[Documentation Quality Framework](docs/agentic/documentation-quality-framework.md)** - Guida completa
- **[RAG Best Practices](docs/agentic/rag-documentation-best-practices.md)** - Ottimizzazione RAG
- **[Audit Workflow](. agent/workflows/audit-wiki.md)** - Workflow automatico
- **[Tagging Howto](Wiki/EasyWayData.wiki/onboarding/howto-tagging.md)** - Come taggare

---

## 🏆 Benefici

### Per Umani 👤
- ✅ Navigazione facile (taxonomy-driven)
- ✅ Link sempre funzionanti
- ✅ Metadata ricco (summary, status, owner)
- ✅ Struttura consistente

### Per RAG 🤖
- ✅ Chunking ottimale (200-600 tokens)
- ✅ Metadata filtering preciso
- ✅ Self-contained sections
- ✅ Entity-based retrieval

### Per Agenti 🔧
- ✅ Validazione automatica
- ✅ Auto-fix (taxonomy + links)
- ✅ CI/CD integration
- ✅ Self-healing docs

---

## 📊 Metriche (EasyWayDataPortal)

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| **Taxonomy Compliance** | 71% | 100% | +29% ✅ |
| **Broken Links** | 140 | 140 | 0% ⚠️ |
| **Canonical Tags** | 27 | 47 | +74% ✅ |
| **Archive Excluded** | ❌ | ✅ | Clean audit |

---

## 🚀 Roadmap

- [x] **v1.0** - Core framework + audit scripts
- [ ] **v1.1** - GitHub Actions integration
- [ ] **v1.2** - RAG analytics dashboard
- [ ] **v1.3** - Multi-language support (EN, IT, ES)
- [ ] **v2.0** - AI-powered taxonomy evolution

---

## 🤝 Contributing

Questo framework è **open source** e riutilizzabile liberamente (MIT License).

**Feedback & Improvements**:
1. Apri una Issue su GitHub
2. Proponi modifiche via PR
3. Condividi use case in Discussions

---

## 📜 License

MIT License - Riutilizzabile liberamente in progetti commerciali e open source.

---

## 🙏 Credits

Sviluppato da **EasyWay Documentation Team** come best practice per documentazione enterprise.

**Maintainers**:
- [@team-docs](mailto:docs@easyway.com) - Framework & governance
- [@team-ai](mailto:ai@easyway.com) - RAG optimization

---

**Version**: 1.0 (2026-02-03)  
**Status**: Production-ready ✅
