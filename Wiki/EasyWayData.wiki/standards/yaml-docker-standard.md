---
id: yaml-docker-standard
title: YAML & Docker Compose Standard
summary: Linee guida per scrivere file YAML e Docker Compose puliti, sicuri e conformi a TESS.
status: active
owner: team-platform
tags: [standard, yaml, docker, best-practices]
updated: 2026-01-27
version: 1.0.0
---

# YAML & Docker Compose Standard

> **"Code is read much more often than it is written."** - Guido van Rossum

Questo documento definisce le regole d'oro per scrivere configurazioni YAML e Docker Compose nell'ecosistema EasyWay.

## 1. YAML Syntax Rules 📝

### 1.1 Indentazione
*   **2 Spazi**. NON usare Tab. Mai.
*   *Perché*: YAML è sensibile all'indentazione. I tab rompono i parser su diversi OS.

### 1.2 Commenti
*   Commenta il **PERCHÉ**, non il *COSA*.
*   👍 `user: "1003:1004" # Match host easyway user`
*   👎 `user: "1003:1004" # Imposta l'utente`

### 1.3 Stringhe
*   Usa le virgolette `"` per valori che sembrano numeri ma sono stringhe (es. porte, versioni).
*   Esempio: `version: "3.8"` (non `3.8` float).

---

## 2. Docker Compose Best Practices 🐳

### 2.1 The "Appliance" Philosophy
*   **1 Compose = 1 Servizio**.
*   Evita i "Monoliti" (un file con 50 servizi).
*   Ogni strumento (`n8n`, `chromadb`) deve poter essere riavviato senza toccare gli altri.

### 2.2 Naming Convention (TESS Compliant)
*   **Container Name**: `easyway-{servizio}`
    *   ✅ `easyway-n8n`
    *   ❌ `n8n_production`
*   **Network**: `easyway-net` (Bridge condiviso)

### 2.3 Storage (Bind Mounts vs Volumes)
*   Standard TESS v1.1 preferisce **BIND MOUNTS**.
*   ✅ `- ./data:/data` (Si vede i file sull'host, facile backup/debug).
*   ❌ `- n8n_data:/data` (Volume nascosto in `/var/lib/docker`).

### 2.4 User Identity (Security) 🛡️
*   **MAI** girare come `root` (UID 0).
*   Usa sempre l'utente `easyway` (UID 1003).
*   Sintassi: `user: "1003:1004"`

### 2.5 Secrets & Config
*   **MAI** password in chiaro nel YAML.
*   Usa variabili d'ambiente: `${DB_PASSWORD}`.
*   Carica da file `.env`.

---

## 3. Template di Riferimento

```yaml
version: '3.8'

services:
  myapp:
    image: myimage:1.2.3  # Pin version (no :latest in prod critici)
    container_name: easyway-myapp
    restart: unless-stopped
    
    # Security: Run as non-root
    user: "1003:1004"
    
    # Network
    ports:
      - "8080:8080"
    networks:
      - easyway-net
      
    # Storage (Bind Mount)
    volumes:
      - ./data:/app/data
      - ./config:/app/config
      
    # Config via Env
    environment:
      - APP_ENV=production
      - DB_HOST=${DB_HOST}
      
    # Resource Limits (Anti-Crash)
    deploy:
      resources:
        limits:
          memory: 512M

networks:
  easyway-net:
    external: true # Usa la rete esistente
```
