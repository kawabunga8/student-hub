'use client';
import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { getSupabaseClient } from '@/lib/supabaseClient';

export default function AuthCallbackPage() {
  const router = useRouter();
  useEffect(() => {
    const supabase = getSupabaseClient();
    const { data: { subscription } } = supabase.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') router.push('/reset-password');
      else if (event === 'SIGNED_IN') router.push('/students');
    });
    return () => subscription.unsubscribe();
  }, [router]);
  return <main style={{ padding: 24, fontFamily: 'system-ui' }}>Completing sign-in…</main>;
}
