import request from 'supertest';
import { createApp } from '../src/app';

describe('functions api', () => {
  const app = createApp();

  it('health works', async () => {
    const res = await request(app).get('/v1/health');
    expect(res.status).toBe(200);
    expect(res.body.ok).toBe(true);
  });

  it('me returns fallback dev auth payload', async () => {
    const res = await request(app)
      .get('/v1/me')
      .set('x-role', 'incharge')
      .set('x-uid', 'u1')
      .set('x-school-id', 's1');
    expect(res.status).toBe(200);
    expect(res.body.user.uid).toBe('u1');
    expect(res.body.user.role).toBe('incharge');
  });
});
