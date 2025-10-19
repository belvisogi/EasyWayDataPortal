import { Request, Response, NextFunction } from "express";
import { createRemoteJWKSet, createLocalJWKSet, jwtVerify, JWTPayload, JWK } from "jose";

let jwks: ReturnType<typeof createRemoteJWKSet> | ReturnType<typeof createLocalJWKSet> | null = null;

function getTenantFromClaims(payload: JWTPayload): string | undefined {
  const claimName = process.env.TENANT_CLAIM || "ew_tenant_id";
  const value = (payload as any)[claimName];
  if (typeof value === "string") return value;
  return undefined;
}

export async function authenticateJwt(req: Request, res: Response, next: NextFunction) {
  try {
    const auth = req.headers.authorization || "";
    const token = auth.startsWith("Bearer ") ? auth.substring(7) : null;
    if (!token) return res.status(401).json({ error: "Missing Bearer token" });

    const issuer = process.env.AUTH_ISSUER;
    const audience = process.env.AUTH_AUDIENCE;
    const jwksUri = process.env.AUTH_JWKS_URI;
    const testJwksText = process.env.AUTH_TEST_JWKS || process.env.AUTH_TEST_JWK;
    if ((!jwksUri && !testJwksText) || !issuer) {
      return res.status(500).json({ error: "Auth not configured" });
    }

    if (!jwks) {
      if (testJwksText) {
        try {
          // Accept single JWK or JWKS
          const parsed = JSON.parse(testJwksText);
          const jwksObj = (parsed.keys ? parsed : { keys: [parsed as JWK] });
          jwks = createLocalJWKSet(jwksObj as any);
        } catch {
          return res.status(500).json({ error: "Invalid AUTH_TEST_JWK(S) JSON" });
        }
      } else if (jwksUri) {
        jwks = createRemoteJWKSet(new URL(jwksUri));
      }
    }

    const { payload } = await jwtVerify(token, jwks, {
      issuer,
      audience,
      algorithms: ["RS256", "PS256"],
    });

    (req as any).user = payload;
    const tenantId = getTenantFromClaims(payload);
    if (tenantId) (req as any).tenantId = tenantId;

    return next();
  } catch (err: any) {
    return res.status(401).json({ error: "Invalid token", details: err?.message });
  }
}
