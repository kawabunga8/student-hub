import { Suspense } from 'react';
import LoginClient from './LoginClient';

export default function LoginPage() {
  return (
    <Suspense fallback={<main style={{ minHeight: '100vh', display: 'grid', placeItems: 'center', fontFamily: 'system-ui', color: '#1F4E79', fontWeight: 800 }}>Loading…</main>}>
      <LoginClient />
    </Suspense>
  );
}
