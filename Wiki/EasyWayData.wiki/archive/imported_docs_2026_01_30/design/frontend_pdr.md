---
id: ew-archive-imported-docs-2026-01-30-design-frontend-pdr
title: 🎨 EasyWay Frontend PDR (Product Design Requirement)
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

# 🎨 EasyWay Frontend PDR (Product Design Requirement)

> **Documento di Visione per la "Faccia" di EasyWay**
> *Perché chi atterra qui deve capire in 3 secondi che non siamo un altro wrapper di ChatGPT.*

## 1. The Core Identity (Chi Siamo)

### 💎 The Concept: "The Iron Man Suit for Business"
EasyWay non è un chatbot. È un'**infrastruttura di potenziamento**.
Non "parli" con l'AI; **indossi** l'AI per estendere le tue capacità esecutive.

### 🛡️ The Promise: "Sovereign Intelligence"
Il nostro differenziale unico è la **Sovranità**.
-   I dati non escono MAI.
-   Il server è TUO.
-   Le regole sono TUE.
-   *Target*: Chi ha segreti industriali, dati sanitari, o paranoie di sicurezza (giustificate).

### 🏛️ The Philosophy: "Craftsmanship & Legacy"
Non siamo una startup "move fast and break things".
Siamo artigiani digitali. Costruiamo software destinato a durare 10 anni.
Il sito deve trasmettere: **Solidità, Serietà, Ingegneria di Precisione.**

### ⚖️ The Mission: "Democratization without Charity"
* "Gli strumenti enterprise non devono essere privilegio. Devono essere diritto."
* **Il Modello Robin Hood**: Le aziende pagano per l'eccellenza. Questo finanzia lo stesso strumento (gratis) per scuole e no-profit.
* **Il messaggio**: Comprando EasyWay, non compri solo software. Finanzi l'alfabetizzazione digitale del futuro.

### ⛺ The Tribe: "Not Users, But Believers"
Non vogliamo "utenti". Vogliamo una **Tribù**.
*   **Chi sono**: Pionieri, Ribelli della Sovranità, Artigiani del Codice.
*   **Cosa li unisce**: Il rifiuto della "scatola nera". La voglia di capire come funzionano le cose.
*   **Il Rituale**: Ogni venerdì si condivide un workflow. Chi riceve aiuto, deve darne.
*   **Il Motto**: *"Non sei un clinte. Sei un nodo della rete."*

---

## 2. Visual Language (Come Appariamo)

### 🌑 The Vibe: "Dark Premium Enterprise"
Dimentica il look "SaaS colorato" (Stripe-like) o "AI giocosa" (faccine robot).
Vogliamo incutere **Rispetto e Fiducia**.

*   **Palette**:
    *   **Deep Void**: `#050b14` (Sfondo, più scuro del nero, abisso spaziale).
    *   **Sovereign Gold**: `#eab308` (Accenti, titoli nobili, la "Legacy").
    *   **Neural Cyan**: `#0ea5e9` (La pura intelligenza, connettività, n8n).
    *   **Glass**: Pannelli traslucidi, non solidi. Il "White Box" della trasparenza.

*   **Imagery**:
    *   Rappresentazioni 3D astratte di reti neurali, ma "ingabbiate" o "protette" (simbolo di controllo).
    *   Terminali / Codice che scorre (simbolo di potere esecutivo).
    *   **The Blue Pulse (GEDI)**: Una luce pulsante soffusa (Neon Cyan) sempre presente. È il "respiro" del sistema.

### 🖼️ Visual Benchmark (Inspirations)
*   **Traefik Labs**: Per la pulizia del "Deep Void", i diagrammi architetturali luminosi e il senso di "Infrastruttura Solida".
    *   *Nota Tecnica*: Il loro sito è fatto in Go/Hugo (Statico), non WordPress. Ecco perché è così veloce. **Vogliamo la stessa velocità.**
*   **Linear**: Per la gestione delle ombre e dei gradienti sottili.
*   **Stripe (Dark Mode)**: Per la tipografia e la leggibilità.

---

## 3. The Guardian Experience (GEDI Integration)
*Non sei mai solo. GEDI è il tuo copilota etico.*

