import { db } from '../lib/firebase';

const SOLVER_URL = process.env.SOLVER_BASE_URL || '';

export async function runSolverJob(schoolId: string, jobId: string) {
  const jobRef = db.collection('schools').doc(schoolId).collection('solverJobs').doc(jobId);
  const jobSnap = await jobRef.get();
  if (!jobSnap.exists) throw new Error('job_not_found');
  const job = jobSnap.data() as any;

  await jobRef.set({ status: 'running', updatedAt: Date.now() }, { merge: true });

  if (!SOLVER_URL) throw new Error('missing_SOLVER_BASE_URL');

  const payload = job.payload || { schoolId, lessons: [], constraints: [], pinned: [], days: 5, periodsPerDay: 8 };
  const res = await fetch(`${SOLVER_URL}/solve`, {
    method: 'POST',
    headers: { 'content-type': 'application/json' },
    body: JSON.stringify({ schoolId, ...payload }),
  });

  if (!res.ok) {
    const txt = await res.text();
    await jobRef.set({ status: 'failed', updatedAt: Date.now(), error: txt }, { merge: true });
    throw new Error('solver_failed');
  }

  const output = await res.json();

  const ttRef = db.collection('schools').doc(schoolId).collection('timetables').doc();
  await ttRef.set({
    status: 'draft',
    sourceJobId: jobId,
    createdAt: Date.now(),
    score: output.score,
    hardViolations: output.hardViolations?.length || 0,
  });

  const batch = db.batch();
  for (const a of output.assignments || []) {
    const eRef = ttRef.collection('entries').doc();
    batch.set(eRef, a);
  }
  await batch.commit();

  await jobRef.set({
    status: 'done',
    updatedAt: Date.now(),
    outputSummary: {
      score: output.score,
      assignments: (output.assignments || []).length,
      hardViolations: (output.hardViolations || []).length,
    },
    timetableVersionId: ttRef.id,
  }, { merge: true });

  return { timetableVersionId: ttRef.id, output };
}
