---
id: ew-query-in-src-queries
title: query in src queries
tags: [domain/control-plane, layer/howto, audience/dev, privacy/internal, language/it, queries]
owner: team-platform
summary: 'Documento su query in src queries.'
status: active
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
updated: '2026-01-05'
next: TODO - definire next step.
---
[Home](../../.././start-here.md) >  > [[Layer - Howto|Howto]]

1. users_select_by_tenant.sql
```sql
SELECT * FROM PORTAL.USERS WHERE tenant_id = @tenant_id AND is_active = 1;
```sql

2. users_update.sql
```sql
UPDATE PORTAL.USERS
SET email = @email,
    display_name = @display_name,
    profile_id = @profile_id,
    is_active = @is_active,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;

SELECT * FROM PORTAL.USERS WHERE user_id = @user_id AND tenant_id = @tenant_id;
```sql

3. users_deactive.sql
```sql
UPDATE PORTAL.USERS
SET is_active = 0,
    updated_at = SYSUTCDATETIME()
WHERE user_id = @user_id AND tenant_id = @tenant_id;
```sql

## Domande a cui risponde
- Cosa fa questa pagina?
- Quali sono i prerequisiti?
- Quali passi devo seguire?
- Quali sono gli errori comuni?
- Dove approfondire?


## Prerequisiti
- Accesso al repository e al contesto target (subscription/tenant/ambiente) se applicabile.
- Strumenti necessari installati (es. pwsh, az, sqlcmd, ecc.) in base ai comandi presenti nella pagina.
- Permessi coerenti con il dominio (almeno read per verifiche; write solo se whatIf=false/approvato).

## Passi
1. Raccogli gli input richiesti (parametri, file, variabili) e verifica i prerequisiti.
2. Esegui i comandi/azioni descritti nella pagina in modalita non distruttiva (whatIf=true) quando disponibile.
3. Se l'anteprima e' corretta, riesegui in modalita applicativa (solo con approvazione) e salva gli artifact prodotti.

## Verify
- Controlla che l'output atteso (file generati, risorse create/aggiornate, response API) sia presente e coerente.
- Verifica log/artifact e, se previsto, che i gate (Checklist/Drift/KB) risultino verdi.
- Se qualcosa fallisce, raccogli errori e contesto minimo (command line, parametri, correlationId) prima di riprovare.




