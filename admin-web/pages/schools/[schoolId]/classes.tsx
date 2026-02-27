import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/router';
import { apiGet, apiPut } from '../../../lib/api';

export default function ClassesPage() {
  const router = useRouter();
  const focus = (router.query.focus as string) || '';
  const [items, setItems] = useState<any[]>([]);
  const [grade, setGrade] = useState('VIII');
  const [section, setSection] = useState('A');

  async function load() {
    const data = await apiGet('/schools/demo-school/classes');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);

  const focusedExists = useMemo(() => items.some((x) => x.id === focus || `${x.grade}-${x.section}` === focus), [items, focus]);

  async function addItem() {
    if (!grade.trim() || !section.trim()) {
      alert('Grade and section are required');
      return;
    }
    const id = `c_${Date.now()}`;
    await apiPut(`/schools/demo-school/classes/${id}`, { grade: grade.trim(), section: section.trim() });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Classes</h2>
    {focus && <div style={{ marginBottom: 10, padding: 8, background: '#fff8e1', border: '1px solid #ffe082' }}>Focus: <b>{focus}</b> {focusedExists ? 'found' : 'not found'}</div>}
    <input value={grade} onChange={e=>setGrade(e.target.value)} placeholder='Grade' />
    <input value={section} onChange={e=>setSection(e.target.value)} placeholder='Section' />
    <button onClick={addItem}>Add</button>
    <ul>{items.map(x=><li key={x.id} style={{ background: (x.id === focus || `${x.grade}-${x.section}` === focus) ? '#e3f2fd' : undefined }}>{x.grade}-{x.section}</li>)}</ul>
  </main>;
}
