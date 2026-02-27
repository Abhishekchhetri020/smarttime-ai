import { useEffect, useMemo, useState } from 'react';
import { useRouter } from 'next/router';
import { apiGet, apiPut } from '../../../lib/api';
import { scrollToId } from '../../../lib/ui';

export default function ClassesPage() {
  const router = useRouter();
  const focus = (router.query.focus as string) || '';
  const create = (router.query.create as string) === '1';
  const [items, setItems] = useState<any[]>([]);
  const [grade, setGrade] = useState('VIII');
  const [section, setSection] = useState('A');

  async function load() {
    const data = await apiGet('/schools/demo-school/classes');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);
  useEffect(() => {
    if (!create || !focus) return;
    const m = focus.match(/^([^-]+)-(.+)$/);
    if (m) {
      setGrade(m[1]);
      setSection(m[2]);
    }
  }, [create, focus]);

  const focusedExists = useMemo(() => items.some((x) => x.id === focus || `${x.grade}-${x.section}` === focus), [items, focus]);

  useEffect(() => {
    if (!focus) return;
    scrollToId(`class-${focus}`);
  }, [focus, items]);

  async function addItem() {
    if (!grade.trim() || !section.trim()) {
      alert('Grade and section are required');
      return;
    }
    const id = `c_${Date.now()}`;
    await apiPut(`/schools/demo-school/classes/${id}`, { grade: grade.trim(), section: section.trim() });
    await load();
  }

  async function editClass(x: any) {
    const nextGrade = prompt('Update grade', x.grade || 'VIII');
    if (!nextGrade) return;
    const nextSection = prompt('Update section', x.section || 'A');
    if (!nextSection) return;
    await apiPut(`/schools/demo-school/classes/${x.id}`, { ...x, grade: nextGrade.trim(), section: nextSection.trim() });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Classes</h2>
    {focus && <div style={{ marginBottom: 10, padding: 8, background: '#fff8e1', border: '1px solid #ffe082' }}>Focus: <b>{focus}</b> {focusedExists ? 'found' : 'not found'}</div>}
    {create && <div style={{ marginBottom: 8, color: '#1565c0' }}>Quick-create mode enabled from conflict dashboard.</div>}
    <input value={grade} onChange={e=>setGrade(e.target.value)} placeholder='Grade' />
    <input value={section} onChange={e=>setSection(e.target.value)} placeholder='Section' />
    <button onClick={addItem}>{create ? 'Create Class' : 'Add'}</button>
    <ul>{items.map(x=><li id={`class-${x.grade}-${x.section}`} key={x.id} style={{ background: (x.id === focus || `${x.grade}-${x.section}` === focus) ? '#e3f2fd' : undefined }}>{x.grade}-{x.section}<button style={{ marginLeft: 8 }} onClick={()=>editClass(x)}>Edit</button></li>)}</ul>
  </main>;
}
