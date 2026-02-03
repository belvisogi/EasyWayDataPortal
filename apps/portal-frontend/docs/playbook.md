# 🦅 The Valentino Playbook: How to Contribute

> *"Quality is not an act, it is a habit."*

Benvenuto nel protocollo di sviluppo del **Valentino Framework**.
Abbiamo installato una serie di "Guardiani" automatici per proteggere la qualità del codice. Questo documento spiega chi sono, cosa fanno e come soddisfarli.

---

## 🛡️ The Code Guardian (Husky + Commitlint)

**Chi è**: Un guardiano che vive nel tuo terminale e si sveglia ogni volta che provi a fare `git commit`.
**Cosa fa**: Controlla *prima* che il codice entri nella history.

### 🛑 Why did my commit fail?
Se vedi un errore rosso mentre committi, il Code Guardian ti ha bloccato per uno di questi motivi:

1.  **Messaggio di Commit non valido**: Non hai seguito lo standard.
2.  **Codice Sporco**: Il codice non passa il linting o i test.

### ✅ How to Fix: Commit Messages
Usiamo la convenzione **Conventional Commits**:
`tipo(ambito): descrizione`

| Tipo | Significato | Esempio Corretto | Esempio Errato |
| :--- | :--- | :--- | :--- |
| `feat` | Nuova funzionalità | `feat: add sovereign-toaster component` | `added toaster` |
| `fix` | Correzione bug | `fix: resolve navigation crash in chaos test` | `fixed bug` |
| `chore` | Manutenzione | `chore: pipelines and deps` | `cleanup` |
| `docs` | Documentazione | `docs: update playbook` | `doc` |
| `style` | Formattazione | `style: fix indentation` | `format` |

**Esempio di Errore:**
```bash
git commit -m "sistemato il login"
# ❌ ERRORE: subject must not be empty
```

**Soluzione:**
```bash
git commit -m "fix(auth): resolve login validation error"
# ✅ SUCCESS
```

---

## 👁️ The Visual Guardian (Visual Regression)

**Chi è**: Un fotografo instancabile (`tests/e2e/visual.spec.ts`).
**Cosa fa**: Scatta foto "Pixel-Perfect" delle pagine chiave (Home, Demo) e le confronta con le originali.

### 🛑 Why did the test fail?
Il test fallisce se *anche solo un pixel* è cambiato.
*   **Se è un bug**: Hai rotto il CSS involontariamente. Correggi il codice.
*   **Se è una modifica voluta**: Hai cambiato il design. Devi aggiornare la "foto originale".

### ✅ How to Fix
Se la modifica è intenzionale (es. hai cambiato colore al bottone), lancia:
```bash
npx playwright test tests/e2e/visual.spec.ts --update-snapshots
```

---

## ♿ The Inclusive Guardian (Accessibility)

**Chi è**: Un auditor severo (`tests/e2e/accessibility.spec.ts`).
**Cosa fa**: Scansiona il DOM cercando violazioni WCAG (colori, etichette, ruoli ARIA).

### 🛑 Why did the test fail?
*   Contrasto insufficiente (testo grigio su sfondo grigio).
*   Input senza etichetta (`aria-label` mancante).
*   Bottoni senza testo.

### ✅ How to Fix
Leggi il report. Spesso basta aggiungere un `aria-label` o scurisre un colore.
```html
<!-- ❌ Bad -->
<button class="icon-btn"><i class="fa fa-save"></i></button>

<!-- ✅ Good -->
<button class="icon-btn" aria-label="Save Document"><i class="fa fa-save"></i></button>
```

---

## ⚡ The Chaos Guardian (Gremlins.js)

**Chi è**: Un'orda di scimmiette dispettose (`tests/e2e/chaos.spec.ts`).
**Cosa fa**: Clicca a caso, scrolla, tocca e digita ovunque per 10 secondi.

### 🛑 Why did the test fail?
La pagina è crashata o ha lanciato un errore in console (`Uncaught TypeError`).

### ✅ How to Fix
Il tuo codice deve gestire gli errori. Non assumere che l'utente cliccherà "nel modo giusto".
*   Controlla i `null` check.
*   Gestisci le eccezioni nelle Promise.

---

> *"Sovereignty requires Discipline."*
