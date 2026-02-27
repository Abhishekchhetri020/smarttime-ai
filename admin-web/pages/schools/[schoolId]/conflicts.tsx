import { useEffect, useState } from 'react';
import { apiGet } from '../../../lib/api';

export default function ConflictsPage() {
  const [jobs, setJobs] = useState<any[]>([]);

  async function load() {
    const data = await apiGet('/schools/demo-school/solver/jobs');
    setJobs(data.items || []);
  }

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, []);

  return (
    <main style={{ fontFamily: 'Arial', padding: 24 }}>
      <h2>Conflict Dashboard</h2>
      {jobs.map((j) => {
        const hv = j?.diagnostics?.hardViolations || [];
        return (
          <div key={j.id} style={{ border: '1px solid #ddd', padding: 10, marginBottom: 12 }}>
            <strong>{j.id}</strong> — {j.status}
            <div>Score: {j?.outputSummary?.score ?? '-'}</div>
            <div>Hard Violations: {hv.length}</div>
            {hv.length > 0 && (
              <ul>
                {hv.slice(0, 10).map((v: any, i: number) => (
                  <li key={i}>{v.type || 'violation'}: {v.reason || JSON.stringify(v)}</li>
                ))}
              </ul>
            )}
          </div>
        );
      })}
    </main>
  );
}