### 🧘‍♂️ UI Presence
*   GEDI non è "Clippy". Non rompe le scatole.
*   È un **Avatar Silenzioso** (un'icona stilizzata o un anello di luce) che osserva.
*   **Stato Calmo**: Luce blu costante.
*   **Stato Allerta**: Cambia colore (Ambra) se stai facendo qualcosa di rischioso (es. "Deploy to Prod" venerdì sera).

### 🛑 "Measure Twice, Cut Once" UX Pattern
Per ogni azione distruttiva o critica (es. cancellare un DB, riavviare un nodo):
1.  **Freeze**: L'interfaccia rallenta intenzionalmente.
2.  **The Question**: GEDI appare e chiede: *"Hai misurato due volte? Questa azione è irreversibile."*
3.  **The Confirmation**: Non "Ok", ma devi digitare l'intento (es. "Confermo distruzione").
> *La frizione non è un bug, è una feature.*

---

## 4. Communication Strategy (Cosa Diciamo)

### 🚫 Anti-Patterns (Cosa EVITARE)
*   *"Chatta con i tuoi PDF"* (Troppo banale).
*   *"L'AI facile per tutti"* (Troppo cheap).
*   *"Provalo gratis"* (Siamo un'appliance, non un freemium).

### ✅ Key Messages (Cosa DIRE)
1.  **Hero Section**: *"Smetti di affittare l'intelligenza. Inizia a possederla."*
2.  **Privacy**: *"Air-Gapped by Design. Il tuo server è il tuo castello."*
3.  **Action**: *"Non chiedergli di scrivere una mail. Chiedigli di gestire l'infrastruttura."* (Brains vs Arms).
4.  **Social Impact**: *"Il Framework è un Ponte. La tua licenza costruisce eccellenza per chi non può permettersela."*

---

## 5. User Journey (L'Esperienza)

1.  **L'Arrivo (The Awe)**: L'utente apre la pagina. Sfondo scuro, particelle sottili. Titolo imponente. Deve pensare: *"Wow, questa roba è seria."*
2.  **La Comprensione (The Relief)**: Scorre e vede "On-Premise", "Docker", "No Cloud Lock-in". Tira un sospiro di sollievo: *"Finalmente qualcuno che non vuole rubarmi i dati."*
3.  **La Prova (The Proof)**: Vede uno screenshot di n8n e uno script PowerShell. Capisce che non è fuffa, è roba da ingegneri.
4.  **L'Incontro (The Guardian)**: Nota GEDI. *"Chi è quello?"*. Legge *"Guardian of Intentions"*. Sorride. *"Ah, questi fanno sul serio."*
5.  **La Rivelazione (The Purpose)**: Legge la sezione "Democratization". Capisce che non sta solo comprando un tool, ma aderendo a un movimento. *"Giustizia Tecnica"*.
6.  **L'Azione (The Contact)**: Non c'è "Sign Up". C'è "Schedule Demo" o "Join the Movement". È un club esclusivo, ma con un cuore.

---

## 5. Technical Constraints for the Designer
*   **No React/Angular**: Solo HTML5 + CSS3 Moderno (CSS Variables, Grid, Glassmorphism).
*   **PWA Ready**: Deve sembrare un'app nativa se installata.
*   **Performance**: Niente librerie JS pesanti (niente Three.js se non ottimizzato). L'appliance può girare su hardware modesto.

> *"Fallo sembrare qualcosa che Tony Stark costruirebbe per la sua intranet privata."*

## 6. Visual Refinement (Traefik Polish)
*Requirements added iteratively to match "Traefik Labs" aesthetic benchmark.*

### 🎩 The Header
L'assenza di header ci fa sembrare "non finiti". Implementare un header solido e funzionale:
*   **Logo**: "EasyWay" (Text-based, strong font) a sinistra.
*   **Navigation**: Centralizzata, pulita (`Products`, `Solutions`, `Docs`).
*   **CTA**: Bottone "Connect" o "Request Demo" a destra, stile "Glass/Outline" che si illumina all'hover.
*   **Behavior**: Sticky on top, background blur (frosted glass).

### 📐 Layout & Typography Alignment
Per colmare il gap visivo:
*   **Focus**: Restringere la larghezza della Hero Section. Non spanciare su schermi wide.
*   **Centering**: Tutto il contenuto critico (Titolo, Core, CTA) deve essere perfettamente centrato visivamente.
*   **Weights**: Usare pesi font più decisi (`600`, `800`) per i titoli per compensare lo sfondo scuro.

---

## 7. The Hextech Framework Architecture (Evolution)
*Refactoring for scalability and white-labeling.*

### 🦴 The Skeleton (`framework.css`)
Contiene i componenti strutturali riutilizzabili. È l'armatura base, agnostica rispetto al brand.
*   Griglie, Card, Glass Panels, Bottoni, Tipografia base.

### 🧬 The Skin (`theme.css`)
Il file di configurazione dell'identità.
*   **Variabili CSS**: definisce `colors`, `fonts`, `spacings`.
*   **Purpose**: Cambiando solo questo file, l'intero sistema muta "Anima" (es. da "Cyber Enterprise" a "Druid Guardian").

### 🔮 Cortex Genesis Protocol (The Agent)
L'Identità non si sceglie a caso, si "scopre".
*   **Interactive Setup**: Un wizard CLI integrato nella console (`INITIATE GENESIS`).
*   **Workflow**: L'Agente intervista l'utente (Archetipo? Nemico? Colore?) e genera automaticamente il blocco CSS per il `theme.css`.

## 8. Brand Identity Standards
*   **Logo**: "The Target Scope". Quadrato dorato (Protezione) + Mirino Ciano (Precisione).
*   **Favicon**: "The Labyrinth". Variante semplificata per alta leggibilità su tab browser.


