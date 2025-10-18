import request from 'supertest';
import app from '../src/app';

describe('Health endpoint', () => {
  it('returns 401 without Bearer token', async () => {
    const res = await request(app).get('/api/health');
    expect([401, 403]).toContain(res.statusCode);
  });
});

