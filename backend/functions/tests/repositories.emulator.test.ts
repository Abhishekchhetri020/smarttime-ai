import { createSolverJob, listCollection, upsertEntity } from '../src/services/firestoreRepo';
import { publishTimetable } from '../src/services/timetableRepo';
import { db } from '../src/lib/firebase';

const hasEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
const d = hasEmulator ? describe : describe.skip;

d('firestore repository integration (emulator)', () => {
  const schoolId = `emu-school-${Date.now()}`;

  it('upsert + list entities', async () => {
    await upsertEntity(schoolId, 'teachers', 't1', { name: 'Teacher One' });
    const items = await listCollection(schoolId, 'teachers');
    expect(items.find((x: any) => x.id === 't1')).toBeTruthy();
  });

  it('create solver job writes queued job', async () => {
    const job = await createSolverJob(schoolId, { lessons: [] }, 'u1');
    expect(job.status).toBe('queued');

    const ref = db.collection('schools').doc(schoolId).collection('solverJobs').doc(job.id);
    const snap = await ref.get();
    expect(snap.exists).toBe(true);
    expect(snap.data()?.status).toBe('queued');
  });

  it('publishTimetable archives old and marks selected as published', async () => {
    const col = db.collection('schools').doc(schoolId).collection('timetables');
    await col.doc('vOld').set({ status: 'published', publishedAt: Date.now() - 1000 });
    await col.doc('vNew').set({ status: 'draft' });

    const out = await publishTimetable(schoolId, 'vNew', 'u1');
    expect(out.status).toBe('published');

    const oldSnap = await col.doc('vOld').get();
    const newSnap = await col.doc('vNew').get();
    expect(oldSnap.data()?.status).toBe('archived');
    expect(newSnap.data()?.status).toBe('published');
  });
});
