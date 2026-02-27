import * as functions from 'firebase-functions';
import express from 'express';
import cors from 'cors';
import { router } from './api/routes';

const app = express();
app.use(cors({ origin: true }));
app.use(express.json({ limit: '2mb' }));
app.use('/v1', router);

export const api = functions.https.onRequest(app);
