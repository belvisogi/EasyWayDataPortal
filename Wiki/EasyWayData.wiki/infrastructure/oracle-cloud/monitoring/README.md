---
id: server-monitoring-tools
title: Server Monitoring Tools - Visual Dashboard Guide
summary: Guida ai tool di monitoring visuale installati su Oracle Cloud (btop, glances, neofetch) per troubleshooting e status check rapidi.
status: active
owner: team-platform
tags: [infrastructure, monitoring, tools, oracle-cloud, ops]
updated: 2026-01-26
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---

# Server Monitoring Tools - Visual Dashboard Guide

> **Scopo**: Avere una visione immediata e "bella" dello stato del server senza dover lanciare 10 comandi diversi.

## 🎯 Tool Installati

### 1. **btop** - Modern Resource Monitor 🔥
Il migliore per avere un "cruscotto" completo del sistema.

**Quando usarlo**: 
- Debug performance
- Vedere processi in tempo reale
- Capire chi sta usando CPU/RAM/Network

**Come lanciarlo**:
```bash
ssh ubuntu@80.225.86.168
btop
```

**Screenshot Layout**:
```
┌─ CPU ────────────────────┐┌─ Memory ──────────────┐
│ [████████░░] 80%        ││ [███░░░░░░] 30%      │
│ Core 0: 90%             ││ Used: 7.2GB/24GB     │
│ Core 1: 70%             ││ Swap: 0GB            │
└─────────────────────────┘└───────────────────────┘
┌─ Processes ─────────────────────────────────────┐
│ PID   User   CPU%  MEM%  Command               │
│ 1234  ubuntu 45.2  12.3  ollama serve          │
│ 5678  ubuntu  8.1   3.2  python3 chromadb...   │
└─────────────────────────────────────────────────┘
```

**Shortcuts utili**:
- `q` = quit
- `m` = sort by memory
- `c` = sort by CPU
- `/` = search process
- `k` = kill process (attenzione!)

---

### 2. **glances** - System Monitoring con API
Più completo, include anche temperatura, I/O disco, e può esporre metriche via web.

**Quando usarlo**:
- Monitoring completo sistema
- Export metriche per grafici
- Troubleshooting avanzato

**Come lanciarlo**:
```bash
# Modalità standard
glances

# Modalità web (accesso via browser)
glances -w
# Poi apri: http://80.225.86.168:61208
```

**Metriche Extra**:
- Disk I/O (letture/scritture al secondo)
- Network traffic (download/upload)
- Sensor temperatures (se disponibili)
- Docker containers (se c'è Docker)

**Export JSON** (utile per automazione):
```bash
glances --export json
```

---

### 3. **neofetch** - System Banner Carino
Mostra info sistema con logo ASCII. Perfetto per screenshot o "what's running here?"

**Quando usarlo**:
- Banner iniziale quando accedi via SSH
- Screenshot per documentazione
- Quick overview del sistema

**Come lanciarlo**:
```bash
neofetch
```

**Output**:
```
       _,met$$$$$gg.          ubuntu@oracle-agent
    ,g$$$$$$$$$$$$$$$P.       -------------------
  ,g$$P"     """Y$$.".        OS: Ubuntu 24.04 LTS aarch64
 ,$$P'              `$$$.     Host: Oracle Cloud Ampere
',$$P       ,ggs.     `$$b:   Kernel: 6.8.0-1015-oracle
`d$$'     ,$P"'   .    $$$    Uptime: 1 day, 10 hours
 $$P      d$'     ,    $$P    Packages: 1247 (dpkg)
 $$:      $$.   -    ,d$$'    Shell: bash 5.2.21
 $$;      Y$b._   _,d$P'      CPU: Ampere Altra (4) @ 3.000GHz
 Y$$.    `.`"Y$$$$P"'         Memory: 1542MiB / 24576MiB
 `$$b      "-.__
  `Y$$
   `Y$$.
     `$$b.
       `Y$$b.
          `"Y$b._
              `"""
```

---

## 🚀 Script Rapidi (Aggiunti a Bashrc)

Per rendere ancora più rapido il monitoring, abbiamo aggiunto degli alias:

```bash
# ~/.bashrc (auto-caricato al login SSH)
alias status='btop'
alias monitor='glances'
alias info='neofetch'
alias agent-status='~/check-agent-health.sh'
```

**Applica subito** (già fatto durante setup):
```bash
echo "alias status='btop'" >> ~/.bashrc
echo "alias monitor='glances'" >> ~/.bashrc
echo "alias info='neofetch'" >> ~/.bashrc
source ~/.bashrc
```

Ora basta digitare `status` invece di `btop`! 🎉

---

## 🏥 Health Check Script (Custom)

Abbiamo creato uno script custom per vedere lo stato dell'Agent in un colpo solo:

**File**: `~/check-agent-health.sh`

```bash
#!/bin/bash
echo "🤖 EasyWay Agent - Health Check"
echo "================================"
echo ""
echo "📡 Ollama Service:"
systemctl status ollama | grep -E "Active|Memory"
echo ""
echo "🧠 Models Loaded:"
ollama list
echo ""
echo "💾 Disk Usage:"
df -h / | tail -1
echo ""
echo "🔋 Memory:"
free -h | grep Mem
echo ""
echo "⏰ Uptime:"
uptime
```

**Uso**:
```bash
chmod +x ~/check-agent-health.sh
~/check-agent-health.sh
```

O semplicemente: `agent-status` (se hai caricato il bashrc alias).

---

## 📊 Comparativa Tool

| Tool      | Caso d'Uso                  | Peso   | Output    |
|-----------|-----------------------------|--------|-----------|
| **btop**  | Dashboard generale, debug   | Leggero| Interactive|
| **glances**| Monitoring avanzato + API  | Medio  | Interactive + JSON |
| **neofetch**| Info rapida, screenshot   | Ultra-leggero | Static |

---

## 🔧 Troubleshooting

### btop non parte
```bash
# Verifica installazione
btop --version

# Reinstalla se necessario
sudo apt-get install --reinstall btop
```

### glances web mode non accessibile
```bash
# Verifica firewall Oracle Cloud
# Devi aprire la porta 61208 nel Security Group

# Alternative: usa SSH tunneling
ssh -L 61208:localhost:61208 ubuntu@80.225.86.168
# Poi apri: http://localhost:61208
```

---

## 📖 Risorse

- [btop GitHub](https://github.com/aristocratos/btop)
- [glances Docs](https://glances.readthedocs.io/)
- [neofetch Wiki](https://github.com/dylanaraps/neofetch/wiki)

---

**Vedi anche**:
- [Oracle Cloud Setup Guide](./agent-local-llm-oracle.md)
- [Deployment Runbook](../brain/deployment-runbook-oracle-to-hetzner.md)

