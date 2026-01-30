# Hextech Design System (HDS)
*Version 1.0 - "Sovereign Evolution"*

The Hextech Design System is the visual language of the EasyWay ecosystem, fusing enterprise authority ("Sovereign") with advanced technological power ("Hextech").

##  Core Palette

| Variable | Value | Description |
| :--- | :--- | :--- |
| `--bg-deep-void` | `#060b13` | **Piltover Night**. Creating infinite depth behind content. |
| `--text-sovereign-gold` | `#c8aa6e` | **Brass Authority**. Used for logos, borders, and hierarchy. |
| `--accent-neural-cyan` | `#0ac8b9` | **Hextech Glow**. The energy source/interaction color. |
| `--glass-bg` | `rgba(6,11,19, 0.7)` | **Void Glass**. translucent surfaces. |

##  Framework Elements ("The Suit")

### 1. Electrical Foundations
The background stack is a layered composite:
1.  **Deep Void**: Base layer.
2.  **Radial Heart**: A deep blue (`#0f2538`) radial gradient at `50% 30%`.
3.  **Active Grid**: Cyan-tinted (`rgba(10,200,185,0.05)`) grid lines.

### 2. The Energy Seal (Header)
A navigation bar characterized by:
-   **Backdrop**: 85% opacity Void Glass + 16px Blur.
-   **Border**: `linear-gradient` fading from Gold (Center) to Transparent (Edges).

### 3. Hextech Crystal (Buttons)
Buttons are designed as power cells:
-   **Border/Text**: Hextech Cyan.
-   **Glow**: Inner shadow + Drop shadow (`0 0 10px`).
-   **Hover**: Fill with energy (Cyan background, Void text).

### 4. Labyrinth Vector (Logo)
-   **Construction**: Code-native SVG.
-   **Shape**: Gold Shield (Square) + Cyan Maze Path + Core.
-   **Behavior**: Responsive sizing (48px Desktop -> 32px Mobile).

##  Exportable CSS ("The Package")

To use this framework in other apps (e.g., EasyWay Console):

```css
/* hextech.css */
:root {
    --bg-deep-void: #060b13;
    --text-sovereign-gold: #c8aa6e;
    --accent-neural-cyan: #0ac8b9;
    --font-family: 'Inter', sans-serif;
}

body {
    background: var(--bg-deep-void);
    color: #f0f2f5;
    font-family: var(--font-family);
}

.hex-btn {
    border: 1px solid var(--accent-neural-cyan);
    color: var(--accent-neural-cyan);
    box-shadow: 0 0 10px rgba(10, 200, 185, 0.1);
}
```

