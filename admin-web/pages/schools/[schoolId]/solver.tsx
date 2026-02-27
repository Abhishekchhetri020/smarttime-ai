import { useEffect, useState } from 'react';
import { apiGet, apiPost } from '../../../lib/api';

export default function SolverPage() {
  const [resp, setResp] = useState<any>(null);
  const [versions, setVersions] = useState<any[]>([]);

  async function loadVersions() {
    const data = await apiGet('/schools/demo-school/timetables');
    setVersions(data.items || []);
  }

  useEffect(() => { loadVersions(); }, []);

  async function run() {
    const data = await apiPost('/schools/demo-school/solver/jobs', {
      days: 5,
      periodsPerDay: 8,
      lessons: [
        { id: 'L1', classId: 'VIII-A', teacherId: 'T1', subjectId: 'ENG' },
        { id: 'L2', classId: 'VIII-A', teacherId: 'T1', subjectId: 'ENG' },
        { id: 'L3', classId: 'VIII-B', teacherId: 'T2', subjectId: 'MATH' }
      ]
    });
    setResp(data);
    setTimeout(loadVersions, 1200);
  }

  async function publish(versionId: string) {
    const data = await apiPost(`/schools/demo-school/timetables/${versionId}/publish`, {});
    setResp(data);
    await loadVersions();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Solver</h2>
    <button onClick={run}>Run Solver Job</button>
    <pre>{JSON.stringify(resp, null, 2)}</pre>

    <h3>Timetable Versions</h3>
    <ul>
      {versions.map((v) => (
        <li key={v.id}>
          {v.id} — status: {v.status || 'draft'}
          {v.status !== 'published' && <button onClick={() => publish(v.id)} style={{ marginLeft: 8 }}>Publish</button>}
        </li>
      ))}
    </ul>
  </main>;
}
