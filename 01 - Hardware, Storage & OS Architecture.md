Hostname: macmini-server
Hardware: Apple Mac Mini (Late 2012)
OS: Ubuntu Server 24.04 LTS (Dockerized)
Stato Aggiornamento: Dicembre 2025

---

## 1. Specifiche Hardware & Risorse

Il server opera con risorse limitate, richiedendo un'ottimizzazione aggressiva della memoria e dei processi.

|**Componente**|**Specifica Reale**|**Stato & Note Operative**|
|---|---|---|
|**CPU**|Intel Core i5 (Dual Core)|Load Average va monitorato durante le scansioni media.|
|**RAM**|**4 GB** (3.7 GiB utilizzabili)|**CRITICO.** Saturazione frequente. Gestita tramite **ZRAM**.|
|**Swap (ZRAM)**|1.9 GB (Compresso)|Essenziale. Se si disattiva, i container Java/Browser crashano.|
|**Boot Drive**|HDD Interno (sda)|Lento. I servizi impiegano 5-10 min per avviarsi post-reboot.|
|**Network**|Ethernet Gigabit|IP Statico LAN: `192.168.178.41`|

---

## 2. Mappa dello Storage (Filesystem)

Il sistema gestisce 3 dischi fisici con 3 file system diversi. Questa eterogeneità richiede configurazioni di montaggio specifiche in `/etc/fstab`.

### 💾 A. Disco di Sistema (Interno)

- **Device:** `/dev/sda3` (EXT4)
- **Mountpoint:** `/` (Root)
- **Contenuto:** Sistema Operativo, Docker Images, Configurazioni Container (`/DATA/AppData`).
- **UUID:** `48cd1c47-20d7-40db-b594-7ed81e5cf787`
- **Policy:** Qui risiedono i database. **Non riempire oltre l'80%** per evitare il blocco di Docker.

### 💾 B. Disco Esterno "Intenso" (USB 3.0)

- **Device:** `/dev/sdb1` (exFAT)
- **Mountpoint:** `/mnt/intenso`
- **Contenuto:** Libreria Media Mista (Video/Foto).
- **UUID:** `5880-A0AB`
- **⚠️ Nota Tecnica (exFAT):** Linux non supporta permessi nativi su exFAT.
    - _Soluzione:_ Montato con `uid=1000,gid=1000` (utente `macmini`).
    - _Limitazione:_ Non è possibile usare `chmod` o `chown` su questo disco. I permessi sono simulati al montaggio.

### 💾 C. Scheda SD (Espansione PCIe)

- **Device:** `/dev/mmcblk0` (EXT4)
- **Mountpoint:** `/mnt/sdcard`
- **Contenuto:** Libreria Media (Download completati).
- **UUID:** `cb62a176-2e0c-45e9-a6d5-15a9b691ffd4`
- **Policy:** Formattata in EXT4 per massime prestazioni con Linux. Supporta permessi nativi.

---

## 3. Gestione Permessi & Utenti

Per evitare conflitti di scrittura tra Docker e Host (errore "Permission Denied"):

- **Utente Host:** `macmini` (UID: 1000, GID: 1000)
- **Utente Container:** I container LinuxServer (Sonarr, Jellyfin, ecc.) sono configurati con `PUID=1000` e `PGID=1000`.

### Comandi di Ripristino Permessi

Se i container non riescono a scrivere/spostare file:

1. **Per la SD Card (EXT4):**
   ```Bash
sudo chmod -R 777 /mnt/sdcard
sudo chown -R macmini:macmini /mnt/sdcard
```
    
2. **Per il Disco Intenso (exFAT):**
    - Non usare `chmod`. Se ci sono errori, verificare che nel file `/etc/fstab` sia presente l'opzione `uid=1000,gid=1000`.
    - Se necessario, smontare e rimontare: `sudo umount /mnt/intenso && sudo mount -a`.

---

## 4. Strategia di Backup (Mancante)

🛑 **ATTENZIONE: Attualmente NON esistono backup automatici.**

Aree critiche a rischio perdita dati totale in caso di rottura HDD interno (`sda`):

1. **Configurazioni Docker:** `/DATA/AppData/my_stacks` (Vitale)
2. **Database Servizi:** `/DATA/AppData/04-ds-arr/...` (Db di Sonarr/Radarr)

_Consiglio immediato:_ Copiare periodicamente la cartella `/DATA/AppData/my_stacks` sul disco `/mnt/intenso`.