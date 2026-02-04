---
id: ew-runbooks-release-checklist
title: EasyWay Core - Release Checklist (QA Protocol)
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# EasyWay Core - Release Checklist (QA Protocol)
*Standard Operating Procedure for dispensing Sovereign Quality.*

## 1. Automated Pre-Flight Checks 🤖
Run `.\scripts\qa\pre-flight-check.ps1` to verify:
- [ ] **Component Imports**: Does `main.ts` import Header/Footer?
- [ ] **Mobile Readiness**: Do all HTML files have `<meta name="viewport">`?
- [ ] **SEO/Branding**: Do all HTML files have a `<title>` starting with "EasyWay"?
- [ ] **Clean Code**: No `console.log` leftovers (except System Boot).

## 2. Visual Verification (The "Human" Eye) 👁️
**Responsive Design (Mobile First)**
- [ ] Open Chrome DevTools (`F12`) -> Toggle Device Toolbar (`Ctrl+Shift+M`).
- [ ] Select **Pixel 7** or **iPhone SE** (Smallest standard).
- [ ] Verify: **Header** does not overlap content (`padding-top` check).
- [ ] Verify: **Grid/Cards** stack vertically (no horizontal scroll).

**Functionality**
- [ ] **Navigation**: Click every link in the Header. Does it go where expected?
- [ ] **Interactivity**: Buttons (`Request Demo`, `Visualize`) click and react?
- [ ] **Console**: Are there Red Errors in the Console? (Ignore harmless warnings).

## 3. Deployment & Final Verification 🚀
- [ ] **Git Push**: Is the repo clean?
- [ ] **Deploy**: Run `deploy-oracle.ps1`.
- [ ] **Live Check**: Visit `http://80.225.86.168`.
    - [ ] Check Title.
    - [ ] Check Easter Eggs (if modified).
    - [ ] Check Footer Version.

---
*Verified by:* `____________________`  *Date:* `__/__/____`



