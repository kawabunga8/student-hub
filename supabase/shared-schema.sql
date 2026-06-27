-- SHARED SCHEMA — Canonical definitions for the RCS app ecosystem
--
-- TABLE USAGE BY APP:
-- ┌─────────────────────┬──────────┬─────────┬─────────────┬───────────────┬───────────────┬───────────────────┬─────────────────────────┐
-- │ App                 │ students │ classes │ enrollments │ student_notes │ student_marks │ learning_standards│ learning_standard_rubrics│
-- ├─────────────────────┼──────────┼─────────┼─────────────┼───────────────┼───────────────┼───────────────────┼─────────────────────────┤
-- │ student-hub         │ R/W      │ R/W     │ R/W         │ R/W           │ R/W           │ R/W               │ R/W                     │
-- │ toc-dayplans        │ R/W      │ R/W     │ R/W         │ R/W           │ R/W           │ R                 │ R                       │
-- │ Kawahoot            │ R        │ R       │ R           │ -             │ -             │ -                 │ -                       │
-- │ group-maker         │ R        │ R       │ R           │ -             │ -             │ -                 │ -                       │
-- │ rcs-report-card-tool│ R        │ -       │ -           │ -             │ -             │ R (via public_standard_id FK on rcs.learning_standards) │ R │
-- └─────────────────────┴──────────┴─────────┴─────────────┴───────────────┴───────────────┴───────────────────┴─────────────────────────┘
--
-- Note: rcs-report-card-tool uses its own rcs.* schema for enrollments/comments.
--
-- learning_standards/learning_standard_rubrics ownership moved here from toc-dayplans.
-- student-hub is the only app that creates/edits catalog rows. Edits to an already-
-- referenced standard create a NEW row (new id) with school_year set and link the old
-- row's superseded_by — never mutate a row in place once it's been referenced. Use the
-- current_learning_standards(p_school_year) function below to resolve "what applies this
-- year" instead of re-implementing the school_year filter in each app.
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
-- LEARNING STANDARDS CATALOG (owned by student-hub)
-- =============================================================================

create table if not exists public.learning_standards (
  id uuid primary key default gen_random_uuid(),
  subject text not null,
  standard_key text not null,
  standard_title text not null,
  sort_order int,
  source_pdf_path text,
  page_ref text,
  school_year text,
  superseded_by uuid references public.learning_standards(id),
  superseded_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint learning_standards_unique unique(subject, standard_key, school_year)
);

create index if not exists learning_standards_subject_idx on public.learning_standards(subject);

create table if not exists public.learning_standard_rubrics (
  id uuid primary key default gen_random_uuid(),
  learning_standard_id uuid not null references public.learning_standards(id) on delete cascade,
  grade int not null,
  level text not null,
  original_text text not null default '',
  edited_text text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint learning_standard_rubrics_grade_check check (grade in (9,10,11,12)),
  constraint learning_standard_rubrics_level_check check (level in ('emerging','developing','proficient','extending')),
  constraint learning_standard_rubrics_unique unique(learning_standard_id, grade, level)
);

create index if not exists learning_standard_rubrics_std_grade_idx on public.learning_standard_rubrics(learning_standard_id, grade);

-- Resolves which version of each standard_key applies for a given school year:
-- prefers an exact school_year match, falls back to the evergreen (school_year is null)
-- row, and excludes anything already superseded for that year.
create or replace function public.current_learning_standards(p_school_year text)
returns setof public.learning_standards
language sql
stable
as $$
  select distinct on (subject, standard_key) ls.*
  from public.learning_standards ls
  where (ls.school_year = p_school_year or ls.school_year is null)
    and ls.superseded_by is null
  order by subject, standard_key, (ls.school_year is not null) desc;
$$;

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
alter table public.learning_standards enable row level security;
alter table public.learning_standard_rubrics enable row level security;

-- Authenticated users (staff) can read and write all tables.
-- The app requires login via middleware; these policies enforce the same rule at the DB layer.
create policy "Authenticated full access" on public.students      for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.classes       for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.enrollments   for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.student_notes for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.student_marks for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.learning_standards for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.learning_standard_rubrics for all to authenticated using (true) with check (true);
