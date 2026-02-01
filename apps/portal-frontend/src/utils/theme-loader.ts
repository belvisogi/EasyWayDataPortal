export async function loadBranding(): Promise<void> {
    try {
        const response = await fetch('/branding.json', { cache: 'no-store' });
        if (!response.ok) throw new Error('Failed to load branding');

        const config = await response.json();
        const root = document.documentElement;

        // Apply Colors
        if (config.theme?.colors) {
            Object.entries(config.theme.colors).forEach(([key, value]) => {
                root.style.setProperty(key, value as string);
            });
        }

        // Apply Fonts
        if (config.theme?.fonts) {
            Object.entries(config.theme.fonts).forEach(([key, value]) => {
                root.style.setProperty(key, value as string);
            });
        }

        console.log(`🦅 [SovereignTheme] Identity Loaded: ${config.meta.name}`);
    } catch (error) {
        console.warn('⚠️ [SovereignTheme] Fallback to default styles.', error);
    } finally {
        (window as any).SOVEREIGN_BRANDING_READY = true;
        window.dispatchEvent(new CustomEvent('sovereign:branding-loaded'));
    }
}
