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

### 🚀 La Proiezione (Remote)
Quando un componente è pronto, uno script (`publish-package.ps1`) lo "proietta" su un repository dedicato.
```
GitLab Sovereign (Remote)
├── repo: easyway-data-portal (Contiene TUTTO - La Madre)
├── repo: dqf-agent           (Contiene SOLO dqf-agent - Il Figlio)
└── repo: valentino           (Contiene SOLO valentino - Il Figlio)
```

### 🔄 Il workflow "Stateless Publish"
Per evitare conflitti Git locali, lo script di pubblicazione esegue questi passaggi atomici:
1.  **Snapshot**: Copia la cartella del package in un'area temporanea.
2.  **Init**: Inizializza un nuovo repository Git pulito.
3.  **Push**: Sovrascrive (`git push --force`) il repository satellite remoto.
4.  **Tag**: Applica il versionamento (es. `v1.0.0`) sul satellite.
5.  **Cleanup**: Distrugge l'area temporanea.

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

