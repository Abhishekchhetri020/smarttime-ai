export type Role = 'super_admin'|'incharge'|'teacher'|'student'|'parent';

export interface ApiUser {
  uid: string;
  role: Role;
  schoolId?: string;
}

export interface ApiRequestMeta {
  requestId: string;
  ts: number;
}
