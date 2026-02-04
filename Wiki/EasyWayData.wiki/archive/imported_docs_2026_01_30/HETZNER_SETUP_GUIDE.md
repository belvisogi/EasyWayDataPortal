---
id: ew-archive-imported-docs-2026-01-30-hetzner-setup-guide
title: 🖥️ Guida Setup Hetzner Cloud - Passo per Passo
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/reference, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# 🖥️ Guida Setup Hetzner Cloud - Passo per Passo

**Data**: 2026-01-24  
**Obiettivo**: Creare server Hetzner Cloud per EasyWay in 15 minuti

---

## 📋 Prerequisiti

Prima di iniziare, prepara:
- ✅ Email valida
- ✅ Carta di credito o PayPal
- ✅ 15 minuti di tempo

**Costo stimato**: €0.44 per il primo giorno di test

---

## 🚀 Step 1: Crea Account Hetzner (5 minuti)

### 1.1 Vai al sito

Apri browser e vai su: **https://console.hetzner.cloud/**

### 1.2 Registrazione

```
1. Click "Sign Up" (in alto a destra)
2. Compila form:
   - Email: la tua email
   - Password: scegli password sicura
   - Accetta Terms of Service
3. Click "Sign Up"
4. Controlla email per verifica
5. Click link di verifica nella email
```

### 1.3 Aggiungi Metodo di Pagamento

```
1. Login su https://console.hetzner.cloud/
2. Click "Billing" nel menu laterale
3. Click "Add Payment Method"
4. Scegli:
   - Carta di credito (Visa/Mastercard), oppure
   - PayPal, oppure
   - SEPA Direct Debit (bonifico EU)
5. Inserisci dati e conferma
```

✅ **Checkpoint**: Dovresti vedere "Payment method added successfully"

---

## 🖥️ Step 2: Crea Progetto (2 minuti)

### 2.1 Nuovo Progetto

```
1. Dalla dashboard, click "New Project"
2. Nome progetto: "EasyWay Production"
3. Click "Add Project"
```

### 2.2 Entra nel Progetto

```
1. Click sul progetto "EasyWay Production"
2. Dovresti vedere dashboard vuota con "Add Server"
```

---

## 🚀 Step 3: Crea Server (5 minuti)

### 3.1 Click "Add Server"

Vedrai wizard di configurazione con 6 sezioni:

### 3.2 Location (Dove)

```
Scegli: Nuremberg, Germany (nbg1)

Perché?
- Più vicino all'Italia
- Datacenter moderno
- Buona connettività
```

### 3.3 Image (Sistema Operativo)

```
Scegli: Ubuntu 22.04

Come:
1. Tab "Operating Systems"
2. Scroll fino a "Ubuntu"
3. Click "Ubuntu 22.04"
```

### 3.4 Type (Potenza Server)

```
Scegli: CPX31 (Shared vCPU)

Specifiche:
- 4 vCPU
- 8 GB RAM
- 160 GB SSD
- 20 TB traffic
- €13.10/mese (€0.018/ora)

Come:
1. Tab "Shared vCPU" (già selezionato)
2. Scroll fino a "CPX31"
3. Click su "CPX31"
```

> [!TIP]
> Se vuoi risparmiare per test iniziale, puoi scegliere **CPX21** (€7.50/mese, 3 vCPU, 4GB RAM)

### 3.5 Networking (Rete)

```
Lascia default:
- IPv4: ✅ (incluso gratis)
- IPv6: ✅ (incluso gratis)
```

### 3.6 SSH Keys (Opzionale ma Consigliato)

**Opzione A: Genera Chiave SSH (Consigliato)**

Dal tuo PC Windows PowerShell:
```powershell
# Genera chiave SSH
ssh-keygen -t ed25519 -C "easyway-hetzner"

# Quando chiede dove salvare, premi Enter (default: C:\Users\TuoNome\.ssh\id_ed25519)
# Quando chiede passphrase, puoi lasciare vuoto o inserirne una

# Copia chiave pubblica
Get-Content $env:USERPROFILE\.ssh\id_ed25519.pub | Set-Clipboard
Write-Host "✅ Chiave copiata negli appunti!"
```

Poi su Hetzner:
```
1. Click "Add SSH Key"
2. Nome: "PC Windows"
3. Incolla chiave (Ctrl+V)
4. Click "Add SSH Key"
```

**Opzione B: Salta (Userai Password)**

Se salti questo step, riceverai password via email.

### 3.7 Additional Features (Extra)

```
Lascia tutto deselezionato per ora:
- Backups: ❌ (costa extra, aggiungi dopo se serve)
- Volumes: ❌ (non serve)
```

### 3.8 Cloud Config (Avanzato)

```
Lascia vuoto per ora
```

### 3.9 Name (Nome Server)

```
Server name: easyway-prod

Opzionale:
- Labels: environment=production
```

