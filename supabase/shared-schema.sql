-- SHARED SCHEMA — Canonical definitions for the RCS app ecosystem
--
-- TABLE USAGE BY APP:
-- ┌─────────────────────┬──────────┬─────────┬─────────────┬───────────────┬───────────────┐
-- │ App                 │ students │ classes │ enrollments │ student_notes │ student_marks │
-- ├─────────────────────┼──────────┼─────────┼─────────────┼───────────────┼───────────────┤
-- │ student-hub         │ R/W      │ R/W     │ R/W         │ R/W           │ R/W           │
-- │ toc-dayplans        │ R/W      │ R/W     │ R/W         │ R/W           │ R/W           │
-- │ Kawahoot            │ R        │ R       │ R           │ -             │ -             │
-- │ group-maker         │ R        │ R       │ R           │ -             │ -             │
-- │ rcs-report-card-tool│ R        │ -       │ -           │ -             │ -             │
-- └─────────────────────┴──────────┴─────────┴─────────────┴───────────────┴───────────────┘
--
-- Note: rcs-report-card-tool uses its own rcs.* schema for enrollments/comments.
--
-- IMPORTANT: This Supabase project has both a public schema and an rcs schema.
-- The SQL editor search path resolves rcs before public, so unqualified table
-- names will silently hit the wrong table. Always use explicit public. prefixes.
--
-- Run this in Supabase SQL editor ONCE during initial setup.
-- When modifying table structure, update THIS file first, then sync to Supabase.

-- =============================================================================
-- CORE STUDENT DATA (owned by student-hub)
-- =============================================================================

create table if not exists public.students (
  id uuid primary key default gen_random_uuid(),
  first_name text not null,
  last_name text not null,
  photo_url text,
  grade_year integer,
  gender text,
  student_number text,
  school_year text,
  created_at timestamptz not null default now()
);

create table if not exists public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  block_label text,
  room text,
  school_year text,
  sort_order integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists public.enrollments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.classes(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  school_year text,
  created_at timestamptz not null default now(),
  unique(class_id, student_id, school_year)
);

create table if not exists public.student_notes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.student_marks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject text not null,
  mark numeric,
  quarter text,
  class_id uuid references public.classes(id),
  note text,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- INDEXES
-- =============================================================================

create index if not exists idx_enrollments_class   on public.enrollments(class_id);
create index if not exists idx_enrollments_student on public.enrollments(student_id);
create index if not exists idx_student_notes_student on public.student_notes(student_id);
create index if not exists idx_student_marks_student on public.student_marks(student_id);

-- =============================================================================
-- RLS POLICIES (customize per your auth needs)
-- =============================================================================

-- Enable RLS
alter table public.students      enable row level security;
alter table public.classes       enable row level security;
alter table public.enrollments   enable row level security;
alter table public.student_notes enable row level security;
alter table public.student_marks enable row level security;

-- Authenticated users (staff) can read and write all tables.
-- The app requires login via middleware; these policies enforce the same rule at the DB layer.
create policy "Authenticated full access" on public.students      for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.classes       for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.enrollments   for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.student_notes for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.student_marks for all to authenticated using (true) with check (true);
