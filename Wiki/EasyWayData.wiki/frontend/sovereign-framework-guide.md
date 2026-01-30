# 🦅 Sovereign Framework Guide
**Philosophy: Reuse. Control. Scalability.**

## 1. Il Concetto (The Why)
Il "Sovereign Framework" non è solo CSS. È un **Motore di Identità**.
Permette di separare completamente:
- **Struttura** (HTML)
- **Stile** (`branding.json`)
- **Contenuto** (`content.json`)

Questo garantisce il rispetto del principio **DRY (Don't Repeat Yourself)** e **REUSE**.
Se devi cambiare il nome dell'azienda o il colore primario, lo fai in **un solo posto**.

---

## 2. Architettura

### 🎨 Theme Engine (`branding.json` + `theme-loader.ts`)
Gestisce l'identità visiva. Invece di hardcodare colori nel CSS, il framework inietta variabili CSS a runtime.

**File Config:** `public/branding.json`
```json
{
  "theme": {
    "colors": {
      "--code-bg": "#050508",
      "--code-gold": "#c8aa6e"
    }
  }
}
```

**Utilizzo (HTML/CSS):**
```css
.my-element {
    background-color: var(--code-bg); /* Valore caricato dinamicamente */
}
```

---

### 📝 Content Engine (`content.json` + `content-loader.ts`)
Gestisce i testi. Nessun testo deve essere scritto nell'HTML (tranne placeholder).

**File Config:** `public/content.json`
```json
{
  "manifesto": {
    "title": "The Sovereign Code",
    "cta": "Unisciti a Noi"
  }
}
```

**Utilizzo (HTML):**
Basta aggiungere l'attributo `data-key` all'elemento.
```html
<h1 data-key="manifesto.title">Loading...</h1>
<button data-key="manifesto.cta">...</button>
```
*Il loader cercherà la chiave `manifesto.title` nel JSON e sostituirà il testo automaticamente.*

---

## 3. Guida Pratica: Creare una Nuova Pagina
Vuoi creare `about.html` usando il Framework? Segui questi passi.

### Passo 1: Crea lo Scheletro HTML
Crea il file e importa `main.ts` (che inizializza il framework).
```html
<!DOCTYPE html>
<html>
<head>
    <script type="module" src="/src/main.ts"></script>
</head>
<body>
    <sovereign-header></sovereign-header>
    
    <main>
        <!-- Usa data-key per i testi -->
        <h1 data-key="about.hero_title">...</h1>
        <p data-key="about.mission_text">...</p>
    </main>

    <sovereign-footer></sovereign-footer>
</body>
</html>
```

### Passo 2: Aggiungi i Testi al JSON
Edita `public/content.json` e aggiungi la sezione `about`.
```json
{
  "about": {
    "hero_title": "Chi Siamo",
    "mission_text": "Siamo la Tribù Sovrana."
  },
  ...
}
```

### Passo 3: Fatto.
Apri la pagina.
- Il **Tema** (Colori/Font) sarà applicato automaticamente (`main.ts` -> `loadBranding`).
- I **Testi** saranno iniettati automaticamente (`main.ts` -> `loadContent`).
- L'**Header/Footer** saranno renderizzati automaticamente (Web Components).

---

## 4. Manutenzione
- **Cambiare Colore Brand**: Modifica `branding.json`. Si applica a *tutto* il sito.
- **Correggere un Typo**: Modifica `content.json`. Si applica istantaneamente.
- **Aggiungere Lingua**: (Futuro) Basterà caricare `content.en.json` invece di `content.json`.

**Questo è Sovereign Engineering.** 🦅
