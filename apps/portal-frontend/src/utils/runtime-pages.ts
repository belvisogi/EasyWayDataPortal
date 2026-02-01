import { loadPagesManifest, loadPageSpec, normalizePathname, resolvePageIdByRoute } from './pages-loader';
import { renderPage } from './pages-renderer';
import { applyThemePacksForPage } from './theme-packs-loader';

function setHeaderActive(active: string) {
    const header = document.querySelector('sovereign-header');
    if (!header) return;
    header.setAttribute('active-page', active);
}

function scrollToTop(): void {
    window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
}

export async function initRuntimePages(): Promise<void> {
    const root = document.getElementById('page-root');
    if (!root) {
        console.warn('[RuntimePages] Missing #page-root. Skipping runtime pages init.');
        return;
    }

    const pathname = normalizePathname(window.location.pathname);
    if (pathname === '/manifesto') {
        window.location.replace('/manifesto.html');
        return;
    }

    let manifest;
    try {
        manifest = await loadPagesManifest();
    } catch (err) {
        root.textContent = 'Runtime pages manifest not found.';
        console.error('[RuntimePages] Failed to load pages manifest', err);
        return;
    }

    const pageId = resolvePageIdByRoute(manifest, pathname) || resolvePageIdByRoute(manifest, '/');
    if (!pageId) {
        root.textContent = 'No pages configured.';
        return;
    }

    const pageEntry = manifest.pages.find(p => p.id === pageId);
    if (!pageEntry) {
        root.textContent = 'Page not found in manifest.';
        return;
    }

    let pageSpec;
    try {
        pageSpec = await loadPageSpec(pageEntry.spec);
    } catch (err) {
        root.textContent = `Failed to load page spec: ${pageEntry.spec}`;
        console.error('[RuntimePages] Failed to load page spec', err);
        return;
    }

    // Apply theme packs (global + per-page override) before rendering.
    await applyThemePacksForPage(pageSpec);

    setHeaderActive(pageSpec.activeNav || pageSpec.id);
    renderPage(root, pageSpec, manifest);
    scrollToTop();

    // Bind navigation once per session.
    const anyRoot = root as any;
    if (!anyRoot.__sovereignNavBound) {
        anyRoot.__sovereignNavBound = true;

        // Simple client-side navigation for internal links.
        root.addEventListener('click', (e) => {
            const target = e.target as HTMLElement | null;
            const anchor = target?.closest('a') as HTMLAnchorElement | null;
            if (!anchor) return;
            const href = anchor.getAttribute('href');
            if (!href) return;

            // Let the browser handle external links, hashes, and downloads.
            if (href.startsWith('http') || href.startsWith('#') || anchor.hasAttribute('download')) return;

            // Only intercept same-origin absolute paths.
            if (!href.startsWith('/')) return;

            const nextId = resolvePageIdByRoute(manifest, normalizePathname(href));
            if (!nextId) return;

            e.preventDefault();
            window.history.pushState({}, '', href);
            scrollToTop();
            initRuntimePages().catch(console.error);
        });

        window.addEventListener('popstate', () => {
            scrollToTop();
            initRuntimePages().catch(console.error);
        });
    }
}
