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
-- Run this in Supabase SQL editor ONCE during initial setup.
-- When modifying table structure, update THIS file first, then sync to Supabase.

-- =============================================================================
-- CORE STUDENT DATA (owned by student-hub)
-- =============================================================================

create table if not exists students (
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

create table if not exists classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  block_label text,
  sort_order integer default 0,
  created_at timestamptz not null default now()
);

create table if not exists enrollments (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references classes(id) on delete cascade,
  student_id uuid not null references students(id) on delete cascade,
  school_year text,
  created_at timestamptz not null default now(),
  unique(class_id, student_id, school_year)
);

create table if not exists student_notes (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  note text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists student_marks (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references students(id) on delete cascade,
  subject text not null,
  mark numeric,
  quarter text,
  class_id uuid references classes(id),
  note text,
  created_at timestamptz not null default now()
);

-- =============================================================================
-- INDEXES
-- =============================================================================

create index if not exists idx_enrollments_class on enrollments(class_id);
create index if not exists idx_enrollments_student on enrollments(student_id);
create index if not exists idx_student_notes_student on student_notes(student_id);
create index if not exists idx_student_marks_student on student_marks(student_id);

-- =============================================================================
-- RLS POLICIES (customize per your auth needs)
-- =============================================================================

-- Enable RLS
alter table students enable row level security;
alter table classes enable row level security;
alter table enrollments enable row level security;
alter table student_notes enable row level security;
alter table student_marks enable row level security;

-- Staff-only access (adjust is_staff() to match your auth setup)
-- Example policy — uncomment and adjust as needed:
-- create policy "Staff can do everything" on students for all using (is_staff());
