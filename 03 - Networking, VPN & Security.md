Gateway Sicurezza: Gluetun (NordVPN via OpenVPN)
DNS & Filtering: AdGuard Home (Configurazione Client-Side)
Routing: Docker Bridge Network & Sidecar Pattern

---

## 1. Architettura VPN (Gluetun)

Il container `gluetun` (Stack 01) agisce come firewall e gateway unico per tutti i servizi che richiedono anonimato (Downloaders & Indexers).

### Configurazione Attiva

- **Provider:** NordVPN
- **Protocollo:** OpenVPN (TCP/UDP)
- **Autenticazione:** Credenziali Utente/Password (Environment Variables).
- **Port Forwarding:** Disabilitato (Modalità Passiva).
- **Kill Switch:** Nativo. Se cade la connessione VPN, il traffico si blocca istantaneamente, prevenendo leak dell'IP reale.

### Il Pattern "Sidecar"

I container **qBittorrent**, **Jackett** e **FlareSolverr** non hanno una loro interfaccia di rete. Sono "parassiti" (Sidecar) del container Gluetun.

**Conseguenze Operative:**

1. **IP Condiviso:** Tutti questi servizi escono su internet con lo stesso IP svizzero/estero fornito da NordVPN.
2. **Porte:** Le porte WebUI (es. 8080 per qBit, 9117 per Jackett) non sono esposte nei loro container, ma **devono essere mappate nel container Gluetun**.
3. **Comunicazione Interna:**
    - Jackett parla con FlareSolverr su `localhost:8191`.
    - Sonarr (esterno alla VPN) parla con qBittorrent su `http://gluetun:8080`.

Traffico Locale (LAN):

Per permettere a Sonarr (192.168.x.x) di parlare con qBittorrent (dentro la VPN), Gluetun è configurato con:

FIREWALL_OUTBOUND_SUBNETS=192.168.178.0/24 (Permette traffico verso la rete locale).

---

## 2. DNS & AdBlocking (AdGuard Home)

Ruolo: Server DNS locale e filtro pubblicitario.

IP Server: 192.168.178.41

Porta DNS: 53 (UDP/TCP)

Porta Dashboard: 3000 (Mappata come 3000 o 80 tramite Nginx in futuro).

### Strategia di Deployment

AdGuard NON è impostato come DNS del router principale (FritzBox/ISP Modem).

È configurato manualmente solo sui client specifici (es. PC Fisso, Mac Mini stesso, Smartphone personali).

- **Vantaggio:** Se il server va offline (manutenzione/crash), il resto della casa (TV, ospiti, domotica) continua a navigare usando i DNS predefiniti del router.
- **Svantaggio:** Bisogna configurare l'IP `192.168.178.41` manualmente nelle impostazioni di rete di ogni dispositivo da proteggere.

---

## 3. Reverse Proxy (Nginx Proxy Manager)

Ruolo: Gestione Certificati SSL e reindirizzamento traffico HTTP.

Porte Esposte: 80 (HTTP), 443 (HTTPS), 81 (Admin UI).

Attualmente utilizzato per:

1. **SSL Locale:** Fornire HTTPS ai servizi interni.
2. **DNS Rewriting:** (Se configurato in accoppiata con AdGuard) Per raggiungere i servizi tramite nomi (es. `jellyfin.lan`) invece che IP:Porta.

---

## 4. Flusso delle Richieste (Esempio Pratico)

### Scenario A: Sonarr cerca un episodio

1. **Sonarr** (Stack 04 - IP LAN) invia richiesta a **Jackett** (Stack 01 - IP VPN).
    - _Indirizzo:_ `http://gluetun:9117`
2. **Jackett** chiede a **FlareSolverr** di risolvere il captcha.
    - _Indirizzo:_ `http://localhost:8191` (Sono nello stesso pod VPN).
3. **Jackett** esce su internet tramite **Gluetun** (NordVPN) -> IP Svizzero -> Sito Torrent.
4. Il sito risponde. Sonarr riceve il file `.torrent`.

### Scenario B: Sonarr scarica l'episodio

1. **Sonarr** invia il `.torrent` a **qBittorrent**.
    - _Indirizzo:_ `http://gluetun:8080`
2. **qBittorrent** (dentro VPN) inizia il download dai peer.
    - Tutto il traffico P2P è crittografato e tunnelizzato da NordVPN.
3. A download finito, qBittorrent sposta il file in `/mnt/sdcard/SDMedia/Downloads/completed`
4. **Sonarr** (che vede la stessa cartella) prende il file, lo rinomina e lo sposta in `/mnt/sdcard/SDMedia/TV`.