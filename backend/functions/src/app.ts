import express from 'express';
import cors from 'cors';
import { router } from './api/routes';
import { randomUUID } from 'crypto';

export function createApp() {
  const app = express();
  app.use(cors({ origin: true }));
  app.use(express.json({ limit: '2mb' }));
  app.use((req, res, next) => {
    (req as any).requestId = randomUUID();
    res.setHeader('x-request-id', (req as any).requestId);
    next();
  });

  app.use('/v1', router);
  return app;
}
