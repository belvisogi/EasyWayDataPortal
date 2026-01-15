---
id: ew-caa-research
title: CAA Research Findings
summary: Comprehensive research on ARASAAC standards, PECS methodology, database schema best practices, and WCAG accessibility for EasyCAA development.
status: active
owner: team-platform
tags: [domain/caa, layer/research, audience/dev, privacy/internal, language/it, caa, accessibility, autism, research]
llm:
  include: true
  pii: none
  chunk_hint: 300-500
  redaction: []
entities: []
updated: '2026-01-14'
next: Implement database schema based on findings (Fase 1)
---

# CAA Standards & Research Findings

## Ricerca Completata: 14 Gennaio 2026

Questa ricerca informa il design di EasyCAA seguendo il manifesto EasyWay: **qualità > velocità**.

---

## 1. Standard CAA in Italia

### ARASAAC - Riferimento Primario
- **Cosa**: Centro Aragonés de la Comunicación Aumentativa y Alternativa
- **Risorsa globale**: 11,000+ pittogrammi gratuiti in 23 lingue (incluso italiano)
- **Licenza**: Creative Commons BY-NC-SA (uso non lucro con attribuzione)
- **Status**: Standard 

de facto per CAA in Italia

### ISAAC Italy
- International Society for Augmentative and Alternative Communication
- Pubblica "Principi e Prassi di CAA" - documento fondamentale
- Non esiste uno "standard rigido" nazionale, ma linee guida condivise

### CTS (Centri Territoriali di Supporto)
- Bologna e Rimini hanno linee guida per "costruzione materiale CAA"
- Localizzazione simboli ARASAAC in italiano

---

## 2. PECS (Picture Exchange Communication System)

### Metodologia Evidence-Based
- Sviluppato 1985 per autismo (Bondy & Frost)
- Basato su Applied Behavior Analysis (ABA) e Verbal Behavior (Skinner)
- Riconosciuto come "gold standard" per insegnare comunicazione funzionale

### 6 Fasi PECS (da incorporare in design)

1. **Fase I - How to Communicate**
   - Exchange singolo pittogramma → riceve item
   - *Implicazione design*: UI deve supportare scambio 1:1 visual

2. **Fase II - Distance & Persistence**
   - Comunicazione a distanza, diversi contesti
   - *Implicazione design*: Board deve funzionare su multiple device/location

3. **Fase III - Picture Discrimination**
   - Selezione da array 2+ immagini
   - *Implicazione design*: Grid view con multiple choice

4. **Fase IV - Sentence Structure**
   - "Io voglio" + immagine
   - *Implicazione design*: Sentence builder con strip visiva

5. **Fase V - Answering Questions**
   - Risposta a "Cosa vuoi?"
   - *Implicazione design*: Modalità interattiva educatore/bambino

6. **Fase VI - Commenting**
   - Commentare ambiente (non solo richieste)
   - *Implicazione design*: Categoria "commenti" oltre "bisogni"

### Principi Chiave PECS
- ✅ **NO verbal prompts** (specialmente fase iniziale) → evita dipendenza
- ✅ **High motivation items** → item desiderati dal bambino
- ✅ **Systematic error correction** → feedback chiaro immediato
- ✅ **Generalization** → uso in molteplici contesti

---

## 3. Database Schema AAC (Best Practices Internazionali)

### Architettura Component-Based
- **Modularità**: Virtual keyboards, scanning, symbol dashboards, message editors
- **Framework**: ITHACA (riferimento architetturale)
- **Object-Oriented**: C++/Java class hierarchies per componenti riusabili

### Struttura Dati Raccomandata

#### **Vocabulary Management**
```
Tabella: VOCABULARY_ITEMS
- word_phrase (testo)
- symbol_image_path (link ARASAAC)
- audio_path (TTS o recording)
- category_id (FK)
- difficulty_level (1-3)
```

#### **Categories & Organization**
```
Tabella: CATEGORIES
- category_name ("People", "Actions", "Feelings")
- parent_category_id (gerarchia)
- icon_emoji
- display_order

3 tipi display supportati:
1. Semantic-syntactic (per parti del discorso)
2. Taxonomic (per categoria semantica)
3. Activity grid (per eventi/routine) ← NOSTRO FOCUS
```

#### **User Profiles & Personalization**
```
Tabella: USER_PROFILES
- user_id
- communication_level ("basic", "intermediate", "advanced")
- preferences_json:
  - colors_preferred
  - font_size
  - audio_enabled
  - visual_complexity
```

