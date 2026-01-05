---
id: ew-notifiche
title: Notifiche - Gestione
summary: Notifiche multi-tenant (tipi, preferenze, flusso invio, best practice, logging/audit).
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, notifications]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---

# Gestione Notifiche - EasyWay Data Portal

## Lookup - Gestione Notifiche

| Cosa vuoi | Cosa devi scrivere | Dammi il .md | Stato |
|-----------|--------------------|--------------|-------|
| Tabella tipologia notifiche | Dammi tabella notifiche | Dammi il .md tabella notifiche | IN BOZZA |
| Gestione preferenze notifica utente | Dammi preferenze notifiche utente | Dammi il .md preferenze notifiche utente | IN BOZZA |
| Flusso invio notifiche (step by step) | Dammi flusso invio notifiche | Dammi il .md flusso invio notifiche | IN BOZZA |
| Best practice notifiche multi-tenant | Dammi best practice notifiche | Dammi il .md best practice notifiche | IN BOZZA |
| Logging/audit notifiche | Dammi logging notifiche | Dammi il .md logging notifiche | IN BOZZA |

## Tabella Tipologia Notifiche

| Tipo Notifica | Scopo/Trigger | Canale | Configurabile da utente | Note Operative |
|---------------|--------------|--------|--------------------------|----------------|
| Onboarding/Welcome | Primo accesso, registrazione completata | Email | No | Obbligatoria, template standard |
| Cambio password/MFA | Reset credenziali, abilitazione MFA | Email, SMS | No | Alert immediato, link one-time |
| Alert sicurezza | Accesso anomalo, tentativi falliti | Email, Teams | No | Alert ad admin e utente, logging obbl. |
| Notifiche sistema | Errori ETL, esito batch, job completato | Email, Teams | Sì | Configurabile da profilo/ruolo |
| Notifiche billing | Scadenza servizio, fattura disponibile | Email | Sì | Solo owner/admin tenant |
| Reminder scadenze | Token/API in scadenza, task da completare | Email | Sì | Alert automatico, scheduling |
| Notifiche personalizzate | Eventi business, comunicazioni custom | Email, Teams | Sì | Gestite da admin tenant/prodotto |

---

## Gestione Preferenze Notifica Utente

- Ogni utente può configurare su quali canali ricevere le notifiche (email, Teams, solo dashboard, ecc.) e quali categorie attivare/disattivare.
- Le preferenze sono salvate su tabella `user_notification_settings` (schema PORTAL).
- Notifiche obbligatorie (onboarding, alert sicurezza) non sono disattivabili.
- Modifica preferenze tracciata in audit log (timestamp, chi ha modificato, vecchio e nuovo stato).
- Template multilingua e personalizzabili (per tenant/ruolo).

---

## Flusso Invio Notifiche (step-by-step)

1. Microservizio/interfaccia rileva evento che richiede notifica (es: job ETL fallito, nuovo login)
2. Recupera preferenze notifica utente/tenant (canale, categoria)
3. Costruisce messaggio usando template predefinito (con merge dati dinamici)
4. Invia tramite canale selezionato (SMTP, Teams webhook, SMS gateway)
5. Logga evento di invio (stato: consegnato, errore, retry)
6. Se fallisce, tenta retry secondo policy e allerta admin se errore persistente

---

## Best Practice Notifiche Multi-tenant

- Tutte le notifiche devono sempre essere riferite a tenant_id e user_id, per garantire isolamento dati.
- Canali separati per ambiente (dev/test/prod): in dev/test, le notifiche vanno solo a indirizzi di test (mai clienti reali).
- Configurazione dinamica canali e template per ogni tenant (supporto white-label).
- Audit logging attivo per tutte le notifiche inviate/non consegnate.
- Retry automatico per canali non disponibili, con alert escalation.
- Conservazione log invio almeno 6 mesi, con dettaglio messaggio, stato, destinatario.

---

## Logging/Audit Notifiche

- Tutte le notifiche inviate sono registrate su tabella `notification_log` (tenant_id, user_id, tipo, canale, timestamp, stato).
- Errori di invio tracciati con motivo, tentativi e outcome finale.
- Modifica preferenze sempre loggata (vecchio e nuovo valore, chi e quando).
- Integrazione con flussi di audit centrale (`portal-audit`), per compliance.

---

## Nota operativa

- Prima di attivare notifiche verso clienti/utenti reali, testare canali e template su ambiente sandbox/dev.
- I template email/notifica devono essere versionati e gestiti come asset del portale (cartella portal-assets).

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

