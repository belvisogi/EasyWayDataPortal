import type { PageSpecV1 } from '../types/runtime-pages';

type AssetsManifest = {
    version: string;
    images?: Record<string, string>;
};

type ThemePacksManifest = {
    version: string;
    defaultId: string;
    packs: Record<string, string>;
};

type ThemePack = {
    version: string;
    id: string;
    label?: string;
    cssVars?: Record<string, string>;
    assets?: Record<string, string>;
};

async function fetchJson<T>(path: string): Promise<T | null> {
    try {
        const res = await fetch(path, { cache: 'no-store' });
        if (!res.ok) return null;
        return await res.json() as T;
    } catch {
        return null;
    }
}

function mergeObjects<T extends Record<string, any>>(base: T, overlay: T): T {
    return { ...base, ...overlay };
}

function applyCssVars(vars: Record<string, string>) {
    const root = document.documentElement;
    for (const [k, v] of Object.entries(vars)) root.style.setProperty(k, v);
}

function applyThemeClass(themeId: string) {
    const body = document.body;
    const prev = body.getAttribute('data-theme');
    if (prev) body.classList.remove(`theme-${prev}`);
    body.setAttribute('data-theme', themeId);
    body.classList.add(`theme-${themeId}`);
}

export async function applyThemePacksForPage(page: PageSpecV1): Promise<void> {
    // Load assets registry (optional but recommended).
    const assets = await fetchJson<AssetsManifest>('/assets.manifest.json');
    window.SOVEREIGN_ASSETS = assets || {};

    const packsManifest = await fetchJson<ThemePacksManifest>('/theme-packs.manifest.json');
    if (!packsManifest?.packs) {
        // No packs configured -> do nothing.
        return;
    }

    const globalId =
        window.SOVEREIGN_CONFIG?.theme?.defaultId ||
        packsManifest.defaultId;

    const pageId = page.themeId || null;

    const globalPath = packsManifest.packs[globalId];
    const pagePath = pageId ? packsManifest.packs[pageId] : null;

    const globalPack = globalPath ? await fetchJson<ThemePack>(globalPath) : null;
    const pagePack = pagePath ? await fetchJson<ThemePack>(pagePath) : null;

    const mergedCss = mergeObjects(globalPack?.cssVars || {}, pagePack?.cssVars || {});
    const mergedAssets = mergeObjects(globalPack?.assets || {}, pagePack?.assets || {});

    const appliedId = pageId || globalId;
    applyThemeClass(appliedId);
    applyCssVars(mergedCss);

    // Convenience: promote common asset ids into CSS variables so pages can remain declarative.
    const heroBgId = mergedAssets.heroBgId as string | undefined;
    const heroBgPath = heroBgId ? (window.SOVEREIGN_ASSETS?.images?.[heroBgId] as string | undefined) : undefined;
    document.documentElement.style.setProperty(
        '--sovereign-hero-bg-image',
        heroBgPath ? `url('${heroBgPath}')` : 'none'
    );

    window.SOVEREIGN_THEME = {
        id: appliedId,
        globalId,
        pageId,
        cssVars: mergedCss,
        assets: mergedAssets
    };

    window.dispatchEvent(new CustomEvent('sovereign:theme-applied', { detail: { id: appliedId } }));
}
