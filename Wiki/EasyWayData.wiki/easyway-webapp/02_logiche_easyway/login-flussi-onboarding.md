---
id: ew-login-onboarding
title: Login – Flussi Onboarding
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags:
  - layer/how-to
  - privacy/internal
  - language/it
llm:
  include: true
  pii: none
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
id: ew-login-flussi-onboarding
title: login flussi onboarding
summary: 
owner: 
---
# Lookup – Flussi Onboarding/Login

| Cosa vuoi                   | Cosa devi scrivere                | Dammi il .md                                 | Stato    |
|-----------------------------|-----------------------------------|----------------------------------------------|----------|
| Overview onboarding/login   | Dammi overview onboarding login   | Dammi il .md overview onboarding login       | IN BOZZA |
| Tabella flussi utente       | Dammi tabella flussi login        | Dammi il .md tabella flussi login            | IN BOZZA |
| Best practice onboarding    | Dammi best practice onboarding    | Dammi il .md best practice onboarding        | IN BOZZA |
| Esempio flusso step-by-step | Dammi esempio flusso onboarding   | Dammi il .md esempio flusso onboarding       | IN BOZZA |

Flussi Onboarding/Login – EasyWay Data Portal
# Flussi Onboarding/Login – EasyWay Data Portal

## Tabella Flussi Utente

| Flusso                     | Attori              | Step Principali                                                  | Security/ACL                 | Note Operative                       |
|----------------------------|---------------------|------------------------------------------------------------------|------------------------------|--------------------------------------|
| Onboarding locale          | Utente finale       | Registrazione, conferma email, creazione credenziali, primo login| Policy password/MFA, ACL     | Utente collegato a tenant_id         |
| Onboarding federato        | Utente azienda/partner | SSO via Entra ID, mappatura tenant, mapping ruoli                | SSO Entra ID, ACL mapping    | Auto-provisioning se abilitato       |
| Onboarding prospect/demo   | Nuovo cliente       | Richiesta accesso, validazione, assegnazione tenant, invito      | Validazione manuale/admin    | Flusso semplificato, accesso limitato|
| Login locale               | Utente finale       | Inserimento credenziali, validazione, MFA se richiesto           | Token JWT, MFA opzionale     | Tentativi falliti loggati            |
| Login federato             | Utente azienda      | SSO redirect, validazione token, mapping ruoli                   | Token Entra ID, ACL mapping  | Timeout/session management           |
| Recupero credenziali       | Utente finale       | Reset password, verifica identità, set nuova password            | Link one-time, scadenza      | Alert admin su troppi reset          |

---

## Best Practice Onboarding/Login

- **Sempre richiesta conferma email o SSO validato prima accesso**
- **Ogni utente associato a tenant_id e profilo (ruolo/ACL)**
- **Password policy forte + MFA per admin/superuser**
- **Log di ogni tentativo di login, reset e modifica profilo**
- **Flusso prospect/demo: separato e “sandboxato” rispetto a clienti reali**
- **Timeout sessione e refresh token configurabili**
- **Processo di disabilitazione/reactivation gestito da admin tenant**

---

## Esempio Flusso Step-by-Step – Onboarding Locale

1. Utente apre pagina di registrazione e inserisce dati (email, nome, azienda…)
2. Sistema invia email di conferma con link “one-time”
3. Utente clicca link, crea password e completa registrazione
4. Primo login, viene assegnato a tenant/azienda e ruolo di default
5. System logga ogni passaggio e invia welcome email/alert admin tenant

---

> **Nota:**  
> Ogni step deve essere tracciato nei log/audit e gestito secondo policy di sicurezza (tentativi, token, scadenze, MFA…).




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?

