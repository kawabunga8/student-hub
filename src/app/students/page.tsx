import { Suspense } from 'react';
import StudentsClient from './StudentsClient';

export const dynamic = 'force-dynamic';

export default function StudentsPage() {
  return <Suspense fallback={<div style={{ padding: 24 }}>Loading…</div>}><StudentsClient /></Suspense>;
}
