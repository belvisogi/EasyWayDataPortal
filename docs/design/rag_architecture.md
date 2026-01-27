# Sovereign Data Architecture: "The Knowledge Loop"

## 1. The Value Proposition ("A cosa aiuta?")
Il valore non è solo "archiviare", ma **attivare** la conoscenza.
Oggi: Hai 1000 PDF su SharePoint. Se cerchi "come si riavvia il server", devi trovare il file giusto, aprirlo, fare CTRL+F.
**EasyWay**: Chiedi al Cortex "Come riavvio il server?". Lui ti risponde (perché ha letto il PDF) e ti dà il link al file originale.

> **Concept**: "Chat with your Enterprise Memory."

## 2. Architecture Overview ("Come finisce?")

```mermaid
graph TD
    User((Operatore))
    
    subgraph "Frontend Layer (The Cockpit)"
        Pulse[Neural Pulse (Upload)]
        Cortex[Cortex Chat (Query)]
        Void[Vector Void (Visualize)]
    end

    subgraph "Orchestration Layer (The Nervous System)"
        N8N[n8n Workflow Engine]
    end

    subgraph "Sovereign Infrastructure (The Brain)"
        MinIO[MinIO (Object Storage)]
        Chroma[ChromaDB (Vector Memory)]
        LLM[Local/Cloud LLM (Reasoning)]
    end

    subgraph "External Sources"
        SP[SharePoint / Drive]
    end

    %% Ingestion Flow
    User -- "Drag & Drop File" --> Pulse
    Pulse -- "POST /upload" --> N8N
    N8N -- "Save Raw File" --> MinIO
    N8N -- "Extract Text & Embed" --> Chroma

    %% Query Flow
    User -- "Ask Question" --> Cortex
    Cortex -- "Query" --> N8N
    N8N -- "Retrieve Context" --> Chroma
    N8N -- "Generate Answer" --> LLM
    N8N -- "Get Download Link" --> MinIO
    N8N -- "Response + Link" --> Cortex

    %% External Sync
    SP -- "Sync/Watch" --> N8N
```

## 3. Retrieval ("E se vogliono riprendere il PDF?")
Il sistema conserva **sempre** l'originale.
*   **Storage**: I file "fisici" (PDF, DOCX) vivono in **MinIO** (un S3 locale, sicuro e veloce).
*   **Action**: Quando il Cortex ti risponde, aggiunge una "Citation Card".
    *   *"In base al manuale 'Server_Config_v2.pdf' (p. 14)..."*
    *   Clicchi sulla card -> **Scarichi/Apri il PDF originale da MinIO**.

## 4. SharePoint Integration ("Leghiamo a SharePoint?")
Assolutamente sì.
Non dobbiamo sostituire SharePoint (che è ottimo per l'editing collaborativo).
Noi ci mettiamo **sopra**.
*   **Sync**: Un workflow n8n "ascolta" SharePoint.
*   **Indice**: Appena qualcuno salva un file su SharePoint, EasyWay lo "legge" e lo indicizza.
*   **Vantaggio**: L'utente cerca su EasyWay (che è istantaneo e intelligente) invece di perdersi nelle cartelle di SharePoint.

## Conclusion
Finisce che EasyWay diventa l'unica interfaccia necessaria per **trovare** e **capire** i dati aziendali. I dati restano dove sono (o in MinIO), ma l'intelligenza è centralizzata.
