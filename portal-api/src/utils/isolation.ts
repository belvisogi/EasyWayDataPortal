import path from 'path';

/**
 * TenantGuard enforces strict folder isolation for file operations.
 * It ensures that access is restricted to the specific tenant's directory
 * or shared core directories (read-only), preventing cross-tenant leakage.
 */
export class TenantGuard {
    private baseDir: string;

    constructor(baseDir: string = process.cwd()) {
        this.baseDir = path.resolve(baseDir);
    }

    /**
     * Validates if the requested path is safe for the given tenant.
     * 
     * Rules:
     * 1. Path must be within baseDir.
     * 2. Path must not contain traversal patterns (../) that escape scope.
     * 3. If writing, path MUST be within `agents/tenants/<tenantId>`.
     * 4. If reading, path CAN be within `agents/tenants/<tenantId>` OR `agents/core`.
     * 
     * @param targetPath The relative or absolute path to check.
     * @param tenantId The tenant ID requesting access.
     * @param operation 'read' or 'write'.
     * @returns True if safe, throws Error if unsafe.
     */
    validatePath(targetPath: string, tenantId: string, operation: 'read' | 'write' = 'read'): boolean {
        // Resolve absolute path
        const resolvedPath = path.isAbsolute(targetPath)
            ? path.resolve(targetPath)
            : path.resolve(this.baseDir, targetPath);

        // 1. Prevent Traversal: Must be inside baseDir
        if (!resolvedPath.startsWith(this.baseDir)) {
            throw new Error(`Security Violation: Path '${targetPath}' is outside the base directory.`);
        }

        const relativePath = path.relative(this.baseDir, resolvedPath);

        // Define allowable scopes
        const tenantScope = path.join('agents', 'tenants', tenantId);
        const coreScope = path.join('agents', 'core');

        // Check Tenant Scope (Always allowed)
        if (!relativePath.startsWith('..') && relativePath.startsWith(tenantScope)) {
            return true;
        }

        // Check Core Scope (Read-only)
        if (operation === 'read' && !relativePath.startsWith('..') && relativePath.startsWith(coreScope)) {
            return true;
        }

        // If we are here, access is denied
        throw new Error(`Security Violation: Access to '${targetPath}' is denied for tenant '${tenantId}'. Operation: ${operation}`);
    }
}
