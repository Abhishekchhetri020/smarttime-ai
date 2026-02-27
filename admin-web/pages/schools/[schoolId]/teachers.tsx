import { useEffect, useState } from 'react';
import { apiGet, apiPut } from '../../../lib/api';

export default function TeachersPage() {
  const [items, setItems] = useState<any[]>([]);
  const [name, setName] = useState('');

  async function load() {
    const data = await apiGet('/schools/demo-school/teachers');
    setItems(data.items || []);
  }

  useEffect(() => { load(); }, []);

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
      <input value={name} onChange={e => setName(e.target.value)} placeholder="Teacher name" />
      <button onClick={addTeacher}>Add</button>
      <ul>{items.map((x) => <li key={x.id}>{x.name || x.id}</li>)}</ul>
    </main>
  );
}
