/**
 * SOVEREIGN CONFIGURATION
 * This file is loaded at runtime.
 * It allows configuration changes without rebuilding the application container.
 */

window.SOVEREIGN_CONFIG = {
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
        version: "0.3.0",
        id: "SOVEREIGN-ONE",
        uploadTimeoutMs: 30000
    }
};

console.log(`[SOVEREIGN] Runtime Config Loaded: ${window.SOVEREIGN_CONFIG.apiEndpoint}`);
