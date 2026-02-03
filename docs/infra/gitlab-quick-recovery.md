---
id: gitlab-quick-recovery
title: GitLab Recovery - Guida Umana (5 Minuti)
summary: Procedura semplificata per ricreare GitLab su nuovo server senza conoscenze tecniche avanzate
tags: [domain/infra, layer/runbook, audience/ops, privacy/internal, language/it]
status: active
owner: team-platform
updated: 2026-02-03
llm:
  include: true
  pii: none
  chunk_hint: 300-500
entities: [GitLab, Disaster Recovery]
---

# GitLab Recovery - Guida Umana

> **Per**: Chiunque debba ricreare GitLab su nuovo server  
> **Tempo**: 30-45 minuti  
> **Difficoltà**: ⭐⭐ (Facile, copia-incolla comandi)

---

## 🎯 Cosa Serve

### Prerequisiti
- [ ] Nuovo server Ubuntu (minimo 8 GB RAM, 50 GB storage)
- [ ] Docker installato sul server
- [ ] SSH key per accedere al server
- [ ] File `docker-compose.gitlab.yml` (in `c:\old\EasyWayDataPortal`)

**Non serve**:
- ❌ Conoscenze Docker avanzate
- ❌ Esperienza GitLab
- ❌ Programmazione

---

## 📋 Procedura Step-by-Step

### Step 1: Accedi al Nuovo Server

**Dal tuo PC Windows** (PowerShell):
```powershell
ssh -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" ubuntu@NUOVO_IP
```

**Sostituisci**: `NUOVO_IP` con l'IP del nuovo server (es. `80.225.86.168`)

**Aspettati**: Prompt del server `ubuntu@server:~$`

---

### Step 2: Crea le Directory

**Sul server** (copia-incolla questo blocco):
```bash
mkdir -p ~/gitlab/config
mkdir -p ~/gitlab/logs
mkdir -p ~/gitlab/data
mkdir -p ~/backups/gitlab
```

**Verifica** (opzionale):
```bash
ls -la ~/gitlab
```

**Aspettati**: Vedi 3 cartelle (config, logs, data)

---

### Step 3: Carica il File Docker Compose

**Dal tuo PC** (nuova finestra PowerShell):
```powershell
cd C:\old\EasyWayDataPortal
scp -i "C:\old\Virtual-machine\ssh-key-2026-01-25.key" docker-compose.gitlab.yml ubuntu@NUOVO_IP:~/
```

**Sostituisci**: `NUOVO_IP` con l'IP del server

**Aspettati**: `docker-compose.gitlab.yml 100% 2821`

---

### Step 4: Avvia GitLab

**Sul server**:
```bash
cd ~
docker compose -f docker-compose.gitlab.yml up -d
```

**⚠️ IMPORTANTE**: Usa `docker compose` (con spazio), NON `docker-compose` (con trattino)

**Aspettati**:
```
Network ubuntu_gitlab Created
Container easyway-gitlab Created
Container easyway-gitlab Started
```

---

### Step 5: Aspetta l'Inizializzazione (3-5 minuti)

**Sul server**:
```bash
echo "Aspetto 3 minuti..."
sleep 180
```

**Cosa succede**: GitLab si sta configurando (database, servizi, ecc.)

**Puoi monitorare** (opzionale):
```bash
docker logs -f easyway-gitlab
```

**Aspetta di vedere**: `gitlab Reconfigured!`

**Esci dai log**: Premi `Ctrl+C`

---

### Step 6: Ottieni la Password Root

**Sul server**:
```bash
docker exec easyway-gitlab cat /etc/gitlab/initial_root_password
```

**Aspettati**:
```
Password: mzLLZFO09gnxwmgcL1HVze3b2RDxUncxN9CL4+790bE=
```

**⚠️ IMPORTANTE**: Copia questa password! Scade dopo 24 ore.

---

### Step 7: Verifica che Funzioni

**Sul server**:
```bash
docker ps | grep gitlab
```

**Aspettati**: 2 container in esecuzione
- `easyway-gitlab`
- `easyway-gitlab-runner`

**Verifica servizi**:
```bash
docker exec easyway-gitlab gitlab-ctl status
```

**Aspettati**: Tutti i servizi con `run:` (15 servizi)

---

### Step 8: Accedi all'Interfaccia Web

**Dal tuo browser**:
```
http://NUOVO_IP:8929
```

**Login**:
- Username: `root`
- Password: (quella copiata allo Step 6)

**Aspettati**: Dashboard GitLab

---

## ✅ Fatto! GitLab è Operativo

**Prossimi step** (opzionali ma consigliati):
1. Cambia password root (Profile → Password)
2. Crea utente admin (Admin Area → Users → New user)
3. Disabilita registrazioni (Admin Area → Settings → Sign-up restrictions)

---

## 🐛 Problemi Comuni

### Problema 1: "docker-compose: command not found"

**Errore**:
```
bash: docker-compose: command not found
```

**Soluzione**: Usa `docker compose` (con spazio), non `docker-compose`

---

### Problema 2: Container si riavvia continuamente

**Verifica**:
```bash
docker ps -a | grep gitlab
# Status: Restarting
```

**Soluzione**:
```bash
# Guarda i log
docker logs easyway-gitlab --tail 50

# Se vedi errori di configurazione, contatta il team
```

---

### Problema 3: Non riesco ad accedere alla UI

**Verifica**:
```bash
# Controlla che il container sia attivo
docker ps | grep gitlab

# Controlla il firewall
sudo ufw status
```

**Soluzione**:
```bash
# Apri la porta 8929
sudo ufw allow 8929/tcp
```

---

### Problema 4: Password non funziona

**Soluzione**:
```bash
# Ottieni nuovamente la password
docker exec easyway-gitlab cat /etc/gitlab/initial_root_password

# Se il file non esiste (>24 ore), resetta la password:
# https://docs.gitlab.com/security/reset_user_password/
```

---

## 📞 Aiuto Aggiuntivo

### Documentazione Completa
- **Setup dettagliato**: `docs/infra/gitlab-setup-guide.md`
- **Troubleshooting**: `docs/infra/gitlab-qa.md`
- **Walkthrough deployment**: `gitlab-deployment-walkthrough.md` (artifacts)

### Comandi Utili

**Fermare GitLab**:
```bash
docker compose -f docker-compose.gitlab.yml down
```

**Riavviare GitLab**:
```bash
docker compose -f docker-compose.gitlab.yml restart
```

**Vedere i log**:
```bash
docker logs easyway-gitlab --tail 100
```

**Backup manuale**:
```bash
docker exec easyway-gitlab gitlab-backup create
```

---

## 🎓 Cosa Hai Imparato

Dopo questa procedura, hai:
- ✅ Creato un'istanza GitLab self-managed
- ✅ Configurato storage persistente
- ✅ Ottenuto accesso amministrativo
- ✅ Verificato che tutti i servizi funzionino

**Tempo impiegato**: ~30-45 minuti

**Difficoltà**: Facile (copia-incolla comandi)

---

## 📝 Checklist Finale

Prima di considerare il lavoro completato:

- [ ] GitLab UI accessibile (`http://NUOVO_IP:8929`)
- [ ] Login come root funziona
- [ ] Password root cambiata
- [ ] Utente admin creato
- [ ] Registrazioni disabilitate
- [ ] Backup automatico configurato (opzionale)
- [ ] GitLab Runner registrato (opzionale)

---

**Creato**: 2026-02-03  
**Testato**: ✅ Su server 80.225.86.168  
**Tempo recovery**: < 1 ora  
**Successo**: 100% (se segui i passaggi)
