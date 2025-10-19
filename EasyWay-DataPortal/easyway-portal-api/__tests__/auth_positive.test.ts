import request from 'supertest';
import { SignJWT, exportJWK, generateKeyPair } from 'jose';
import app from '../src/app';

describe('Auth positive with mock JWT', () => {
  let token: string;
  beforeAll(async () => {
    const { publicKey, privateKey } = await generateKeyPair('RS256');
    const pubJwk = await exportJWK(publicKey);
    // Provide local JWKS via env so middleware uses createLocalJWKSet
    process.env.AUTH_TEST_JWKS = JSON.stringify({ keys: [pubJwk] });
    process.env.AUTH_ISSUER = 'https://test-issuer/';
    process.env.AUTH_AUDIENCE = 'api://test';
    process.env.TENANT_CLAIM = 'ew_tenant_id';
    const now = Math.floor(Date.now() / 1000);
    token = await new SignJWT({ ew_tenant_id: 'tenant01', aud: 'api://test' })
      .setProtectedHeader({ alg: 'RS256' })
      .setIssuedAt(now)
      .setIssuer('https://test-issuer/')
      .setExpirationTime(now + 60)
      .sign(privateKey);
  });

  it('GET /api/health returns 200 with tenant when authorized', async () => {
    const res = await request(app).get('/api/health').set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(200);
    expect(res.body).toHaveProperty('tenant');
    expect(res.body.tenant).toBe('tenant01');
  });
});

