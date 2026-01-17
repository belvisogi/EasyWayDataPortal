---
id: ew-caa-overview
title: EasyCAA Overview
summary: Comprehensive overview of EasyCAA project - free AAC tool for autism/DSA children following EasyWay manifesto principles.
status: active
owner: team-platform
tags: [domain/caa, layer/overview, audience/non-expert, audience/dev, privacy/internal, language/it, caa, social-impact]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: []
entities: []
updated: '2026-01-14'
next: Wait for teacher input on child routines, then start Fase 1
---

[[start-here|Home]] > [[Domain - Caa|Caa]] > [[Layer - Overview|Overview]]

# EasyCAA - Comunicazione Aumentativa Alternativa

**Mission**: Strumento CAA gratuito per ragazzi con autismo/DSA/disabilità comunicative.

## Filosofia

EasyCAA è costruito seguendo il [Manifesto EasyWay](../../../MANIFESTO.md):
- 🎯 **"Misuriamo Due, Tagliamo Una"** - ARGOS quality gates + ARASAAC standards
- 🐢 **"Preferisco Qualità alla Velocità"** - 2-3 mesi per farlo BENE
- 🛤️ **"Il Percorso da Godersi"** - Test reale con bambino prima di scaling
- 🎨 **"Impronta Tangibile"** - Codice che insegna + documentazione completa

**Guardian**: [Agent GEDI](../../../agents/agent_gedi/manifest.json)

---

## Documenti Chiave

### Ricerca & Standards
- **[CAA Research Findings](../../docs/caa/CAA_RESEARCH_FINDINGS.md)** - Comprehensive research:
  - ARASAAC (11k+ simboli gratuiti, standard italiano)
  - PECS metodologia (6 fasi per autismo)
  - Database schema best practices
  - WCAG 3.0 + autism accessibility guidelines
  - Competitor analysis (Tobii, Proloquo2Go, Grid 3)

### Planning
- **[Implementation Plan](../../../../../.gemini/antigravity/brain/6f45a52f-6c85-4393-8fe9-9f0e973a0b19/implementation_plan.md)** - Technical plan:
  - Database schema (child_profiles, vocabulary, routines, boards)
  - AI generation strategy (Claude + fallback templates)
  - Frontend accessibility design
  - Verification plan (test con figlio utente)

- **[Task List](../../../../../.gemini/antigravity/brain/6f45a52f-6c85-4393-8fe9-9f0e973a0b19/task.md)** - Breakdown per fasi:
  - Fase 1: Fondamenta (3-4 settimane)
  - Fase 2: AI & Interface (3-4 settimane)
  - Fase 3: Test Reale (2-3 settimane)
  - Fase 4: Build in Public (quando pronto)

---

## Architettura CAA

### Database Schema (Planned)
```sql
caa.child_profiles      - Profili bambini (età, PECS phase, preferences)
caa.vocabulary          - ARASAAC symbols + emoji fallback
caa.categories          - Gerarchia semantica (People, Actions, Feelings)
caa.routines            - Activity grids (mattina, scuola, pranzo)
caa.sentence_templates  - PECS Phase IV+ (sentence builder)
caa.generated_boards    - AI output cache
caa.progress_log        - Tracking completamento task
```sql

### API Endpoints (Planned)
```sql
POST /api/caa/routine/upload    - Upload Excel routine da educatori
GET  /api/caa/board/:child_id   - Retrieve board generata
POST /api/caa/progress/:child_id - Log task completato
```sql

### Standards Compliance
- ✅ **ARASAAC** library integration (Creative Commons BY-NC-SA)
- ✅ **PECS 6-phase** methodology support
- ✅ **WCAG 3.0** accessibility (perceivable, operable, understandable, robust)
- ✅ **Autism-specific design**:
  - Muted color palettes (no vivaci)
  - Large touch targets (44x44px min)
  - Sans-serif fonts adjustable
  - Minimal animations, NO auto-play

---

## Timeline

**Start**: 14 Gennaio 2026  
**Approccio**: **Qualità > Velocità** (Agent GEDI approved)

