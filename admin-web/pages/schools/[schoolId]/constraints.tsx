import { useEffect, useState } from 'react';
import { apiGet, apiPut } from '../../../lib/api';

export default function ConstraintsPage() {
  const [items, setItems] = useState<any[]>([]);
  const [type, setType] = useState('max_gaps_teacher');
  const [weight, setWeight] = useState(10);

  async function load() {
    const data = await apiGet('/schools/demo-school/constraints');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);

  async function addItem() {
    const id = `k_${Date.now()}`;
    await apiPut(`/schools/demo-school/constraints/${id}`, { type, weight, enabled: true });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Constraints</h2>
    <input value={type} onChange={e=>setType(e.target.value)} />
    <input type='number' value={weight} onChange={e=>setWeight(Number(e.target.value))} />
    <button onClick={addItem}>Add</button>
    <ul>{items.map(x=><li key={x.id}>{x.type} (w={x.weight})</li>)}</ul>
  </main>;
}
