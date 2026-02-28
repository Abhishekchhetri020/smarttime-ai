import express from 'express';
import cors from 'cors';
import admin from 'firebase-admin';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '2mb' }));

const projectId = process.env.FIREBASE_PROJECT_ID || 'smarttime-ai-1b64f';
if (!admin.apps.length) {
  const sa = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
  if (sa) {
    const serviceAccount = JSON.parse(await (await import('node:fs/promises')).readFile(sa, 'utf8'));
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount), projectId });
  } else {
    admin.initializeApp({ projectId });
  }
}
const db = admin.firestore();

app.get('/v1/health', (_req, res) => res.json({ ok: true, service: 'smarttime-backend-server' }));

app.post('/v1/schools/:schoolId/solver/jobs', async (req, res) => {
  const { schoolId } = req.params;
  const jobRef = db.collection('schools').doc(schoolId).collection('solverJobs').doc();
  await jobRef.set({
    status: 'queued',
    createdAt: Date.now(),
    updatedAt: Date.now(),
    payload: req.body || {},
    triggeredBy: req.headers['x-uid'] || 'mobile-admin',
  });
  res.json({ schoolId, jobId: jobRef.id, status: 'queued' });
});

app.post('/v1/schools/:schoolId/timetables/:versionId/publish', async (req, res) => {
  const { schoolId, versionId } = req.params;
  const col = db.collection('schools').doc(schoolId).collection('timetables');
  const published = await col.where('status', '==', 'published').get();
  const b = db.batch();
  published.docs.forEach((d) => b.set(d.ref, { status: 'archived', archivedAt: Date.now() }, { merge: true }));
  b.set(col.doc(versionId), { status: 'published', publishedAt: Date.now() }, { merge: true });
  await b.commit();
  res.json({ ok: true, versionId, status: 'published' });
});

app.get('/v1/schools/:schoolId/solver/jobs', async (req, res) => {
  const { schoolId } = req.params;
  const snap = await db.collection('schools').doc(schoolId).collection('solverJobs').limit(100).get();
  res.json({ items: snap.docs.map((d) => ({ id: d.id, ...d.data() })) });
});

const port = Number(process.env.PORT || 8080);
app.listen(port, () => console.log(`smarttime backend listening on :${port}`));
