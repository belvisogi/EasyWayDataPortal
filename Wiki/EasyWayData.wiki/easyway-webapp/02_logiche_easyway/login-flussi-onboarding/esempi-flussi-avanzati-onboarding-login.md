---
id: ew-esempi-flussi-avanzati-onboarding-login
title: esempi flussi avanzati onboarding login
summary: 'Documento su esempi flussi avanzati onboarding login.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/frontend, layer/reference, audience/dev, privacy/internal, language/it, login, onboarding, sso]
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

## Esempi Flussi Avanzati Onboarding/Login

| Flusso/Variante                   | Attori                   | Step Principali                                                          | Security/ACL                        | Note Operative                                   |
|-----------------------------------|--------------------------|--------------------------------------------------------------------------|--------------------------------------|--------------------------------------------------|
| Onboarding SSO aziendale custom   | Utente azienda/IT admin  | Admin IT configura SSO (es. via Entra ID, SAML, OIDC), provisioning utenti automatico | Policy SSO, ACL mapping, auto-onboard | Flusso zero-touch, utenti creati al primo login   |
| Onboarding da Azure Marketplace   | Cliente marketplace      | Utente acquista/attiva dal marketplace, riceve invito onboarding automatico          | ACL predefiniti, mapping offerta      | Stato “pending” finché completato primo login     |
| Gestione consensi privacy         | Utente finale            | Accetta/revoca consensi privacy all’atto di onboarding o nel profilo                 | Policy privacy, logging, audit       | Gestire versioning consensi e revoca retroattiva  |
| Onboarding con autenticazione forte (SPID/CIE) | Utente pubblico       | Login con SPID/CIE, mappatura identità e assegnazione tenant/profilo                 | SPID/CIE integration, ACL mapping    | Obbligatorio in ambito pubblico/PA               |
| Provisioning utenti “just-in-time”| Utente azienda/SSO       | Utente SSO non ancora presente, viene creato “al volo” al primo accesso              | SSO, claim mapping, policy onboarding| Profilo base fino a completamento anagrafica      |
| Gestione consensi granulari       | Utente finale            | Possibilità di accettare/negare consensi specifici (newsletter, analytics, ecc.)     | Policy granular, audit consensi      | Stato consensi loggato con timestamp e motivazione|
| Flusso “invito da altro sistema”  | Admin/integrazione esterna| Invio automatico di invito a utente da altro sistema/app                             | API external, ACL mapping            | Validazione invito e mappatura su tenant esistente|
| Multi-factor onboarding           | Utente finale            | Obbligo attivazione MFA (OTP, Authenticator App) durante onboarding                  | Policy MFA, logging, audit           | Blocco login se MFA non completato                |
| Onboarding/Accesso tramite QR code| Utente mobile/desktop    | Scan QR per onboarding rapido su dispositivi mobili                                  | Token QR one-time, ACL onboarding    | Valido per demo, eventi o partnership             |


## Dettaglio Esempio – SSO Aziendale Custom (Entra ID/SAML/OIDC)

1. Admin IT dell’azienda entra nell’area “Configura SSO”
2. Registra dominio e imposta federazione (es: metadati SAML o OIDC)
3. Testa la connessione con account di prova
4. Dal primo login di un utente aziendale → provisioning automatico (profilo base, ACL default)
5. Utente può essere auto-approvato o soggetto a verifica admin tenant
6. Logging di tutta la procedura su audit centrale e notifica owner tenant

---

## Dettaglio Esempio – Gestione Consensi Privacy

1. Utente, in fase di onboarding o nella sezione “Profilo”, visualizza i consensi richiesti e opzionali (es: marketing, profilazione, newsletter, analytics…)
2. Ogni consenso può essere accettato/negato singolarmente, con registrazione timestamp e versione testo informativa
3. Modifica consensi tracciata in audit log
4. In caso di revoca, il sistema deve bloccare/aggiornare le funzionalità collegate
5. Log e stato consensi accessibili su richiesta (per GDPR)

---

## Dettaglio Esempio – Onboarding da Azure Marketplace

1. Cliente attiva servizio direttamente da Azure Marketplace
2. Sistema genera tenant_id e invia invito onboarding al referente specificato in fase d’ordine
3. Utente accede al portale tramite link ricevuto, completa anagrafica, imposta password/MFA
4. Profilo, ACL e permessi pre-caricati in base al tipo di offerta sottoscritta (es: demo, starter, premium)
5. Logging di tutte le azioni, stato “pending” finché onboarding completato

---

## Nota operativa

- Tutti i flussi avanzati vanno sempre collegati alle stesse policy di logging/audit, notifiche admin, e gestione ACL/tenant.
- Le **customizzazioni (es. SSO, consensi, onboarding esterni)** vanno descritte anche nelle API/contratti REST tra sistemi.




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?










