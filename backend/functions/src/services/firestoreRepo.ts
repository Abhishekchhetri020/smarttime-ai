import { db } from '../lib/firebase';

export async function listCollection(schoolId: string, entity: string) {
  const snap = await db.collection('schools').doc(schoolId).collection(entity).limit(500).get();
  return snap.docs.map(d => ({ id: d.id, ...d.data() }));
}

export async function upsertEntity(schoolId: string, entity: string, id: string, payload: any) {
  const ref = db.collection('schools').doc(schoolId).collection(entity).doc(id);
  await ref.set({ ...payload, updatedAt: Date.now() }, { merge: true });
  const doc = await ref.get();
  return { id: doc.id, ...doc.data() };
}

export async function createSolverJob(schoolId: string, payload: any, actorId: string) {
  const ref = db.collection('schools').doc(schoolId).collection('solverJobs').doc();
  const job = {
    status: 'queued',
    createdAt: Date.now(),
    updatedAt: Date.now(),
    triggeredBy: actorId,
    payload,
  };
  await ref.set(job);
  return { id: ref.id, ...job };
}
