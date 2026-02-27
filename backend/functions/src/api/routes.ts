import { Router } from 'express';
import { requireAuth, requireRole, AuthedRequest } from '../middleware/auth';
import { createSolverJob, listCollection, upsertEntity } from '../services/firestoreRepo';
import { runSolverJob } from '../services/solverClient';

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

  // Fire-and-forget async run (Phase 2). Replace with Pub/Sub worker in Phase 3.
  setTimeout(() => {
    runSolverJob(schoolId, job.id).catch(() => null);
  }, 50);

  res.json({ schoolId, jobId: job.id, status: job.status });
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

router.get('/schools/:schoolId/timetables', requireRole(['super_admin', 'incharge', 'teacher', 'student', 'parent']), async (req, res) => {
  const items = await listCollection(req.params.schoolId, 'timetables');
  res.json({ items });
});
