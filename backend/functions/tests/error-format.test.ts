import request from 'supertest';
import { createApp } from '../src/app';

describe('error format', () => {
  const app = createApp();
  it('returns standardized not_found payload', async () => {
    const res = await request(app).get('/v1/does-not-exist');
    expect(res.status).toBe(404);
    expect(res.body.ok).toBe(false);
    expect(res.body.error.code).toBe('not_found');
  });
});
