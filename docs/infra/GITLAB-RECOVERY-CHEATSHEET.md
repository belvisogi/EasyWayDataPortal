# GitLab Recovery - Cheat Sheet (1 Pagina)

## 🚨 Emergenza: Server GitLab Down

**Tempo recovery**: 30 minuti | **Difficoltà**: ⭐⭐ Facile

---

## ⚡ Quick Start (5 Comandi)

### 1. Accedi al nuovo server
```bash
ssh -i "ssh-key.key" ubuntu@NUOVO_IP
```

### 2. Crea directory
```bash
mkdir -p ~/gitlab/{config,logs,data} ~/backups/gitlab
```

### 3. Upload docker-compose.yml (dal tuo PC)
```powershell
scp -i "ssh-key.key" docker-compose.gitlab.yml ubuntu@NUOVO_IP:~/
```

### 4. Avvia GitLab (sul server)
```bash
docker compose -f docker-compose.gitlab.yml up -d
sleep 180  # Aspetta 3 minuti
```

### 5. Ottieni password
```bash
docker exec easyway-gitlab cat /etc/gitlab/initial_root_password
```

**Accedi**: `http://NUOVO_IP:8929` (user: `root`)

---

## 🔧 Troubleshooting Rapido

| Errore | Fix |
|--------|-----|
| `docker-compose: command not found` | Usa `docker compose` (con spazio) |
| Container restart loop | `docker logs easyway-gitlab --tail 50` |
| UI non accessibile | `sudo ufw allow 8929/tcp` |
| Password non funziona | Riottieni con comando Step 5 |

---

## 📋 Verifica Successo

```bash
docker ps | grep gitlab  # 2 container running
docker exec easyway-gitlab gitlab-ctl status  # 15 servizi "run"
```

**Fatto!** GitLab operativo.

---

**File necessari**: `docker-compose.gitlab.yml` (in `c:\old\EasyWayDataPortal`)  
**Docs complete**: `docs/infra/gitlab-setup-guide.md`
