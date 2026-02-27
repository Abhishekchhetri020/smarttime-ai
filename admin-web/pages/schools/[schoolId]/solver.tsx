import { useState } from 'react';
import { API_BASE } from '../../../lib/api';

export default function SolverPage() {
  const [resp, setResp] = useState<any>(null);

  async function run() {
    const res = await fetch(`${API_BASE}/schools/demo-school/solver/jobs`, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'x-role': 'incharge',
        'x-school-id': 'demo-school',
        'x-uid': 'admin-demo',
      },
      body: JSON.stringify({
        days: 5,
        periodsPerDay: 8,
        lessons: [
          { id: 'L1', classId: 'VIII-A', teacherId: 'T1', subjectId: 'ENG' },
          { id: 'L2', classId: 'VIII-A', teacherId: 'T1', subjectId: 'ENG' },
          { id: 'L3', classId: 'VIII-B', teacherId: 'T2', subjectId: 'MATH' }
        ]
      })
    });
    setResp(await res.json());
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Solver</h2>
    <button onClick={run}>Run Solver Job</button>
    <pre>{JSON.stringify(resp, null, 2)}</pre>
  </main>;
}
