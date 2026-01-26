# 📄 02 - Docker Architecture & Stacks

Strategia: Modularità Funzionale
Networking: Bridge Network Condiviso (docker-general-network)
VPN Provider: NordVPN (Gestito da Gluetun)

---

## 1. Panoramica degli Stack

Il sistema è diviso in 4 Stack logici per isolare le responsabilità.

### 🧱 Stack 01: Infrastructure & Network Gateway

Path: /DATA/AppData/my_stacks/01-ds-infrastructure

Ruolo: Gestione traffico, Sicurezza, VPN e Download Attivi.

|**Servizio**|**Porta Esterna**|**Note Critiche**|
|---|---|---|
|**Nginx Proxy Manager**|80, 81, 443|Reverse Proxy & SSL Management.|
|**AdGuard Home**|53 (DNS), 3000|Blocco pubblicità e DNS Server della LAN.|
|**Gluetun**|-|**VPN Client (NordVPN).** Non espone porte dirette, fa da gateway per gli altri.|
|**Wireguard**|51820 (UDP)|VPN Server (per accedere a casa da fuori).|
|**qBittorrent**|8080 (WebUI)|**Sotto VPN.** Scarica i file. UI accessibile via porta mappata su Gluetun.|
|**Jackett**|9117|**Sotto VPN.** Indicizzatore Torrent.|
|**FlareSolverr**|8191|**Sotto VPN.** Bypass Cloudflare.|

**Nota Architetturale:** In questo stack, i servizi `qBittorrent`, `Jackett` e `FlareSolverr` sono "Sidecar" di Gluetun. Usano `network_mode: service:gluetun`.

---

### 📊 Stack 02: Monitoring & Dashboard

Path: /DATA/AppData/my_stacks/02-ds-monitoring

Ruolo: Controllo salute del server e interfaccia utente unificata.

|**Servizio**|**Porta Esterna**|**Note**|
|---|---|---|
|**Homepage**|3003|Dashboard principale (Landing Page).|
|**Portainer**|9000, 9443|Gestione grafica Docker.|
|**Uptime Kuma**|3001|Monitoraggio stato servizi (Ping/HTTP).|
|**Gotify**|8085|Server notifiche push locale.|

---

### 💼 Stack 03: Productivity

Path: /DATA/AppData/my_stacks/03-ds-productivity

Ruolo: Strumenti di ufficio e automazione.

|**Servizio**|**Porta Esterna**|**Note**|
|---|---|---|
|**Stirling-PDF**|8585|Suite modifica PDF (OCR disabilitato per performance).|
|**N8N**|5678|Workflow Automation (Low Code).|
|**CopyParty**|3923|File Server Web leggero (HTTP Upload/Download).|

---

### 🎬 Stack 04: Media Center (The Brains)

Path: /DATA/AppData/my_stacks/04-ds-media-center

Ruolo: Gestione librerie, organizzazione file e riproduzione.

Dipendenza: Questi servizi non sono sotto VPN (non necessario), ma comunicano con lo Stack 01 per richiedere i download.

|**Servizio**|**Porta Esterna**|**Ruolo**|
|---|---|---|
|**Jellyfin**|8096|Media Server (Netflix personale). Transcodifica via CPU.|
|**Jellyseerr**|5055|Interfaccia richieste (Request Movies/TV).|
|**Sonarr**|8989|Gestore Serie TV. Parla con qBit (Stack 01) e Jackett (Stack 01).|
|**Radarr**|7878|Gestore Film.|
|**Lidarr**|8686|Gestore Musica.|
|**Audiobookshelf**|13378|Gestore Audiolibri & Podcast.|
|**Youtarr**|3050|YouTube DVR (Scarica canali yt-dlp).|

---

## 2. Flusso di Rete (Networking Flow)

Come fanno i servizi dello Stack 04 (Media) a parlare con lo Stack 01 (Download) se sono in file diversi?

1. **Rete Condivisa:** Tutti i container sono collegati a una rete Docker personalizzata chiamata **`docker-general-network`** (definita come `external: true` nei vari compose).
2. **Risoluzione Nomi:**
    - Sonarr (Stack 04) chiama qBittorrent usando l'indirizzo: `http://gluetun:8080`.
    - _Perché `gluetun`?_ Perché qBittorrent è "nascosto" dentro la rete di Gluetun. La porta 8080 è aperta sul container Gluetun.
3. **Il caso FlareSolverr:**
    - Jackett (Stack 01) chiama FlareSolverr (Stack 01) usando: `http://localhost:8191`.
    - _Perché `localhost`?_ Perché entrambi vivono dentro il container Gluetun, quindi condividono lo stesso indirizzo locale (come coinquilini).