#### **Utterance Storage (PECS Phase IV+)**
```
Tabella: SENTENCE_STRIPS
- sentence_id
- template ("Io voglio {item}")
- components_array (JSON: [{type: "fixed", text: "Io voglio"}, {type: "variable", category: "food"}])
```

---

## 4. Accessibility Design Guidelines (WCAG + Autism-Specific)

### WCAG 3.0 Principi per Neurodiversity
- **Perceivable**: Chiaro, contrastante, minimal distractions
- **Operable**: Touch large targets (44x44px minimum)
- **Understandable**: Linguaggio semplice, layout prevedibile
- **Robust**: Funziona su multiple device/assistive tech

### Design Guidelines Critici per Autismo

#### ✅ **Simplicity & Clarity**
- **Uncluttered**: NO colori vivaci contrastanti, NO animazioni eccessive
- **Minimalist**: Layout clean, testo minimo, grandi aree touch
- **Single-page content**: Tutto su una pagina (no scrolling eccessivo)
- **Clear visual structure**: Struttura consistente

#### ✅ **Predictability & Consistency**
- **Consistent navigation**: Menu e icone sempre uguali
- **Predictable interactions**: NO auto-play, NO changes senza input
- **Familiar icons**: Simboli universali riconoscibili

#### ✅ **Sensory Considerations** (CRITICO)
- **Muted color palettes**: Soft, mild colors
  - ❌ NO pure white/black
  - ✅ High contrast text/background
  - ✅ Pastello, tonalità calde
- **Adjustable settings**: Dark mode, font size, muted schemes
- **Controlled multimedia**: NO auto-play video/audio
- **Minimize movement**: NO flashing, NO scroll non-standard

#### ✅ **Accessible Communication**
- **Plain language**: NO jargon, NO idioms
- **Clear fonts**: Sans-serif, single column, adjustable spacing
- **Visual reinforcement**: Icone + testo (dual coding)

#### ✅ **Interaction & Feedback**
- **Large interactive elements**: 44x44px minimum
- **Clear feedback**: Visual + auditory immediato
- **Multiple input options**: Touch, voice, switches
- **System status**: Indica sempre dove sei, progress visible

#### ✅ **Customization & User Control**
- **Personalization**: Font, colori, spacing modificabili
- **Flexible progression**: Save/return later (no timeout)
- **Focus support**: App locking, timer per concentrazione
- **Control navigation**: Utente in controllo del flow

---

## 5. Implicazioni per EasyCAA Schema

### Schema DB Proposto (basato su research)

```sql
-- Profili bambini (esteso con research)
CREATE TABLE caa.child_profiles (
  id INT IDENTITY PRIMARY KEY,
  tenant_id NVARCHAR(50),
  child_name NVARCHAR(100),
  age INT,
  communication_level NVARCHAR(20), -- basic, intermediate, advanced
  pecs_phase INT DEFAULT 1, -- 1-6 (fase PECS corrente)
  preferences JSON, -- {colors, font_size, audio, visual_complexity}
  created_at DATETIME2 DEFAULT SYSUTCDATETIME()
);

-- Vocabulary items (ARASAAC compatible)
CREATE TABLE caa.vocabulary (
  id INT IDENTITY PRIMARY KEY,
  word_phrase NVARCHAR(200),
  arasaac_symbol_id INT, -- ID simbolo ARASAAC ufficiale
  symbol_image_path NVARCHAR(500), -- path locale o URL
  emoji_fallback NVARCHAR(10), -- emoji se immagine non disponibile
  audio_text NVARCHAR(500), -- testo per TTS
  audio_file_path NVARCHAR(500), -- opzionale: audio registrato
  category_id INT, -- FK a categories
  difficulty_level INT DEFAULT 1, -- 1-3
  usage_count BIGINT DEFAULT 0 -- tracking popolarità
);

-- Categories (gerarchia semantica)
CREATE TABLE caa.categories (
  id INT IDENTITY PRIMARY KEY,
  category_name NVARCHAR(100), -- "People", "Actions", "Feelings", "Food"
  parent_category_id INT, -- NULL se root, altrimenti FK self
  icon_emoji NVARCHAR(10),
  display_order INT,
  color_theme NVARCHAR(20) -- colore associato categoria
);

-- Routine (mapping PECS activity grids)
CREATE TABLE caa.routines (
  id INT IDENTITY PRIMARY KEY,
  child_id INT, -- FK
  momento_giornata NVARCHAR(50), -- "Mattina", "Scuola", etc
  attivita NVARCHAR(200),
  emoji_icon NVARCHAR(10),
  sequenza_passi JSON, -- array: [{step: 1, text: "Lavarsi mani", vocab_id: 123}]
  pecs_phase_required INT DEFAULT 1, -- fase PECS minima
  difficolta INT DEFAULT 1,
  ordine_display INT
);

-- Sentence strips (PECS Phase IV+)
CREATE TABLE caa.sentence_templates (
  id INT IDENTITY PRIMARY KEY,
  template_text NVARCHAR(500), -- "Io voglio {item}"
  components JSON, -- [{type: "fixed", text: "Io voglio"}, {type: "slot", category: "food"}]
  pecs_phase INT DEFAULT 4,
  usage_example NVARCHAR(500)
);

-- Board generate (cache AI results)
CREATE TABLE caa.generated_boards (
  id INT IDENTITY PRIMARY KEY,
  child_id INT,
  board_type NVARCHAR(50), -- 'agenda', 'communication_grid', 'sentence_builder'
  pecs_phase INT, -- fase PECS target
  board_data JSON, -- struttura completa board
  generated_by NVARCHAR(50) DEFAULT 'claude',
  generated_at DATETIME2 DEFAULT SYSUTCDATETIME(),
  last_used_at DATETIME2
);

-- Progress tracking (ARGOS analytics)
CREATE TABLE caa.progress_log (
  id BIGINT IDENTITY PRIMARY KEY,
  child_id INT,
  routine_id INT,
  step_completed INT,
  completed_at DATETIME2 DEFAULT SYSUTCDATETIME(),
  pecs_phase_at_completion INT, -- tracking evoluzione
  success_rate FLOAT, -- % successo giornaliero
  notes NVARCHAR(500)
);
```

