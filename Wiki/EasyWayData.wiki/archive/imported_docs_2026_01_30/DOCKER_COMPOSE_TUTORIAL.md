---
id: ew-archive-imported-docs-2026-01-30-docker-compose-tutorial
title: Docker Compose per Principianti - Guida EasyWay
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
# Docker Compose per Principianti - Guida EasyWay

## 🎯 Cos'è Docker Compose?

**Immagina Docker come un "contenitore" per applicazioni.**

Invece di installare programmi sul tuo PC (che possono creare conflitti), Docker li mette in "scatole" separate.

**Docker Compose = Il regista che coordina più "scatole" insieme**

---

## 📦 Analogia Semplice

### Senza Docker (Metodo Tradizionale)

```
Il Tuo PC
├── Installi n8n (Node.js 18 richiesto)
├── Installi Qdrant (Rust richiesto)
├── Installi Ollama (CUDA drivers richiesti)
└── Conflitti! 💥
    - n8n vuole Node 18
    - Un altro programma vuole Node 16
    - Tutto si rompe!
```

### Con Docker Compose (Metodo Moderno)

```
Il Tuo PC
├── Docker Engine (solo questo da installare)
└── docker-compose.yml (file di configurazione)
    ├── Container n8n (ha tutto ciò che serve)
    ├── Container Qdrant (ha tutto ciò che serve)
    └── Container Ollama (ha tutto ciò che serve)
    
Nessun conflitto! Ogni container è isolato! ✅
```

---

## 🏗️ Anatomia del docker-compose.yml

### Struttura Base (Spiegata Riga per Riga)

```yaml
version: '3.8'  # Versione di Docker Compose (usa sempre 3.8)

services:  # Lista dei "container" (le nostre scatole)
  
  # CONTAINER 1: n8n
  n8n:  # Nome del container (puoi chiamarlo come vuoi)
    image: n8nio/n8n:latest  # Quale programma scaricare (da Docker Hub)
    container_name: easyway-n8n  # Nome visibile quando fai "docker ps"
    
    ports:  # Quali porte aprire
      - "5678:5678"  # Formato: "porta_tuo_pc:porta_container"
      # Significa: "Apri porta 5678 sul mio PC e collegala alla porta 5678 del container"
    
    environment:  # Variabili d'ambiente (come impostazioni)
      - N8N_BASIC_AUTH_USER=admin  # Username per accedere
      - N8N_BASIC_AUTH_PASSWORD=password123  # Password
    
    volumes:  # Dove salvare i dati (persistenza)
      - n8n_data:/home/node/.n8n  # "cartella_virtuale:cartella_container"
      # I dati di n8n vengono salvati in "n8n_data" (non si perdono se riavvii)
    
    restart: unless-stopped  # Riavvia automaticamente se crasha
    
    networks:  # Rete virtuale (per far parlare i container tra loro)
      - easyway-net

volumes:  # Definizione delle "cartelle virtuali"
  n8n_data:  # Docker crea questa cartella e la gestisce

networks:  # Definizione delle "reti virtuali"
  easyway-net:  # I container in questa rete possono parlarsi
    driver: bridge  # Tipo di rete (bridge = standard)
```

---

## 🎓 Spiegazione Dettagliata dei Concetti

### 1. **Image (Immagine)**

```yaml
image: n8nio/n8n:latest
```

**Cos'è?** Un "template" preconfezionato del programma.

**Analogia:** È come scaricare un'app dall'App Store.
- `n8nio/n8n` = Nome dell'app
- `latest` = Versione (latest = ultima disponibile)

**Dove si trova?** Docker Hub (come App Store per Docker)
- https://hub.docker.com/r/n8nio/n8n

### 2. **Ports (Porte)**

```yaml
ports:
  - "5678:5678"
```

**Cos'è?** Un "tunnel" tra il tuo PC e il container.

**Analogia:** Come il citofono di un palazzo.
- `5678` (sinistra) = Campanello esterno (tuo PC)
- `5678` (destra) = Appartamento interno (container)

**Esempio pratico:**
```yaml
ports:
  - "8080:5678"  # Accedi a http://localhost:8080 sul tuo PC
                 # Ma dentro il container gira sulla porta 5678
```

### 3. **Volumes (Volumi)**

```yaml
volumes:
  - n8n_data:/home/node/.n8n
```

**Cos'è?** Una "cartella condivisa" tra PC e container.

**Analogia:** Come Dropbox.
- I dati vengono salvati fuori dal container
- Se cancelli il container, i dati rimangono!

