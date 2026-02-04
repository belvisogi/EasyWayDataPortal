---
id: ew-archive-imported-docs-2026-01-30-infra-oracle-oracle-ubuntu-desktop-setup
title: Oracle Cloud - Ubuntu Desktop + RDP Setup Guide
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
# Oracle Cloud - Ubuntu Desktop + RDP Setup Guide

> **Guida completa per configurare una VM Oracle Cloud Free Tier con Ubuntu Desktop e Remote Desktop (XRDP)**

---

## 🎯 Obiettivo

Creare una VM Oracle Cloud **GRATIS per sempre** con:
- ✅ Ubuntu Desktop 24.04
- ✅ Remote Desktop (RDP) funzionante
- ✅ 24 GB RAM + 4 CPU ARM (Free Tier!)
- ✅ Accessibile da internet

---

## 📋 Prerequisiti

- Account Oracle Cloud (Free Tier)
- Carta di credito (per verifica, non viene addebitato nulla)
- Chiave SSH generata (o la generiamo durante il setup)

---

## 🏗️ Parte 1: Configurazione Networking Oracle

### 1. Crea VCN (Virtual Cloud Network)

1. **Networking** → **Virtual Cloud Networks**
2. Click **"Create VCN"**
3. Compila:
   - **Name**: `vcn-prod`
   - **IPv4 CIDR Block**: `10.0.0.0/16`
   - **Compartment**: Seleziona il tuo compartment
4. Click **"Create VCN"**

---

### 2. Crea Internet Gateway

1. Apri la VCN appena creata (`vcn-prod`)
2. Menu sinistra → **"Internet Gateways"**
3. Click **"Create Internet Gateway"**
4. Compila:
   - **Name**: `igw-prod`
   - **Compartment**: Stesso della VCN
5. Click **"Create Internet Gateway"**

---

### 3. Crea Route Table

1. Nella VCN, menu sinistra → **"Route Tables"**
2. Click **"Create Route Table"**
3. Compila:
   - **Name**: `rt-public-prod`
   - **Compartment**: Stesso della VCN
4. Nella sezione **"Route Rules"**, click **"+ Another Route Rule"**
5. Compila:
   - **Target Type**: Internet Gateway
   - **Destination CIDR Block**: `0.0.0.0/0`
   - **Target Internet Gateway**: Seleziona `igw-prod`
   - **Description**: `Route to Internet`
6. Click **"Create"**

---

### 4. Crea Subnet Pubblica

1. Nella VCN, menu sinistra → **"Subnets"**
2. Click **"Create Subnet"**
3. Compila:
   - **Name**: `subnet-public-prod`
   - **Subnet Type**: **Regional**
   - **IPv4 CIDR Block**: `10.0.0.0/24`
   - **Route Table**: Seleziona `rt-public-prod`
   - **Subnet Access**: **Public Subnet**
   - **DHCP Options**: Default
   - **Security List**: Default Security List
4. Click **"Create Subnet"**

---

### 5. Configura Security List (Firewall)

1. Nella VCN, menu sinistra → **"Security Lists"**
2. Click su **"Default Security List for vcn-prod"**
3. Click **"Add Ingress Rules"**

#### Regola 1: SSH (Porta 22)
- **Source Type**: CIDR
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: TCP
- **Destination Port Range**: `22`
- **Description**: `SSH Access`
- Click **"Add Ingress Rules"**

#### Regola 2: RDP (Porta 3389)
- Click di nuovo **"Add Ingress Rules"**
- **Source Type**: CIDR
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: TCP
- **Destination Port Range**: `3389`
- **Description**: `RDP Remote Desktop`
- Click **"Add Ingress Rules"**

#### Regola 3: HTTP (Opzionale - Porta 80)
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: TCP
- **Destination Port Range**: `80`
- **Description**: `HTTP`

#### Regola 4: HTTPS (Opzionale - Porta 443)
- **Source CIDR**: `0.0.0.0/0`
- **IP Protocol**: TCP
- **Destination Port Range**: `443`
- **Description**: `HTTPS`

---

## 💻 Parte 2: Creazione VM

### 1. Crea Instance

1. **Compute** → **Instances**
2. Click **"Create Instance"**

### 2. Configurazione Base

- **Name**: `vm-ubuntu-desktop-prod`
- **Compartment**: Il tuo compartment
- **Availability Domain**: Seleziona uno disponibile

### 3. Image e Shape

#### Image:
- Click **"Change Image"**
- Seleziona **"Canonical Ubuntu"**
- Versione: **Ubuntu 24.04** (o 22.04)
- Click **"Select Image"**

#### Shape:
- Click **"Change Shape"**
- **Shape series**: Ampere (ARM)
- **Shape name**: **VM.Standard.A1.Flex** ⭐ **FREE TIER!**
- **OCPU**: `4` (massimo gratis)
- **Memory (GB)**: `24` (massimo gratis)
- Click **"Select Shape"**

### 4. Networking

- **Primary network**: Select existing virtual cloud network
- **Virtual cloud network**: `vcn-prod`
- **Subnet**: `subnet-public-prod`
- ☑️ **Assign a public IPv4 address** ✅ **IMPORTANTE!**

### 5. SSH Keys

- Seleziona **"Generate a key pair for me"**
- Click **"Save Private Key"** → Salva in `C:\Users\TuoNome\.ssh\oracle-vm-key.pem`
- Click **"Save Public Key"** → Salva in `C:\Users\TuoNome\.ssh\oracle-vm-key.pub`

### 6. Boot Volume

- Lascia default (50 GB)

### 7. Crea VM

- Click **"Create"**
- Aspetta 2-3 minuti che la VM si crei
- Stato diventa **"Running"** (verde)
- **Annota l'IP pubblico** (es: `150.110.12.61`)

