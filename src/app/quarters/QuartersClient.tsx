'use client';

import { useEffect, useState } from 'react';
import { getSupabaseClient } from '@/lib/supabaseClient';
import Banner from '@/components/Banner';

type QuarterRow = { id: number; label: string; start_date: string; end_date: string };

const RCS = {
  deepNavy: '#1F4E79', midBlue: '#2E75B6', lightBlue: '#D6E4F0',
  gold: '#C9A84C', paleGold: '#FDF3DC', white: '#FFFFFF', textDark: '#1A1A1A',
} as const;

export default function QuartersClient() {
  const [quarters, setQuarters] = useState<QuarterRow[]>([]);
  const [status, setStatus] = useState<'loading' | 'idle' | 'saving' | 'error'>('loading');
  const [error, setError] = useState<string | null>(null);

  async function load() {
    setStatus('loading');
    setError(null);
    const supabase = getSupabaseClient();
    const { data, error } = await supabase.from('school_quarters').select('id,label,start_date,end_date').order('id');
    if (error) { setError(error.message); setStatus('error'); return; }
    setQuarters((data ?? []) as QuarterRow[]);
    setStatus('idle');
  }

  useEffect(() => { load(); }, []);

  async function save() {
    setStatus('saving');
    setError(null);
    const supabase = getSupabaseClient();
    for (const q of quarters) {
      const { error } = await supabase.from('school_quarters').update({ start_date: q.start_date, end_date: q.end_date }).eq('id', q.id);
      if (error) { setError(error.message); setStatus('error'); return; }
    }
    setStatus('idle');
  }

  return (
    <div style={{ minHeight: '100vh', background: '#f0f4f8', fontFamily: 'system-ui, sans-serif' }}>
      <Banner active="quarters" />
      <div style={{ padding: 24, color: RCS.textDark }}>
      <h1 style={{ color: RCS.deepNavy, marginTop: 0 }}>School Quarters</h1>
      <p style={{ fontSize: 13, color: '#555', marginBottom: 16 }}>
        Set the start/end dates for Q1–Q4. TOC-Dayplans, Report Card Tool, and Kawahoot all read these dates
        to know which courses/classes are active on a given day — change them here once, applies everywhere.
      </p>

      {status === 'loading' && <div>Loading…</div>}
      {error && <div style={{ color: 'crimson', marginBottom: 12 }}>{error}</div>}

      <div style={{ border: `1px solid ${RCS.deepNavy}`, borderRadius: 12, padding: 16, background: RCS.paleGold, display: 'grid', gap: 12, maxWidth: 480 }}>
        {quarters.map((q, i) => (
          <div key={q.id} style={{ display: 'flex', gap: 16, alignItems: 'center' }}>
            <div style={{ width: 32, fontWeight: 900, color: RCS.midBlue }}>{q.label}</div>
            <label style={{ display: 'grid', gap: 4 }}>
              <span style={{ fontSize: 12, color: RCS.midBlue }}>Start</span>
              <input
                type="date"
                value={q.start_date}
                onChange={(e) => setQuarters((prev) => prev.map((x, idx) => (idx === i ? { ...x, start_date: e.target.value } : x)))}
                style={{ padding: 6, border: `1px solid ${RCS.deepNavy}`, borderRadius: 6 }}
              />
            </label>
            <label style={{ display: 'grid', gap: 4 }}>
              <span style={{ fontSize: 12, color: RCS.midBlue }}>End</span>
              <input
                type="date"
                value={q.end_date}
                onChange={(e) => setQuarters((prev) => prev.map((x, idx) => (idx === i ? { ...x, end_date: e.target.value } : x)))}
                style={{ padding: 6, border: `1px solid ${RCS.deepNavy}`, borderRadius: 6 }}
              />
            </label>
          </div>
        ))}
        <button
          onClick={save}
          disabled={status === 'saving' || status === 'loading'}
          style={{ background: RCS.deepNavy, color: RCS.white, border: `1px solid ${RCS.gold}`, borderRadius: 10, fontWeight: 900, padding: '8px 16px', cursor: 'pointer', justifySelf: 'start' }}
        >
          {status === 'saving' ? 'Saving…' : 'Save quarters'}
        </button>
      </div>
      </div>
    </div>
  );
}
