# Start Here: Runtime Frontend (Pages + Themes + Assets)

Purpose: keep the EasyWay frontend **low-hardcoding** and **antifragile**.
Pages, copy, themes and assets are runtime JSON + static files, so you can change them without rebuilding the app/Docker image.

This doc is the single entrypoint for humans and AI agents.

## Canonical Locations (Source of Truth)
- Authoring workspace (edit here first):
  - `C:\old\Work-space-frontend`
- Repo runtime (served by Nginx from this folder):
  - `EasyWayDataPortal/apps/portal-frontend/public`

## Core vs Runtime
Hardcoded core (changes rarely):
- `EasyWayDataPortal/apps/portal-frontend/index.html` (single-shell)
- `EasyWayDataPortal/apps/portal-frontend/src/utils/runtime-pages.ts` (router + bootstrap)
- `EasyWayDataPortal/apps/portal-frontend/src/utils/pages-renderer.ts` (canonical section renderer)
- `EasyWayDataPortal/apps/portal-frontend/src/utils/theme-packs-loader.ts` (theme pack loader)
- `EasyWayDataPortal/apps/portal-frontend/src/framework.css` (skeleton)
- `EasyWayDataPortal/apps/portal-frontend/src/theme.css` (defaults + CSS vars contract)

Runtime content (changes often, no rebuild):
- Pages:
  - `EasyWayDataPortal/apps/portal-frontend/public/pages/pages.manifest.json`
  - `EasyWayDataPortal/apps/portal-frontend/public/pages/<id>.json`
- Copy (i18n):
  - Base dictionary: `EasyWayDataPortal/apps/portal-frontend/public/content/base.json` (preferred) or `.../public/content.json` (legacy)
  - Overlay (delta): `EasyWayDataPortal/apps/portal-frontend/public/content/<lang>.json`
- Themes + assets registry:
  - `EasyWayDataPortal/apps/portal-frontend/public/theme-packs.manifest.json`
  - `EasyWayDataPortal/apps/portal-frontend/public/theme-packs/theme-pack.<id>.json`
  - `EasyWayDataPortal/apps/portal-frontend/public/assets.manifest.json`
  - `EasyWayDataPortal/apps/portal-frontend/public/assets/themes/<themeId>/...`

## Theme Precedence (Config Flag)
Configured in:
- `EasyWayDataPortal/apps/portal-frontend/public/config.js`

Values:
- `branding_over_theme` (default): theme packs first, then `branding.json` (branding wins)
- `theme_over_branding`: `branding.json` first, then theme packs (theme wins)

## Add a Page (Checklist)
1) Add entry to `public/pages/pages.manifest.json`
2) Create `public/pages/<id>.json`
3) Add copy keys to `public/content/<lang>.json`
4) (Optional) set `themeId` in `public/pages/<id>.json`
5) Validate (see QA below)

## Add a Theme Pack (Checklist)
1) Add assets under workspace:
   - `C:\old\Work-space-frontend\assets\themes\<themeId>\...`
2) Map asset ids in:
   - `C:\old\Work-space-frontend\assets.manifest.json`
3) Create pack:
   - `C:\old\Work-space-frontend\theme-packs\theme-pack.<themeId>.json`
4) Register in:
   - `C:\old\Work-space-frontend\theme-packs.manifest.json`
5) Sync to repo public (script)

## Sync Workflow (Workspace -> Repo)
Use the sync script (recommended):
- `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -Verify`
- Dry-run: `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -WhatIf`
- Clean + verify: `pwsh .\\scripts\\sync-workspace-frontend-themes.ps1 -Clean -Verify`

## QA / Validation
Fast "schema-lite" validation (no deps) from repo root:
- `pwsh .\\scripts\\qa\\validate-runtime-pages.ps1`

Full JSON-Schema validation (AJV) from `apps/portal-frontend`:
- `npm run validate:runtime`

## Docker Compose (No Rebuild In Prod)
Mount theme packs + assets directly from the workspace folder:
- `EasyWayDataPortal/docker-compose.apps.workspace-frontend-themes.override.yml`

Mount pages + content directly from the workspace folder:
- `EasyWayDataPortal/docker-compose.apps.workspace-frontend-pages-content.override.yml`

## References
- Runtime pages manual: `EasyWayDataPortal/apps/portal-frontend/RUNTIME_PAGES.md`
- Workspace rules: `EasyWayDataPortal/apps/portal-frontend/WORKSPACE_FRONTEND.md`
- Frontend overview: `EasyWayDataPortal/apps/portal-frontend/README.md`
