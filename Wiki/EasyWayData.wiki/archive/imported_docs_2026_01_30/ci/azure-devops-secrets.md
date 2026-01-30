# Azure DevOps – Variable Group (Secrets)

Crea un Variable Group (es. `EasyWay-Secrets`) in ADO > Pipelines > Library e aggiungi le variabili come secret:

- AZURE_STORAGE_ACCOUNT_NAME
- AZURE_STORAGE_ACCOUNT_KEY
- SQLSERVER_HOST (es. repos-easyway-dev.database.windows.net)
- SQLSERVER_PORT (es. 1433)
- SQLSERVER_DATABASE (es. easyway-admin)
- SQLSERVER_USER
- SQLSERVER_PASSWORD

La pipeline `azure-pipelines.yml` importa il gruppo con:

```
variables:
  - group: EasyWay-Secrets
```

Le variabili diventano disponibili come env in step script (bash/pwsh) e possono essere mappate all’app o ai test.

> Consiglio: per i deploy futuri, valuta Azure Key Vault + Variable Group collegato.

