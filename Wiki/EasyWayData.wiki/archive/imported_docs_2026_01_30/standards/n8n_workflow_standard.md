---
id: ew-archive-imported-docs-2026-01-30-standards-n8n-workflow-standard
title: n8n Best Practices & Standards ⚡
summary: TODO - aggiungere un sommario breve.
status: draft
owner: team-platform
tags: [domain/docs, layer/spec, privacy/internal, language/it, audience/dev]
llm:
  include: true
  pii: none
  chunk_hint: 250-400
  redaction: [email, phone]
entities: []
type: guide
---
# n8n Best Practices & Standards ⚡

> **"A workflow is code. Treat it with respect."**

Prima di disegnare il primo nodo, stabiliamo le Regole d'Ingaggio per evitare lo "Spaghetti Workflow".

## 1. Naming Convention (Parlante & Standard) 🏷️
I nomi dei nodi devono seguire la struttura **`VERBO_OGGETTO_CONTESTO`**.
Devono essere leggibili come una frase.

*   ✅ `Get_User_FromDB` (Chiaro)
*   ✅ `Send_Email_ToAdmin` (Specifico)
*   ✅ `Calculate_Tax_Italy` (Contestualizzato)
*   ❌ `Set1` (Muto)
*   ❌ `User` (Vago)
*   ❌ `Process` (Generico)

**Regola:** Se leggi i nomi dei nodi in sequenza, devi capire la storia senza aprire i parametri.

## 2. Error Handling (Chiaro & Coccoloso) 🧸
Un errore tecnico (`HTTP 500`) spaventa l'utente.
Noi vogliamo errori "Coccolosi" (User Friendly).

Il payload di errore DEVE sempre avere due facce:
```json
{
  "technical_error": "Timeout 5000ms on 192.168.1.1",
  "friendly_message": "Il server ci sta mettendo un po' troppo a rispondere. Riprovo tra poco! ☕",
  "source_step": "Fetch_Data"
}
```
L'utente vedrà solo il `friendly_message`. Il tecnico vedrà il `technical_error` nel DB.

**Regola:** Ogni "Padre" deve catturare gli errori dei "Figli" e tradurli in messaggi gentili.

## 3. Modularity (Lego, non Monoliti) 🧱
Non fare workflow di 500 nodi.
*   **Sub-Workflows**: Se una logica si ripete (es. "Log to SQL"), fanne un workflow a parte e richiamalo (`Execute Workflow`).
*   **Atomic**: Un workflow deve fare UNA cosa bene (es. "Ingest PDF"). Non "Ingest PDF + Send Email + Buy Bitcoin".

## 4. Credentials & Security 🔒
*   **NO Hardcoding**: Mai scrivere password dentro i nodi.
*   **Credentials Store**: Usa il gestore credenziali di n8n.
*   **Environment Variables**: Usa `$env.NOME_VAR` per URL e Token globali.

## 6. Project Structure (Borgata System) 🏙️

Per mantenere l'ordine, organizziamo i workflow in "Quartieri" (Cartelle):

*   📂 **`Common/`**: Workflow riutilizzabili da tutti (es. `Log_To_MinIO`, `Send_Slack_Alert`).
*   📂 **`Infra/`**: Gestione server, Docker check, Manutenzione.
*   📂 **`Monitoring/`**: Controllano che gli altri workflow funzionino (Healthcheck).
*   📂 **`Business/`**: La logica vera del cliente (es. `Ingest_Invoice`, `Calc_Tax`).
*   📂 **`Templates/`**: I pattern sacri da clonare.

**Regola:**
Ogni nuovo workflow DEVE partire clonando il **`MASTER_TEMPLATE`** presente in `Templates/`.
Questo garantisce che la gestione errori sia già presente fin dal primo click.

## 7. The Pipeline Pattern (Tubatura Modulare) 🔧
Evita i "Monoliti" (Workflow di 100 nodi). Usa il pattern **Padre-Figlio**.

*   **Parent Workflow**: Contiene SOLO la sequenza logica.
    *   *Start -> Chiama Figlio 1 -> Chiama Figlio 2 -> Fine.*
    *   È la "Mappa".
*   **Child Workflow**: Fa il lavoro sporco (es. "Legge PDF").
    *   Deve essere piccolo ("Grande quanto basta").
    *   Restituisce un JSON pulito al Padre.

**Vantaggio**:
Se il Figlio 2 fallisce, puoi fixarlo e far ripartire il Padre dal punto 2, senza rifare il punto 1.
Ogni "snodo" della tubatura è un punto di controllo.

## 8. Standardized Logging Payload 📋
Quando chiami `Log_To_SQL` o `Send_Email`, usa sempre questo JSON standard:
```json
{
  "source": "Nome_Workflow",
  "level": "INFO|ERROR",
  "message": "Descrizione umana",
  "metadata": { "file_id": "123", "user": "mario" }
}
```
Questo garantisce che i log siano leggibili da chiunque.

## 9. The Identity Card (__METADATA__) 🆔
Ogni workflow DEVE iniziare con un nodo `Set` chiamato **`__METADATA__`**.
Questo nodo non fa nulla di logico, ma contiene i dati vitali per la manutenzione.

Deve contenere questi campi:
*   `description`: "Cosa fa questo workflow in italiano."
*   `domain`: "Infra / Business / Monitoring"
*   `version`: "1.0.0"
*   `dependencies`: (Array) "Chi chiama? es: ['Common/Send_Email']"

**Perché?**
Perché così un domani potremo lanciare uno script che legge tutti i file `.json` e ci disegna il **Grafico delle Dipendenze** automatico.
Senza questo nodo, il workflow è un "Cavaliere Senza Nome".

- [ ] I nodi hanno nomi sensati?
- [ ] C'è una gestione errori?
- [ ] **Ho compilato il nodo `__METADATA__`?**
- [ ] Le password sono al sicuro?
- [ ] Ho rimosso i nodi di debug (es. `console.log`)?


