/**
 * easyway-core (main.ts)
 * ----------------------
 * @branding EasyWay Core
 * @codebase EasyWayDataPortal
 * 
 * ARCHITECTURAL NOTE:
 * We intentionally keep the 'EasyWayDataPortal' namespace in code to ensure
 * backward compatibility with Docker volumes and GitOps scripts.
 * The UI renders "EasyWay Core".
 */
// ---------------------------------------------------------------------------
// "Non costruiamo software. Coltiviamo ecosistemi di pensiero." 
// Co-Authored: gbelviso78 & Antigravity/Codex/ChatGPT (2026-01-30)
// ---------------------------------------------------------------------------
import { loadBranding } from './utils/theme-loader';
import { loadContent } from './utils/content-loader';
import { initRuntimePages } from './utils/runtime-pages';
import './components/sovereign-header';
import './components/sovereign-footer';

let navBound = false;

function bindGlobalRuntimeNav() {
    if (navBound) return;
    const root = document.getElementById('page-root');
    if (!root) return;

    navBound = true;
    document.addEventListener('click', (e) => {
        const target = e.target as HTMLElement | null;
        const anchor = target?.closest('a') as HTMLAnchorElement | null;
        if (!anchor) return;
        if (anchor.target === '_blank') return;
        if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;

        const href = anchor.getAttribute('href');
        if (!href) return;
        if (href.startsWith('http') || href.startsWith('#') || anchor.hasAttribute('download')) return;
        if (!href.startsWith('/')) return;
        if (href.endsWith('.html')) return;

        e.preventDefault();
        window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
        window.history.pushState({}, '', href);
        initRuntimePages().catch(console.error);
    });
}

async function bootstrap() {
    const precedence = window.SOVEREIGN_CONFIG?.theme?.precedence || 'branding_over_theme';

    // Always load content first so the header/page renderer can resolve keys.
    await loadContent();

    if (precedence === 'theme_over_branding') {
        // branding.json first, theme packs after (theme wins)
        await loadBranding();
        await initRuntimePages();
        bindGlobalRuntimeNav();
        return;
    }

    // Default: theme packs first, branding.json last (branding wins)
    await initRuntimePages();
    bindGlobalRuntimeNav();
    await loadBranding();
}

bootstrap().catch((err) => console.error('[Sovereign] Bootstrap failed', err));

console.log(
    '%c EasyWay Core %c Sovereign Intelligence Online ',
    'background: #eaa91c; color: #000; font-weight: bold; padding: 4px; border-radius: 4px 0 0 4px;',
    'background: #060b13; color: #4deeea; padding: 4px; border-radius: 0 4px 4px 0;'
);

console.log('%c > Ci adattiamo alle novita evolvendoci grazie a loro.', 'color: #888; font-style: italic;');
