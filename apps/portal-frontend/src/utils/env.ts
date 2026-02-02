/**
 * Environment Detection Utility
 * Antifragile: Works with any domain (IP, localhost, production domain)
 */

export function getBaseUrl(): string {
    // Priority 1: Explicit config (set after DNS purchase)
    if (window.SOVEREIGN_CONFIG?.apiEndpoint) {
        return window.SOVEREIGN_CONFIG.apiEndpoint;
    }

    // Priority 2: Current origin (works everywhere)
    return window.location.origin;
}

export function getApiUrl(path: string): string {
    const base = getBaseUrl();
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    return `${base}${cleanPath}`;
}

export function getStaticUrl(path: string): string {
    const base = window.location.origin;
    const cleanPath = path.startsWith('/') ? path : `/${path}`;
    return `${base}${cleanPath}`;
}

export function isDevelopment(): boolean {
    return window.location.hostname === 'localhost' ||
        window.location.hostname === '127.0.0.1';
}

export function isProduction(): boolean {
    return !isDevelopment();
}

export function getCurrentDomain(): string {
    return window.location.hostname;
}