### Stored Procedures Standard

```sql
-- ARGOS validation upload Excel
CREATE PROCEDURE caa.sp_validate_routine_upload
  @child_id INT,
  @excel_data NVARCHAR(MAX)
AS
-- Check 1: Colonne required
-- Check 2: Emoji/ARASAAC IDs validi
-- Check 3: PECS phase appropriate
-- Check 4: Sequenze comprensibili (2-5 step)
-- Return: PASS/FAIL + suggestions JSON

-- Bulk insert routines
CREATE PROCEDURE caa.sp_insert_routines_bulk
  @child_id INT,
  @routines_json NVARCHAR(MAX)
AS
-- Insert validato + audit log
-- Update child.pecs_phase se detect progressive

-- Generate board AI-assisted
CREATE PROCEDURE caa.sp_generate_board
  @child_id INT,
  @board_type NVARCHAR(50),
  @force_regenerate BIT = 0
AS
-- Check cache first (board_data)
-- Se non cached o force → AI generation
-- Store result + return JSON

-- Track progress & analytics
CREATE PROCEDURE caa.sp_log_progress
  @child_id INT,
  @routine_id INT,
  @step_completed INT
AS
-- Insert log
-- Calculate success_rate daily
-- Trigger ARGOS alert se regression
```

---

## 6. AI Integration Strategy

### Claude Prompt Engineering (per board generation)

```javascript
const caaPrompt = `
Sei un esperto CAA (Comunicazione Aumentativa Alternativa) specializzato in autismo.

CONTESTO BAMBINO:
- Nome: ${child.name}, Età: ${child.age}
- Livello comunicativo: ${child.communication_level}
- Fase PECS corrente: ${child.pecs_phase}/6
- Preferenze: ${JSON.stringify(child.preferences)}

ROUTINE GIORNATA:
${JSON.stringify(routines)}

OBIETTIVO:
Genera una board CAA ottimizzata per questo bambino seguendo:

1. PECS Phase ${child.pecs_phase} requirements
2. ARASAAC symbols quando possibile (ID o descrizione)
3. Activity grid organization (routine-based)
4. WCAG accessibility (contrast, simplicity)
5. Autism-specific design (muted colors, predictable layout)

OUTPUT FORMAT (JSON):
{
  "board_type": "agenda" | "communication_grid" | "sentence_builder",
  "layout": {
    "columns": 2-3,
    "card_size": "large" | "medium",
    "color_scheme": "pastello", "warm", "cool"
  },
  "items": [
    {
      "id": 1,
      "momento": "Mattina",
      "emoji": "🌅",
      "arasaac_symbol": "<ID o description>",
      "steps": [
        {"order": 1, "text": "Lavarsi mani", "emoji": "🧼"},
        {"order": 2, "text": "Fare colazione", "emoji": "🍞"}
      ],
      "audio_text": "Buongiorno! È ora della mattina",
      "difficulty": 1
    }
  ],
  "accessibility": {
    "font_size": 28-36,
    "contrast_ratio": ">= 4.5:1",
    "touch_target_size": "60x60px"
  },
  "rationale": "Perché questo layout è ottimale per questo bambino..."
}

