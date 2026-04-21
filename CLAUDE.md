# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
npm run dev      # start dev server on localhost:3000
npm run build    # production build
npm run lint     # ESLint check
```

No test suite is configured.

## Environment Variables

Create `.env.local` with:

```
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
```

## Architecture

**Student Hub** is a Next.js 16 App Router app that serves as the central student data source for a suite of RCS (Richmond Christian School) tools: TOC-Dayplans, RCS Report Card Tool, Kawahoot, and Group Maker. It writes to a shared Supabase database; the other apps read from it.

### Supabase tables (managed here)
- `public.students` — core student records (name, grade, gender, photo_url, student_number)
- `public.classes` — class definitions with block_label and sort_order
- `public.enrollments` — many-to-many students ↔ classes
- `public.student_notes` — per-student timestamped notes
- `public.student_marks` — per-student subject marks with quarter and class references

Photos are stored in the Supabase Storage bucket **"Student Photos"**.

### Supabase client pattern
- **Browser (client components):** use `getSupabaseClient()` from `src/lib/supabaseClient.ts` — singleton `createBrowserClient` instance, throws if called server-side.
- **Middleware:** `createServerClient` from `@supabase/ssr` using `req.cookies`.
- There is no server-side Supabase helper; all data fetching happens client-side in `StudentsClient`.

### Auth flow
`middleware.ts` guards all routes except `/login`, `/auth/callback`, and `/api/*`. Unauthenticated requests redirect to `/login?next=<path>`. After sign-in or password reset, `/auth/callback/page.tsx` handles the `onAuthStateChange` event and redirects accordingly.

### Page structure
Each route uses a thin Server Component page that wraps a `*Client.tsx` component in `<Suspense>`. All business logic and data fetching lives in the client components.

- `/` — redirects to `/students` (root page)
- `/login` — email/password sign-in + forgot password (sends reset email to `/auth/callback`)
- `/students` — main app: student list, search/filter, detail panel with tabs (Info, Classes, Notes, Marks), CSV import, photo upload

### Styling

No CSS framework. The RCS design system lives in two files:

| File | Purpose |
|------|---------|
| `public/rcs-theme.css` | **Vercel-hosted stylesheet** — CSS custom properties (`--rcs-*`) and utility classes (`.rcs-btn-primary`, `.rcs-card`, etc.). Other RCS apps link to this via `<link rel="stylesheet" href="https://<domain>/rcs-theme.css" />`. |
| `src/lib/theme.ts` | **JS mirror** — exports `RCS` object with the same color values for use in React inline `style` props. |

`globals.css` imports `rcs-theme.css` so CSS variables and utility classes are available everywhere.

In components, import colors like this — never define them locally:
```ts
import { RCS } from '@/lib/theme';
// then use: style={{ color: RCS.deepNavy }}
```

**Palette:**
```ts
deepNavy: '#1F4E79'  // headers, borders, primary buttons
midBlue:  '#2E75B6'  // labels, links, secondary accents
lightBlue:'#D6E4F0'  // backgrounds, tab underlines
gold:     '#C9A84C'  // accent borders, gold buttons
paleGold: '#FDF3DC'  // pale gold backgrounds
white:    '#FFFFFF'
textDark: '#1A1A1A'
bg:       '#F0F4F8'  // page background
```
