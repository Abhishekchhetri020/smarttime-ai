import { Request, Response, NextFunction } from 'express';

export type Role = 'super_admin'|'incharge'|'teacher'|'student'|'parent';

export function requireRole(allowed: Role[]) {
  return (req: Request, res: Response, next: NextFunction) => {
    const role = (req.headers['x-role'] as Role) || 'teacher';
    if (!allowed.includes(role)) return res.status(403).json({ error: 'forbidden', role });
    (req as any).role = role;
    next();
  };
}
