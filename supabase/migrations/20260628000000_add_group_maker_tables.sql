-- Group Maker's own ad-hoc classes/students (manually-typed groupings, not tied
-- to a real course). Named distinctly from public.classes/public.students so
-- they never collide with the real shared schema those tables already use.
-- Group Maker was previously on its own separate Supabase project with RLS
-- disabled and a leaked anon key in its public repo; this migration is part
-- of moving it onto the shared, RLS-protected project.
create table if not exists public.group_maker_classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.group_maker_students (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.group_maker_classes(id) on delete cascade,
  full_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists group_maker_students_class_id_idx on public.group_maker_students(class_id);

alter table public.group_maker_classes enable row level security;
alter table public.group_maker_students enable row level security;

create policy "Authenticated full access" on public.group_maker_classes for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.group_maker_students for all to authenticated using (true) with check (true);
