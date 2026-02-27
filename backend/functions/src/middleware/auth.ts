import { Request, Response, NextFunction } from 'express';
import admin from 'firebase-admin';
import { Role } from '../types/common';

export interface AuthedRequest extends Request {
  user?: {
    uid: string;
    role: Role;
    schoolId?: string;
  };
}

export async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  const auth = req.headers.authorization || '';
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : '';

  // Phase 2 fallback for local/dev if no bearer token but role headers exist
  if (!token) {
    const role = (req.headers['x-role'] as Role) || 'teacher';
    const schoolId = (req.headers['x-school-id'] as string) || undefined;
    const uid = (req.headers['x-uid'] as string) || 'dev-user';
    req.user = { uid, role, schoolId };
    return next();
  }

  try {
    const decoded = await admin.auth().verifyIdToken(token);
    const role = (decoded.role as Role) || 'teacher';
    const schoolId = (decoded.schoolId as string) || undefined;
    req.user = { uid: decoded.uid, role, schoolId };
    return next();
  } catch (e) {
    return res.status(401).json({ error: 'unauthorized' });
  }
}

export function requireRole(allowed: Role[]) {
  return (req: AuthedRequest, res: Response, next: NextFunction) => {
    const role = req.user?.role;
    if (!role || !allowed.includes(role)) {
      return res.status(403).json({ error: 'forbidden', role });
    }
    next();
  };
}
