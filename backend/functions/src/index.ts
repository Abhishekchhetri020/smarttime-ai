import * as functions from 'firebase-functions';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import express from 'express';
import cors from 'cors';
import { router } from './api/routes';
import { randomUUID } from 'crypto';
import { runSolverJob } from './services/solverClient';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '2mb' }));
app.use((req, res, next) => {
  (req as any).requestId = randomUUID();
  res.setHeader('x-request-id', (req as any).requestId);
  next();
});

app.use('/v1', router);

export const api = functions.region('asia-south1').https.onRequest(app);

export const solverWorker = onMessagePublished(
  {
    topic: process.env.SOLVER_TOPIC || 'smarttime-solver-jobs',
    region: 'asia-south1',
  },
  async (event) => {
    const msg = event.data.message;
    const raw = msg.json || JSON.parse(Buffer.from(msg.data || '', 'base64').toString() || '{}');
    const schoolId = raw.schoolId;
    const jobId = raw.jobId;
    if (!schoolId || !jobId) return;
    await runSolverJob(schoolId, jobId);
  }
);
