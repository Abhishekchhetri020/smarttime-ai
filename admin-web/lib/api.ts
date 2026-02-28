export const API_BASE = process.env.NEXT_PUBLIC_API_BASE || 'http://localhost:5001/<project>/asia-south1/api/v1';

export async function apiGet(path: string) {
  const res = await fetch(`${API_BASE}${path}`, {
    headers: {
      'x-role': 'incharge',
      'x-school-id': 'demo-school',
      'x-uid': 'admin-demo',
    },
    cache: 'no-store',
  });
  if (!res.ok) throw new Error(`GET ${path} failed`);
  return res.json();
}

const defaultHeaders = {
  'content-type': 'application/json',
  'x-role': 'incharge',
  'x-school-id': 'demo-school',
  'x-uid': 'admin-demo',
};

export async function apiPut(path: string, body: any) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'PUT',
    headers: defaultHeaders,
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`PUT ${path} failed`);
  return res.json();
}

export async function apiPost(path: string, body: any = {}) {
  const res = await fetch(`${API_BASE}${path}`, {
    method: 'POST',
    headers: defaultHeaders,
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`POST ${path} failed`);
  return res.json();
}

export async function getSolverDiagnostics(schoolId: string, jobId: string) {
  return apiGet(`/schools/${schoolId}/solver/jobs/${jobId}/diagnostics`);
}

export async function requeueSolverJob(schoolId: string, jobId: string) {
  return apiPost(`/schools/${schoolId}/solver/jobs/${jobId}/requeue`, {});
}
