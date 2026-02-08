---
id: rag-operations
title: 🧠 RAG Operations & Q&A Guide
summary: Manuale operativo per l'utilizzo e la manutenzione del sistema RAG (Private Brain).
status: live
owner: team-platform
created: '2026-02-08'
updated: '2026-02-08'
tags: [layer/runbook, component/rag, role/operator]
---

# 🧠 RAG Operations & Q&A Guide

Questo documento descrive come utilizzare e mantenere il sistema *Retrieval-Augmented Generation* (RAG) di EasyWay, noto come **"The Private Brain"**. Si tratta di una memoria semantica locale basata su **Qdrant**, che permette agli Agenti IA di accedere alla conoscenza aziendale contenuta nella Wiki.

## 🤖 Q&A: Come usare il RAG

Esistono due modi principali per interrogare la Knowledge Base.

### 1. Via Agente (Linguaggio Naturale) - "Chiedi all'esperto"
Questo è il metodo standard. Quando interagisci con un agente abilitato (es. *Scrum Master*, *Architect*), puoi porre domande dirette sulla documentazione.

> **Esempio:**
> *"Come gestiamo i backup nel datalake secondo la documentazione?"*
> *"Quali sono le regole di naming per i nuovi oggetti DB?"*

L'agente userà autonomamente la skill `retrieval.rag-search` per:
1.  Cercare i paragrafi pertinenti nella Wiki.
2.  Leggere il contenuto recuperato.
3.  Formulare una risposta basata *solo* sui fatti trovati (o ammettere di non sapere).

### 2. Via PowerShell (Manuale) - "Debug Mode"
Utile per verificare cosa "vede" l'agente o per integrare la ricerca in script di automazione.

```powershell
# Esempio: Cercare informazioni su Azure Architecture
$results = Invoke-RAGSearch -Query "Architettura Azure" -Limit 3

# Visualizzare i risultati
$results | Format-Table filename, score, content -AutoSize
```

**Parametri:**
- `-Query`: La frase o le parole chiave da cercare.
- `-Limit`: Numero massimo di risultati (default: 3).

**Output:**
Ogni risultato contiene:
- `filename`: Il file Markdown di origine.
- `content`: Il frammento di testo trovato.
- `score`: Punteggio di rilevanza (0.0 - 1.0). Più alto è meglio.
- `path`: Percorso relativo del file.

---

## ⚙️ Manutenzione e Ingestion ("Nutrire il Cervello")

Il contenuto di Qdrant *non* si aggiorna magicamente. Se la Wiki viene modificata significativamente, è necessario eseguire una re-indicizzazione.

### Quando eseguire l'Ingestion?
- **Obbligatorio**: Dopo aver aggiunto nuovi documenti importanti (es. nuovi Runbook, decisioni architetturali).
- **Consigliato**: Periodicamente (es. ogni settimana) se la Wiki è molto attiva.

### Procedura di Ingestion (Sul Server)

1.  **Collegarsi al Server**:
    ```bash
    ssh ubuntu@<SERVER_IP>
    ```

2.  **Lanciare l'Ingestion**:
    Usare il comando Docker pre-configurato che esegue lo script Node.js all'interno del container `easyway-runner`. Questo garantisce l'uso delle versioni corrette delle librerie.

    ```bash
    docker exec easyway-runner bash -c 'cd /app/scripts && node ingest_wiki.js'
    ```

    *Nota: Se necessario, per pulire completamente il DB prima di ricaricare (es. per rimuovere duplicati), il comando sopra esegue un "upsert", quindi aggiorna i documenti esistenti. Per un reset totale, vedere la sezione Troubleshooting.*

3.  **Verifica**:
    Se l'output termina con `✅ Ingestion Complete!`, il cervello è aggiornato.

---

## 🛠️ Troubleshooting

### L'Agente dice "Non trovo nulla" ma il documento esiste
- **Causa**: Il documento potrebbe non essere stato indicizzato o la query è troppo diversa dal testo.
- **Soluzione**: Esegui una ricerca manuale con `Invoke-RAGSearch` usando parole chiave presenti nel testo. Se ancora non trova nulla, riesegui l'Ingestion.

### Errore "Connection Refused" o Timeout
- **Causa**: Il container Qdrant potrebbe essere spento o irraggiungibile.
- **Soluzione**:
    1.  Verifica che Qdrant sia su: `docker ps | grep qdrant`
    2.  Se spento, riavvia lo stack RAG: `docker compose -f docker-compose-rag.yml up -d`

### Reset Totale della Memoria (Nuclear Option ☢️)
Se l'indice è corrotto o pieno di duplicati, puoi cancellare la collezione e ricrearla.

1.  **Cancellare la Collezione**:
    ```bash
    # Richiede la API KEY corretta (vedi .env)
    docker exec -e KEY=<QDRANT_API_KEY> easyway-runner bash -c 'curl -X DELETE http://qdrant:6333/collections/easyway_wiki -H "api-key: $KEY"'
    ```

2.  **Rieseguire l'Ingestion**:
    ```bash
    docker exec easyway-runner bash -c 'cd /app/scripts && node ingest_wiki.js'
    ```
