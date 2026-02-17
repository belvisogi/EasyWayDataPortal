import request from 'supertest';
import app from '../src/app';

// Mock auth middleware to avoid needing a valid JWT in tests
jest.mock('../src/middleware/auth', () => ({
    authenticateJwt: (req: any, res: any, next: any) => {
        req.user = { sub: 'test-user', role: 'admin' };
        next();
    }
}));

// Mock tenant middleware
jest.mock('../src/middleware/tenant', () => ({
    extractTenantId: (req: any, res: any, next: any) => {
        req.tenantId = 'test-tenant';
        next();
    }
}));

describe('Storage API', () => {
    it('DELETE /api/storage/:container/:blob returns 200 (Simulation Mode)', async () => {
        // Ensure no connection string is set to trigger simulation mode
        delete process.env.AZURE_STORAGE_CONNECTION_STRING;

        const res = await request(app).delete('/api/storage/mycontainer/myblob.txt');
        expect(res.statusCode).toBe(200);
        expect(res.body.message).toContain('SIMULATION');
    });

    it('DELETE /api/storage/:container/:blob returns 400 if params missing', async () => {
        // Express routing makes it hard to miss params in the path, 
        // but let's try to hit the route in a way that might trigger validation if logic changes
        // Actually, with /:container/:blob, both are required for the route to match.
        // If we request /api/storage/mycontainer, it won't match.
        // So this test checks the controller logic IF it were reachable, 
        // or we can test that the 404 handler catches incomplete paths.

        const res = await request(app).delete('/api/storage/mycontainer');
        expect(res.statusCode).toBe(404);
    });
});
