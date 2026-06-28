-- Kawahoot's own ad-hoc classes/students (manually-typed groupings via "+ New
-- Class"), distinct from the real public.classes/public.students -- same fix
-- as group_maker_classes/students, since the old "+ New Class" code was
-- writing class_id/full_name onto public.students, columns that don't exist there.
create table if not exists public.kawahoot_classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table if not exists public.kawahoot_students (
  id uuid primary key default gen_random_uuid(),
  class_id uuid not null references public.kawahoot_classes(id) on delete cascade,
  full_name text not null,
  created_at timestamptz not null default now()
);

create index if not exists kawahoot_students_class_id_idx on public.kawahoot_students(class_id);

alter table public.kawahoot_classes enable row level security;
alter table public.kawahoot_students enable row level security;

create policy "Authenticated full access" on public.kawahoot_classes for all to authenticated using (true) with check (true);
create policy "Authenticated full access" on public.kawahoot_students for all to authenticated using (true) with check (true);
