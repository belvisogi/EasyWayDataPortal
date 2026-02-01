# EasyWay Core — Frontend Best Practices

These guidelines keep the UI consistent, antifragile, and easy to maintain by humans and agents.

## Content & i18n
- Use `/public/content/base.json` for canonical copy.
- Add language overrides in `/public/content/<lang>.json` (e.g. `it.json`, `en.json`).
- Avoid hardcoded text in HTML except for placeholders.

## Pages & routing
- Runtime pages live in `/public/pages/*.json` and are registered in `/public/pages/pages.manifest.json`.
- Static pages are allowed for long‑form content (e.g. `manifesto.html`).
- `/manifesto` should redirect to `/manifesto.html` to keep long-form static content stable.

## CSS framework usage
- Every page must include:
  - `/src/theme.css`
  - `/src/framework.css`
  - `/src/style.css`
- Use `.h1` / `.h2` classes for headings (scale + consistency).
- Avoid hardcoded `font-family` (use `var(--font-family)`).
- Monospace is allowed only for code blocks.

## Header/Nav consistency
- Always use `<sovereign-header>` and `<sovereign-footer>`.
- Links between runtime pages should stay in SPA navigation (no full reload).

## Cache policy
- HTML + `config.js` are `no-store` (always fresh).
- Static assets (CSS/JS/SVG/fonts) are long‑cached and immutable.

## QA automation
- `scripts/qa/audit-frontend.ps1` enforces:
  - framework CSS presence
  - no Google Fonts
  - no hardcoded font-family
  - `.h1/.h2` on H1/H2
- `scripts/qa/pre-flight-check.ps1` runs before deploy.

## When adding a new page
- Decide: runtime JSON vs static HTML.
- If runtime:
  - Add spec to `/public/pages/*.json`
  - Register in `/public/pages/pages.manifest.json`
  - Add copy to `base.json` + language file.
- If static:
  - Include theme/framework/style CSS
  - Use `.h1/.h2` classes
  - Ensure header/footer are present

## Mini checklist (quick scan)
- [ ] Uses `/src/theme.css`, `/src/framework.css`, `/src/style.css`
- [ ] H1/H2 use `.h1` / `.h2`
- [ ] No hardcoded `font-family` (except code blocks)
- [ ] Text in `content/base.json` + language file
- [ ] Runtime pages registered in `pages.manifest.json`
- [ ] Nav links stay SPA (no full reload for runtime routes)

## Tests (must do)
Automated (agent)
- Run `scripts/qa/audit-frontend.ps1`
- HTTP checks for `/`, `/demo`, `/manifesto`, `/memory`, `/pricing`
- Run all: `scripts/qa/qa-run-all.ps1`

Manual (owner)
- Visual nav stability (no flicker)
- CTA color consistency (Home vs Demo)
- Manifesto readability + theming

## Accessibility (baseline)
- Use `aria-current="page"` on active nav items.
- Use `aria-busy="true"` while SPA is loading.
- Focus the main heading after SPA navigation.
