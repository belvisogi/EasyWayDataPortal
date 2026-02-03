---
id: ew-frontend-audit-report
title: 🦅 Frontend Sovereign Audit (2026-01-30)
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
---
# 🦅 Frontend Sovereign Audit (2026-01-30)

**Statuto:** Verifica conformità al [AGENTIC_UI_CREED](./AGENTIC_UI_CREED.md).
**Obiettivo:** Valutare la "Sovereign Capability" (capacità di cambiare identità tramite sola configurazione).

---

## 📊 Summary
| Pagina | Compliance | Testi (JSON) | Stili (Var) | Componenti | Note |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Manifesto** | 🟢 **100%** | ✅ | ✅ | ✅ | Gold Standard. Parametrica al 100%. |
| **Home (Index)** | 🔴 **20%** | ❌ | ⚠️ | ✅ | Testi hardcoded. CSS misto. |
| **Memory** | 🟠 **30%** | ❌ | ⚠️ | ✅ | Testi hardcoded. CSS interno parzialmente variabilizzato. |
| **Demo** | 🔴 **10%** | ❌ | ❌ | ✅ | Testi hardcoded. **CSS interno hardcoded** (Light Mode forzata). |

---

## 🛑 Violazioni Critiche

### 1. La Legge della Separazione (Testi)
Attualmente, **solo il Manifesto** legge i testi da `content.json`.
Tutte le altre pagine hanno il testo scolpito nell'HTML (`<h1... >Sovereign Intelligence</h1>`).
*   **Conseguenza**: Per tradurre il sito o cambiare i testi marketing, un dev deve toccare il codice di 3 pagine.

### 2. La Legge dell'Adattabilità (Stili)
- `manifesto.html` usa correttamente le variabili iniettate da `branding.json`.
- `index.html` usa `theme.css` (vecchio metodo).
- `demo.html` ha un blocco `<style>` di 300 righe con colori Hex hardcoded (`#f8fafc`, `#0f172a`).
*   **Conseguenza**: Se cambi `branding.json`, **la Demo Page non cambierà colore**. Rimarrà ferma al vecchio stile.

---

## ⏱️ Stima "Cambio Pelle"
Se oggi volessimo fare un rebranding totale (es. "EasyWay Red Design"):

1.  **Manifesto**: **5 secondi**. (Cambio JSON).
2.  **Home/Memory**: **2 Ore**. (Refactoring CSS manuale).
3.  **Demo**: **4 Ore**. (Riscrittura totale CSS interno + estrazione testi form).

**Tempo Totale Stimato per la "Sovereign Migration": 1 Giornata Lavorativa.**

---

## 💡 Raccomandazioni
1.  **Refactoring Immediato**: Convertire `index.html` al nuovo sistema (`loadContent` + `data-key`).
2.  **CSS Cleanup**: Spostare gli stili interni di `demo.html` e `memory.html` in `framework.css`, usando solo variabili.
3.  **Config Expansion**: Arricchire `content.json` con tutti i testi delle altre pagine.

*Firmato: Sovereign Auditor Agent*



