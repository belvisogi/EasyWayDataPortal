- **Deployment**: Docker Multi-stage + Nginx Alpine.

## 🚀 Quick Start

### Prerequisites
- Node.js 22+
- Docker (optional, for containerized run)

### Local Development
```bash
# Install dependencies
npm install

# Start Dev Server
npm run dev
```

### Build for Production
```bash
npm run build
# Output located in /dist
```

### Docker Deployment
```bash
docker-compose up -d --build frontend
```

## 🎨 Design Philosophy (PDR)
> *"Il Frontend è il nostro vestito."*
> [Leggi il Manifesto 🌹](docs/manifesto-valentino.md)

**Valentino Framework** è l'architettura frontend "Sovereign" di EasyWay.

*   **Identity**: "Sovereign Intelligence". You own the machine.
*   **Visuals**: Dark, Serious, Engineering-focused.
*   **GEDI**: The "Guardian" is integrated as a visual copilot.

## 🏆 Sovereignty Status: 100%
> **Zero Dependencies.** This project behaves like a standard HTML/JS website, but with the power of a modern framework.

- **Runtime Dependencies**: 0 (Clean `package.json`)
- **Framework**: Valentino (Native Web Components)
- **Quality Shield**: Active (Visual, Inclusive, Chaos)

---

## Project Structure & Blueprints (The "Valentino" Standard)

To prevent technical debt, **ALWAYS** use the official blueprints when creating new files.
Do not invent new patterns. Clone and adapt these templates:

- 📄 **Pages**: `src/_blueprints/page.blueprint.ts`
- 🧩 **Components**: `src/_blueprints/component.blueprint.ts`
- 🔌 **Services**: `src/_blueprints/service.blueprint.ts`

### Core Principles
- **Framework**: Vanilla TypeScript + Vite (No React, No Angular).
- **Styling**: Pure CSS3 with Custom Properties (Variables).

## 🛡️ Security
*   **Headers**: Nginx is configured with strictly enforced security headers (HSTS, No-Sniff).
*   **Dependency-Free**: Minimized attack surface by removing complex UI libraries.

## 🧩 Runtime Pages (No Rebuild)
To add/modify pages without rebuilding the app/image, see:
- `RUNTIME_PAGES.md`
- `START_HERE_RUNTIME_FRONTEND.md`
