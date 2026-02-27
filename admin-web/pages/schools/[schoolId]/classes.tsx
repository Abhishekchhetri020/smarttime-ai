import { useEffect, useState } from 'react';
import { apiGet, apiPut } from '../../../lib/api';

export default function ClassesPage() {
  const [items, setItems] = useState<any[]>([]);
  const [grade, setGrade] = useState('VIII');
  const [section, setSection] = useState('A');

  async function load() {
    const data = await apiGet('/schools/demo-school/classes');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);

  async function addItem() {
    const id = `c_${Date.now()}`;
    await apiPut(`/schools/demo-school/classes/${id}`, { grade, section });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Classes</h2>
    <input value={grade} onChange={e=>setGrade(e.target.value)} placeholder='Grade' />
    <input value={section} onChange={e=>setSection(e.target.value)} placeholder='Section' />
    <button onClick={addItem}>Add</button>
    <ul>{items.map(x=><li key={x.id}>{x.grade}-{x.section}</li>)}</ul>
  </main>;
}
