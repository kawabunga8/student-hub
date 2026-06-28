import { Suspense } from 'react';
import QuartersClient from './QuartersClient';

export const dynamic = 'force-dynamic';

export default function QuartersPage() {
  return <Suspense fallback={<div style={{ padding: 24 }}>Loading…</div>}><QuartersClient /></Suspense>;
}
