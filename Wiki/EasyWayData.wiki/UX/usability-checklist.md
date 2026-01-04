---
id: ew-ux-usability-checklist
title: UX – Usability Checklist (One‑Button)
summary: Checklist rapida per validare semplicità ed efficacia delle schermate (3‑click rule, leggibilità, zero dead‑ends, CTA chiare, default sicuri).
status: active
owner: team-platform
tags: [ux, checklist, language/it]
llm:
  include: true
  pii: none
  chunk_hint: 200-300
  redaction: [email, phone]
entities: []
---

# UX – Usability Checklist (One‑Button)

Obiettivo
- Garantire che ogni schermata del diario sia semplice “come accendere la luce”: un’azione chiara, linguaggio semplice, nessun vicolo cieco.

Checklist (rapida)
- 3‑Click Rule: l’utente arriva alla dashboard in ≤ 3 azioni dal caricamento (MVP).
- CTA primaria evidente: un solo pulsante principale (es. “Continua”, “Apri Dashboard”).
- Zero dead‑ends: sempre presente un’azione per uscire/continuare (Retry, Scarica modello, Vedi dettagli).
- Linguaggio semplice: messaggi brevi, senza gergo tecnico, con “Cosa non va” e “Come risolvere”.
- Default sicuri: scelte precompilate non distruttive e reversibili.
- Consistenza: etichette e messaggi coerenti tra stati (copioni IT/EN).
- Accessibilità: contrasto, dimensione font minima, focus visibile, testi alternativi per immagini.
- Feedback immediato: spinner/progresso + conferme esplicite su azioni.
- Error budget UX: evitare troppi warning consecutivi (digestare e semplificare).
- Privacy: non mostrare PII non necessarie; sanificare anteprime.

Come usarla
- Applicare la checklist ad ogni PR che modifica UI/UX e allegare evidenze (screenshot/wireframe) nel diario.




