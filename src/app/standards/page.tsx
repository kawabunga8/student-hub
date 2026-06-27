import { Suspense } from 'react';
import StandardsClient from './StandardsClient';

export const dynamic = 'force-dynamic';

export default function StandardsPage() {
  return <Suspense fallback={<div style={{ padding: 24 }}>Loading…</div>}><StandardsClient /></Suspense>;
}
