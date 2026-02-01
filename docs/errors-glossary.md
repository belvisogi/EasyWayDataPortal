# EasyWay Core — Error Glossary (Human‑Readable)

This glossary describes common errors in plain language and how to fix them.

## Template (use for new entries)
**Short title**
- Symptom: "Exact message or close variant"
- Meaning: One line plain explanation.
- Fix: One line actionable remediation.

## Content / i18n
**Missing content key**
- Symptom: Console warning like `[ContentLoader] Missing key: ...`
- Meaning: The page expects a text key that does not exist in `content/base.json` or the language overlay.
- Fix: Add the missing key to `public/content/base.json` (and override language file if needed).

## Runtime Pages
**Manifest not found**
- Symptom: “Runtime pages manifest not found.”
- Meaning: `/pages/pages.manifest.json` is missing or not reachable.
- Fix: Ensure the file exists in `public/pages/` and is copied in build.

**Runtime root missing**
- Symptom: “[RuntimePages] Missing #page-root. Skipping runtime pages init.”
- Meaning: The SPA root `<main id="page-root">` is missing in the HTML shell.
- Fix: Ensure `index.html` contains `#page-root`.

**Manifest load failed**
- Symptom: “[RuntimePages] Failed to load pages manifest”
- Meaning: Network/JSON error while loading the manifest.
- Fix: Check `/pages/pages.manifest.json` exists and is valid JSON.

**Page spec failed to load**
- Symptom: “Failed to load page spec: /pages/xyz.json” or “[RuntimePages] Failed to load page spec”
- Meaning: The page JSON is missing or invalid.
- Fix: Confirm the file path in `pages.manifest.json` and validate JSON schema.

**Invalid JSON**
- Symptom: Console error `Invalid JSON at /pages/...`
- Meaning: JSON contains syntax errors.
- Fix: Fix JSON syntax and re-run `npm run validate:runtime`.

## Boot / App init
**Bootstrap failed**
- Symptom: “[Sovereign] Bootstrap failed”
- Meaning: Startup failed due to earlier runtime errors.
- Fix: Check console logs above for the first failure.

## Branding / Theme
**Branding fallback**
- Symptom: Warning `Fallback to default styles.` or `⚠️ [SovereignTheme] Fallback to default styles.`
- Meaning: `branding.json` missing or unreadable.
- Fix: Ensure `public/branding.json` exists and is valid JSON.

## Network / HTTP
**Smoke test failed**
- Symptom: HTTP smoke test reports non‑200 routes.
- Meaning: A route is not reachable or the server is down.
- Fix: Check deployment, Nginx/Traefik routing, and container health.

## Accessibility
**No focus after navigation**
- Symptom: Screen reader focus does not move to main heading.
- Meaning: H1 missing or page isn’t focusing.
- Fix: Ensure page renders an H1 and use `.h1` class.
