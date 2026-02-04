---
id: ew-archive-imported-docs-2026-01-30-project-root-anti-philosophy-starter-kit
title: 🚀 Anti-Philosophy Starter Kit
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
# 🚀 Anti-Philosophy Starter Kit

**Obiettivo**: Deploy EasyWay in produzione in 7 giorni. Zero filosofia, solo esecuzione.

---

## 📋 Checklist 7 Giorni

### Giorno 1 (Oggi): Setup Infrastruttura

#### ✅ Task 1.1: Crea Account Hetzner (10 minuti)

1. Vai su https://console.hetzner.cloud/
2. Registrati con email + carta di credito
3. Verifica email
4. Accedi al pannello

#### ✅ Task 1.2: Ordina Server (5 minuti)

```
Location: Nuremberg (Germania)
Image: Ubuntu 22.04
Type: CPX31 (4 vCPU, 8GB RAM) - €13.10/mese
SSH Key: [Genera o usa esistente]
Name: easyway-prod
```

Click "Create & Buy Now"

#### ✅ Task 1.3: Salva Credenziali

Riceverai email con:
```
IP: 95.217.xxx.xxx
Password: xxxxxxxxx
```

Salvale in un posto sicuro (es: Azure Key Vault o password manager)

**Tempo totale Giorno 1**: 15 minuti  
**Costo**: €0.44 (1 giorno × €13.10/30)

---

### Giorno 2: Setup Sistema Operativo

#### ✅ Task 2.1: Primo Accesso (5 minuti)

```powershell
# Dal tuo PC Windows
ssh root@95.217.xxx.xxx

# Inserisci password dalla email
# Ti chiederà di cambiarla
```

#### ✅ Task 2.2: Setup Automatico (10 minuti)

```bash
# Sul server Hetzner, copia-incolla questo script

#!/bin/bash
set -e

echo "🚀 Setup EasyWay - Anti-Philosophy Edition"

# Update sistema
apt update && apt upgrade -y

# Installa Docker
curl -fsSL https://get.docker.com | sh

# Installa Docker Compose
apt install docker-compose-plugin -y

# Installa PowerShell
snap install powershell --classic

# Installa Git
apt install git -y

# Installa Hetzner CLI (per gestione da PC)
snap install hcloud

echo "✅ Setup base completato!"
```

Salva come `setup.sh`, poi:
```bash
chmod +x setup.sh
./setup.sh
```

**Tempo totale Giorno 2**: 15 minuti  
**Costo cumulativo**: €0.88

---

### Giorno 3: Deploy Stack

#### ✅ Task 3.1: Clona Repository (5 minuti)

```bash
cd /root
git clone https://github.com/tuo-account/EasyWayDataPortal.git easyway
cd easyway
```

Se repository privato:
```bash
# Genera SSH key sul server
ssh-keygen -t ed25519 -C "easyway-prod"
cat ~/.ssh/id_ed25519.pub
# Copia output e aggiungi a GitHub → Settings → SSH Keys
```

#### ✅ Task 3.2: Configura Environment (5 minuti)

```bash
cd /root/easyway

# Crea .env
cat > .env << 'EOF'
# Azure SQL
AZURE_SQL_SERVER=your-server.database.windows.net
AZURE_SQL_DATABASE=EasyWayDataPortal
AZURE_SQL_USER=your-user
AZURE_SQL_PASSWORD=your-password

# LLM APIs
DEEPSEEK_API_KEY=sk-your-deepseek-key
OPENAI_API_KEY=sk-your-openai-key

# Configurazione
EASYWAY_MODE=Production
NODE_ENV=production
EOF

# Proteggi .env
chmod 600 .env
```

#### ✅ Task 3.3: Deploy Containers (10 minuti)

```bash
# Avvia stack
docker compose up -d

# Verifica
docker compose ps

# Dovresti vedere:
# easyway-runner    Up
# easyway-cortex    Up (ChromaDB)
# easyway-portal    Up (Frontend)
```

#### ✅ Task 3.4: Test Connessione (5 minuti)

