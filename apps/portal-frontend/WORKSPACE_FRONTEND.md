# Work-Space Frontend (Themes & Assets)

Canonical authoring location for theme packs and their assets:
- `C:\old\Work-space-frontend`

Repo runtime location (frontend container serves from here):
- `EasyWayDataPortal/apps/portal-frontend/public`

Start here:
- `START_HERE_RUNTIME_FRONTEND.md`

## Layout (Work-space-frontend)
- `theme-packs.manifest.json`
- `assets.manifest.json`
- `pages/`
  - `pages.manifest.json` (served as `/pages/pages.manifest.json`)
  - `<id>.json`
- `content/`
  - `base.json`
  - `<lang>.json`
- `theme-packs/`
  - `theme-pack.easyway-arcane.json`
  - `theme-pack.utilitaria.json`
  - `theme-pack.fuoriserie.json`
  - `theme-pack.accoglienza.json`
- `assets/themes/<themeId>/hero.webp` (or `.svg` as placeholder)

## Rules
- Do not hardcode asset paths in PageSpecs. Use asset ids from `assets.manifest.json`.
- Theme packs must reference assets via ids (example: `heroBgId`).
- Default theme is `SOVEREIGN_CONFIG.theme.defaultId` in `public/config.js`.
- CSS precedence is controlled by `SOVEREIGN_CONFIG.theme.precedence`:
  - `branding_over_theme` (default): theme packs first, then branding.json
  - `theme_over_branding`: branding.json first, then theme packs
- Per-page override is `pages.<id>.json.themeId`.

## Sync Workflow (Manual)
Copy these files/folders from `C:\old\Work-space-frontend` into `EasyWayDataPortal/apps/portal-frontend/public`:
- `theme-packs.manifest.json`
- `assets.manifest.json`
- `theme-packs/`
- `assets/themes/`

Goal: allow editing themes/assets without rebuilding the app or Docker image (mount as volumes in prod).

## Sync Workflow (Script)
From repo root:
- `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1`
- Dry-run: `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -WhatIf`
- Clean target folders first: `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -Clean -Verify`
- Write JSON report: `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -Verify -ReportPath out\\sync-report.frontend-themes.json`

## Docker Compose Override (No Rebuild)
Mount theme packs + assets directly from the workspace folder (runtime content):
- `EasyWayDataPortal\\docker-compose.apps.workspace-frontend-themes.override.yml`
Mount pages + content directly from the workspace folder:
- `EasyWayDataPortal\\docker-compose.apps.workspace-frontend-pages-content.override.yml`

Example:
- `WORKSPACE_FRONTEND=C:/old/Work-space-frontend docker compose -f docker-compose.apps.yml -f docker-compose.apps.workspace-frontend-themes.override.yml up -d`
- `WORKSPACE_FRONTEND=C:/old/Work-space-frontend docker compose -f docker-compose.apps.yml -f docker-compose.apps.workspace-frontend-themes.override.yml -f docker-compose.apps.workspace-frontend-pages-content.override.yml up -d`
