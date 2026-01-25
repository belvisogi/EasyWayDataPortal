# Remote Infra Scripts

Questi script servono al provisioning/deploy remoto in modo ripetibile da Windows.

## Prerequisiti
- PowerShell 7+ (`pwsh`).
- OpenSSH client disponibile (`ssh`).
- Accesso SSH al server (utente `ubuntu`).
- Chiave privata locale (vedi `C:\old\Virtual-machine\ssh-key-2026-01-25.key`).
- PAT Azure DevOps salvato fuori repo in `C:\old\azure_pat.txt`.

## Config rapida (prima esecuzione)
Apri lo script e aggiorna questi parametri:
- `$IP` (IP server)
- `$Key` (percorso chiave SSH)
- `$PAT` (lascia leggere da `C:\old\azure_pat.txt`)
Oppure compila `remote.config.ps1` e/o passa i parametri da riga di comando.

## Sequenza consigliata (Swiss-clock)
1) `install_docker_remote.ps1`
2) `deploy_easyway.ps1`
3) `launch_remote_build.ps1`
4) `monitor_deployment.ps1`

## Update routine
- `update_only.ps1`
- `update_and_deploy.ps1`

## Esempi di esecuzione
Da root repo:
```powershell
pwsh .\scripts\infra\remote\install_docker_remote.ps1
pwsh .\scripts\infra\remote\deploy_easyway.ps1
```
Con parametri:
```powershell
pwsh .\scripts\infra\remote\deploy_easyway.ps1 -IP 1.2.3.4 -Key C:\keys\id_rsa -PatPath C:\secrets\azure_pat.txt
```
Con config:
```powershell
# copia scripts\infra\remote\remote.config.example.ps1 in remote.config.ps1 e compila i valori
pwsh .\scripts\infra\remote\deploy_easyway.ps1
```
Dry-run:
```powershell
pwsh .\scripts\infra\remote\deploy_easyway.ps1 -WhatIf
```

## Preflight checklist
- SSH raggiungibile: `ssh -i <key> ubuntu@<ip> "echo ok"`
- PAT presente e non vuoto: `Get-Content C:\old\azure_pat.txt`
- Repo presente sul server (se non presente, esegui `deploy_easyway.ps1`)

## Note
- Tenere i segreti fuori dalla repo (PAT, password, chiavi).
- Se cambi host/IP, aggiornare i parametri degli script prima di eseguire.
- Se il server non ha ancora la repo, eseguire prima `deploy_easyway.ps1`.
