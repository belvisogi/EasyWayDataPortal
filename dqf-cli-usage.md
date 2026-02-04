# DQF Agent CLI (PowerShell Edition) 🚜

L'agente standalone per sanificare la documentazione EasyWay.
Connette il tuo Vault locale al cervello remoto di DeepSeek per generare Tags e Link intelligenti.

## Prerequisiti
1.  **PowerShell Core** (Windows/Linux/Mac).
2.  **Accesso al Server AI** (`80.225.86.168`).

## 1. Setup Tunnel (Se necessario)
Se non sei nella stessa VPN del server, apri un tunnel SSH per esporre Ollama:
```powershell
ssh -L 11434:localhost:11434 ubuntu@80.225.86.168 -i path/to/key
```
*Se sei già connesso o il server è pubblico, salta questo step.*

## 2. Esecuzione
Lancia lo script dalla root del repository:

```powershell
# Analizza la cartella 'agents' (limitato a 3 file per test)
scripts/pwsh/dqf-analyze.ps1 -Path "Wiki/EasyWayData.wiki/agents" -Action analyze
```

### Parametri Opzionali
- `-OllamaUrl`: Default `http://80.225.86.168:11434` (o `http://localhost:11434` se usi il tunnel).
- `-Model`: Default `deepseek-r1:7b`.
- `-Limit`: Quanti file processare (Default 3, metti `9999` per tutto).

## Cosa Fa (The Magic 🪄)
1.  **Harvester**: Legge tutti i file della cartella target.
2.  **World View**: Costruisce un indice in memoria di TUTTE le pagine trovate.
3.  **Reasoning**: Invia ogni pagina a DeepSeek + l'Indice Globale.
4.  **Output**: Ti suggerisce:
    - ✅ **Tags** (basati sulla Taxonomy).
    - 🔗 **Cross-Links** (basati sulle altre pagine che ha visto).
    - 👪 **Parent** (gerarchia suggerita).
