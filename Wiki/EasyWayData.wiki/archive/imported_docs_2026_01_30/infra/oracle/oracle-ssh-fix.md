---
id: ew-archive-imported-docs-2026-01-30-infra-oracle-oracle-ssh-fix
title: Oracle Cloud SSH Connection Fix
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
# Oracle Cloud SSH Connection Fix

## 🔴 Problema: SSH Connection Timed Out

Hai configurato correttamente:
- ✅ Security List con porta 22 aperta
- ✅ Route Table con 0.0.0.0/0 → Internet Gateway
- ✅ Subnet pubblica
- ✅ IP pubblico assegnato

**Ma SSH non funziona!** ❌

## 🎯 Causa Principale

**Ubuntu su Oracle Cloud ha un firewall interno (iptables) che blocca tutto per default!**

Anche se la Security List Oracle permette porta 22, il firewall interno di Ubuntu la blocca.

---

## 🔧 Soluzione: Usa Oracle Cloud Console

Non puoi connetterti via SSH, quindi devi usare la **Console seriale** di Oracle Cloud.

### Passo 1: Accedi alla Console della VM

1. Vai su **Oracle Cloud Console**
2. **Compute** → **Instances**
3. Click sulla tua VM: `vm-easyway-prod`
4. Scroll down fino a **Resources** (menu sinistra)
5. Click su **Console Connection**

### Passo 2: Crea Console Connection

Se non hai già una console connection:

1. Click **"Create Console Connection"**
2. **Upload SSH Key**: Carica la tua chiave pubblica
   - Usa la stessa chiave: `C:\old\Virtual-machine\ssh-key-2026-01-25.key.pub`
   - Se non hai il file `.pub`, generalo:
     ```powershell
     ssh-keygen -y -f C:\old\Virtual-machine\ssh-key-2026-01-25.key > C:\old\Virtual-machine\ssh-key-2026-01-25.key.pub
     ```
3. Click **"Create Console Connection"**
4. Aspetta che lo stato diventi **"Active"** (1-2 minuti)

### Passo 3: Connetti alla Console

1. Click sui **tre puntini** (⋮) della console connection
2. Click **"Connect with SSH"**
3. Copia il comando SSH mostrato, sarà simile a:
   ```bash
   ssh -i <privateKey> -o ProxyCommand='ssh -i <privateKey> -W %h:%p -p 443 ocid1.instanceconsoleconnection.oc1...@instance-console.eu-frankfurt-1.oci.oraclecloud.com' ocid1.instance.oc1...
   ```

4. **Apri PowerShell** e incolla il comando, sostituendo `<privateKey>` con il percorso della tua chiave:
   ```powershell
   ssh -i C:\old\Virtual-machine\ssh-key-2026-01-25.key -o ProxyCommand='ssh -i C:\old\Virtual-machine\ssh-key-2026-01-25.key -W %h:%p -p 443 ocid1.instanceconsoleconnection.oc1...@instance-console.eu-frankfurt-1.oci.oraclecloud.com' ocid1.instance.oc1...
   ```

5. Premi **Enter** più volte finché non vedi il prompt di login
6. Login:
   - **Username**: `ubuntu`
   - **Password**: Non c'è! Premi **Ctrl+C** e usa questo metodo alternativo:

### Passo 4: Usa Launch Cloud Shell Console (Più Facile!)

**Metodo alternativo più semplice:**

1. Nella pagina della VM, sotto **Console Connection**
2. Click **"Launch Cloud Shell Console"** (icona terminale)
3. Si apre una console web nel browser
4. Premi **Enter** più volte
5. Login come `ubuntu` (potrebbe non chiedere password)

---

## 🛠️ Passo 5: Fix Firewall Ubuntu

Una volta dentro la console, esegui questi comandi:

### 1. Verifica Firewall Attuale
```bash
sudo iptables -L -n -v
```

Vedrai regole che bloccano tutto.

### 2. Apri Porta SSH (22)
```bash
sudo iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
```

### 3. Apri Porta RDP (3389)
```bash
sudo iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT
```

### 4. Salva Regole Permanentemente
```bash
sudo netfilter-persistent save
```

Se il comando sopra non funziona:
```bash
sudo apt update
sudo apt install -y iptables-persistent
# Durante installazione, rispondi "Yes" per salvare regole IPv4 e IPv6
```

Poi salva di nuovo:
```bash
sudo netfilter-persistent save
```

### 5. Verifica Regole
```bash
sudo iptables -L -n -v | grep -E "22|3389"
```

Dovresti vedere:
```
ACCEPT  tcp  --  *  *  0.0.0.0/0  0.0.0.0/0  tcp dpt:22
ACCEPT  tcp  --  *  *  0.0.0.0/0  0.0.0.0/0  tcp dpt:3389
```

---

## ✅ Passo 6: Testa SSH da PowerShell

Ora prova a connetterti via SSH normale:

