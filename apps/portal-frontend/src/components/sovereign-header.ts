/**
 * Sovereign Header Component
 * Encapsulates the global navigation logic and standard styling.
 * 
 * Usage: <sovereign-header active-page="home|memory|n8n|docs"></sovereign-header>
 */

export class SovereignHeader extends HTMLElement {
    constructor() {
        super();
    }

    connectedCallback() {
        const activePage = this.getAttribute('active-page') || 'home';

        this.innerHTML = `
    <header class="site-header">
        <div class="header-container">
            <a href="/" class="logo">
                <svg width="32" height="32" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-right: 12px;">
                    <rect x="4" y="4" width="32" height="32" rx="6" stroke="var(--text-sovereign-gold)" stroke-width="3" fill="rgba(6, 11, 19, 0.9)"/>
                    <path d="M14 12H10V28H14" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M26 12H30V28H26" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M20 10V30" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M10 20H30" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <circle cx="20" cy="20" r="4" fill="var(--text-sovereign-gold)" stroke="none"/>
                </svg>
                EasyWay
            </a>
            <nav class="nav-links">
                <a href="/" class="${activePage === 'home' ? 'active' : ''}">Home</a>
                <a href="/memory.html" class="${activePage === 'memory' ? 'active' : ''}">Memory</a>
                <a href="/n8n/" class="${activePage === 'n8n' ? 'active' : ''}">N8N</a>
                <a href="#docs">Docs</a>
            </nav>
            <div class="header-actions">
                <a href="/demo.html?ref=nav" class="btn-glass ${activePage === 'demo' ? 'active-btn' : ''}">Request Demo</a>
            </div>
        </div>
    </header>
        `;
    }
}

// Self-Register
customElements.define('sovereign-header', SovereignHeader);
