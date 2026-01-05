---
id: ew-esempi-flussi-verticali-pa-–-accesso-tramite-spid-e-cie
title: Esempi Flussi Verticali PA – Accesso tramite SPID e CIE
summary: Breve descrizione del documento.
status: draft
owner: team-docs
created: '2025-01-01'
updated: '2025-01-01'
tags: [domain/frontend, layer/reference, audience/dev, privacy/internal, language/it, login, onboarding, spid, cie]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
# Esempi Flussi Verticali PA – Accesso tramite SPID e CIE

| Flusso/Variante                        | Attori            | Step Principali                                                        | Security/ACL                | Note Operative                                  |
|----------------------------------------|-------------------|-----------------------------------------------------------------------|-----------------------------|-------------------------------------------------|
| Accesso tramite SPID                   | Utente PA         | Scelta login “SPID”, redirect a provider, autenticazione, callback app| SPID SAML2, ACL mapping     | Idem PA, enti pubblici, aziende in convenzione  |
| Accesso tramite CIE                    | Utente PA         | Scelta login “CIE”, autenticazione via middleware CIE (NFC/desktop), callback| CIE OIDC/SAML2, ACL mapping | Serve middleware CIE (browser o desktop), forte autenticazione |
| Onboarding integrato SPID/CIE          | Utente PA/ente    | Primo accesso SPID/CIE, creazione automatica profilo utente, mapping su tenant PA | Auto-provisioning, audit    | Profilazione automatica dati anagrafici e ente di appartenenza |
| Profilazione utente da attributi SPID/CIE | Utente PA       | Lettura attributi (CF, nome, ente, ruolo), mapping su ruoli e permessi | Policy SPID/CIE, ACL        | Attributi verificati legalmente, audit trail completo           |
| Cambio autenticazione (es. upgrade da SPID a CIE) | Utente PA  | Accesso con un metodo, upgrade sicurezza con l’altro                  | Policy MFA, logging         | Migliora sicurezza, tracciato audit                                 |

## Esempio Dettagliato – Accesso tramite SPID

1. Utente PA apre la pagina di login e seleziona “Accedi con SPID”
2. Sistema effettua redirect verso l’Identity Provider SPID scelto dall’utente
3. Utente completa autenticazione sul portale SPID (livello 1, 2 o 3)
4. Identity Provider rimanda callback all’applicazione con attributi (es. codice fiscale, nome, ente di appartenenza)
5. Sistema crea (o aggiorna) profilo utente, associa a tenant/ente corretto, applica ruoli ACL corrispondenti
6. Logging completo di ogni step (tentativi, esito, mapping ACL, dati minimi)
7. Utente accede alla dashboard secondo i permessi assegnati dal mapping

---

## Esempio Dettagliato – Accesso tramite CIE

1. Utente seleziona “Accedi con CIE”
2. Viene avviato il middleware CIE (browser plugin, desktop app, o mobile NFC)
3. Utente autentica tramite PIN e dispositivo abilitato (NFC, smart card reader)
4. Sistema riceve callback dal servizio CIE con dati anagrafici certificati
5. Creazione/mapping automatico profilo utente, assegnazione tenant e ruoli, logging completo di processo
6. Accesso consentito solo se attributi minimi presenti e validi

---

## Esempio Onboarding Integrato SPID/CIE

- Al primo accesso tramite SPID o CIE, l’utente non presente viene automaticamente creato come “utente PA”, associato a tenant dell’ente di appartenenza, e profilato in base agli attributi forniti.
- In caso di accesso ripetuto con provider diverso (es. prima SPID, poi CIE), sistema unifica il profilo in base a codice fiscale.
- Ogni variazione/mapping viene tracciata in audit, con log motivazione e data/ora.

---

## Note Operative Verticale PA

- **Audit trail dettagliato** per ogni accesso, cambio provider, update profilo
- **Conservazione dati** in conformità con linee guida AGID (minimo, necessario, logging)
- **Mapping attributi → ACL/ruoli** basato su dati SPID/CIE (ruolo pubblico, ente, funzione)
- **Possibilità di auto-provisioning** per enti federati; per altri, validazione manuale admin
- **Alert automatici** su accessi anomali, tentativi falliti, cambi provider

---

## Vantaggi per la PA

- Accesso **semplice e sicuro** per cittadini, aziende e dipendenti pubblici
- Nessun onboarding manuale: dati certificati da provider
- **Compliance completa** con normative italiane (SPID/CIE, GDPR, AGID)
- Tutto il processo pronto per essere **automatizzato e auditato** via microservizi e policy

---




## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?






