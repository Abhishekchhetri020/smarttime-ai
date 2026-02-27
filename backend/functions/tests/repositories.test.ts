jest.mock('../src/lib/firebase', () => {
  const makeDoc = (id: string, data: any) => ({ id, data: () => data, ref: { set: jest.fn() } });

  const entries = [makeDoc('d1', { name: 'X' })];
  const getSnap = async () => ({ docs: entries, empty: false });

  const docRef: any = {
    id: 'newid',
    set: jest.fn(async () => undefined),
    get: jest.fn(async () => ({ id: 'newid', data: () => ({ ok: true }) })),
    collection: () => ({
      doc: () => ({ id: 'e1' }),
      get: getSnap,
      where: () => ({ get: getSnap, orderBy: () => ({ limit: () => ({ get: getSnap }) }) }),
    }),
  };

  const collectionRef: any = {
    limit: () => ({ get: getSnap }),
    doc: () => docRef,
    where: () => ({ get: getSnap, orderBy: () => ({ limit: () => ({ get: getSnap }) }) }),
  };

  const db = {
    collection: () => ({
      doc: () => ({
        collection: () => collectionRef,
      }),
    }),
    batch: () => ({ set: jest.fn(), commit: jest.fn(async () => undefined) }),
  };

  return { db };
});

import { listCollection, upsertEntity, createSolverJob } from '../src/services/firestoreRepo';
import { publishTimetable } from '../src/services/timetableRepo';

describe('repository services', () => {
  it('listCollection returns items', async () => {
    const out = await listCollection('s1', 'teachers');
    expect(Array.isArray(out)).toBe(true);
  });

  it('upsertEntity returns item', async () => {
    const out = await upsertEntity('s1', 'subjects', 'sub1', { name: 'English' });
    expect(out.id).toBe('newid');
  });

  it('createSolverJob returns queued job', async () => {
    const out = await createSolverJob('s1', { lessons: [] }, 'u1');
    expect(out.status).toBe('queued');
  });

  it('publishTimetable returns published status', async () => {
    const out = await publishTimetable('s1', 'v1', 'u1');
    expect(out.status).toBe('published');
  });
});
