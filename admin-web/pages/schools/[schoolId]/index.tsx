import Link from 'next/link';

export default function SchoolHome() {
  return (
    <main style={{ fontFamily: 'Arial', padding: 24 }}>
      <h1>School Admin</h1>
      <ul>
        <li><Link href="/schools/demo-school/teachers">Teachers</Link></li>
        <li><Link href="/schools/demo-school/classes">Classes</Link></li>
        <li><Link href="/schools/demo-school/subjects">Subjects</Link></li>
        <li><Link href="/schools/demo-school/constraints">Constraints</Link></li>
        <li><Link href="/schools/demo-school/solver">Run Solver</Link></li>
      </ul>
    </main>
  );
}