```bash
# Test Azure SQL
docker exec easyway-runner pwsh -c "
  \$conn = New-Object System.Data.SqlClient.SqlConnection
  \$conn.ConnectionString = 'Server=your-server.database.windows.net;Database=EasyWayDataPortal;User ID=your-user;Password=your-password;Encrypt=true'
  \$conn.Open()
  Write-Host '✅ SQL Connection OK'
  \$conn.Close()
"

# Test ChromaDB
curl http://localhost:8000/api/v1/heartbeat
# Risposta: {"nanosecond heartbeat": ...}
```

**Tempo totale Giorno 3**: 25 minuti  
**Costo cumulativo**: €1.31

---

### Giorno 4: Primo Agente in Esecuzione

#### ✅ Task 4.1: Scegli UN Agente

**Raccomandazione**: `agent_ado_governance` (è il più semplice e utile)

```bash
cd /root/easyway/agents/agent_ado_governance
cat manifest.json
```

#### ✅ Task 4.2: Test Manuale (15 minuti)

```bash
docker exec -it easyway-runner pwsh

# In PowerShell container
cd /app/agents/agent_ado_governance

# Esegui manualmente
./run.ps1 -Action "ado:intent.resolve" -Intent "list work items"

# Verifica output
# Dovrebbe mostrare work items da Azure DevOps
```

#### ✅ Task 4.3: Registra in Database (10 minuti)

```bash
# Verifica che l'esecuzione sia stata loggata
docker exec easyway-runner pwsh -c "
  Invoke-Sqlcmd -ServerInstance 'your-server.database.windows.net' \
    -Database 'EasyWayDataPortal' \
    -Username 'your-user' \
    -Password 'your-password' \
    -Query 'SELECT TOP 5 * FROM AGENT_MGMT.agent_executions ORDER BY started_at DESC'
"
```

**Tempo totale Giorno 4**: 25 minuti  
**Costo cumulativo**: €1.75

---

### Giorno 5: Automazione

#### ✅ Task 5.1: Cron Job (10 minuti)

```bash
# Crea script di esecuzione automatica
cat > /root/easyway/run-agent-daily.sh << 'EOF'
#!/bin/bash
docker exec easyway-runner pwsh -c "
  cd /app/agents/agent_ado_governance
  ./run.ps1 -Action 'ado:intent.resolve' -Intent 'sync daily'
"
EOF

chmod +x /root/easyway/run-agent-daily.sh

# Aggiungi a crontab (esegui ogni giorno alle 9:00)
crontab -e
# Aggiungi: 0 9 * * * /root/easyway/run-agent-daily.sh
```

#### ✅ Task 5.2: Monitoring (10 minuti)

```bash
# Script per check status
cat > /root/easyway/check-status.sh << 'EOF'
#!/bin/bash
echo "🔍 EasyWay Status Check"
echo "======================="

# Containers
echo "📦 Containers:"
docker compose ps

# Disk space
echo -e "\n💾 Disk:"
df -h | grep -E '^/dev/'

# Last execution
echo -e "\n🤖 Last Agent Execution:"
docker exec easyway-runner pwsh -c "
  Invoke-Sqlcmd -ServerInstance 'your-server.database.windows.net' \
    -Database 'EasyWayDataPortal' \
    -Username 'your-user' \
    -Password 'your-password' \
    -Query 'SELECT TOP 1 agent_id, status, started_at FROM AGENT_MGMT.agent_executions ORDER BY started_at DESC'
"
EOF

chmod +x /root/easyway/check-status.sh
```

**Tempo totale Giorno 5**: 20 minuti  
**Costo cumulativo**: €2.19

---

### Giorno 6: Primo Utente

#### ✅ Task 6.1: Identifica Utente

