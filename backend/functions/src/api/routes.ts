import { Router } from 'express';
import { requireRole } from '../lib/auth';

export const router = Router();

router.get('/health', (_req, res) => res.json({ ok: true, service: 'functions-api' }));

router.get('/schools/:schoolId/summary', requireRole(['super_admin','incharge']), (req, res) => {
  res.json({ schoolId: req.params.schoolId, status: 'phase1-ready' });
});

const entities = ['teachers', 'classes', 'subjects', 'rooms', 'constraints'];
for (const e of entities) {
  router.get(`/schools/:schoolId/${e}`, requireRole(['super_admin','incharge']), (req, res) => {
    res.json({ entity: e, schoolId: req.params.schoolId, items: [] });
  });
}

router.post('/schools/:schoolId/solver/jobs', requireRole(['super_admin','incharge']), (req, res) => {
  res.json({ schoolId: req.params.schoolId, jobId: `job_${Date.now()}`, status: 'queued' });
});