### 3.10 Crea!

```
1. Verifica riepilogo:
   - Location: Nuremberg
   - Image: Ubuntu 22.04
   - Type: CPX31
   - Costo: €13.10/mese

2. Click "Create & Buy Now"
```

---

## ⏱️ Step 4: Attendi Creazione (1-2 minuti)

Vedrai:
```
Creating server...
[████████████░░░░] 75%
```

Quando completo:
```
✅ Server easyway-prod is running
```

---

## 📧 Step 5: Salva Credenziali

### 5.1 Dalla Dashboard Hetzner

```
1. Click sul server "easyway-prod"
2. Vedrai:
   - IPv4: 95.217.xxx.xxx (esempio)
   - Status: Running
   - Type: CPX31
```

**Copia l'IP** e salvalo!

### 5.2 Dalla Email (se non hai usato SSH Key)

Riceverai email:
```
Subject: Your new Hetzner Cloud Server

Server: easyway-prod
IPv4: 95.217.xxx.xxx
Root Password: Xy9#kL2mP8qR
```

**Salva password** in posto sicuro (password manager)!

---

## 🔌 Step 6: Primo Accesso (2 minuti)

### 6.1 Connetti via SSH

Dal tuo PC Windows PowerShell:

**Se hai usato SSH Key**:
```powershell
ssh root@95.217.xxx.xxx
# Dovrebbe connettersi senza chiedere password
```

**Se usi Password**:
```powershell
ssh root@95.217.xxx.xxx
# Inserisci password dalla email quando richiesto
# Ti chiederà di cambiarla al primo accesso
```

### 6.2 Primo Login

```bash
# Dovresti vedere:
Welcome to Ubuntu 22.04.3 LTS (GNU/Linux 5.15.0-91-generic x86_64)

root@easyway-prod:~#
```

✅ **Sei dentro!**

---

## 🎯 Step 7: Setup Base (5 minuti)

### 7.1 Aggiorna Sistema

```bash
apt update && apt upgrade -y
```

Aspetta ~2-3 minuti.

### 7.2 Installa Docker

```bash
curl -fsSL https://get.docker.com | sh
```

Aspetta ~1 minuto.

### 7.3 Installa Docker Compose

```bash
apt install docker-compose-plugin -y
```

### 7.4 Verifica

```bash
docker --version
# Output: Docker version 24.x.x

docker compose version
# Output: Docker Compose version v2.x.x
```

✅ **Docker installato!**


---

## 🔐 Next Steps: Go Production

Una volta completato questo setup rapido, **DEVI** applicare il protocollo di sicurezza per la produzione.

👉 **Vedi: [SERVER_BOOTSTRAP_PROTOCOL.md](../../../../scripts/docs/infra/SERVER_BOOTSTRAP_PROTOCOL.md)**

Ti spiegherà come:
1. 🛡️ Configurare il Firewall (UFW)
2. 🔑 Disabilitare accesso password SSH
3. 🌐 Whitelistare l'IP su Azure SQL
4. 📂 Spostare tutto in structure `/opt/easyway` standard



## 🎉 Completato!

Hai ora:
- ✅ Account Hetzner attivo
- ✅ Server Ubuntu 22.04 running
- ✅ Docker installato
- ✅ IP pubblico: 95.217.xxx.xxx

### Costi Finora

```
Tempo trascorso: ~15 minuti
Costo: ~€0.005 (mezzo centesimo!)
```

---

## 📝 Prossimi Step

Ora puoi:
1. Installare PowerShell Core
2. Clonare repository EasyWay
3. Configurare docker-compose.yml
4. Avviare primi containers

Vedi: `ANTI_PHILOSOPHY_STARTER_KIT.md` → Giorno 2

---

## 🆘 Troubleshooting

### Non riesco a connettermi via SSH

```powershell
# Verifica che server sia running
# Vai su https://console.hetzner.cloud/
# Controlla status server

# Prova con verbose
ssh -v root@95.217.xxx.xxx
```

### Password non funziona

```
1. Vai su console Hetzner
2. Click server → Console
3. Usa console web per resettare password
```

### Server costa troppo

```bash
# Spegni server quando non lo usi
# Da console Hetzner: Power Off

# Oppure da CLI:
hcloud server poweroff easyway-prod
```

---

## 💡 Tips

### Installa Hetzner CLI sul tuo PC

```powershell
# Windows
winget install hetzner.hcloud

# Poi configura
hcloud context create easyway
# Inserisci API token (da console Hetzner → Security → API Tokens)
```

Ora puoi gestire server dal PC:
```powershell
hcloud server list
hcloud server poweron easyway-prod
hcloud server poweroff easyway-prod
```

---

**Creato**: 2026-01-24  
**Tempo stimato**: 15 minuti  
**Difficoltà**: ⭐⭐☆☆☆ (Facile)



