import request from 'supertest';
import { createApp } from '../src/app';

jest.mock('../src/services/firestoreRepo', () => ({
  listCollection: jest.fn(async (_schoolId: string, entity: string) => [{ id: 'x1', entity }]),
  upsertEntity: jest.fn(async (_schoolId: string, entity: string, id: string, body: any) => ({ id, entity, ...body })),
  createSolverJob: jest.fn(async () => ({ id: 'job1', status: 'queued' })),
}));

jest.mock('../src/services/queue', () => ({
  enqueueSolverJob: jest.fn(async () => ({ topic: 'smarttime-solver-jobs' })),
}));

describe('entity routes', () => {
  const app = createApp();
  const hdr = { 'x-role': 'incharge', 'x-uid': 'u1', 'x-school-id': 's1' };

  it('lists teachers', async () => {
    const res = await request(app).get('/v1/schools/s1/teachers').set(hdr);
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.items)).toBe(true);
  });

  it('upserts subject', async () => {
    const res = await request(app)
      .put('/v1/schools/s1/subjects/sub1')
      .set(hdr)
      .send({ name: 'English' });
    expect(res.status).toBe(200);
    expect(res.body.item.id).toBe('sub1');
  });

  it('creates solver job', async () => {
    const res = await request(app)
      .post('/v1/schools/s1/solver/jobs')
      .set(hdr)
      .send({ lessons: [] });
    expect(res.status).toBe(200);
    expect(res.body.jobId).toBe('job1');
    expect(res.body.queued).toBe(true);
  });
});
