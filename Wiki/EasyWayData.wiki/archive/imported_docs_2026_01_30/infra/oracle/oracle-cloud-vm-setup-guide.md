# Oracle Cloud - Guida Completa Setup VM Ubuntu Desktop + RDP (Versione 2.0)

> **Aggiornamento 25/01/2026**: Introdotto metodo **Cloud-Init** per risolvere il blocco firewall alla radice.

---

## 🏆 Procedura "Zero Problemi"

Segui questi passi precisi per creare una VM perfetta.

### 1. Configurazione Iniziale
- **Image**: Canonical Ubuntu 24.04
- **Shape**: VM.Standard.A1.Flex (Ampere ARM) - 4 OCPU, 24 GB RAM
- **Networking**: Seleziona VCN esistente con Subnet Pubblica
- **Public IP**: Assicurati che "Assign a public IPv4 address" sia **CHECKED**

### 2. Il Passo Cruciale: Cloud-Init
Nella sezione di creazione VM, in basso:
1. Espandi **Advanced Options**
2. Vai nel tab **Management**
3. Seleziona **Paste cloud-init script**
4. Incolla questo blocco esatto:

```yaml
#cloud-config
runcmd:
  - iptables -I INPUT 1 -p tcp --dport 22 -j ACCEPT
  - iptables -I INPUT 1 -p tcp --dport 3389 -j ACCEPT
  - iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
  - apt-get update
  - DEBIAN_FRONTEND=noninteractive apt-get install -y iptables-persistent
  - netfilter-persistent save
```

> **Perché?** Questo apre le porte SSH (22) e RDP (3389) *prima* che la VM finisca il boot, aggirando il blocco di default di Oracle.

---

### 3. Primo Accesso e Installazione Desktop
Appena la VM è "Running":

1. **Connetti via SSH**:
   ```powershell
   ssh -i "tua-chiave.key" ubuntu@IP-DELLA-VM
   ```
   *Se hai usato lo script sopra, entrerai subito senza timeout!*

2. **Installa Desktop e XRDP** (Copia-incolla tutto in blocco):
   ```bash
   sudo apt update && sudo apt upgrade -y
   export DEBIAN_FRONTEND=noninteractive
   sudo apt install -y ubuntu-desktop-minimal xrdp xorgxrdp
   sudo adduser xrdp ssl-cert
   sudo systemctl enable xrdp && sudo systemctl enable xrdp-sesman
   
   # Crea utente desktop
   sudo useradd -m -s /bin/bash produser
   echo "produser:EasyWay2026!" | sudo chpasswd
   sudo usermod -aG sudo produser
   
   # Configura sessione
   echo "gnome-session" | sudo tee /home/produser/.xsession
   sudo chown produser:produser /home/produser/.xsession
   sudo chmod +x /home/produser/.xsession
   
   # Configura startwm.sh per evitare schermo nero
   sudo bash -c 'cat > /etc/xrdp/startwm.sh <<EOF
   #!/bin/sh
   if [ -r /etc/default/locale ]; then . /etc/default/locale; export LANG LANGUAGE; fi
   if [ -f /home/\$USER/.xsession ]; then . /home/\$USER/.xsession; else exec /usr/bin/gnome-session; fi
   EOF'
   sudo chmod +x /etc/xrdp/startwm.sh
   
   # Fix Porta 3389
   sudo sed -i 's/^port=.*/port=tcp:\/\/:3389/' /etc/xrdp/xrdp.ini
   sudo systemctl restart xrdp
   ```

3. **Connetti via RDP**:
   - Apri **Remote Desktop Connection** (mstsc)
   - IP: `IP-DELLA-VM`
   - User: `produser`
   - Pass: `EasyWay2026!`

---

## 🔧 Troubleshooting

### SSH Timeout?
Se ottieni "Connection timed out" sulla porta 22:
- **Causa**: Hai dimenticato lo script Cloud-Init durante la creazione.
- **Soluzione**: Devi ricreare la VM (più veloce) oppure usare la tortuosa procedura via Cloud Shell Console.

### Schermo Nero in RDP?
- **Causa**: XRDP non sa quale sessione avviare.
- **Soluzione**: Verifica di aver creato il file `.xsession` e `startwm.sh` come mostrato nello script sopra.

### Password Rifiutata?
- Le tastiere in RDP a volte fanno scherzi. Prova a scrivere la password `EasyWay2026!` in un notepad locale e copiala, oppure digitala con molta attenzione.

---

**Versione Guida**: 2.0 (Cloud-Init Edition)
**Stato**: Verificato su vm-easyway-dev