---

## 🔑 Parte 3: Connessione SSH

### Windows PowerShell

```powershell
# Imposta permessi chiave SSH
icacls C:\Users\TuoNome\.ssh\oracle-vm-key.pem /inheritance:r
icacls C:\Users\TuoNome\.ssh\oracle-vm-key.pem /grant:r "%USERNAME%:R"

# Connetti SSH
ssh -i C:\Users\TuoNome\.ssh\oracle-vm-key.pem ubuntu@150.110.12.61
```

Sostituisci `150.110.12.61` con il tuo IP pubblico!

---

## 🖥️ Parte 4: Installazione Ubuntu Desktop + XRDP

Una volta connesso via SSH, esegui questi comandi **in ordine**:

### 1. Update Sistema
```bash
sudo apt update && sudo apt upgrade -y
```

### 2. Installa Ubuntu Desktop (15-20 minuti)
```bash
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ubuntu-desktop-minimal
```

### 3. Installa XRDP
```bash
sudo apt install -y xrdp xorgxrdp
```

### 4. Configura XRDP
```bash
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
```

### 5. Crea Utente Desktop
```bash
sudo useradd -m -s /bin/bash produser
echo "produser:YourStrongPassword123!" | sudo chpasswd
sudo usermod -aG sudo produser
```

**Cambia `YourStrongPassword123!` con una password sicura!**

### 6. Configura Sessione GNOME
```bash
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession
```

### 7. Configura startwm.sh
```bash
sudo bash -c 'cat > /etc/xrdp/startwm.sh << "EOF"
#!/bin/sh
if [ -r /etc/default/locale ]; then
  . /etc/default/locale
  export LANG LANGUAGE
fi
if [ -f /home/$USER/.xsession ]; then
  . /home/$USER/.xsession
else
  exec /usr/bin/gnome-session
fi
EOF'
sudo chmod +x /etc/xrdp/startwm.sh
```

### 8. Fix Config per IPv4
```bash
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
```

### 9. Restart XRDP
```bash
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman
```

### 10. Verifica XRDP
```bash
sudo systemctl status xrdp --no-pager
sudo netstat -tulpn | grep 3389
```

Dovresti vedere:
```
tcp  0  0  0.0.0.0:3389  0.0.0.0:*  LISTEN  xxxxx/xrdp
```

---

## 🎯 Parte 5: Connessione Remote Desktop

### Windows

1. Premi `Win + R`
2. Scrivi: `mstsc`
3. Premi Enter
4. **Computer**: `150.110.12.61` (il tuo IP pubblico)
5. Click **"Connect"**
6. **Username**: `produser`
7. **Password**: `YourStrongPassword123!` (quella che hai impostato)
8. Click **"OK"**

### Se Appare Avviso Certificato
- Click **"Yes"** o **"Sì"**

---

## ✅ Verifica Finale

Dovresti vedere il desktop Ubuntu GNOME! 🎉

---

## 🔧 Troubleshooting

### SSH Connection Timed Out

**Causa**: Firewall non propagato o Route Table non associata

**Soluzione**:
1. Aspetta 5-10 minuti (le regole Oracle impiegano tempo)
2. Verifica Security List abbia porta 22 aperta
3. Verifica Subnet usi Route Table `rt-public-prod`
4. Verifica Route Table abbia regola `0.0.0.0/0` → Internet Gateway

### RDP Non Si Connette

**Causa**: XRDP non in ascolto su IPv4

**Soluzione**:
```bash
# Verifica XRDP
sudo netstat -tulpn | grep 3389

# Se non vedi 0.0.0.0:3389, riapplica fix
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
sudo systemctl restart xrdp
```

### Schermo Nero dopo Login RDP

**Causa**: Sessione GNOME non configurata

**Soluzione**:
```bash
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession
```

---

## 💰 Costi Oracle Cloud Free Tier

| Risorsa | Quantità | Costo |
|---------|----------|-------|
| VM ARM Ampere | 4 OCPU, 24 GB RAM | **GRATIS per sempre** |
| Storage | 200 GB | **GRATIS per sempre** |
| Traffico | 10 TB/mese | **GRATIS per sempre** |
| IP Pubblico | 1 | **GRATIS per sempre** |

**Totale: €0/mese!** 🎉

---

## 📝 Note Importanti

1. **Non eliminare la VCN di default**: Oracle crea una VCN di default, puoi usarla o crearne una nuova
2. **Backup chiavi SSH**: Salva le chiavi SSH in un posto sicuro, senza non puoi più accedere!
3. **Firewall interno**: Ubuntu ha `ufw` disabilitato di default, se lo abiliti ricorda di aprire porte 22 e 3389
4. **Aggiornamenti**: Esegui `sudo apt update && sudo apt upgrade -y` regolarmente
5. **Snapshot**: Oracle Free Tier include snapshot gratuiti, usali per backup!

---

## 🚀 Prossimi Passi

Dopo aver configurato Ubuntu Desktop:

1. Installa Docker: `sudo apt install -y docker.io docker-compose`
2. Installa Git: `sudo apt install -y git`
3. Installa VS Code: Scarica da https://code.visualstudio.com/
4. Configura Azure DevOps / GitHub
5. Clone repository progetto

---

## 📚 Risorse Utili

- [Oracle Cloud Free Tier](https://www.oracle.com/cloud/free/)
- [Oracle Cloud Documentation](https://docs.oracle.com/en-us/iaas/Content/home.htm)
- [XRDP Documentation](http://xrdp.org/)
- [Ubuntu Server Guide](https://ubuntu.com/server/docs)

---

**Creato il**: 2026-01-25  
**Ultima modifica**: 2026-01-25  
**Versione**: 1.0


