import { Request, Response, NextFunction } from "express";

type AccessSpec = {
  roles?: string[];
  scopes?: string[];
};

function parseCsv(value?: string): string[] {
  if (!value) return [];
  return value.split(",").map((v) => v.trim()).filter(Boolean);
}

function asArray(value: unknown): string[] {
  if (Array.isArray(value)) return value.map((v) => String(v)).filter(Boolean);
  if (typeof value === "string") return value.split(" ").map((v) => v.trim()).filter(Boolean);
  return [];
}

function getRoles(payload: any): string[] {
  const claim = process.env.AUTH_ROLE_CLAIM || "roles";
  return asArray(payload?.[claim]);
}

function getScopes(payload: any): string[] {
  const claim = process.env.AUTH_SCOPE_CLAIM || "scp";
  return asArray(payload?.[claim]);
}

function hasAny(required: string[], actual: string[]): boolean {
  if (required.length === 0) return true;
  const set = new Set(actual.map((v) => v.toLowerCase()));
  return required.some((r) => set.has(r.toLowerCase()));
}

export function requireAccess(spec: AccessSpec) {
  return (req: Request, res: Response, next: NextFunction) => {
    const user = (req as any).user;
    if (!user) return res.status(401).json({ error: "Missing user context" });

    const roles = getRoles(user);
    const scopes = getScopes(user);
    const requiredRoles = spec.roles ?? [];
    const requiredScopes = spec.scopes ?? [];

    const ok = hasAny(requiredRoles, roles) || hasAny(requiredScopes, scopes);
    if (!ok) {
      return res.status(403).json({ error: "Forbidden", requiredRoles, requiredScopes });
    }
    next();
  };
}

export function requireAccessFromEnv(opts: {
  rolesEnv?: string;
  scopesEnv?: string;
  defaultRoles?: string[];
  defaultScopes?: string[];
}) {
  const roles = parseCsv(opts.rolesEnv ? process.env[opts.rolesEnv] : undefined);
  const scopes = parseCsv(opts.scopesEnv ? process.env[opts.scopesEnv] : undefined);
  return requireAccess({
    roles: roles.length ? roles : (opts.defaultRoles ?? []),
    scopes: scopes.length ? scopes : (opts.defaultScopes ?? [])
  });
}
