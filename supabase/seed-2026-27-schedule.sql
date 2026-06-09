-- 2026-27 Master Timetable — Shingo Kawamura
-- Run this ONCE after shared-schema.sql to seed classes for the upcoming year.
-- Skips insertion if a class with the same name + block_label + school_year already exists.
--
-- If upgrading an existing database, run these first to add new columns:
--   alter table public.classes add column if not exists room text;
--   alter table public.classes add column if not exists school_year text;

do $$
declare
  rows_to_insert record;
begin
  for rows_to_insert in
    select *
    from (values
      ('Computer Programming 11/12', 'A', '124',     1),
      ('Biblical Perspectives 10',   'B', '124',     2),
      ('Biblical Perspectives 10',   'C', '124',     3),
      ('Band 10-12',                 'D', '130',     4),
      ('Worship Leadership 11/12',   'F', '130/MPR', 6),
      ('Computer Studies 10',        'G', '124',     7),
      ('ICT 9 / Band 9',             'H', '124',     8),
      ('Career Class 10',            'CL','124',     9)
    ) as t(name, block_label, room, sort_order)
  loop
    if not exists (
      select 1 from public.classes
      where name = rows_to_insert.name
        and block_label = rows_to_insert.block_label
        and school_year = '2026-27'
    ) then
      insert into public.classes (name, block_label, room, school_year, sort_order)
      values (
        rows_to_insert.name,
        rows_to_insert.block_label,
        rows_to_insert.room,
        '2026-27',
        rows_to_insert.sort_order
      );
    end if;
  end loop;
end $$;
