---
name: valentino-premium-design
description: Review and generate UI/UX design components with Antigravity Premium Design standards. Use when asked to generate wireframes, create design systems, mockups, or implement pixel-perfect UI.
---

# Valentino Premium Design

Run this skill to elevate UI generation, wireframing, and component implementation to a Figma-level premium standard.

## 🎯 When To Use
- The user asks you to "design a mockup", "create a wireframe", or "ideate a UX".
- The user asks you to "create a design system" or "generate CSS/Tailwind rules".
- The user asks you to "implement a pixel-perfect UI" or "refine the aesthetics of a component".

## 💎 The Antigravity Aesthetic Pillars
You must enforce and apply these three pillars when analyzing or generating UI code:

### 1. Mockup & Layout Ideation (UX Generation)
- NEVER start coding without defining the structure first.
- Provide a structured layout plan (Wireframe text format) separating Header, Content, Sidebar, and Modals.
- Enforce negative space (padding/margin) to let the content breathe. Do not cram elements together.

### 2. Design System Generation (Tokens & Styles)
- **Palette**: Avoid generic primary colors (e.g., "red", "blue", "green"). Generate curated HSL/RGB palettes (e.g., Slate, Zinc, Emerald). Provide a distinct Light and Dark mode.
- **Typography**: Mandate modern sans-serif fonts (e.g., `Inter`, `Roboto`, `Outfit`, `SF Pro Display`).
- **Gradients & Shadows**: Use soft, multi-layered shadows (`box-shadow: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);`). Use subtle gradients instead of flat backgrounds where appropriate.

### 3. Pixel-Perfect Implementation (Micro-animations)
- **Hover & Focus States**: Every interactive element MUST have a visible, smooth transition on hover, active, and focus (`transition: all 0.2s ease-in-out;`).
- **Micro-animations**: Suggest adding small scale impacts on button press (`transform: scale(0.98)`).
- **Glassmorphism**: When building modals, dropdowns, or sticky navs, favor frosted-glass effects (`backdrop-filter: blur(12px)`) instead of solid colors.

## 🏁 Output Expectations
1. When asked to review: Provide a detailed audit against the three pillars above. Point out where the UI feels "cheap" or "static" and provide the exact CSS/Tailwind classes to fix it.
2. When asked to generate: Deliver the component code fully polished, incorporating animations, modern typographic scales, and premium color tokens natively.
