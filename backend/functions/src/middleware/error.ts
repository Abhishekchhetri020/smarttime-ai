import { NextFunction, Request, Response } from 'express';

export function notFound(_req: Request, res: Response) {
  res.status(404).json({ ok: false, error: { code: 'not_found', message: 'Route not found' } });
}

export function errorHandler(err: any, _req: Request, res: Response, _next: NextFunction) {
  const status = err?.status || 500;
  const code = err?.code || 'internal_error';
  const message = err?.message || 'Unexpected error';
  res.status(status).json({ ok: false, error: { code, message } });
}
