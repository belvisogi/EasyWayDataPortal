import request from 'supertest';
import app from '../src/app';

describe('Auth-required endpoints', () => {
  it('GET /api/users -> 401 without token', async () => {
    const res = await request(app).get('/api/users');
    expect([401, 403]).toContain(res.statusCode);
  });
  it('POST /api/onboarding -> 401 without token', async () => {
    const res = await request(app).post('/api/onboarding').send({});
    expect([401, 403]).toContain(res.statusCode);
  });
});

