# 🌹 Valentino Framework: The "Wishlist" Library
> *"Sostituiamo i Mostri con l'Artigianato."*

Qui mappiamo le librerie standard (i "Mostri" pesanti e vincolanti) che vogliamo rimpiazzare con Componenti Sovereign su misura.
Questa è la nostra roadmap per una **Libreria Componenti Interna**.

---

## 📅 1. The Timekeeper (Datepicker)
> **The Monster**: `react-datepicker`, `moment.js` (Pesanti, stili difficili da sovrascrivere)
> **Valentino Wish**: `<sovereign-datepicker>`

### Why Sovereign?
- **Fasi Lunari**: Possiamo renderizzare icone custom nei giorni (es. 🌕 Luni).
- **Fiscal Calendar**: Supporto per calendari aziendali 4-4-5 o custom.
- **Zero Dipendenze**: Niente `moment.js` o `date-fns`, solo `Intl.DateTimeFormat` nativo.

**Status**: 📝 *Wishlist*

---

## 📊 2. The Grid (Data Table)
> **The Monster**: `ag-grid`, `tanstack-table` (Giganteschi, costosi, complessi)
> **Valentino Wish**: `<sovereign-datagrid>`

### Why Sovereign?
- **Virtual Scrolling**: Scritto a mano per performance massime su DOM leggeri.
- **Excel-like**: Copia/Incolla nativo senza plugin.
- **Custom Renderers**: Celle che contengono grafici o mini-ragni.

**Status**: 📝 *Wishlist*

---

## 🔽 3. The Selector (Dropdown/Combobox)
> **The Monster**: `react-select` (Il DOM diventa un incubo di `div` annidati)
> **Valentino Wish**: `<sovereign-select>`

### Why Sovereign?
- **Glassmorphism**: Dropdown che sfocano lo sfondo (difficile con librerie standard).
- **Multi-select con Chip**: Gestione tag stile "Notion".
- **Ricerca Server-side**: Integrata direttamente con le nostre API.

**Status**: 📝 *Wishlist*

---

## 🔔 4. The Herald (Toasts & Notifications)
> **The Monster**: `react-toastify`, `sweetalert` (Design generico)
> **Valentino Wish**: `<sovereign-toaster>`

### Why Sovereign?
- **Stacked Cards**: Notifiche che si impilano 3D.
- **Actionable**: Bottoni "Undo" o "Retry" collegati direttamente alla logica business.
- **Sound Design**: Suoni custom per errori/successi (facoltativo).

**Status**: 📝 *Wishlist*

---

## 🖼️ 5. The Gallery (Image/Media Viewer)
> **The Monster**: `react-lightbox`, `swiper.js`
> **Valentino Wish**: `<sovereign-lightbox>`

### Why Sovereign?
- **Deep Zoom**: Zoom infinito su immagini tecniche/CAD.
- **Metadata Overlay**: Mostrare EXIF o dati tecnici di bordo in sovraimpressione.

**Status**: 📝 *Wishlist*

---

## 📝 Roadmap di Implementazione

Per ogni componente:
1.  Creare file in `src/components/lib/[name].ts` usando **component.blueprint.ts**.
2.  Implementare logica Core (No dipendenze).
3.  Applicare stili `glassmorphism`.
4.  Scrivere Test E2E dedicati.

---
*Created: 2026-02-02*
