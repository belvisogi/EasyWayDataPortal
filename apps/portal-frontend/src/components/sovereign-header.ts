/**
 * Sovereign Header Component
 * Encapsulates the global navigation logic and standard styling.
 * 
 * Usage: <sovereign-header active-page="home|memory|n8n|docs"></sovereign-header>
 */

import { getContentValue } from '../utils/content';
import type { PagesManifestV1 } from '../types/runtime-pages';

export class SovereignHeader extends HTMLElement {
    private manifest: PagesManifestV1 | null = null;

    constructor() {
        super();
    }

    connectedCallback() {
        const activePage = this.getAttribute('active-page') || 'home';
        this.renderShell(activePage);

        this.loadManifestAndRenderNav(activePage).catch(console.error);
        window.addEventListener('sovereign:content-loaded', () => {
            this.renderNav(activePage);
        });

        // 🥚 EASTER EGG: The Warren Robinett Tribute
        let clicks = 0;
        this.querySelector('#egg-icon')?.addEventListener('click', (e) => {
            e.preventDefault();
            e.stopPropagation(); // Stop Navigation
            clicks++;
            if (clicks === 5) {
                alert("🕹️ SECRET FOUND\n\nCreated by gbelviso78\n& Antigravity/Codex/ChatGPT\n\n(The Sovereign Architects)");
                clicks = 0;
            }
        });
    }

    private renderShell(activePage: string) {
        this.innerHTML = `
    <header class="site-header">
        <div class="header-container">
            <a href="/" class="logo">
                <svg id="egg-icon" width="32" height="32" viewBox="0 0 40 40" fill="none" xmlns="http://www.w3.org/2000/svg" style="margin-right: 12px; cursor: pointer;">
                    <rect x="4" y="4" width="32" height="32" rx="6" stroke="var(--text-sovereign-gold)" stroke-width="3" fill="rgba(6, 11, 19, 0.9)"/>
                    <path d="M14 12H10V28H14" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M26 12H30V28H26" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M20 10V30" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <path d="M10 20H30" stroke="var(--accent-neural-cyan)" stroke-width="3" stroke-linecap="round"/>
                    <circle cx="20" cy="20" r="4" fill="var(--text-sovereign-gold)" stroke="none"/>
                </svg>
                EasyWay Core
            </a>
            <nav class="nav-links" id="nav-links"></nav>
            <div class="header-actions">
                <a href="/demo.html" class="btn-glass ${activePage === 'demo' ? 'active-btn' : ''}">${getContentValue('nav.cta_demo', 'Request Demo')}</a>
            </div>
        </div>
    </header>
        `;
    }

    private async loadManifestAndRenderNav(activePage: string) {
        try {
            const res = await fetch('/pages/pages.manifest.json', { cache: 'no-store' });
            if (!res.ok) return;
            this.manifest = await res.json();
            this.renderNav(activePage);
        } catch {
            // Best-effort: keep header usable even if runtime content is missing.
        }
    }

    private renderNav(activePage: string) {
        const nav = this.querySelector('#nav-links');
        if (!nav) return;

        if (!this.manifest?.pages?.length) {
            nav.innerHTML = `
                <a href="/" class="${activePage === 'home' ? 'active' : ''}">Home</a>
                <a href="/manifesto" class="${activePage === 'manifesto' ? 'active' : ''}">Manifesto</a>
                <a href="/demo" class="${activePage === 'demo' ? 'active' : ''}">Demo</a>
            `;
            return;
        }

        const pages = this.manifest.pages
            .filter(p => !!p.nav)
            .sort((a, b) => (a.nav?.order ?? 0) - (b.nav?.order ?? 0));

        const hoverCopy: Record<string, string> = {
            manifesto: 'Principi e visione',
            memory: 'Your data. Your intelligence.',
            demo: 'See it in action',
            pricing: 'Piani & sconto sociale'
        };

        nav.innerHTML = '';
        for (const p of pages) {
            const a = document.createElement('a');
            a.href = p.route;
            a.textContent = getContentValue(p.nav!.labelKey, p.id);
            if (hoverCopy[p.id]) a.title = hoverCopy[p.id];
            if (activePage === p.id) a.classList.add('active');
            nav.appendChild(a);
        }
    }
}

// Self-Register
customElements.define('sovereign-header', SovereignHeader);
