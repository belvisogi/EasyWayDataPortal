# HDS Identity Protocol (The Interview)

*Use this script to extract the "Soul" of a new project from a client (or friend).*

## Phase 1: The Soul (Concept)
> "Non parlarmi di siti web. Parlami di chi sei."

1.  **Archetypes**:
    *   *Se il tuo progetto fosse un personaggio, chi sarebbe?* (Es. Iron Man, Gandalf, Il Padrino, Wall-E).
    *   *Perché?* (Potenza? Saggezza? Controllo? Simpatia?)
2.  **The Enemy**:
    *   *Chi state combattendo?* (Il Caos? La Lentezza? La Burocrazia?)
    *   *Questo definisce il "Mood" (Guerra = Scuro/Rosso, Pace = Chiaro/Blu).*

## Phase 2: The Suit (Visuals)
> "Adesso costruiamo l'armatura."

3.  **Primary Color (The Power Source)**:
    *   *Immagina il cuore del reattore. Di che colore brilla?*
    *   Mapping: `var(--accent-neural-cyan)`
4.  **Base Material (The Armour)**:
    *   *Di cosa è fatta la tua base?*
        *   Space Void (Black/Deep Blue) -> *Hextech / Cyber*
        *   Marble (White/Grey) -> *Enterprise / Medical*
        *   Steel (Grey/Silver) -> *Industrial*
    *   Mapping: `var(--bg-deep-void)`
5.  **Authority (The Trim)**:
    *   *Qual è il colore del comando?* (Gold? Silver? Red?)
    *   Mapping: `var(--text-sovereign-gold)`

## Phase 3: The Configuration (Execution)

Once you have the answers, open `src/theme.css` and map them:

```css
:root {
    /* PHASE 2 ANSWERS */
    --bg-deep-void:       [BASE MATERIAL]; 
    --text-sovereign-gold:[AUTHORITY];     
    --accent-neural-cyan: [POWER SOURCE];  
    
    /* DERIVED VALUES */
    --glass-border:       [AUTHORITY (opacity 0.2)];
    --glass-bg:           [BASE MATERIAL (opacity 0.7)];
}
```

### Example: "The Forest Guardian" (Druid Vibe)
*   **Soul**: Gandalf / Nature.
*   **Power**: Green Life (`#10b981`).
*   **Material**: Deep Moss (`#064e3b`).
*   **Authority**: Wood Brown (`#d97706`).

**Result:** You change 3 lines, and the entire "Hextech" interface becomes a "Druid" interface instantly. Everything (Buttons, Headers, Grids) adapts properly.
