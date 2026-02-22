# PRD - Ingestion Saldi da Fonti Esterne + Fatture Cloud
Versione: 0.1 (Draft)
Owner: IT / Product
Stato: In revisione

## 1. Obiettivo business
Consentire il caricamento dei saldi da fonti esterne (oltre alle fatture cloud), con visualizzazione aggregata su portale EasyWay e possibilita' di condivisione controllata.

## 2. Scope
In scope:
- Upload file da interfaccia EasyWay (formato principale: Excel template EasyWay)
- Parsing/mapping campi verso modello dati interno
- Validazioni Data Quality e gestione errori
- Aggregazione e visualizzazione su portale
- Condivisione dati con utenti autorizzati

Out of scope:
- Modifica retroattiva massiva dello storico legacy
- Nuovi canali di upload non file-based (API esterne real-time) in questa release

## 3. Fonti dati
- Fatture cloud (esistente)
- Fonti esterne file-based (Excel)
- Eventuali estensioni future: CSV/API (documentare come roadmap)

## 4. Mapping dati (Excel -> modello EasyWay)
- Template: `docs/prd/templates/easyway-balance-upload-template.xlsx` (placeholder)
- Campi minimi:
  - `CustomerCode`
  - `DocumentDate`
  - `BalanceAmount`
  - `Currency`
  - `SourceSystem`
  - `ReferenceId`

## 5. Data Quality Rules
- Controlli schema: colonne obbligatorie presenti
- Controlli dominio: currency valida, amount numerico, date valida
- Deduplica: chiave logica (`CustomerCode` + `ReferenceId` + `DocumentDate`)
- Soglie: righe invalide > X% => blocco ingest
- Error handling: report errori scaricabile + log audit

## 6. Frequenza e modello operativo
- Upload manuale on-demand (fase 1)
- Opzione schedulazione futura (giornaliera/settimanale)
- SLA elaborazione: <N minuti per file <= M righe

## 7. UX portale e aggregazioni
- Pagina upload con feedback validazione
- Dashboard aggregata per cliente/periodo/fonte
- Filtri + export
- Stato ingest (success/fail/parziale) con dettaglio errori

## 8. Sicurezza, permessi, audit
- RBAC: upload solo ruoli autorizzati
- Condivisione: visibilita' per tenant/ruolo
- Audit trail: chi ha caricato cosa e quando
- Policy segreti/connessioni conforme governance EasyWay

## 9. Impatti tecnici
- API: endpoint upload/validate/process/status
- DB: nuove tabelle staging + canonical + audit
- Frontend: pagina upload + dashboard aggregata
- ETL: pipeline parse/validate/merge
- Governance: aggiornamento runbook, checklist, gate

## 10. Rischi principali e mitigazioni
- File non conformi -> validazione preventiva e template ufficiale
- Duplicati -> dedup key + idempotenza pipeline
- Qualita' bassa dati -> soglie + blocco ingest + feedback operatore

## 11. Acceptance criteria (alto livello)
- Upload Excel valido produce record aggregati visibili su portale
- Upload con errori produce report chiaro senza corrompere dati
- Tracciabilita' completa in audit log
- Permessi applicati correttamente su upload e consultazione
