-- Adds student email so KawaHoot and RCS Report Card Tool can auto-identify
-- a signed-in student (Google OAuth, restricted to @rcseagles.ca) instead of
-- requiring them to pick their name from a list.
alter table public.students add column if not exists email text;
create unique index if not exists students_email_unique on public.students (lower(email)) where email is not null;
