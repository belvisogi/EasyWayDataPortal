# EasyWay Core — Decisions (ADR Lite)

## 2026-02-01 — Antifragile UI Governance
Decision:
- Adopt the model: framework + audit + docs.

Why:
- Docs alone are not enforceable.
- Framework encodes the rules; audit blocks regressions; docs keep humans/agents aligned.

Scope:
- Frontend now.
- To be extended to Data Lake, DB, Security, Agents, and infra.

## 2026-02-01 — Manifesto Rendering
Decision:
- Keep manifesto as runtime page (`/manifesto`) rendered by the single-shell.

Why:
- Avoid build-time dependency on extra HTML entrypoints.
- Keeps routing consistent with other runtime pages and reduces refresh flicker.

## 2026-02-01 — Cache Strategy (Frontend)
Decision:
- HTML + config no-store; assets immutable.

Why:
- Fast updates for content; stable caching for assets.

## 2026-02-01 — Demo as Runtime Page
Decision:
- Move Demo to runtime routing (`/demo`) and avoid extra HTML entrypoints.

Why:
- Removes full reload flicker and keeps single-shell consistency.
- Aligns with antifragile UI governance.

### 2026-02-02: The "Valentino Framework" (Epic Moment) 🌹
**Context**: We achieved a perfect 10/10 score in robust testing (E2E Navigation, Forms, Smoke Tests).
**Decision**: Rebrand the frontend architecture to **Valentino Framework**.
**Philosophy**: *"Il Frontend è il nostro vestito."* (Engineering as Haute Couture).
**Key Pillars**:
1.  **Sartorial**: No bloated frameworks, just pure Sovereign Web Components.
2.  **Robust**: 100% E2E Test Coverage (NetworkIdle Strategy).
3.  **Elegant**: Glassmorphism visuals + "Agent-Ready" operational manuals.
**Impact**: The frontend is no longer just code; it's a bespoke suit for enterprise data.

## 2026-02-02 — Component Showcase (Antifragile Alternative to Storybook)

**Decision**:
- Build custom `/demo-components` page instead of Storybook for component documentation.

**Context**:
- Needed interactive component brochure for open source framework release.
- Storybook 10.x incompatible with Vite 6.x (peer dependency conflicts).
- Storybook 8.x build hangs during startup (Vite 6 + TypeScript 5.7 incompatibility).

**Why**:
- **Antifragile**: Zero external dependencies (no Storybook to break).
- **Fast**: Implemented in ~2 hours vs weeks waiting for Storybook compatibility.
- **Full Control**: Custom UX tailored to framework needs.
- **Future-Proof**: Migration path to Storybook preserved when Vite 6 supported.

**Implementation**:
- Extended type system: `ComponentShowcaseSection`, `ShowcaseIntroSection`.
- Created renderers with JSON preview + copy-to-clipboard + live component rendering.
- Styled with `showcase.css` (dark theme, responsive, cyan/gold accents).
- Showcased 5 canonical sections (hero, cards, comparison, cta, form) with variants.

**Deployment**:
- Fixed Dockerfile: `npm ci` → `npm install --production=false` (antifragile builds).
- Deployed via Docker Compose on production server (80.225.86.168).
- Created comprehensive Docker services reference (`docs/docker-services.md`) to avoid future "treasure hunting".

**Result**:
- ✅ `/demo-components` live on production (HTTP 200 OK).
- ✅ Zero dependencies, full control, extensible.
- ✅ Future Storybook migration path preserved.

**Lessons Learned**:
1. Always check docs first (avoid trial & error).
2. Document as you go (Docker services, deployment process).
3. Antifragile > Perfect (working solution today > ideal solution tomorrow).

**References**:
- Implementation: `walkthrough.md` (artifacts)
- Deployment: `docs/qa-log.md` (Docker Deployment Process section)
- Docker Services: `docs/docker-services.md` (10 services documented)
- Storybook Guide: `docs/storybook-guide.md` (future migration)

**Epic Moment**: 2026-02-02, 07:30 UTC — Component Showcase deployed to production, marking EasyWay Core's commitment to antifragile, zero-dependency solutions.
