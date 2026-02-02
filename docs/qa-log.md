# EasyWay Core — Q&A / Change Log (Frontend)

This log tracks decisions and fixes from the current build cycle.

## 2026-02-01
- Manifesto routing: `/manifesto` is a runtime page rendered by the single-shell (no extra HTML entrypoints).
- SPA nav: global runtime link interception to avoid full reloads.
- Footer flash: runtime preload guard to prevent layout jump on navigation.
- Header stability: nav renders only after content + branding ready (prevents flicker).
- Demo moved to runtime (`/demo`) with form section; `/demo.html` redirects.
- Typography: unified `.h1/.h2` and `--font-family`/`--font-mono` usage across pages.
- Cache policy: HTML/config no-store; static assets immutable (nginx).
- QA: frontend audit added + wired into pre-commit and pre-flight.
- Audit status: 10/10 (framework + audit + docs complete).

## 2026-02-02
- HTTP Smoke Test: Configured `.env.production` with `SMOKE_BASE_URL=http://80.225.86.168`.
- Smoke test validates 5 routes: /, /demo, /manifesto, /memory, /pricing (all return 200 OK).
- Phase 1 of 10/10 roadmap complete: Production smoke testing operational.
- **Storybook Setup Attempt**: Tried Storybook 10.x → incompatible with Vite 6.x.
- **Storybook Downgrade**: Installed Storybook 8.6.15 → still has package incompatibility warnings.
- **Storybook Startup Issue**: Server starts but hangs during build (doesn't complete loading).
- **Root Cause**: Vite 6.x + TypeScript 5.7 + Storybook 8.x have peer dependency conflicts.
- **Decision**: Skip Storybook, implement custom `/demo-components` page instead (simpler, antifragile).
- **Rationale**: Custom demo page = zero dependencies, full control, 30min vs 5 days.

## Test Policy (Agreed)
- Automated tests (agent): audit scripts + HTTP sanity checks.
- Manual tests (owner): UI/UX visual validation.

## Notes
- Goal: "change skin in minutes" with minimal hardcoded styling.
- Rule: framework + audit + docs for antifragility.
