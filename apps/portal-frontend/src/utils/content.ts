export function getContentValue(key: string, fallback: string = ''): string {
    const data = window.SOVEREIGN_CONTENT || {};
    const value = key.split('.').reduce((obj, k) => (obj ? obj[k] : undefined), data);

    if (value === undefined || value === null) return fallback || key;
    return String(value);
}
