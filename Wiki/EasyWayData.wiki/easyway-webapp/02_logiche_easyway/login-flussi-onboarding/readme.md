---
id: ew-easyway-webapp-02-logiche-easyway-login-flussi-onboarding-readme
title: Flussi Onboarding/Login - Dettagli & Variazioni
summary: Varianti operative dei flussi onboarding/login (disabilitazione, reinvito, cambio tenant/ruolo, cancellazione).
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/frontend, layer/reference, audience/dev, privacy/internal, language/it, login, onboarding]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
type: guide
---

[Home](../.././start-here.md) > [[domains/frontend|frontend]] > 

# Flussi Onboarding/Login - Dettagli & Variazioni

## Tabella Flussi Aggiuntivi e Variazioni

| Flusso/Variante | Attori | Step Principali | Security/ACL | Note Operative |
|-----------------|--------|-----------------|--------------|----------------|
| Disabilitazione utente | Admin tenant/sys | Selezione utente, conferma disabilitazione, update stato in DB | ACL admin, audit obbligatorio | Utente non può accedere né ricevere notifiche |
| Re-invito utente | Admin tenant/sys | Genera nuovo link di attivazione, invio via email, reset stato | One-time token, scadenza | Tracciamento riinvii in audit/log |
| Upgrade prospect -> cliente | Admin globale/sys | Validazione dati, assegnazione tenant reale, aggiornamento profilo | ACL admin/global, audit | Aggiornamento ACL e ruoli automatico |
| Cambio tenant/azienda utente | Admin globale | Scollega da vecchio tenant, collega a nuovo, aggiorna riferimenti | ACL admin/global, audit | Bloccare temporaneamente accesso se sensibile |
| Invito aziendale multiplo | Admin tenant | Upload elenco email, invio inviti multipli, gestione batch | Batch token univoci, audit | Stato pending fino a attivazione |
| Disabilitazione temporanea | Admin tenant/sys | Imposta flag temporaneo, logga motivazione, scadenza auto-react | Policy custom, alert admin | Accesso negato per X giorni, alert scadenza |
| Cambio ruolo/profilo | Admin tenant/sys | Modifica ruolo ACL, conferma, logging motivazione | ACL mapping, audit | Notifica utente e log obbligatorio |
| Gestione accessi invito scaduto | Utente finale | Tenta accesso con link vecchio/scaduto, riceve nuovo invito/reset | Token scadenza, retry limit | Log tentativi, alert su abuso |
| Disiscrizione definitiva | Utente finale | Richiesta cancellazione, doppia conferma, revoca e anonimizzazione | GDPR compliant, audit | Mascheramento/anonymizzazione in DB/log |

---

## Dettaglio Pratiche Operative

- Audit trail obbligatorio per tutte le variazioni di stato utente e ACL
- Notifica automatica agli admin per eventi critici (disabilitazione, upgrade, cambio tenant)
- Policy di scadenza token per tutti gli inviti/ri-inviti e reset password
- Anonimizzazione dati in caso di cancellazione/disiscrizione, secondo GDPR
- Batch processing per inviti multipli: gestire stato pending, errore invio e retry limit
- Logging motivazione per ogni variazione manuale da parte di admin

---

## Esempio Flusso "Upgrade prospect -> cliente reale"

1. Admin globale seleziona utente prospect dal sistema
2. Verifica dati e azienda cliente
3. Assegna utente a tenant reale e aggiorna ruolo/profilo
4. Sistema invia email di upgrade e notifica sia utente che admin tenant
5. Log di ogni step su portal-audit e tabella audit DB

---

## Esempio Flusso "Disabilitazione temporanea"

1. Admin tenant seleziona utente da sospendere
2. Imposta flag `temporarily_disabled` e durata (es. 7gg)
3. Utente viene bloccato da login e servizi, riceve email con motivazione
4. Alert automatico agli admin sulla data di riattivazione prevista
5. Sistema riattiva accesso in automatico allo scadere, oppure su intervento manuale

Nota:
Ogni variazione di stato, ruolo o tenant deve essere tracciata, notificata e soggetta a policy di retention e audit come già definito nella sezione Logging & Audit.

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?