**Tipi di volumi:**

```yaml
# Named volume (gestito da Docker)
volumes:
  - n8n_data:/home/node/.n8n

# Bind mount (cartella reale sul tuo PC)
volumes:
  - ./my-folder:/home/node/.n8n
  # ./my-folder = cartella sul tuo PC
  # /home/node/.n8n = cartella nel container
```

### 4. **Environment (Variabili d'Ambiente)**

```yaml
environment:
  - N8N_BASIC_AUTH_USER=admin
  - DEEPSEEK_API_KEY=sk-123456
```

**Cos'è?** Impostazioni del programma.

**Analogia:** Come le "Impostazioni" di un'app.

**Metodi per definirle:**

```yaml
# Metodo 1: Direttamente nel file
environment:
  - API_KEY=sk-123456

# Metodo 2: Da file .env (più sicuro)
environment:
  - API_KEY=${API_KEY}  # Legge da file .env
```

**File .env (nella stessa cartella):**
```env
API_KEY=sk-123456
```

### 5. **Networks (Reti)**

```yaml
networks:
  - easyway-net
```

**Cos'è?** Una "rete locale virtuale" per i container.

**Analogia:** Come il WiFi di casa.
- Tutti i container nella stessa rete possono parlarsi
- Usano i nomi dei container come "indirizzi"

**Esempio:**
```yaml
# Container n8n può chiamare Qdrant così:
http://qdrant:6333/collections
# "qdrant" = nome del container (non serve IP!)
```

---

## 🚀 Il Nostro docker-compose.yml Completo (Commentato)

```yaml
version: '3.8'

services:
  # ============================================
  # n8n - Workflow Automation
  # ============================================
  n8n:
    image: n8nio/n8n:latest  # Scarica n8n da Docker Hub
    container_name: easyway-n8n  # Nome del container
    
    ports:
      - "5678:5678"  # Accedi a http://localhost:5678
    
    environment:
      # Autenticazione
      - N8N_BASIC_AUTH_ACTIVE=true  # Abilita login
      - N8N_BASIC_AUTH_USER=admin  # Username
      - N8N_BASIC_AUTH_PASSWORD=easyway2026  # Password
      
      # Configurazione base
      - N8N_HOST=0.0.0.0  # Ascolta su tutte le interfacce
      - N8N_PORT=5678  # Porta interna
      - N8N_PROTOCOL=http  # Usa HTTP (non HTTPS)
      - WEBHOOK_URL=http://localhost:5678/  # URL per webhook
      
      # Timezone
      - GENERIC_TIMEZONE=Europe/Rome  # Fuso orario italiano
      
      # API Keys (legge da file .env)
      - DEEPSEEK_API_KEY=${DEEPSEEK_API_KEY}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      
      # Database Azure SQL
      - AZURE_SQL_SERVER=${AZURE_SQL_SERVER}
      - AZURE_SQL_DATABASE=${AZURE_SQL_DATABASE}
      - AZURE_SQL_USER=${AZURE_SQL_USER}
      - AZURE_SQL_PASSWORD=${AZURE_SQL_PASSWORD}
    
    volumes:
      # Dati persistenti di n8n
      - n8n_data:/home/node/.n8n
      
      # Cartelle condivise (opzionali)
      - ./workflows:/workflows  # I tuoi workflow
      - ./scripts:/scripts  # I tuoi script
    
    restart: unless-stopped  # Riavvia sempre (tranne se fermato manualmente)
    
    networks:
      - easyway-net  # Unisciti alla rete "easyway-net"

  # ============================================
  # Qdrant - Vector Database
  # ============================================
  qdrant:
    image: qdrant/qdrant:latest  # Scarica Qdrant
    container_name: easyway-qdrant
    
    ports:
      - "6333:6333"  # REST API - http://localhost:6333
      - "6334:6334"  # gRPC API (per performance)
    
    volumes:
      - qdrant_storage:/qdrant/storage  # Salva i vettori qui
    
    environment:
      - QDRANT__SERVICE__GRPC_PORT=6334  # Porta gRPC
    
    restart: unless-stopped
    
    networks:
      - easyway-net

  # ============================================
  # Ollama - Local LLM (Modelli AI locali)
  # ============================================
  ollama:
    image: ollama/ollama:latest  # Scarica Ollama
    container_name: easyway-ollama
    
    ports:
      - "11434:11434"  # API - http://localhost:11434
    
    volumes:
      - ollama_data:/root/.ollama  # Salva i modelli qui (possono essere grandi!)
    
    restart: unless-stopped
    
    networks:
      - easyway-net

  # ============================================
  # PostgreSQL - Database per n8n (opzionale)
  # ============================================
  postgres:
    image: postgres:15-alpine  # PostgreSQL versione 15 (leggera)
    container_name: easyway-postgres
    
    environment:
      - POSTGRES_USER=n8n  # Username database
      - POSTGRES_PASSWORD=n8n  # Password database
      - POSTGRES_DB=n8n  # Nome database
    
    volumes:
      - postgres_data:/var/lib/postgresql/data  # Dati database
    
    restart: unless-stopped
    
    networks:
      - easyway-net

# ============================================
# Definizione Volumi (Cartelle Persistenti)
# ============================================
volumes:
  n8n_data:  # Dati di n8n (workflow, credenziali, etc.)
  qdrant_storage:  # Vettori di Qdrant
  ollama_data:  # Modelli AI di Ollama (possono essere 10+ GB!)
  postgres_data:  # Database PostgreSQL

# ============================================
# Definizione Reti (Comunicazione tra Container)
# ============================================
networks:
  easyway-net:  # Rete virtuale per tutti i container
    driver: bridge  # Tipo di rete standard
```

