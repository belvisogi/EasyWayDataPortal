# Schema Viewer - Web App

Applicazione web interattiva per visualizzare lo schema del database.

## 🚀 Quick Start

```bash
# Opzione 1: Python HTTP Server
cd db/db-deploy-ai/viewer
python -m http.server 8000

# Opzione 2: Node.js HTTP Server
npx serve .

# Opzione 3: VS Code Live Server
# Click destro su index.html → "Open with Live Server"
```

Poi apri: http://localhost:8000

## ✨ Features

### ✅ Implementate
- 📊 Visualizzazione ER diagram interattivo
- 🎨 Design moderno glassmorphism
- 🔍 Search tables in tempo reale
- 🖱️ Drag & drop tabelle
- 📐 Auto-layout
- 🏷️ Badge PK/FK
- 🔗 Linee di relazione automatiche
- 📱 Responsive design

### 🔜 Prossime
- 💾 Export PNG/SVG
- 🎨 Temi personalizzabili
- 📝 Note e commenti
- 🔄 Sync live con database
- 📊 Stats avanzate
- 🔐 Visualizzazione permessi RLS

## 🎯 Come Funziona

1. **Carica** blueprint JSON automaticamente
2. **Renderizza** tabelle come card interattive
3. **Connette** tabelle based on FK (column che termina con `_id`)
4. **Permette** drag & drop per riorganizzare
5. **Search** filtra tabelle in real-time

## 🎨 Design

- **Colori**: Gradient viola/blu (brand EasyWay)
- **Font**: System fonts (optimal performance)
- **Layout**: Responsive grid 3 colonne
- **Animations**: Smooth transitions
- **Shadows**: Depth con glassmorphism

## 📝 Personalizzazione

### Cambia colori
Modifica CSS variabili in `<style>`:
```css
/* Primary color */
background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);

/* Cambia con i tuoi colori brand */
background: linear-gradient(135deg, #YOUR_COLOR_1 0%, #YOUR_COLOR_2 100%);
```

### Aggiungi features
Vedi sezione `<script>` per:
- `loadBlueprint()` - caricamento dati
- `renderSchema()` - rendering
- `drawConnections()` - relazioni

## 🔧 Integration

### Auto-refresh su blueprint change
```javascript
// Aggiungi file watcher
setInterval(async () => {
  const newData = await fetch('../schema/easyway-portal.blueprint.json');
  if (JSON.stringify(newData) !== JSON.stringify(blueprint)) {
    blueprint = newData;
    renderSchema();
  }
}, 5000); // Check ogni 5 sec
```

### Export API
```javascript
// Export current layout
function exportLayout() {
  return tables.map(t => ({
    table: t.table.name,
    x: t.element.offsetLeft,
    y: t.element.offsetTop
  }));
}

// Save layout
localStorage.setItem('schema-layout', JSON.stringify(exportLayout()));
```

---

**Tipo dbdiagram.io ma custom per EasyWay!** 🎉
