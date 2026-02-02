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
This frontend implements the **Product Design Requirement** defined in `docs/design/frontend_pdr.md`.

*   **Identity**: "Sovereign Intelligence". You own the machine.
*   **Visuals**: Dark, Serious, Engineering-focused.
*   **GEDI**: The "Guardian" is integrated as a visual copilot.

## 🛡️ Security
*   **Headers**: Nginx is configured with strictly enforced security headers (HSTS, No-Sniff).
*   **Dependency-Free**: Minimized attack surface by removing complex UI libraries.

## 🧩 Runtime Pages (No Rebuild)
To add/modify pages without rebuilding the app/image, see:
- `RUNTIME_PAGES.md`
- `START_HERE_RUNTIME_FRONTEND.md`
