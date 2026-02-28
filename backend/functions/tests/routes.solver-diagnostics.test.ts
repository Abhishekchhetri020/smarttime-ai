import request from 'supertest';
import { createApp } from '../src/app';

jest.mock('../src/services/firestoreRepo', () => ({
  listCollection: jest.fn(async () => []),
  upsertEntity: jest.fn(),
  createSolverJob: jest.fn(),
}));

jest.mock('../src/services/queue', () => ({
  enqueueSolverJob: jest.fn(async () => ({ topic: 'smarttime-solver-jobs' })),
}));

jest.mock('../src/services/solverClient', () => ({ runSolverJob: jest.fn() }));
jest.mock('../src/services/timetableRepo', () => ({ publishTimetable: jest.fn() }));

const fakeDoc = {
  exists: true,
  data: () => ({
    status: 'done',
    outputSummary: { score: -12, assignments: 10, hardViolations: 0 },
    runDurationMs: 122,
    diagnostics: { hardViolations: [], softPenaltyBreakdown: [{ type: 'teacher_gaps', penalty: 2, weight: 5 }] },
  }),
};

jest.mock('../src/lib/firebase', () => ({
  db: {
    collection: () => ({
      doc: () => ({
        collection: () => ({
          doc: () => ({ get: async () => fakeDoc }),
          where: () => ({ orderBy: () => ({ limit: () => ({ get: async () => ({ empty: true, docs: [] }) }) }) }),
        }),
      }),
    }),
  },
}));

describe('solver diagnostics routes', () => {
  const app = createApp();
  const hdr = { 'x-role': 'incharge', 'x-uid': 'u1', 'x-school-id': 's1' };

  it('gets solver diagnostics for a job', async () => {
    const res = await request(app).get('/v1/schools/s1/solver/jobs/job-1/diagnostics').set(hdr);
    expect(res.status).toBe(200);
    expect(res.body.jobId).toBe('job-1');
    expect(res.body.status).toBe('done');
    expect(res.body.diagnostics).toBeTruthy();
  });

  it('requeues an existing job', async () => {
    const res = await request(app).post('/v1/schools/s1/solver/jobs/job-1/requeue').set(hdr);
    expect(res.status).toBe(200);
    expect(res.body.queued).toBe(true);
  });
});
