---
id: ew-archive-imported-docs-2026-01-30-infra-oracle-quick-start
title: ⚡ QUICK START - Oracle VM (dev edition)
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
# ⚡ QUICK START - Oracle VM (dev edition)

## 🎯 Dati di Accesso
- **VM Name**: `vm-easyway-dev`
- **IP Pubblico**: `80.225.86.168`
- **Stato**: ✅ Running

## 🚀 1. Connetti SSH (Subito)
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@80.225.86.168
```

## 🖥️ 2. Installa Desktop (Copia nel terminale SSH)
```bash
# Copia e incolla questo blocco intero:
sudo apt update && sudo apt upgrade -y
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ubuntu-desktop-minimal xrdp xorgxrdp
sudo adduser xrdp ssl-cert
sudo useradd -m -s /bin/bash produser
echo "produser:EasyWay2026!" | sudo chpasswd
sudo usermod -aG sudo produser
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
sudo systemctl restart xrdp
```

## 🔌 3. Connetti RDP (Fra 15 min)
- **Host**: `80.225.86.168`
- **User**: `produser`
- **Pass**: `EasyWay2026!`

---
**Documento correlato**: vedi snapshot in `docs/infra/ORACLE_ENV_DOC.md`

*Documento aggiornato automaticamente il 2026-01-25*


