import * as functions from 'firebase-functions';
import { onMessagePublished } from 'firebase-functions/v2/pubsub';
import { runSolverJob } from './services/solverClient';
import { createApp } from './app';

const app = createApp();

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
