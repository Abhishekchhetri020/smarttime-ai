import { useEffect, useMemo, useState } from 'react';
import { apiGet } from '../../../lib/api';

export default function ConflictsPage() {
  const [jobs, setJobs] = useState<any[]>([]);
  const [typeFilter, setTypeFilter] = useState<string>('all');

  async function load() {
    const data = await apiGet('/schools/demo-school/solver/jobs');
    setJobs(data.items || []);
  }

  useEffect(() => {
    load();
    const id = setInterval(load, 5000);
    return () => clearInterval(id);
  }, []);

  const types = useMemo(() => {
    const s = new Set<string>();
    for (const j of jobs) {
      for (const v of (j?.diagnostics?.hardViolations || [])) s.add(v.type || 'violation');
    }
    return ['all', ...Array.from(s)];
  }, [jobs]);

  return (
    <main style={{ fontFamily: 'Arial', padding: 24 }}>
      <h2>Conflict Dashboard</h2>
      <label>
        Filter by type:{' '}
        <select value={typeFilter} onChange={(e) => setTypeFilter(e.target.value)}>
          {types.map((t) => <option key={t} value={t}>{t}</option>)}
        </select>
      </label>

      {jobs.map((j) => {
        const hvAll = j?.diagnostics?.hardViolations || [];
        const hv = typeFilter === 'all' ? hvAll : hvAll.filter((x: any) => (x.type || 'violation') === typeFilter);
        const severity = hv.length === 0 ? 'low' : hv.length <= 3 ? 'medium' : 'high';
        return (
          <div key={j.id} style={{ border: '1px solid #ddd', padding: 10, marginBottom: 12 }}>
            <strong>{j.id}</strong> — {j.status}
            <div>Score: {j?.outputSummary?.score ?? '-'}</div>
            <div>Hard Violations: {hv.length} (severity: <b>{severity}</b>)</div>
            {hv.length > 0 && (
              <ul>
                {hv.slice(0, 10).map((v: any, i: number) => (
                  <li key={i}>
                    {v.type || 'violation'}: {v.reason || JSON.stringify(v)}
                    {v.type === 'unscheduled_lesson' && ' → Suggestion: reduce constraints or free slot for this teacher/class.'}
                    <span style={{ marginLeft: 8 }}>
                      <a href="/schools/demo-school/teachers">Teacher</a>
                      {' | '}
                      <a href="/schools/demo-school/classes">Class</a>
                      {' | '}
                      <a href="/schools/demo-school/constraints">Constraints</a>
                    </span>
                  </li>
                ))}
              </ul>
            )}
          </div>
        );
      })}
    </main>
  );
}
