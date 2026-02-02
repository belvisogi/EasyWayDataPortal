import type { PageSpecV1, PagesManifestV1 } from '../types/runtime-pages';
import { getStaticUrl } from './env';

async function fetchJson<T>(path: string): Promise<T> {
    try {
        const url = path.startsWith('http') ? path : getStaticUrl(path);
        const res = await fetch(url, { cache: 'no-store' });
        if (!res.ok) throw new Error(`Failed to fetch ${path} (${res.status})`);
        const raw = await res.text();
        try {
            return JSON.parse(raw) as T;
        } catch (err) {
            console.error(`[PagesLoader] Invalid JSON at ${path}`, err);
            throw err;
        }
    } catch (err) {
        console.error(`[PagesLoader] Fetch failed for ${path}`, err);
        throw err;
    }
}

export async function loadPagesManifest(): Promise<PagesManifestV1> {
    return await fetchJson<PagesManifestV1>('/pages/pages.manifest.json');
}

export async function loadPageSpec(specPath: string): Promise<PageSpecV1> {
    return await fetchJson<PageSpecV1>(specPath);
}

export function normalizePathname(pathname: string): string {
    if (!pathname) return '/';
    if (pathname !== '/' && pathname.endsWith('/')) return pathname.slice(0, -1);
    return pathname;
}

export function resolvePageIdByRoute(manifest: PagesManifestV1, pathname: string): string | null {
    const normalized = normalizePathname(pathname);
    const page = manifest.pages.find(p => normalizePathname(p.route) === normalized);
    return page ? page.id : null;
}
