---
id: ew-runbooks-instructions-collect-azure-inventory
title: instructions collect azure inventory
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [docs, domain/control-plane, layer/runbook, audience/ops, privacy/internal, language/it, inventory]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
---
Istruzioni passo‑passo — esecuzione scripts/collect_azure_inventory.ps1 e invio azure_inventory.json
Scopo
- Raccogliere automaticamente l’inventory Azure utile per la Fase 0 (inventory → RTO/RPO) e incollare qui il JSON di output.

Prerequisiti
1. PowerShell (Windows PowerShell o PowerShell 7 / pwsh).
2. Modulo Az installato:
   - Se non installato: Execute in PowerShell con diritti utente:
     Install-Module -Name Az -Scope CurrentUser -Force
3. Accesso alla subscription Azure con permessi di lettura sulle risorse che vuoi inventariare.

Passi esecutivi
1. Apri PowerShell (o pwsh) e autentica:
   - Connect-AzAccount
   - (opzionale se hai più subscription) Select-AzSubscription -SubscriptionId "<SUBSCRIPTION_ID>"
2. Posizionati nella cartella del repository dove è presente lo script:
   - cd <path-to-repo>
    Esempio (se sei nella root del repo): `cd "<repo-root>/EasyWayDataPortal"`
3. Esegui lo script (comando consigliato — non distruttivo):
   - pwsh -NoProfile -ExecutionPolicy Bypass -File .\scripts\collect_azure_inventory.ps1 -OutputFile .\azure_inventory.json
   Oppure, se usi Windows PowerShell senza pwsh:
   - .\scripts\collect_azure_inventory.ps1 -OutputFile .\azure_inventory.json
4. Attendi il completamento: lo script scrive il file azure_inventory.json nella cartella corrente e mostra un’anteprima nel terminale.
5. Verifica il file:
   - Apri il file con un editor (es. code .\azure_inventory.json o Notepad) e verifica che contenga sezioni come: ResourceGroups, WebApps, SqlServers, SqlDatabases, KeyVaults, StorageAccounts, PrivateEndpoints, FrontDoors, DnsZones, ecc.

Cosa incollare qui
- Apri azure_inventory.json, copia il contenuto (tutto) e incollalo nella risposta qui nella chat.
- Se il JSON è molto grande e la chat lo tronca, puoi:
  1) comprimere e condividere via link (es. GitHub Gist o upload interno), oppure
  2) incollare solo le sezioni principali (SqlServers, SqlDatabases, KeyVaults, StorageAccounts, PrivateEndpoints, WebApps, FrontDoors, DnsZones) — indicami quali hai incollato.

Sicurezza e note
- Lo script non raccoglie segreti/chiavi in chiaro; tuttavia rivedi il JSON per non includere accidentalmente valori sensibili prima di incollarlo.
- Se in azienda ci sono policy che vietano l’esportazione di inventari in chat pubbliche, esegui lo script e consegna il file al canale/designato (es. ADO artifact, Teams/SharePoint) e avvisami dove posso reperirlo.
- Se il comando Get-AzRoleAssignment restituisce output molto ampio, puoi modificare lo script per non includere RoleAssignmentsSample (rimuovendone la generazione temporaneamente).

In caso di errori comuni
- "Connect-AzAccount non eseguito": esegui Connect-AzAccount.
- Permessi insufficienti: esegui con un account che abbia almeno Reader sulle subscriptions/resource groups target.
- Modulo Az mancante: esegui Install-Module -Name Az -Scope CurrentUser -Force
- Problemi di esecuzione script per policy: usa -ExecutionPolicy Bypass come mostrato.

Consegna
- Dopo che incolli il JSON qui, procederò a:
  1) parsare automaticamente le sezioni principali,
  2) popolare la matrice componente→RTO/RPO con i nomi risorsa (RG, id, hostnames),
  3) segnalare eventuali gap informativi e richiedere solo i dettagli mancanti.

Se preferisci, posso anche generare una versione equivalente in bash/Az CLI: dimmi se la vuoi.






