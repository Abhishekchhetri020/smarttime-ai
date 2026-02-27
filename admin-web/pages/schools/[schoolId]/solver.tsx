import { useEffect, useState } from 'react';
import { apiGet, apiPost } from '../../../lib/api';

export default function SolverPage() {
  const [resp, setResp] = useState<any>(null);
  const [versions, setVersions] = useState<any[]>([]);
  const [jobs, setJobs] = useState<any[]>([]);

  async function loadVersions() {
    const data = await apiGet('/schools/demo-school/timetables');
    setVersions(data.items || []);
  }

  async function loadJobs() {
    const data = await apiGet('/schools/demo-school/solver/jobs');
    setJobs(data.items || []);
  }

  useEffect(() => {
    loadVersions();
    loadJobs();
    const id = setInterval(() => {
      loadVersions();
      loadJobs();
    }, 5000);
    return () => clearInterval(id);
  }, []);

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
          {v.status === 'published' && <strong style={{ marginLeft: 8, color: 'green' }}>[CURRENT]</strong>}
          {v.status !== 'published' && <button onClick={() => publish(v.id)} style={{ marginLeft: 8 }}>Publish</button>}
        </li>
      ))}
    </ul>

    <h3>Solver Jobs</h3>
    <ul>
      {jobs.map((j) => (
        <li key={j.id}>{j.id} — {j.status}</li>
      ))}
    </ul>
  </main>;
}
