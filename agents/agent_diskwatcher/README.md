# Agent DiskWatcher — The Sentinel

Monitora l'utilizzo del disco sul server OCI. Emette alert quando le soglie sono superate.

**Principio antifragile**: warn-only per default. Nessuna azione distruttiva automatica.
Il Sentinel avvisa — l'umano decide se e cosa pulire.

## Trigger

| Evento | Azione |
|--------|--------|
| `pctUsed >= 70%` | INFO (log) |
| `pctUsed >= 80%` | WARNING (output + exit 1) |
| `pctUsed >= 90%` | CRITICAL (output + exit 2) |

## Uso

```bash
# Check standard (human-readable)
pwsh scripts/pwsh/agent-diskwatcher.ps1

# JSON per pipeline/n8n
pwsh scripts/pwsh/agent-diskwatcher.ps1 -Json

# Soglie custom
pwsh scripts/pwsh/agent-diskwatcher.ps1 -WarnAt 75 -CritAt 85

# Cleanup interattivo (solo su server, richiede conferma 'yes')
pwsh scripts/pwsh/agent-diskwatcher.ps1 -Cleanup
```

## Cron sul server OCI

```bash
# Modifica crontab del server
crontab -e

# Aggiungi questa riga (ogni 6 ore, log in /tmp)
0 */6 * * * pwsh /home/ubuntu/EasyWayDataPortal/scripts/pwsh/agent-diskwatcher.ps1 >> /tmp/diskwatcher.log 2>&1
```

## Output

### Human-readable (default)
```
============================================================
  DISK WATCHER  --  2026-02-27 19:00:00
  Status: WARNING
============================================================

ALERTS
  [WARNING] Disco /: 83% usato (45G / 55G)

DISK USAGE
  /                    [################....] 83%   45G / 55G
  /home                [....................]  2%  512M / 30G

DOCKER DISK
  Images               total:12GB   reclaimable:3.2GB
  Containers           total:200MB  reclaimable:0B
  Volumes              total:8GB    reclaimable:0B

AZIONI SUGGERITE (eseguire manualmente dopo verifica):
  docker system prune -f
  journalctl --vacuum-size=100M
```

### Exit codes

| Code | Significato |
|------|-------------|
| 0 | OK — tutto sotto soglia |
| 1 | WARNING — almeno un mount tra 80-90% |
| 2 | CRITICAL — almeno un mount sopra 90% |

## Report persistente

Ogni esecuzione aggiorna `agents/agent_diskwatcher/memory/last-report.json`
con il report completo in formato JSON. Usare per trend/history.

## Cleanup

Il flag `-Cleanup` esegue `docker system prune -f` (container fermati + immagini dangling + build cache).
**I volumi non vengono mai toccati automaticamente.**

Richiede conferma interattiva — non puo' essere automatizzato via cron.
Per cleanup da cron: implementare una logica separata con soglie molto alte (>95%).

## Integrazione futura (Layer 1)

Quando il Layer 1 ADO awareness sara' attivo (n8n), questo agente potra' inviare
l'output JSON a n8n che aggiornera' `control-plane/session-state.md` con lo stato disco.

Riferimento: `Wiki/EasyWayData.wiki/guides/ado-session-awareness.md`