Chi può usare EasyWay?
- Collega che usa Azure DevOps
- Te stesso (per un caso d'uso reale)
- Amico developer

#### ✅ Task 6.2: Setup Accesso (15 minuti)

```bash
# Esponi portal (con autenticazione!)
# Modifica docker-compose.yml per aggiungere nginx con basic auth

cat > /root/easyway/nginx.conf << 'EOF'
server {
    listen 80;
    
    location / {
        auth_basic "EasyWay Portal";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://easyway-portal:80;
    }
}
EOF

# Crea password
apt install apache2-utils -y
htpasswd -c /root/easyway/.htpasswd admin
# Inserisci password quando richiesto
```

#### ✅ Task 6.3: Raccogli Feedback (30 minuti)

Chiedi all'utente:
1. È riuscito ad accedere?
2. Il caso d'uso funziona?
3. Cosa non funziona?
4. Lo userebbe di nuovo?

**Documenta risposte** in `FEEDBACK_GIORNO_6.md`

**Tempo totale Giorno 6**: 45 minuti  
**Costo cumulativo**: €2.63

---

### Giorno 7: Checkpoint

#### ✅ Task 7.1: Verifica Metriche

```sql
-- Esegui query su Azure SQL
SELECT 
    COUNT(*) as total_executions,
    COUNT(DISTINCT agent_id) as active_agents,
    SUM(CASE WHEN status = 'success' THEN 1 ELSE 0 END) as successful,
    SUM(CASE WHEN status = 'failed' THEN 1 ELSE 0 END) as failed,
    AVG(DATEDIFF(second, started_at, completed_at)) as avg_duration_sec
FROM AGENT_MGMT.agent_executions
WHERE started_at >= DATEADD(day, -7, GETDATE());
```

#### ✅ Task 7.2: Decisione GO/NO-GO

| Metrica | Target | Reale | Status |
|---------|--------|-------|--------|
| Server uptime | >90% | ___% | ⏳ |
| Esecuzioni | >10 | ___ | ⏳ |
| Success rate | >70% | ___% | ⏳ |
| Utenti | ≥1 | ___ | ⏳ |

**Se tutte ✅ → Continua per altri 23 giorni**  
**Se anche una ❌ → Analizza e aggiusta**

#### ✅ Task 7.3: Commit Storico

```bash
cd /root/easyway
git add .
git commit -m "🎉 First 7 days in production - REAL EXECUTION!"
git tag v0.1.0-production
git push origin main --tags
```

**Tempo totale Giorno 7**: 30 minuti  
**Costo totale 7 giorni**: €3.06

---

## 🎯 Regole d'Oro (Ripetere ogni giorno)

1. ❌ **NO** nuovi documenti di design
2. ❌ **NO** nuovi agenti
3. ❌ **NO** refactoring "per bellezza"
4. ✅ **SÌ** fix bug bloccanti
5. ✅ **SÌ** log metriche
6. ✅ **SÌ** feedback utenti

---

## 📞 Comandi Utili dal Tuo PC

### Gestione Server

```powershell
# Accendi server (se spento)
hcloud server poweron easyway-prod

# Spegni server (per risparmiare)
hcloud server poweroff easyway-prod

# Status
hcloud server describe easyway-prod

# SSH rapido
ssh root@$(hcloud server ip easyway-prod)
```

### Check Status Remoto

```powershell
# Status containers
ssh root@easyway-prod "cd /root/easyway && docker compose ps"

# Logs
ssh root@easyway-prod "cd /root/easyway && docker compose logs -f --tail=50"

# Metriche DB
ssh root@easyway-prod "/root/easyway/check-status.sh"
```

---

## 🆘 Troubleshooting

### Container non parte

```bash
docker compose logs easyway-runner
# Leggi errori e aggiusta
```

### SQL Connection Failed

```bash
# Verifica firewall Azure SQL
# Aggiungi IP server Hetzner alla whitelist
```

### Disk pieno

```bash
# Pulisci Docker
docker system prune -a
```

---

## 📊 Costi Previsti

| Periodo | Costo |
|---------|-------|
| 7 giorni | €3.06 |
| 30 giorni | €13.10 |
| 90 giorni | €39.30 |

**Se non funziona dopo 7 giorni**: Cancella server, perdi €3.06, riprova.  
**Se funziona**: Continua, scala, celebra! 🎉

---

**Creato**: 2026-01-24  
**Versione**: 1.0 - Anti-Philosophy Edition  
**Motto**: "Done is better than perfect"


