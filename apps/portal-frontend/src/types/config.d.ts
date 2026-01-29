export { };

declare global {
    interface Window {
        SOVEREIGN_CONFIG: {
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
    }
}
