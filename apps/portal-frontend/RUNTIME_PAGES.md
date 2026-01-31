# Runtime Pages Framework (v1)

Goal: add/modify pages without rebuilding the frontend and without rebuilding the Docker image.
Only the "engine" (router + renderer + components + CSS) is built; page structure and copy are runtime JSON.

## What Is Hardcoded (Core)
- `src/framework.css`: Skeleton (layout/grid/cards/buttons/header responsive)
- `src/theme.css`: Skin default (CSS variables)
- `src/utils/runtime-pages.ts`: router + page bootstrap
- `src/utils/pages-renderer.ts`: section renderer (canonical components)
- `src/components/sovereign-header.ts`: header (nav is manifest-driven)
- `public/branding.json` + `public/config.js`: runtime configuration (already supported)

## What Is Runtime (No Rebuild)
These files can be mounted into the Nginx container and edited live:
- Pages manifest (sitemap + navbar + route -> spec):
  - `public/pages/pages.manifest.json`
- Page specs (one file per page):
  - `public/pages/<id>.json` (examples: `public/pages/home.json`, `public/pages/demo.json`)
- Copy/i18n overlay (language-specific):
  - `public/content/<lang>.json` (example: `public/content/it.json`)
- Base copy dictionary (legacy-friendly):
  - `public/content/base.json` (preferred) or `public/content.json` (legacy fallback)
- Theme packs + assets registry:
  - `public/theme-packs.manifest.json`
  - `public/theme-packs/theme-pack.<id>.json`
  - `public/assets.manifest.json`

Content loading rules:
- Prefer loading `content/base.json` as the base dictionary.
- Legacy fallback: if missing, load `content.json` as the base dictionary.
- Then load the first available overlay (example: `content/it.json`) and deep-merge it on top.

## Routing (Single-Shell + Nginx Rewrite)
- The app uses a single shell: `index.html` contains `<main id="page-root"></main>`.
- Nginx already serves SPA routes via `try_files $uri $uri/ /index.html;` in `nginx.conf`.
- URLs are "clean" (example: `/demo`, `/manifesto`).

## How To Add A New Page (Human or AI Agent)
Example: add a new page `pricing` on route `/pricing`.

1) Add the page entry to `public/pages/pages.manifest.json`
- Choose an `id` (kebab-case)
- Choose a `route` (leading `/`)
- Set `spec` to `/pages/<id>.json`
- Add `nav` with `labelKey` and `order` (if it must appear in the navbar)
- Set `titleKey` (recommended)

2) Create `public/pages/pricing.json`
- Use only canonical section `type` values (v1):
  - `hero`, `cards` (variant: `catalog`), `comparison`, `cta`, `spacer`
- No hardcoded text: use `...Key` fields and put the copy in the content dictionaries.

3) Add/override copy keys
- Add navbar label: `nav.pricing`
- Add page title: `page.pricing.title`
- Put them in `public/content/it.json` (and other languages if needed)

4) Verify in dev
- `npm run dev` from `apps/portal-frontend`
- Open `http://localhost:5173/pricing`

## Production / Docker: Mount Runtime Content
To change pages without rebuilding the image, mount overrides into the container html root:
- Target path inside container: `/usr/share/nginx/html/`
- Files you can mount:
  - `pages/` (folder)
  - `content/` (folder)
  - `branding.json`
  - `config.js`

Example (conceptual):
- `./portal-content/pages:/usr/share/nginx/html/pages:ro`
- `./portal-content/content:/usr/share/nginx/html/content:ro`
- `./portal-content/branding.json:/usr/share/nginx/html/branding.json:ro`
- `./portal-content/config.js:/usr/share/nginx/html/config.js:ro`
- `./portal-content/theme-packs.manifest.json:/usr/share/nginx/html/theme-packs.manifest.json:ro`
- `./portal-content/assets.manifest.json:/usr/share/nginx/html/assets.manifest.json:ro`
- `./portal-content/theme-packs:/usr/share/nginx/html/theme-packs:ro`
- `./portal-content/assets/themes:/usr/share/nginx/html/assets/themes:ro`

## Conventions (Must Follow)
- IDs: kebab-case (`agent-catalog`, `request-demo`)
- Routes: leading `/` and no trailing slash (except `/`)
- Copy: never embed strings in TS/HTML when the text belongs to content (use keys)
- HTML in content: allowed (renderer uses innerHTML when it sees `<`), but keep it minimal
- Themes:
  - Global default is `SOVEREIGN_CONFIG.theme.defaultId`
  - Page override is `pages/<id>.json.themeId`
  - Theme packs live in `public/theme-packs/theme-pack.<id>.json` and are listed in `public/theme-packs.manifest.json`
  - Assets are referenced by id via `public/assets.manifest.json` (avoid hardcoding paths in PageSpecs)
  - Precedence is controlled by `SOVEREIGN_CONFIG.theme.precedence`:
    - `branding_over_theme` (default): theme packs first, then `branding.json` (branding wins)
    - `theme_over_branding`: `branding.json` first, then theme packs (theme wins)
- Versions:
  - `pages.manifest.json.version` must remain `"1"` unless breaking changes
  - each `pages.<id>.json.version` must remain `"1"` unless breaking changes

## Notes For AI Agents
- Only touch:
  - manifest + page spec + content overlay when adding/modifying pages
  - do not modify CSS unless required by a new canonical component
- Keep keys stable: renaming keys requires migrating content in *all* languages.

## QA Validation (Recommended)
Run schema-lite validation (no external deps) from repo root:
- `pwsh .\\scripts\\qa\\validate-runtime-pages.ps1`

Run full JSON-Schema validation from portal-frontend (requires `npm install` there):
- `npm run validate:runtime`
