import request from 'supertest';
import { createApp } from '../src/app';

jest.mock('../src/services/firestoreRepo', () => ({
  listCollection: jest.fn(async () => [{ id: 'tt1', status: 'draft' }]),
  upsertEntity: jest.fn(),
  createSolverJob: jest.fn(),
}));

jest.mock('../src/services/queue', () => ({ enqueueSolverJob: jest.fn() }));
jest.mock('../src/services/solverClient', () => ({ runSolverJob: jest.fn() }));
jest.mock('../src/services/timetableRepo', () => ({
  publishTimetable: jest.fn(async (_schoolId: string, versionId: string) => ({ versionId, status: 'published' })),
}));

const fakeEntriesGet = async () => ({ docs: [{ id: 'e1', data: () => ({ day: 1, period: 1 }) }] });
const fakeDoc = {
  id: 'tt_published_1',
  data: () => ({ status: 'published', publishedAt: 123 }),
  ref: { collection: () => ({ get: fakeEntriesGet }) },
};

const fakeSnap = {
  empty: false,
  docs: [fakeDoc],
};

jest.mock('../src/lib/firebase', () => ({
  db: {
    collection: () => ({
      doc: () => ({
        collection: () => ({
          where: () => ({ orderBy: () => ({ limit: () => ({ get: async () => fakeSnap }) }) }),
        }),
      }),
    }),
  },
}));

describe('timetable routes', () => {
  const app = createApp();
  const hdr = { 'x-role': 'incharge', 'x-uid': 'u1', 'x-school-id': 's1' };

  it('publishes timetable', async () => {
    const res = await request(app)
      .post('/v1/schools/s1/timetables/v1/publish')
      .set(hdr);
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('published');
  });

  it('gets latest published timetable with entries', async () => {
    const res = await request(app)
      .get('/v1/schools/s1/timetables/published/latest')
      .set(hdr);
    expect(res.status).toBe(200);
    expect(res.body.timetable.id).toBe('tt_published_1');
    expect(res.body.entries.length).toBe(1);
  });
});
