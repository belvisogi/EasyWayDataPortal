Azure Boards – Seed Script

Prerequisiti
- Azure CLI installata: `az --version`
- Estensione Azure DevOps: `az extension add --name azure-devops`
- Login: `az login` (o `az devops login` con PAT)
- Defaults (opzionali): `az devops configure --defaults organization=https://dev.azure.com/<org> project=<project>`

Uso rapido
1) Dry-run (anteprima):
   `pwsh scripts/ado/boards-seed.ps1 -DryRun`
2) Esecuzione reale (con org/progetto):
   `pwsh scripts/ado/boards-seed.ps1 -OrgUrl https://dev.azure.com/<org> -Project <project>`
   Opzioni: `-AreaPath '<proj>\\Area' -IterationPath '<proj>\\Sprint 1'`

Cosa crea
- Epics: F0–F5 allineati alla roadmap (Quick Wins → Performance)
- Features: sotto ciascun Epic (test/OpenAPI/hooks; versioning/observability/health; Flyway/backup/audit/gates; CI/CD/IaC/quality; AI/Docs; performance)
- Collegamenti: ogni Feature è linkata al relativo Epic (Parent)

Idempotenza
- Il titolo + tipo viene cercato via WIQL; se esiste, non viene ricreato.

Note
- Il campo descrizione include criteri di accettazione sintetici; modifica liberamente dopo la creazione da web UI.
- Se servono User Stories/Tasks, duplica lo schema nel file e aggiungi una seconda passata (o apri una PR per estendere lo script).

