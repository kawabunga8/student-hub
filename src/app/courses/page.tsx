import { Suspense } from 'react';
import CoursesClient from './CoursesClient';

export const dynamic = 'force-dynamic';

export default function CoursesPage() {
  return <Suspense fallback={<div style={{ padding: 24 }}>Loading…</div>}><CoursesClient /></Suspense>;
}
