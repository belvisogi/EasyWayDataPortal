# 🛡️ Quality Shield Runbook
> *"Rules of Engagement for the Guardians"*

Questo documento definisce le strategie operative, le configurazioni e le procedure di intervento per i 3 Guardiani del Valentino Framework.

---

## 👁️ Visual Guardian (Pixel-Perfect)

### Strategia
Il Visual Guardian protegge l'integrità estetica scattando "foto" (snapshot) ai componenti e confrontandole con versioni approvate (baselines).

### ⚙️ Configurazione
- **Threshold**: 0.2% (Tolleranza minima per anti-aliasing).
- **Viewport**: Desktop (1280x720) standard (configurabile in `playwright.config.ts`).
- **Full Page**: Sì, cattura l'intera lunghezza della pagina.

### 📖 Procedure
- **Test Fallito**: Il test fallisce se i pixel differiscono.
    1.  Ispeziona il report HTML: `npx playwright show-report`.
    2.  È un bug? -> **Fix Code**.
    3.  È un cambio intenzionale? -> **Aggiorna Baseline**:
        ```bash
        npx playwright test visual --update-snapshots
        ```

---

## ♿ Inclusive Guardian (Accessibility)

### Strategia
L'Inclusive Guardian scansiona il DOM renderizzato alla ricerca di violazioni delle regole WCAG (Web Content Accessibility Guidelines).

### ⚙️ Configurazione
- **Standard**: WCAG 2.1 AA (Requisito legale standard).
- **Regole monitorate**: Contrasto colori, ARIA labels, Heading hierarchy, Alt text.

### 📖 Procedure
- **Test Fallito**: Viene segnalata una violazione (es. "Button non ha label").
    1.  Esegui il test locale: `npx playwright test accessibility`.
    2.  Identifica il componente colpevole.
    3.  Correggi il codice (es. aggiungi `aria-label="Chiudi"`).

---

## 👹 Chaos Guardian (Resilience)

### Strategia: "The Drunken Monkey"
Attualmente, il Chaos Guardian utilizza una strategia **Stocastica (Casuale)**. Simula un utente frenetico o confuso che interagisce con l'interfaccia senza seguire un flusso logico.

### 🤖 Logica di Azione (The Algorithm)
1.  **Identificazione**: Trova tutti gli elementi interattivi visibili (`button, a, input, select`).
2.  **Selezione**: Ne sceglie uno a caso (`Math.random()`).
3.  **Azione**:
    - Se è un Input: Digita testo casuale (Fuzzing).
    - Altrimenti: Clicca (anche furiosamente).
4.  **Ciclo**: Ripete per `N` volte (Default: 50).

### ⚙️ Configurazione (`tests/e2e/chaos.spec.ts`)
Puoi tarare l'intensità dell'attacco modificando queste costanti nello script:
```typescript
const ACTIONS = 50;       // Numero di pugni (aumentare per stress test)
const DELAY = 50;         // Millisecondi tra azioni (diminuire per "Rage Click")
const GREMLIN_MODE = true; // (Futuro) Attiva comportamenti più distruttivi
```

### 📖 Procedure
- **Crash Rilevato**: Se il sito esplode (Pagina bianca, Errore Console critico).
    1.  Il test fallisce e mostra l'errore catturato.
    2.  Si analizza lo "Stack Trace" del Chaos.
    3.  Si blinda il componente fragile (Antifragilità).

---

## 🚨 Emergency Protocols
In caso di falsi positivi bloccanti in CI/CD:

1.  **Disarmare un Guardiano**:
    Aggiungi `.skip` al test file:
    ```typescript
    test.describe.skip('Visual Guardian', () => { ... })
    ```
