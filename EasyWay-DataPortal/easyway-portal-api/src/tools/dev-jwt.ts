import { generateKeyPair, exportJWK, SignJWT } from "jose";

async function main() {
  const tenantId = process.env.DEFAULT_TENANT_ID || "tenant01";
  const issuer = process.env.AUTH_ISSUER || "https://test-issuer/";
  const audience = process.env.AUTH_AUDIENCE || "api://test";

  const { publicKey, privateKey } = await generateKeyPair("RS256");
  const jwk = await exportJWK(publicKey);
  const jwks = { keys: [jwk] };

  const now = Math.floor(Date.now() / 1000);
  const token = await new SignJWT({ ew_tenant_id: tenantId, aud: audience })
    .setProtectedHeader({ alg: "RS256" })
    .setIssuedAt(now)
    .setIssuer(issuer)
    .setExpirationTime(now + 3600)
    .sign(privateKey);

  // eslint-disable-next-line no-console
  console.log("AUTH_TEST_JWKS=", JSON.stringify(jwks));
  // eslint-disable-next-line no-console
  console.log("Bearer ", token);
}

main().catch((e) => {
  // eslint-disable-next-line no-console
  console.error(e);
  process.exit(1);
});