---

## 📝 File .env (Variabili Sensibili)

**Crea questo file nella stessa cartella del docker-compose.yml:**

```env
# File: .env
# Questo file contiene le tue credenziali (NON committare su Git!)

# DeepSeek API
DEEPSEEK_API_KEY=sk-your-deepseek-key-here

# OpenAI API (opzionale)
OPENAI_API_KEY=sk-your-openai-key-here

# Azure SQL
AZURE_SQL_SERVER=your-server.database.windows.net
AZURE_SQL_DATABASE=EasyWayDataPortal
AZURE_SQL_USER=your-username
AZURE_SQL_PASSWORD=your-password
```

**IMPORTANTE:** Aggiungi `.env` al `.gitignore`!

```bash
# File: .gitignore
.env
```

---

## 🎮 Comandi Docker Compose (Guida Pratica)

### 1. Avviare Tutti i Container

```bash
# Vai nella cartella con docker-compose.yml
cd ~/easyway-playground

# Avvia tutti i servizi
docker compose up -d

# Spiegazione:
# - "up" = avvia i container
# - "-d" = detached mode (in background, non blocca il terminale)
```

**Output atteso:**
```
[+] Running 5/5
 ✔ Network easyway-net          Created
 ✔ Container easyway-postgres   Started
 ✔ Container easyway-n8n        Started
 ✔ Container easyway-qdrant     Started
 ✔ Container easyway-ollama     Started
```

### 2. Verificare Stato dei Container

```bash
# Mostra container in esecuzione
docker compose ps

# Output:
# NAME                IMAGE               STATUS
# easyway-n8n         n8nio/n8n:latest    Up 2 minutes
# easyway-qdrant      qdrant/qdrant       Up 2 minutes
# easyway-ollama      ollama/ollama       Up 2 minutes
# easyway-postgres    postgres:15-alpine  Up 2 minutes
```

### 3. Vedere i Log (Debug)

```bash
# Log di tutti i container
docker compose logs

# Log di un container specifico
docker compose logs n8n

# Log in tempo reale (segui i nuovi messaggi)
docker compose logs -f n8n

# Ultimi 50 messaggi
docker compose logs --tail=50 n8n
```

### 4. Fermare i Container

```bash
# Ferma tutti i container (ma non li cancella)
docker compose stop

# Ferma un container specifico
docker compose stop n8n
```

### 5. Riavviare i Container

```bash
# Riavvia tutti
docker compose restart

# Riavvia uno specifico
docker compose restart n8n
```

### 6. Fermare e Cancellare Tutto

```bash
# Ferma e rimuove i container (MA NON i volumi/dati)
docker compose down

# Ferma, rimuove container E volumi (ATTENZIONE: perdi i dati!)
docker compose down -v
```

### 7. Vedere Risorse Utilizzate

```bash
# Mostra CPU, RAM, Rete in tempo reale
docker stats

# Output:
# CONTAINER       CPU %   MEM USAGE / LIMIT   NET I/O
# easyway-n8n     2.5%    150MB / 8GB         1.2kB / 890B
# easyway-qdrant  0.5%    80MB / 8GB          0B / 0B
```

### 8. Entrare Dentro un Container (Debug Avanzato)

```bash
# Apri una shell dentro il container n8n
docker exec -it easyway-n8n sh

# Ora sei "dentro" il container! Puoi esplorare:
ls -la
pwd
exit  # Per uscire
```

