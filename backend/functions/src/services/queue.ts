import { PubSub } from '@google-cloud/pubsub';

const pubsub = new PubSub();
const TOPIC = process.env.SOLVER_TOPIC || 'smarttime-solver-jobs';

export async function enqueueSolverJob(schoolId: string, jobId: string) {
  const payload = Buffer.from(JSON.stringify({ schoolId, jobId }));
  await pubsub.topic(TOPIC).publishMessage({ data: payload });
  return { topic: TOPIC };
}
