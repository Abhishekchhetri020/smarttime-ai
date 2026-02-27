import { useEffect, useState } from 'react';
import { useRouter } from 'next/router';
import { apiGet, apiPut } from '../../../lib/api';
import { scrollToId } from '../../../lib/ui';

export default function ConstraintsPage() {
  const router = useRouter();
  const hint = (router.query.hint as string) || '';
  const create = (router.query.create as string) === '1';
  const [items, setItems] = useState<any[]>([]);
  const [type, setType] = useState('max_gaps_teacher');
  const [weight, setWeight] = useState(10);

  async function load() {
    const data = await apiGet('/schools/demo-school/constraints');
    setItems(data.items || []);
  }
  useEffect(() => { load(); }, []);
  useEffect(() => { if (hint) setType(hint); }, [hint]);
  useEffect(() => { if (hint) scrollToId(`constraint-${hint}`); }, [hint, items]);

  async function addItem() {
    if (!type.trim() || Number.isNaN(weight)) {
      alert('Constraint type and valid weight are required');
      return;
    }
    const id = `k_${Date.now()}`;
    await apiPut(`/schools/demo-school/constraints/${id}`, { type: type.trim(), weight, enabled: true });
    await load();
  }

  async function editConstraint(x: any) {
    const nextType = prompt('Update constraint type', x.type || 'max_gaps_teacher');
    if (!nextType) return;
    const nextWeight = prompt('Update weight', String(x.weight ?? 10));
    if (!nextWeight) return;
    await apiPut(`/schools/demo-school/constraints/${x.id}`, {
      ...x,
      type: nextType.trim(),
      weight: Number(nextWeight),
    });
    await load();
  }

  return <main style={{fontFamily:'Arial',padding:24}}>
    <h2>Constraints</h2>
    {hint && <div style={{ marginBottom: 10, padding: 8, background: '#fff8e1', border: '1px solid #ffe082' }}>Hint received: <b>{hint}</b></div>}
    {create && <div style={{ marginBottom: 8, color: '#1565c0' }}>Quick-create mode enabled from conflict dashboard.</div>}
    <input value={type} onChange={e=>setType(e.target.value)} />
    <input type='number' value={weight} onChange={e=>setWeight(Number(e.target.value))} />
    <button onClick={addItem}>{create ? 'Create Constraint' : 'Add'}</button>
    <ul>{items.map(x=><li id={`constraint-${x.type}`} key={x.id} style={{ background: x.type === hint ? '#e3f2fd' : undefined }}>{x.type} (w={x.weight})<button style={{ marginLeft: 8 }} onClick={()=>editConstraint(x)}>Edit</button></li>)}</ul>
  </main>;
}
