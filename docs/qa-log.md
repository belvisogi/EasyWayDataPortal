# EasyWay Core — Q&A / Change Log (Frontend)

This log tracks decisions and fixes from the current build cycle.

## 2026-02-01
- Manifesto routing: `/manifesto` redirects to `/manifesto.html` for long-form stability.
- SPA nav: global runtime link interception to avoid full reloads.
- Footer flash: runtime preload guard to prevent layout jump on navigation.
- Header stability: nav renders only after content + branding ready (prevents flicker).
- Typography: unified `.h1/.h2` and `--font-family`/`--font-mono` usage across pages.
- Cache policy: HTML/config no-store; static assets immutable (nginx).
- QA: frontend audit added + wired into pre-commit and pre-flight.

## Notes
- Goal: "change skin in minutes" with minimal hardcoded styling.
- Rule: framework + audit + docs for antifragility.