### 9. Aggiornare le Immagini

```bash
# Scarica le ultime versioni
docker compose pull

# Riavvia con le nuove versioni
docker compose up -d
```

---

## 🧪 Test Pratico - Passo per Passo

### Step 1: Crea la Struttura

```bash
# Crea cartella
mkdir -p ~/easyway-playground
cd ~/easyway-playground

# Crea file docker-compose.yml
nano docker-compose.yml
# (Copia il contenuto del file YAML sopra)

# Crea file .env
nano .env
# (Aggiungi le tue API keys)
```

### Step 2: Avvia i Servizi

```bash
docker compose up -d
```

### Step 3: Verifica che Funzionino

```bash
# Test n8n
curl http://localhost:5678
# Dovresti vedere HTML di n8n

# Test Qdrant
curl http://localhost:6333/collections
# Dovresti vedere: {"result":{"collections":[]}}

# Test Ollama
curl http://localhost:11434/api/tags
# Dovresti vedere: {"models":[]}
```

### Step 4: Accedi alle Interfacce Web

**n8n:**
- URL: http://localhost:5678
- User: admin
- Password: easyway2026

**Qdrant Dashboard:**
- URL: http://localhost:6333/dashboard

### Step 5: Scarica un Modello Ollama

```bash
# Entra nel container Ollama
docker exec -it easyway-ollama bash

# Scarica un modello (es. llama3.2 - 2GB)
ollama pull llama3.2

# Esci
exit

# Testa il modello
curl http://localhost:11434/api/generate -d '{
  "model": "llama3.2",
  "prompt": "Ciao, come stai?",
  "stream": false
}'
```

---

## 🔧 Troubleshooting Comune

### Problema 1: "Port already in use"

```bash
# Errore: Bind for 0.0.0.0:5678 failed: port is already allocated

# Soluzione: Cambia la porta nel docker-compose.yml
ports:
  - "5679:5678"  # Usa 5679 invece di 5678
```

### Problema 2: "Permission denied"

```bash
# Errore: permission denied while trying to connect to Docker daemon

# Soluzione: Aggiungi il tuo utente al gruppo docker
sudo usermod -aG docker $USER
newgrp docker  # Ricarica i gruppi
```

### Problema 3: Container si Riavvia Continuamente

```bash
# Vedi i log per capire perché
docker compose logs n8n

# Errori comuni:
# - Variabile d'ambiente mancante
# - Porta già in uso
# - Volume con permessi sbagliati
```

### Problema 4: "No space left on device"

```bash
# Docker ha riempito il disco!

# Pulisci immagini inutilizzate
docker system prune -a

# Pulisci volumi inutilizzati (ATTENZIONE!)
docker volume prune
```

---

## 📊 Struttura Finale delle Cartelle

```
~/easyway-playground/
├── docker-compose.yml       # File principale
├── .env                     # Credenziali (NON committare!)
├── workflows/               # I tuoi workflow n8n (opzionale)
│   ├── agent-executor.json
│   └── wiki-vectorizer.json
└── scripts/                 # Script PowerShell (opzionale)
    ├── test-deepseek.ps1
    └── sync-agents.ps1

# Docker crea automaticamente:
/var/lib/docker/volumes/
├── easyway-playground_n8n_data/
├── easyway-playground_qdrant_storage/
├── easyway-playground_ollama_data/
└── easyway-playground_postgres_data/
```

---

## 🎯 Prossimi Step

Dopo aver avviato tutto:

1. ✅ Accedi a n8n (http://localhost:5678)
2. ✅ Crea il tuo primo workflow
3. ✅ Testa DeepSeek API
4. ✅ Scarica un modello Ollama
5. ✅ Crea una collection in Qdrant
6. ✅ Integra con Azure SQL

---

## 💡 Consigli Finali

### 1. Backup dei Dati

```bash
# Backup di tutti i volumi
docker run --rm \
  -v easyway-playground_n8n_data:/data \
  -v $(pwd):/backup \
  alpine tar czf /backup/n8n-backup.tar.gz /data
```

### 2. Monitoraggio Risorse

```bash
# Installa ctop (Docker top)
sudo wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop

# Usa ctop per monitorare
ctop
```

### 3. Aggiornamenti Automatici (Opzionale)

```bash
# Installa Watchtower (aggiorna container automaticamente)
docker run -d \
  --name watchtower \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --interval 86400  # Controlla ogni 24 ore
```

---

**Ora sei pronto! 🚀**

**Domande?** Chiedi pure! 💙


