import { Router } from 'express';
import { requireAuth, requireRole, AuthedRequest } from '../middleware/auth';
import { createSolverJob, listCollection, upsertEntity } from '../services/firestoreRepo';

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
  const job = await createSolverJob(req.params.schoolId, req.body || {}, req.user?.uid || 'unknown');
  // Phase 2: async trigger placeholder (Pub/Sub wiring in next step)
  res.json({ schoolId: req.params.schoolId, jobId: job.id, status: job.status });
});