```powershell
ssh -i C:\old\Virtual-machine\ssh-key-2026-01-25.key ubuntu@150.110.12.61
```

**Dovrebbe funzionare!** 🎉

---

## 🖥️ Passo 7: Installa Ubuntu Desktop + XRDP

Una volta connesso via SSH, segui la guida in `oracle-ubuntu-desktop-setup.md` dalla **Parte 4**.

### Script Automatico Completo

Puoi copiare tutto questo blocco e incollarlo nella sessione SSH:

```bash
#!/bin/bash
set -e

echo "🚀 Installazione Ubuntu Desktop + XRDP..."

# 1. Update sistema
echo "📦 Aggiornamento sistema..."
sudo apt update && sudo apt upgrade -y

# 2. Installa Ubuntu Desktop
echo "🖥️ Installazione Ubuntu Desktop (15-20 minuti)..."
export DEBIAN_FRONTEND=noninteractive
sudo apt install -y ubuntu-desktop-minimal

# 3. Installa XRDP
echo "🔧 Installazione XRDP..."
sudo apt install -y xrdp xorgxrdp

# 4. Configura XRDP
echo "⚙️ Configurazione XRDP..."
sudo adduser xrdp ssl-cert
sudo systemctl enable xrdp
sudo systemctl enable xrdp-sesman

# 5. Crea utente desktop
echo "👤 Creazione utente produser..."
sudo useradd -m -s /bin/bash produser
echo "produser:EasyWay2026!" | sudo chpasswd
sudo usermod -aG sudo produser

# 6. Configura sessione GNOME
echo "🎨 Configurazione GNOME..."
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession

# 7. Configura startwm.sh
echo "📝 Configurazione startwm.sh..."
sudo bash -c 'cat > /etc/xrdp/startwm.sh <<EOF
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

# 8. Fix config per IPv4
echo "🔧 Fix IPv4..."
sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini

# 9. Apri porta 3389 nel firewall
echo "🔥 Apertura porta 3389 nel firewall..."
sudo iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT
sudo netfilter-persistent save

# 10. Restart XRDP
echo "🔄 Restart XRDP..."
sudo systemctl restart xrdp
sudo systemctl restart xrdp-sesman

# 11. Verifica
echo "✅ Verifica installazione..."
sudo systemctl status xrdp --no-pager
sudo netstat -tulpn | grep 3389

echo ""
echo "🎉 Installazione completata!"
echo ""
echo "📋 Credenziali RDP:"
echo "   IP: 150.110.12.61"
echo "   Username: produser"
echo "   Password: EasyWay2026!"
echo ""
echo "🔌 Connettiti con Remote Desktop (mstsc)"
```

**Nota**: La password è `EasyWay2026!` - cambiala dopo il primo login!

---

## 🎯 Connessione Remote Desktop

1. Premi `Win + R`
2. Scrivi: `mstsc`
3. **Computer**: `150.110.12.61`
4. **Username**: `produser`
5. **Password**: `EasyWay2026!`

---

## 📝 Checklist Completa

- [ ] Accesso a Oracle Cloud Console
- [ ] Creazione Console Connection
- [ ] Connessione via Cloud Shell Console
- [ ] Fix firewall iptables (porta 22 e 3389)
- [ ] Salvataggio regole con netfilter-persistent
- [ ] Test SSH da PowerShell
- [ ] Installazione Ubuntu Desktop
- [ ] Installazione XRDP
- [ ] Configurazione utente produser
- [ ] Test connessione RDP

---

## 🔍 Comandi Diagnostici Utili

### Verifica Security List Oracle
```bash
# Dalla console Oracle, verifica che ci siano regole per:
# - Porta 22 (SSH)
# - Porta 3389 (RDP)
```

### Verifica Firewall Ubuntu
```bash
sudo iptables -L -n -v
```

### Verifica Porte in Ascolto
```bash
sudo netstat -tulpn | grep -E "22|3389"
```

### Verifica XRDP
```bash
sudo systemctl status xrdp
sudo systemctl status xrdp-sesman
```

### Log XRDP
```bash
sudo tail -f /var/log/xrdp.log
sudo tail -f /var/log/xrdp-sesman.log
```

---

## ⚠️ Troubleshooting

### Console Connection Non Si Crea
- Aspetta 2-3 minuti
- Ricarica la pagina
- Verifica che la VM sia in stato "Running"

### Cloud Shell Console Non Risponde
- Premi **Enter** più volte
- Aspetta 30 secondi
- Prova a digitare `ubuntu` e premere Enter

### iptables-persistent Non Salva
```bash
# Salva manualmente
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
```

### XRDP Schermo Nero
```bash
# Riconfigura sessione
echo "gnome-session" | sudo tee /home/produser/.xsession
sudo chown produser:produser /home/produser/.xsession
sudo chmod +x /home/produser/.xsession
sudo systemctl restart xrdp
```

---

**Creato il**: 2026-01-25  
**Versione**: 1.0  
**Stato**: Ready to Execute


