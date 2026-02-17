import path from 'path';
import { TenantGuard } from '../src/utils/isolation';

describe('TenantGuard Isolation', () => {
    // Mock base dir to be a temp folder
    const mockBaseDir = path.resolve(__dirname, 'mock-root');
    const guard = new TenantGuard(mockBaseDir);
    const tenantId = 'tenant-123';

    it('should allow access to tenant workspace', () => {
        const target = `agents/tenants/${tenantId}/data.json`;
        expect(guard.validatePath(target, tenantId, 'write')).toBe(true);
    });

    it('should allow read access to core', () => {
        const target = `agents/core/config.json`;
        expect(guard.validatePath(target, tenantId, 'read')).toBe(true);
    });

    it('should DENY write access to core', () => {
        const target = `agents/core/config.json`;
        expect(() => guard.validatePath(target, tenantId, 'write')).toThrow();
    });

    it('should DENY access to other tenant', () => {
        const target = `agents/tenants/other-tenant/data.json`;
        expect(() => guard.validatePath(target, tenantId, 'read')).toThrow();
    });

    it('should DENY path traversal', () => {
        const target = `agents/tenants/${tenantId}/../../secrets.env`;
        expect(() => guard.validatePath(target, tenantId, 'read')).toThrow();
    });

    it('should DENY absolute paths outside root', () => {
        // Windows absolute path simulation might be tricky cross-platform, 
        // but TenantGuard resolves absolute paths against baseDir check.
        const outside = path.resolve(mockBaseDir, '../outside.txt');
        expect(() => guard.validatePath(outside, tenantId, 'read')).toThrow();
    });
});
