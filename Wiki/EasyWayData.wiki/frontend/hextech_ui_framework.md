# Hextech UI Framework & Page Catalog 🎨

> **"Sovereignty needs to look premium to be taken seriously."**

This document describes the Frontend Architecture of EasyWay One. Unlike modern bloated SPAs, we use a **"Sovereign Vanilla"** approach: standard Web Technologies (HTML, CSS custom properties, Web Components) with zero runtime dependencies.

## 1. Architecture: The "Vanilla Sovereign" Stack

*   **Build Tool**: Vite (Multi-Page App Mode).
*   **Framework**: None (Vanilla TypeScript).
*   **Components**: Native Web Components (`customElements.define`).
*   **CSS**: CSS Variables for Theming (`theme.css`) + Utility Classes (`framework.css`).

### Why this choice?
1.  **Longevity**: Standard HTML/JS will run in 2036. React 18 might not.
2.  **Speed**: Zero JS payload interactions for static content.
3.  **Portability**: Can be hosted anywhere (Nginx, S3, Apache).

## 2. The Design System ("Hextech")

We use a "Magic vs Tech" aesthetic inspired by Arcane/Hextech.

### Core Tokens (`theme.css`)
*   **Gold**: `#c8aa6e` (Prestige, Sovereignty, Value) – Used for Borders, Key Text.
*   **Cyan**: `#0ac8b9` (Energy, Flow, AI) – Used for Actions, Gradients, Active States.
*   **Deep Void**: `#060b13` (The Unknown, Depth) – Main Background.

### Reusable Components
*   **`<sovereign-header>`**: Single source of truth for global navigation. Defined in `src/components/sovereign-header.ts`.
*   **`<sovereign-footer>`**: Standardized footer (Brand, Platform, Legal). Defined in `src/components/sovereign-footer.ts`.

## 3. Page Catalog

### 🏠 Home (`index.html`)
*   **Role**: Landing Page & Operator Console.
*   **Access**: 🌍 Public.
*   **Features**:
    *   Status Dashboard (Agents, System Health).
    *   "Protocol" Activation (Hero Button).
    *   Documentation Internal Links.

### 🧠 Memory (`memory.html`)
*   **Theme**: "Deep Space" (Darker, star-field background).
*   **Role**: Visualization of the Vector Database (Qdrant).
*   **Access**: 🔒 Private (Login Required).
*   **Features**:
    *   Explains Long-term Memory vs Short-term Context.
    *   Visual representation of "Embeddings".

### 🚀 Request Demo (`demo.html`)
*   **Theme**: "Business Light" (White Background, Clean Form).
    *   *Note*: Overrides default Dark Mode via `!important` CSS classes for professional appeal.
*   **Role**: Inbound Lead Capture.
*   **Access**: 🌍 Public.
*   **Features**:
    *   Multi-step Form.
    *   **Integration**: POST to `n8n` Webhook (`/webhook/demo-request`).
    *   Live validation.

## 4. How to Add a New Page

1.  Create `mypage.html` in the root.
2.  Add it to `vite.config.ts` inputs:
    ```ts
    input: {
      mypage: 'mypage.html'
    }
    ```
3.  Add the Header Component:
    ```html
    <sovereign-header active-page="docs"></sovereign-header>
    <script type="module" src="/src/components/sovereign-header.ts"></script>
    ```
4.  Run `npm run build`.
