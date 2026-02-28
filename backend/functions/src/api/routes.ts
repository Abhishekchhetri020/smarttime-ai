import { Router } from 'express';
import { requireAuth, requireRole, AuthedRequest } from '../middleware/auth';
import { createSolverJob, listCollection, upsertEntity } from '../services/firestoreRepo';
import { runSolverJob } from '../services/solverClient';
import { enqueueSolverJob } from '../services/queue';
import { publishTimetable } from '../services/timetableRepo';
import { db } from '../lib/firebase';

export const router = Router();

router.get('/health', (_req, res) => res.json({ ok: true, service: 'functions-api', phase: 2 }));

router.use(requireAuth);

router.get('/me', (req: AuthedRequest, res) => res.json({ user: req.user }));

router.get('/schools/:schoolId/summary', requireRole(['super_admin', 'incharge']), async (req, res) => {
  res.json({ schoolId: req.params.schoolId, status: 'phase2-live' });
});

const entities = ['teachers', 'classes', 'subjects', 'rooms', 'constraints'];

for (const entity of entities) {
  router.get(`/schools/:schoolId/${entity}`, requireRole(['super_admin', 'incharge']), async (req, res) => {
    const items = await listCollection(req.params.schoolId, entity);
    res.json({ entity, schoolId: req.params.schoolId, items });
  });

  router.put(`/schools/:schoolId/${entity}/:id`, requireRole(['super_admin', 'incharge']), async (req, res) => {
    const item = await upsertEntity(req.params.schoolId, entity, req.params.id, req.body || {});
    res.json({ entity, item });
  });
}

router.post('/schools/:schoolId/solver/jobs', requireRole(['super_admin', 'incharge']), async (req: AuthedRequest, res) => {
  const schoolId = req.params.schoolId;
  const job = await createSolverJob(schoolId, req.body || {}, req.user?.uid || 'unknown');

  await enqueueSolverJob(schoolId, job.id);
  res.json({ schoolId, jobId: job.id, status: job.status, queued: true });
});

router.post('/schools/:schoolId/solver/jobs/:jobId/run', requireRole(['super_admin', 'incharge']), async (req, res) => {
  try {
    const result = await runSolverJob(req.params.schoolId, req.params.jobId);
    res.json({ ok: true, ...result });
  } catch (e: any) {
    res.status(500).json({ ok: false, error: e?.message || 'run_failed' });
  }
});

router.get('/schools/:schoolId/solver/jobs', requireRole(['super_admin', 'incharge']), async (req, res) => {
  const items = await listCollection(req.params.schoolId, 'solverJobs');
  res.json({ items });
});

router.get('/schools/:schoolId/solver/jobs/:jobId/diagnostics', requireRole(['super_admin', 'incharge']), async (req, res) => {
  const ref = db.collection('schools').doc(req.params.schoolId).collection('solverJobs').doc(req.params.jobId);
  const snap = await ref.get();
  if (!snap.exists) return res.status(404).json({ ok: false, error: { code: 'job_not_found' } });

  const data = snap.data() || {};
  res.json({
    jobId: req.params.jobId,
    status: data.status,
    outputSummary: data.outputSummary || null,
    runDurationMs: data.runDurationMs || null,
    diagnostics: data.diagnostics || {},
  });
});

router.post('/schools/:schoolId/solver/jobs/:jobId/requeue', requireRole(['super_admin', 'incharge']), async (req, res) => {
  await enqueueSolverJob(req.params.schoolId, req.params.jobId);
  res.json({ schoolId: req.params.schoolId, jobId: req.params.jobId, queued: true });
});

router.get('/schools/:schoolId/timetables', requireRole(['super_admin', 'incharge', 'teacher', 'student', 'parent']), async (req, res) => {
  const items = await listCollection(req.params.schoolId, 'timetables');
  res.json({ items });
});

router.post('/schools/:schoolId/timetables/:versionId/publish', requireRole(['super_admin', 'incharge']), async (req: AuthedRequest, res) => {
  const out = await publishTimetable(req.params.schoolId, req.params.versionId, req.user?.uid || 'unknown');
  res.json(out);
});

router.get('/schools/:schoolId/timetables/published/latest', requireRole(['super_admin', 'incharge', 'teacher', 'student', 'parent']), async (req, res) => {
  const col = db.collection('schools').doc(req.params.schoolId).collection('timetables');
  const snap = await col.where('status', '==', 'published').orderBy('publishedAt', 'desc').limit(1).get();
  if (snap.empty) return res.json({ timetable: null, entries: [] });

  const doc = snap.docs[0];
  const entries = await doc.ref.collection('entries').get();
  res.json({ timetable: { id: doc.id, ...doc.data() }, entries: entries.docs.map(d => ({ id: d.id, ...d.data() })) });
});
