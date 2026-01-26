Shell: Bash (/bin/bash)
Script Path: /DATA/Scripts/
Backup Target: /mnt/intenso (SSD Esterno - exFAT)

---

## 1. Censimento Comandi & Alias

Il server è gestito tramite un mix di script personalizzati (in `/DATA/Scripts`) e alias di shell definiti in `~/.bashrc`.

### 🧭 Navigazione Rapida (Stacks)

Comandi per saltare direttamente nelle cartelle dei `docker-compose.yml`.

| **Comando**  | **Destinazione**                               |
| ------------ | ---------------------------------------------- |
| `goto-infra` | `/DATA/AppData/my_stacks/01-ds-infrastructure` |
| `goto-mon`   | `/DATA/AppData/my_stacks/02-ds-monitoring`     |
| `goto-prod`  | `/DATA/AppData/my_stacks/03-ds-productivity`   |
| `goto-media` | `/DATA/AppData/my_stacks/04-ds-media-center`   |

### 🐳 Gestione Docker

Comandi operativi per gestire container e stack.

| **Comando**     | **Funzione**           | **Note**                                                           |
| --------------- | ---------------------- | ------------------------------------------------------------------ |
| `dps`           | Lista container attiva | Formattata come tabella pulita (Nome, Status, Porte).              |
| `dstats`        | Statistiche Risorse    | CPU/RAM istantanea (no stream).                                    |
| `dlogs [nome]`  | Leggi Log              | Esempio: `dlogs sonarr`.                                           |
| `dentra [nome]` | Entra in Shell         | Apre `/bin/bash` dentro il container.                              |
| `d-update`      | Aggiorna Stack         | Esegue `pull` + `up -d --force-recreate` nella cartella corrente.  |
| `check-vpn`     | Verifica IP VPN        | Esegue `curl` da dentro qBittorrent per verificare l'IP di uscita. |

### 🛠️ Gestione Sistema (Custom Scripts)

Script di amministrazione creati per la manutenzione dell'host.

| **Comando**      | **Script Sottostante**   | **Descrizione**                                |
| ---------------- | ------------------------ | ---------------------------------------------- |
| `server-health`  | `server_health.sh`       | Report stato generale del server.              |
| `server-clean`   | `utils/clean_house.sh`   | Pulizia file temporanei e log.                 |
| `server-update`  | `utils/update_system.sh` | Aggiornamento pacchetti OS (apt).              |
| `server-restart` | `restart-pc.sh`          | Riavvio sicuro del server.                     |
| `stacks`         | `utils/stack_manager.sh` | Menu interattivo per gestire gli stack Docker. |

### 📊 Monitoring Rete

| **Comando** | **Funzione**                                         |
| ----------- | ---------------------------------------------------- |
| `net-live`  | Monitoraggio traffico per processo (`nethogs`).      |
| `net-stats` | Statistiche traffico giornaliero/mensile (`vnstat`). |

---

## 2. Strategia di Backup "Survival"

Obiettivo: Salvare configurazioni e database (/DATA/AppData) per ripristino rapido in caso di rottura HDD interno.

Vincolo Tecnico: Il disco di destinazione (/mnt/intenso) è formattato in exFAT, che non supporta i permessi Linux.

Soluzione: Utilizzo di archivi compressi .tar.gz (che preservano i permessi al loro interno).

### 💾 Procedura Manuale (Mensile)

1. Stop Servizi Critici:
    
    Per evitare database corrotti (Sonarr/Radarr/Jellyfin) durante la copia.
    ```Bash
    docker stop sonarr radarr jellyfin jackett
```
    
2. Creazione Archivio (TAR):
    Crea un file compresso datato sull'SSD esterno.
    ```Bash
    # Sintassi: tar -czvf [DESTINAZIONE] [SORGENTE]
    sudo tar -czvf /mnt/intenso/Backup_AppData_$(date +%F).tar.gz /DATA/AppData
```
3. **Verifica e Riavvio:**
    ```Bash
    ls -lh /mnt/intenso/Backup_AppData_*
    docker start sonarr radarr jellyfin jackett
    ```

**Nota:** In caso di ripristino su nuovo disco, scompattare l'archivio con `tar -xzvf [file] -C /`.

---

## 3. Manutenzione Periodica

### Aggiornamenti

- **OS:** Lanciare `server-update` quando notificato dal sistema.
- **Docker:**
    - _Metodo Sicuro:_ Navigare nello stack (`goto-media`) -> Lanciare `d-update`.
    - _Metodo Menu:_ Lanciare `stacks` -> Selezionare lo stack -> Scegliere "Update".

### Pulizia Spazio Disco

Se `server-health` segnala spazio in esaurimento su `/` (Root):

1. **Docker Prune:** Rimuove immagini vecchie e container non usati.
    ```Bash
    docker system prune -a
    ```
    
2. **Log Journal:** Riduce i log di sistema a 100MB.
    ```Bash
    sudo journalctl --vacuum-size=100M
    ```

---

## 4. Troubleshooting Rapido

|**Sintomo**|**Diagnosi Probabile**|**Azione**|
|---|---|---|
|**Sito Web Down**|Container spento o Boot lento|Controlla con `dps`. Se "Up < 2 min", aspetta.|
|**"Permission Denied"**|Permessi corrotti su SD Card|`sudo chmod -R 777 /mnt/sdcard/SDMedia`|
|**Jackett Timeout**|VPN lenta o FlareSolverr spento|`check-vpn` per testare la linea, poi `dlogs flaresolverr`.|
|**Lentezza Generale**|RAM satura / Swap pieno|`htop` per verificare carico. Riavviare container pesanti (Java).|

---