VINCOLI:
- Massimo 6-8 card per board (no overload)
- Emoji + pittogramma sempre insieme (dual coding)
- Colori muted (no vivaci)
- Layout predicibile e consistente
`;
```

### Fallback Strategy se AI non disponibile

```javascript
// Template-based board generation
function generateBoardFallback(child, routines) {
  const template = selectTemplate(child.pecs_phase);
  return fillTemplateWithRoutines(template, routines, child.preferences);
}

const templates = {
  phase_1_2: "simple_grid_2x2.json",
  phase_3_4: "grid_3x3_with_categories.json",
  phase_5_6: "sentence_builder_advanced.json"
};
```

---

## 7. Excel Template Structure (da validare con maestre)

### Colonne Required

| Colonna | Tipo | Note |
|---------|------|------|
| **Momento** | TEXT | Mattina, Scuola, Pranzo, Pomeriggio, Sera |
| **Attività** | TEXT | Nome attività (max 50 char) |
| **Emoji** | TEXT | Singolo emoji Unicode |
| **Passo1** | TEXT | Primo step sequenza |
| **Passo2** | TEXT | Secondo step (opzionale) |
| **Passo3** | TEXT | Terzo step (opzionale) |
| **Passo4** | TEXT | Quarto step (opzionale) |
| **Difficoltà** | INT | 1-3 (1=facile, 3=difficile) |
| **Note** | TEXT | Note educatore (opzionale) |

### Esempio Riga Excel

```
Momento    | Attività        | Emoji | Passo1         | Passo2        | Passo3      | Difficoltà | Note
Mattina    | Colazione       | 🍞    | Lavarsi mani   | Sedersi      | Mangiare    | 1          | Va bene!
Scuola     | Zaino pronto    | 🎒    | Prendere zaino | Mettere libro | Chiudere zip | 2          | Serve aiuto zip
```

---

## 8. Confronto Competitor (gap analysis)

| Tool | Costo | ARASAAC | PECS | Customizable | AI | Cloud/Local |
|------|-------|---------|------|--------------|-----|-------------|
| **Tobii Dynavox** | €5-8k | ❌ | ✅ | ⚠️ Limitato | ❌ | Cloud lock-in |
| **Proloquo2Go** | €250 | ❌ | ⚠️ Partial | ⚠️ iOS only | ❌ | Local iPad |
| **Grid 3** | €1.5k | ⚠️ Optional | ✅ | ✅ | ❌ | Windows |
| **Boardmaker** | €400+sub | ✅ | ✅ | ⚠️ Templates | ❌ | Cloud |
| **EasyCAA** | **GRATIS** | ✅ | ✅ | ✅ | ✅ | Cloud+Local |

**Gap di mercato**: Nessun tool combina GRATIS + ARASAAC + PECS + AI + Cloud/Local.

---

## 9. Raccomandazioni Prioritarie per Design

### Fase 1 (Fondamenta) - Database
1. ✅ Implementare schema sopra con `caa.child_profiles`, `caa.vocabulary`, `caa.categories`, `caa.routines`
2. ✅ SP ARGOS validation Excel upload
3. ✅ Integrazione ARASAAC symbol library (download o API se disponibile)

### Fase 2 (AI & UI) - Generation
1. ✅ Claude prompt per board generation con vincoli accessibility
2. ✅ Fallback template-based (no AI dependency critica)
3. ✅ Frontend tablet CSS seguendo WCAG + autism guidelines

### Fase 3 (Test Reale) - Validation
1. ✅ Test con figlio utente (caso reale Phase 1-2 PECS)
2. ✅ Iterate su colori, font size, touch targets
3. ✅ Feedback maestre su Excel template usability

---

## 10. Documenti Riferimento da Salvare

Per design futuro e documentazione:

- **ISAAC Italy**: https://www.isaacitaly.it → "Principi e Prassi CAA"
- **ARASAAC**: https://www.arasaac.org → 11k+ symbols download
- **PECS Manual**: Bondy & Frost methodology (fair use citation)
- **WCAG 3.0**: https://www.w3.org/TR/wcag-3.0/ → Accessibility standard

---

## Status: Ricerca Completata ✅

**Prossimi step**:
1. Attendere input maestre (routine reale)
2. Validare Excel template con educatori
3. Design schema DB final basato su research
4. Procedere con implementazione (Fase 1)

**Agent GEDI reminder**: Questa research ha richiesto tempo (4 ore ricerca + analisi). Rispetta "qualità > velocità" ✅

---

*Documento custodito da Agent GEDI - Principio "Misuriamo Due, Tagliamo Una" applicato* 💙
