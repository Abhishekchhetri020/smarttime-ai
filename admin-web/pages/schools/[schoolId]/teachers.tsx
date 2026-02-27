import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/router';
import { apiGet, apiPut } from '../../../lib/api';

export default function TeachersPage() {
  const router = useRouter();
  const focus = (router.query.focus as string) || '';
  const create = (router.query.create as string) === '1';
  const presetName = (router.query.name as string) || '';
  const [items, setItems] = useState<any[]>([]);
  const [name, setName] = useState('');

  async function load() {
    const data = await apiGet('/schools/demo-school/teachers');
    setItems(data.items || []);
  }

  useEffect(() => { load(); }, []);
  useEffect(() => {
    if (create && presetName) setName(presetName);
    else if (create && focus) setName(focus);
  }, [create, presetName, focus]);

  const focusedExists = useMemo(() => items.some((x) => x.id === focus || x.code === focus), [items, focus]);

  async function addTeacher() {
    if (!name.trim()) {
      alert('Teacher name is required');
      return;
    }
    const id = `t_${Date.now()}`;
    await apiPut(`/schools/demo-school/teachers/${id}`, { name: name.trim(), code: id });
    setName('');
    await load();
  }

  return (
    <main style={{ fontFamily: 'Arial', padding: 24 }}>
      <h2>Teachers</h2>
      {focus && (
        <div style={{ marginBottom: 10, padding: 8, background: '#fff8e1', border: '1px solid #ffe082' }}>
          Focus: <b>{focus}</b> {focusedExists ? 'found' : 'not found'}
        </div>
      )}
      {create && <div style={{ marginBottom: 8, color: '#1565c0' }}>Quick-create mode enabled from conflict dashboard.</div>}
      <input value={name} onChange={e => setName(e.target.value)} placeholder="Teacher name" />
      <button onClick={addTeacher}>{create ? 'Create Teacher' : 'Add'}</button>
      <ul>
        {items.map((x) => (
          <li key={x.id} style={{ background: (x.id === focus || x.code === focus) ? '#e3f2fd' : undefined }}>
            {x.name || x.id} ({x.code || x.id})
          </li>
        ))}
      </ul>
    </main>
  );
}
