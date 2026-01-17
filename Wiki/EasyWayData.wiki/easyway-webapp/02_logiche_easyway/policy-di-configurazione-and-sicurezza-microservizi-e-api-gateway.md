---
id: ew-policy-di-configurazione-&-sicurezza-–-microservizi-e-api-gateway
title: Policy di Configurazione & Sicurezza – Microservizi e API Gateway
summary: 'Documento su Policy di Configurazione & Sicurezza – Microservizi e API Gateway.'
status: active
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/control-plane, layer/spec, audience/dev, audience/ops, privacy/internal, language/it, security]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
next: TODO - definire next step.
---
[[start-here|Home]] > [[Domain - Control-Plane|Control-Plane]] > [[Layer - Spec|Spec]]

# Policy di Configurazione & Sicurezza – Microservizi e API Gateway
EasyWay Data Portal

| Policy/Configurazione        | Obiettivo/Descrizione                                                                              | Dove si applica                | Best Practice Azure/Dev           | Note Operative / Dettaglio Implementativo                                |
|------------------------------|----------------------------------------------------------------------------------------------------|--------------------------------|-----------------------------------|--------------------------------------------------------------------------|
| Isolation tenant             | Garantire isolamento dati/logica tra tenant (aziende/clienti diversi)                             | API Gateway, microservizi, DB  | Tenant_id in ogni request/claim   | Ogni chiamata deve includere il tenant_id; query e storage filtrati      |
| Row-Level Security           | Applicare filtri sui dati in base al tenant e all’ACL utente                                      | Database, API                  | SQL Server RLS, claim JWT         | Le tabelle chiave usano sempre RLS su tenant_id/profilo/ruolo            |
| Identity tecnica             | Usare identità di servizio (managed identity/service principal) per comunicazione tra microservizi | App Service, Container         | Azure Managed Identity            | Niente credenziali hardcoded, tutti i permessi dati a identity dedicate  |
| Segreti/parametri sicuri     | Gestione centralizzata di connessioni e segreti, versionamento, auditing accessi                  | Microservizi, pipeline, API    | Azure Key Vault, env YAML, dotenv | Tutti i segreti fuori codice, accesso auditato e rotazione periodica     |
| Networking sicuro            | Limitare accesso solo a Gateway e tra servizi interni, evitare endpoint pubblici non autorizzati  | App Service, API Gateway       | VNet Integration, Private Endpoint| Solo traffico interno autorizzato; nessun esposto su Internet diretto    |
| Policy ACL centralizzata     | Gestione ruoli, permessi e mapping ACL in modo centralizzato e versionabile                        | API Gateway, microservizi, DB  | ACL repository, policy API Mgmt   | ACL gestite via DB o repository, mapping dinamico su ruoli e tenant      |
| Policy config versionabile   | Configurazioni ambiente/dev/test/prod sempre versionate e storicizzate                            | Tutti i servizi                | IaC (Bicep/ARM), YAML, GitOps     | Niente settaggi manuali fuori controllo, tutto in versioning             |
| Audit & logging security     | Tracciare tutte le azioni rilevanti per sicurezza, compliance e troubleshooting                    | API Gateway, microservizi      | Log Analytics, Storage Audit      | Logging centralizzato, retention policy attiva, alert su anomalie        |
| Compliance GDPR/SOC2/DORA    | Aderire alle policy di mascheramento, tracciamento, protezione dati sensibili                     | Storage, API, DB               | Masking metadata, audit DB        | Uso tabella masking e audit trail per ogni accesso ai dati personali     |
| Security testing continuo    | Ridurre vulnerabilita' note e regressioni                                                        | CI/CD, pre-prod, runtime       | SAST/SCA/DAST, pen test periodici | Scansioni ad ogni PR, DAST pre-release, pen test almeno annuale          |

## Dettaglio Implementativo Policy Chiave

### 1. Isolation Tenant & Row-Level Security
- Ogni richiesta (API Gateway → microservizio → DB) **porta sempre il tenant_id**.
- Le query DB usano filtri su tenant_id (e profilo/ruolo se necessario).
- Implementazione RLS su tutte le tabelle multi-tenant.
- **Refuso da evitare:** mai lasciare endpoint senza validazione tenant/ruolo.

### 2. Identity Tecnica
- Ogni microservizio/container **usa un Managed Identity Azure** oppure uno specifico Service Principal.
- Le identity hanno **solo i permessi strettamente necessari** (least privilege).
- Accesso a Key Vault, storage e DB solo tramite queste identity.

### 3. Gestione Segreti e Parametri
- Nessuna password/chiave hardcoded nel codice o pipeline.
- Tutte le connessioni, segreti, token API sono su **Azure Key Vault** o (in locale) file `.env` cifrati/versionati.
- Ogni accesso ai segreti viene loggato/auditato e ruotato periodicamente.

### 4. Networking Sicuro
- Ogni microservizio è raggiungibile **solo via VNet interna** o Private Endpoint.
- Accesso pubblico solo all’API Gateway.
- Nessun database o storage esposto su Internet.
- Firewall e NSG su ogni subnet/container group.

### 5. Policy Config Versionabile
- Tutte le configurazioni sono mantenute come **Infrastructure as Code** (Bicep, ARM, Terraform) o in repository YAML/GitOps.
- Ogni modifica/configurazione ambientale è storicizzata.
- Niente “parametri manuali” inseriti a mano su Azure Portal.

### 6. Audit & Logging
- Ogni richiesta critica (login, cambio ACL, accesso dati sensibili, errore auth) è tracciata in modo centralizzato.
- Log e audit trail con retention policy e alert su accessi/anomalie.
- Tutto lo storico a disposizione per compliance e troubleshooting.

---

## **Best Practice Operativa**
> Ogni script, template o codice dovrà SEMPRE:
> - Integrare queste policy come requisito base
> - Indicare (in README/commenti) che le configurazioni vanno versionate e i segreti gestiti fuori dal codice
> - Prevedere auditing/logging centralizzato per qualsiasi azione rilevante
> - Considerare vulnerabilita' note (OWASP) durante lo sviluppo e nei code review

---

**Se questa sezione va bene, la segno come “PRONTA PER CODICE” e passo alla prossima macro-sezione che vuoi tu.**
Vuoi aggiungere o dettagliare una specifica policy?  
Oppure proseguiamo con la prossima sezione (es: “Gestione logging & audit”, “Best practice naming e scaling”, ecc.)?



## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?










