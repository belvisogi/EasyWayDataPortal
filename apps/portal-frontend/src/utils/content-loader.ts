function resolveKeyPath(data: any, key: string): any {
    return key.split('.').reduce((obj, k) => (obj ? obj[k] : undefined), data);
}

async function fetchJson(path: string): Promise<any | null> {
    try {
        const res = await fetch(path, { cache: 'no-store' });
        if (!res.ok) return null;
        return await res.json();
    } catch {
        return null;
    }
}

function deepMerge(base: any, overlay: any): any {
    if (Array.isArray(base) || Array.isArray(overlay)) return overlay ?? base;
    if (typeof base !== 'object' || base === null) return overlay ?? base;
    if (typeof overlay !== 'object' || overlay === null) return overlay ?? base;

    const out: any = { ...base };
    for (const [k, v] of Object.entries(overlay)) {
        out[k] = deepMerge((base as any)[k], v);
    }
    return out;
}

function pickLanguage(): string {
    const cfg = window.SOVEREIGN_CONFIG || {};
    const fromCfg = cfg?.i18n?.lang;

    const nav = (typeof navigator !== 'undefined' && navigator.language) ? navigator.language : 'it';
    const nav2 = nav.slice(0, 2).toLowerCase();

    return (fromCfg || nav2 || 'it').toLowerCase();
}

export async function loadContent(): Promise<any> {
    const lang = pickLanguage();

    // Base dictionary (preferred): /content/base.json
    // Legacy fallback: /content.json
    const base = (await fetchJson('/content/base.json')) || (await fetchJson('/content.json')) || {};

    // Optional language overlay: keep it small, override only what differs.
    const overlays = [
        `/content/${lang}.json`,
        `/content/it.json`,
        `/content.${lang}.json`,
        `/content.it.json`
    ];

    let overlay: any | null = null;
    for (const path of overlays) {
        overlay = await fetchJson(path);
        if (overlay) break;
    }

    const data = deepMerge(base, overlay || {});

    window.SOVEREIGN_CONTENT = data;
    window.dispatchEvent(new CustomEvent('sovereign:content-loaded', { detail: { lang } }));

    // Back-compat: inject into any static markup that still uses data-key.
    const elements = document.querySelectorAll('[data-key]');
    elements.forEach(el => {
        const key = el.getAttribute('data-key');
        if (!key) return;

        const value = resolveKeyPath(data, key);
        if (value === undefined || value === null) {
            console.warn(`[ContentLoader] Missing key: ${key}`);
            return;
        }

        if (typeof value === 'string' && value.includes('<')) {
            (el as HTMLElement).innerHTML = value;
        } else {
            el.textContent = String(value);
        }
    });

    console.log(`🦅 [SovereignContent] Loaded language '${lang}'`);
    return data;
}
