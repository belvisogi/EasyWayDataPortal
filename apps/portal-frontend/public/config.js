/**
 * SOVEREIGN CONFIGURATION
 * This file is loaded at runtime.
 * It allows configuration changes without rebuilding the application container.
 */

window.SOVEREIGN_CONFIG = {
    // i18n
    i18n: {
        // Default language for content overlays (content.<lang>.json)
        lang: "it"
    },

    // Theme packs (runtime). A page can override via PageSpec.themeId.
    theme: {
        defaultId: "easyway-arcane",

        // Precedence of CSS var sources:
        // - "branding_over_theme": theme packs first, then branding.json (customer/instance overrides win)
        // - "theme_over_branding": branding.json first, then theme packs (theme packs win)
        precedence: "branding_over_theme"
    },

    // Infrastructure
    // Default to localhost for dev, overwrite in prod
    apiEndpoint: "http://localhost:5678",

    // Feature Flags - Can be toggled live
    features: {
        matrixMode: true,    // Enable visual particles
        dragDrop: true,      // Enable file ingestion
        gediProtocol: true   // Enable safety guards
    },

    // System Behavior
    system: {
        version: "0.3.1",
        id: "SOVEREIGN-ONE",
        uploadTimeoutMs: 30000
    }
};

console.log(`[SOVEREIGN] Runtime Config Loaded: ${window.SOVEREIGN_CONFIG.apiEndpoint}`);