| Fase | Durata | Focus | Status |
|------|--------|-------|--------|
| **Fase 0** | 1 giorno | Research CAA standards | ✅ Completata |
| **Fase 1** | 3-4 sett | Database + Excel template + Backend API | 🔜 Aspettando input maestre |
| **Fase 2** | 3-4 sett | AI generation + Frontend accessibility | ⏳ Pianificata |
| **Fase 3** | 2-3 sett | Test reale con figlio utente + iterate | ⏳ Pianificata |
| **Fase 4** | Quando pronto | Build in Public + beta 100 famiglie | ⏳ Pianificata |

**Nessuna deadline rigida.** Agent GEDI ricorda: "1 donna fa figlio in 9 mesi, 9 donne non in 1 mese" 💙

---

## Integration ARGOS

CAA utilizza ARGOS per quality gates:

### Upload Validation
```sql
EXEC caa.sp_validate_routine_upload 
  @child_id INT,
  @excel_data NVARCHAR(MAX)
```sql

**Checks**:
1. Colonne required presenti (Momento, Attività, Emoji, Passi)
2. PECS phase appropriate per bambino
3. Sequenze comprensibili (2-5 step)
4. Emoji/ARASAAC IDs validi

**Return**: PASS/FAIL + suggestions JSON

---

## Use Case: Educatore Workflow

1. **Upload Routine**:
   - Educatore compila Excel template (standard)
   - Upload via web UI
   - ARGOS validation in real-time

2. **AI Board Generation**:
   - Claude genera board ottimizzata per bambino
   - Considera: età, PECS phase, preferenze colori/font
   - Fallback template-based se AI non disponibile

3. **Bambino Usage**:
   - Apre board su tablet (large icons, touch-friendly)
   - Tap su "Mattina" → sequenza passi con checkbox
   - Text-to-speech feedback audio
   - Progress tracking automatico

4. **Feedback Cycle**:
   - Educatore vede statistiche progressi
   - Iterate routine basato su uso reale
   - Export PDF schedine se needed

---

## Social Impact

### Target Users
- **Famiglie** con ragazzi autistici/DSA (tool GRATIS)
- **Scuole pubbliche** senza budget CAA (GRATIS)
- **Educatori/terapisti** che cercano tool personalizzabile

### Competitor Context

| Tool | Costo | Customizable | AI | Our Advantage |
|------|-------|--------------|-----|---------------|
| Tobii Dynavox | €5-8k | Limitato | ❌ | **GRATIS** |
| Proloquo2Go | €250 | iOS only | ❌ | **Cross-platform + AI** |
| Grid 3 | €1.5k | ✅ | ❌ | **GRATIS + AI** |
| **EasyCAA** | **GRATIS** | ✅ | ✅ | **Unique** |

**Gap di mercato**: Nessun tool combina GRATIS + ARASAAC + PECS + AI generation + Cloud/Local.

### Build in Public Strategy

**Non "comprate il prodotto"**, ma **"guardate come costruisco per mio figlio"**:

- Post 1: Perché costruisco EasyCAA (storia personale)
- Post 2: Research CAA standards (processo trasparente)
- Post 3: Test con mio figlio (risultati autentici)
- Post 4: 100 famiglie beta (quando è PERFETTO)

---

## Prossimi Step

1. ✅ **Research completata** → `docs/caa/CAA_RESEARCH_FINDINGS.md`
2. ⏳ **Aspettando input maestre** → routine tipo reale
3. ⏳ **Design schema DB** → basato su research
4. ⏳ **Implementazione Fase 1** → quando fondamenta chiare

**Niente rush. Con calma. Agent GEDI vigila.** 💙

---

## Related Links

- **Manifesto EasyWay**: [../../MANIFESTO.md](../../MANIFESTO.md)
- **Agent GEDI**: [../../agents/agent_gedi/manifest.json](../../agents/agent_gedi/manifest.json)
- **ARGOS Overview**: [../argos/argos-overview.md](../argos/argos-overview.md)
- **ARASAAC Official**: https://www.arasaac.org
- **ISAAC Italy**: https://www.isaacitaly.it

