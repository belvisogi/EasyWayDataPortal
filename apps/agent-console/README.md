# 🌹 EasyWay Agent Console

**Valentino Framework** • Sovereign Architecture • Haute Couture Engineering

## Overview

Agent Console è la dashboard interattiva per visualizzare e gestire l'ecosistema di 26 agenti EasyWay.

### Features

- 📊 **Dashboard**: Statistiche in tempo reale (10 agenti attivi, 13 skills, 105 nodi nel Knowledge Graph)
- 🤖 **Agents View**: Griglia di tutti gli agenti con classificazione Brain/Arm
- 🗺️ **Knowledge Graph**: Visualizzazione interattiva D3.js con 105 nodi e 30 relazioni
- 🛠️ **Skills Registry**: Catalogo completo delle 13 skills disponibili
- 🔍 **Search**: Ricerca semantica su agenti e skills

## Valentino Framework Principles

### 1. Sovereign Architecture
- ✅ No React, Vue, o framework esterni
- ✅ Web Components nativi
- ✅ Vanilla CSS (no Tailwind)
- ✅ Unica dipendenza: D3.js (giustificata per graph visualization)

### 2. Haute Couture Engineering
- ✅ Design system custom con color palette sofisticata
- ✅ Spacing system basato su 8px
- ✅ Componenti "cuciti su misura" per EasyWay

### 3. Agent-Native
- ✅ Codice strutturato per essere letto e modificato da AI
- ✅ Commenti chiari e documentazione inline

## Quick Start

### Local Development

```bash
# Naviga nella directory
cd apps/agent-console

# Serve con Python (user-space, no sudo)
python -m http.server 8080

# Oppure con Node.js
npx http-server -p 8080
```

Apri: `http://localhost:8080`

### Production Deployment

```bash
# Build (già pronto, no build step necessario!)
# Deploy via Caddy (già configurato)
```

## File Structure

```
agent-console/
├── index.html              # Entry point
├── styles/
│   ├── valentino.css       # Core framework
│   └── console.css         # Console-specific styles
├── scripts/
│   ├── valentino-core.js   # Navigation & utilities
│   ├── console-app.js      # App logic & data loading
│   └── knowledge-graph.js  # D3.js graph visualization
└── README.md
```

## Data Sources

- **Agents**: `../../agents/kb/agents-summary.json` (auto-generated fallback)
- **Skills (runtime)**: `../../agents/skills/registry.json`
- **Skills (macro-use-case)**: `../../docs/skills/catalog.generated.json`
- **Knowledge Graph**: `../../agents/kb/knowledge-graph.json`

### Macro Skills Bridge

Rigenera il registry macro-use-case consumabile dalla console:

```bash
pwsh ../../scripts/pwsh/generate-macro-skills-registry.ps1
```

## Browser Support

- ✅ Chrome/Edge 90+
- ✅ Firefox 88+
- ✅ Safari 14+

## Performance

- **Load Time**: < 1s (no build, no bundler)
- **Bundle Size**: ~15KB CSS + ~20KB JS (minified)
- **Dependencies**: D3.js (~250KB, CDN cached)

## Future Enhancements

- [ ] 4 Guardiani (Visual, Inclusive, Chaos, Code)
- [ ] RAG Search integration con Qdrant
- [ ] Real-time agent status updates
- [ ] Export Knowledge Graph as PNG/SVG

---

**Built with ❤️ using Valentino Framework**
