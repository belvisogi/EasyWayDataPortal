# La Fabbrica Software (The Factory Strategy)

> **Architectural Pattern: Monorepo Split**
> *"Centralized Development, Distributed Distribution."*

Questo documento formalizza la strategia di gestione del codice di EasyWay.
Adottiamo il pattern **Monorepo Split**, utilizzato da grandi progetti Open Source come **Symfony**, **Laravel** e **React**.

## 1. Il Problema
Vogliamo due cose apparentemente opposte:
1.  **Sviluppo Integrato**: Lavorare su tutti i progetti (`dqf-agent`, `valentino`, `portal`) insieme, rifattorizzare codice condiviso e muovere file liberamente.
2.  **Distribuzione Modulare**: I clienti e la community vogliono scaricare *solo* il pezzo che gli serve (es. solo `dqf-agent`), senza tutto il resto.

La soluzione classica (Git Submodules) è fragile e complessa da gestire quotidianamente.

## 2. La Soluzione: Monorepo Split
Invece di usare Git dentro Git, usiamo un processo di **Proiezione**.

### 🏗️ L'Organizzazione (Local)
Tutto vive in un unico repository gigante (`C:\old\EasyWayDataPortal`).
```
EasyWayDataPortal/
├── packages/dqf-agent/    (Sorgente)
├── packages/valentino/    (Sorgente)
└── apps/core/             (Sorgente)
```

### 🚀 La Proiezione e Ridondanza (Remote Strategy)

Il server GitLab è il Master, ma non è l'unico punto di salvataggio. Sfruttiamo i tier gratuiti per la massima antifragilità.

```mermaid
graph TD
    Factory[💻 Tuo PC] -->|Push| GitLab[🏰 Sovereign GitLab\n(Master)]

    subgraph "Cloud Gratuito (Bunker & Vetrina)"
        GitHubPrivate[🔒 GitHub Private\n(Backup Core)]
        GitHubPublic[🌍 GitHub Public\n(Community Agent)]
    end

    GitLab -->|Auto-Mirror| GitHubPrivate
    GitLab -->|Auto-Mirror| GitHubPublic

    style GitLab fill:#d4fae6,stroke:#198754,stroke-width:2px
```

**La Regola del 3-2-1 (Automatizzata):**
1.  **3 Copie del dato**: PC Locale, Server GitLab, GitHub Cloud.
2.  **2 Media diversi**: Tuo Hard Disk, Cloud Oracle, Cloud GitHub.
3.  **1 Off-site**: GitHub è geograficamente lontano dal tuo server.

**Tutto questo costa 0€.**

## 3. Perché questa scelta? (The Why)

| Strategia | Sviluppo Locale | Gestione Versioni | Complessità |
|-----------|-----------------|-------------------|-------------|
| **Git Submodules** | Lento, fragile | Complesso (pointer hell) | ALTA 🔴 |
| **Repos Separati** | Difficile condividere codice | Facile | MEDIA 🟡 |
| **Monorepo Split** | **Fluido e Veloce** | **Centralizzata e Atomica** | **BASSA** 🟢 |

**Vantaggi Chiave**:
1.  **Zero Drift**: Non ci sono versioni disallineate in locale. Quello che vedi nella cartella è la verità.
2.  **Developer Experience**: Non devi imparare comandi Git avanzati submodule.
3.  **Sovereignty**: Il codice "vero" è tutto al sicuro nel Monorepo Madre. I satelliti sono solo proiezioni sacrificabili/rigenerabili.

---
*Strategy adopted on 2026-02-03 by EasyWay Core Architecture Team*

