export { };

declare global {
    interface Window {
        SOVEREIGN_CONFIG: {
            i18n?: {
                lang?: string;
            };
            theme?: {
                defaultId?: string;
                precedence?: "branding_over_theme" | "theme_over_branding";
            };
            apiEndpoint: string;
            features?: {
                matrixMode?: boolean;
                dragDrop?: boolean;
                gediProtocol?: boolean;
            };
            system?: {
                version: string;
                id: string;
                uploadTimeoutMs: number;
            };
        };
        SOVEREIGN_CONTENT?: any;
        SOVEREIGN_ASSETS?: any;
        SOVEREIGN_THEME?: any;
    }
}
