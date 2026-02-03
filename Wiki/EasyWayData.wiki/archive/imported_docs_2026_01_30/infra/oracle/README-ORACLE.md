---
id: ew-archive-imported-docs-2026-01-30-infra-oracle-readme-oracle
title: 📚 Oracle Cloud VM - Documentazione "Golden Path"
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
---
# 📚 Oracle Cloud VM - Documentazione "Golden Path"

> **Metodo Definitivo Testato (2026-01-25)**
> Questa guida contiene il metodo **vincente** per creare VM Oracle Cloud funzionanti al primo colpo, evitando i problemi di firewall.

---

## 🏆 Il Segreto: Cloud-Init Script

Il problema principale delle VM Oracle Cloud Ubuntu è che nascono con il firewall chiuso. 
**La soluzione** è inserire questo script nella sezione **"Advanced Options"** → **"Management"** durante la creazione.

### 📜 Lo Script Magico (Copia e Incolla)

```yaml
#cloud-config
runcmd:
  # Apre le porte nel firewall interno PRIMA del primo avvio
  - iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
  - iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT
  - iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
  - iptables -I INPUT 1 -p tcp --dport 443 -j ACCEPT
  # Aggiorna e rende le regole persistenti
  - apt-get update
  - DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
  - netfilter-persistent save
  - systemctl enable netfilter-persistent
```

---

## 🚀 Procedura Creazione VM (Golden Path)

1. **Nome**: `vm-easyway-dev` (o tua scelta)
2. **Image**: Ubuntu 24.04
3. **Shape**: VM.Standard.A1.Flex (4 OCPU, 24 GB RAM)
4. **Networking**: 
   - Seleziona VCN esistente (`vcn-ew-dev`)
   - Seleziona Subnet Pubblica
   - **IMPORTANTE**: "Assign a public IPv4 address" = **YES**
5. **SSH Keys**: Carica la tua chiave pubblica (`.pub`)
6. **Advanced Options** (IN BASSO):
   - Vai su **Management**
   - Initialization script: **Paste cloud-init script**
   - **INCOLLA LO SCRIPT SOPRA** 👆
7. **Create!**

Risultato: **SSH Funziona subito!** ✅

---

## 🖥️ Installazione Desktop (Post-Creazione)

Una volta entrato via SSH (`ssh -i key.key ubuntu@IP`), esegui questo comando unico per installare il desktop:

```bash
# Script automatico installazione Desktop + RDP
cat << 'EOF' > install_desktop.sh
#!/bin/bash
set -e
echo "🚀 INSTALLING UBUNTU DESKTOP & XRDP..."
sudo apt update && sudo apt upgrade -y
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ubuntu-desktop-minimal xrdp xorgxrdp
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman
sudo useradd -m -s /bin/bash produser
echo "produser:EasyWay2026!" | sudo chpasswd
sudo usermod -aG sudo produser
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession
sudo bash -c 'cat > /etc/xrdp/startwm.sh <<END
#!/bin/sh
if [ -r /etc/default/locale ]; then . /etc/default/locale; export LANG LANGUAGE; fi
if [ -f /home/\$USER/.xsession ]; then . /home/\$USER/.xsession; else exec /usr/bin/gnome-session; fi
END'
sudo chmod +x /etc/xrdp/startwm.sh
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
sudo systemctl restart xrdp
echo "✅ DONE! Connect with RDP now!"
EOF

bash install_desktop.sh
```

---

## 📊 Dati Attuali (vm-easyway-dev)

- **IP Pubblico**: `80.225.86.168`
- **Utente SSH**: `ubuntu`
- **Utente RDP**: `produser`
- **Password RDP**: `EasyWay2026!`
- **Stato**: ✅ Running & Port 22 Open

---

## 📂 File nella Cartella

| File | Descrizione |
|------|-------------|
| `README-ORACLE.md` | Questo file (Best Practices) |
| `oracle-cloud-vm-setup-guide.md` | Guida dettagliata passo-passo |
| `oracle-ssh-test.ps1` | Script diagnostico connessione |
| `oracle-vm-connect.ps1` | Manager connessioni SSH/RDP |

---

**Creato il**: 2026-01-25  
**Stato**: Verified & Working 🏆


