-- 2026-27 Master Timetable — Shingo Kawamura
-- Run this ONCE in the Supabase SQL editor.
-- Each statement is idempotent: skips if the class already exists for this year.
--
-- If upgrading an existing database, run these first to add new columns:
--   alter table public.classes add column if not exists room text;
--   alter table public.classes add column if not exists school_year text;

do $$ begin

  if not exists (select 1 from public.classes where name = 'Computer Programming 11/12' and block_label = 'A' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Computer Programming 11/12', 'A', '124', '2026-27', 1);
  end if;

  if not exists (select 1 from public.classes where name = 'Biblical Perspectives 10' and block_label = 'B' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Biblical Perspectives 10', 'B', '124', '2026-27', 2);
  end if;

  if not exists (select 1 from public.classes where name = 'Biblical Perspectives 10' and block_label = 'C' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Biblical Perspectives 10', 'C', '124', '2026-27', 3);
  end if;

  if not exists (select 1 from public.classes where name = 'Band 10-12' and block_label = 'D' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Band 10-12', 'D', '130', '2026-27', 4);
  end if;

  if not exists (select 1 from public.classes where name = 'Worship Leadership 11/12' and block_label = 'F' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Worship Leadership 11/12', 'F', '130/MPR', '2026-27', 6);
  end if;

  -- Block G: CPST 10 has separate rosters for Q1/Q2 and Q3/Q4
  if not exists (select 1 from public.classes where name = 'Computer Studies 10 Q1/Q2' and block_label = 'G' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order, active_quarters) values ('Computer Studies 10 Q1/Q2', 'G', '124', '2026-27', 7, array[1,2]);
  end if;

  if not exists (select 1 from public.classes where name = 'Computer Studies 10 Q3/Q4' and block_label = 'G' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order, active_quarters) values ('Computer Studies 10 Q3/Q4', 'G', '124', '2026-27', 8, array[3,4]);
  end if;

  -- Block H: ICT 9 runs Q1 and Q2 (two separate rosters); Band 9 runs Q3 and Q4
  if not exists (select 1 from public.classes where name = 'ICT 9 Q1' and block_label = 'H' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order, active_quarters) values ('ICT 9 Q1', 'H', '124', '2026-27', 9, array[1]);
  end if;

  if not exists (select 1 from public.classes where name = 'ICT 9 Q2' and block_label = 'H' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order, active_quarters) values ('ICT 9 Q2', 'H', '124', '2026-27', 10, array[2]);
  end if;

  if not exists (select 1 from public.classes where name = 'Band 9' and block_label = 'H' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order, active_quarters) values ('Band 9', 'H', '130', '2026-27', 11, array[3,4]);
  end if;

  if not exists (select 1 from public.classes where name = 'Career Class 10' and block_label = 'CL' and school_year = '2026-27') then
    insert into public.classes (name, block_label, room, school_year, sort_order) values ('Career Class 10', 'CL', '124', '2026-27', 12);
  end if;

end $$;
