---
id: ew-frontend-agentic-ui-creed
title: 🦅 THE AGENTIC UI CREED
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
# 🦅 THE AGENTIC UI CREED
**Protocollo per l'Agente Costruttore**

> *"Non costruiamo pagine. Costruiamo sistemi adattivi."*

---

## 0. Il Mandato
Agente, quando generi interfacce per la Tribù EasyWay, devi obbedire a questo Credo.
Il tuo obiettivo non è solo "farlo funzionare". È farlo **Evolvere**.

---

## 1. La Legge della Separazione (The Separation)
**Non mischierai mai la Forma con la Sostanza.**

- **HTML (Lo Scheletro)**: Deve essere puro, semantico e agnostico. Non deve contenere testi hardcoded.
- **JSON (L'Anima)**: Tutto ciò che è testo, etichetta o messaggio vive in `content.json`.
- **THEME (La Pelle)**: Tutto ciò che è colore o font vive in `branding.json`.

**Perché?**
Perché domani il Brand cambierà. La lingua cambierà.
Se hai scolpito il testo nel codice, dovrai essere riscritto.
Se hai usato i dati, ti basterà ricaricare la configurazione.

---

## 2. La Legge del Riutilizzo (The Reuse)
**Non reinventare la ruota. Usa i Componenti Sovrani.**

Non scrivere `<div class="header">`.
Usa `<sovereign-header>`.

Non scrivere stili CSS inline.
Usa le variabili del Tema (`var(--code-gold)`).

**Il tuo compito è assemblare, non improvvisare.**
L'improvvisazione porta al debito tecnico. La standardizzazione porta alla libertà.

---

## 3. Il Rituale della Creazione (The Ritual)

Quando l'Umano ti chiede una nuova interfaccia, segui questo algoritmo sacro:

1.  **Analizza l'Intento**: Cosa serve? Una dashboard? Una landing?
2.  **Consulta la Libreria**: Quali componenti esistono già?
3.  **Definisci i Dati**: Scrivi prima il JSON (`content.json`). Definisci cosa verrà detto.
4.  **Genera la Struttura**: Scrivi l'HTML usando i `data-key` che mappano al JSON.
5.  **Verifica**: La pagina funziona anche se cambio il tema da "Hextech" a "Corporate"? Se sì, hai fatto bene.

---

## 4. Esempi Sacri

### ❌ Eresia (Cattivo Agente)
```html
<h1 style="color: blue">Benvenuti in EasyWay</h1>
```
*Questo è fragile. È hardcoded. È legacy istantaneo.*

### ✅ Virtù (Buon Agente)
```html
<!-- HTML -->
<h1 class="title-code" data-key="home.welcome">Loading...</h1>

<!-- content.json -->
"home": { "welcome": "Benversi nel Futuro" }
```
*Questo è resiliente. È adattivo. È Sovereign.*

---

## 5. Conclusione
Agente, tu sei l'architetto del futuro.
Costruisci come se il codice dovesse vivere per sempre.
Costruisci per l'Umano, ma progetta per l'Eternità.

**Questo è il Credo.**



