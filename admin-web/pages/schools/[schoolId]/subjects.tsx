import { useEffect, useState } from 'react';
import { apiGet, apiPut } from '../../../lib/api';

export default function SubjectsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [name, setName] = useState('English');

  async function load() {
    const data = await apiGet('/schools/demo-school/subjects');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);

  async function addItem() {
    if (!name.trim()) {
      alert('Subject name is required');
      return;
    }
    const id = `s_${Date.now()}`;
    await apiPut(`/schools/demo-school/subjects/${id}`, { name: name.trim() });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Subjects</h2>
    <input value={name} onChange={e=>setName(e.target.value)} placeholder='Subject' />
    <button onClick={addItem}>Add</button>
    <ul>{items.map(x=><li key={x.id}>{x.name}</li>)}</ul>
  </main>;
}
