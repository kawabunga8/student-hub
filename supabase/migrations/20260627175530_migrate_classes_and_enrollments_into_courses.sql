-- Populates the new public.courses canonical catalog from the two legacy
-- catalogs (public.classes, rcs.courses) and repoints public.enrollments
-- to it, merging in rcs.enrollments. Per-block resolution confirmed with
-- the user:
--   - blocks A/B/D/F (CP/Band/WL): rcs.courses is finer-grained (already
--     split per grade); disambiguate classes-side enrollments by student grade.
--   - block G, 2025-26 only: public.classes is finer-grained (already split
--     per quarter) while rcs.courses has one unsplit row; classes wins and
--     the rcs-side enrollment uses the classes-side split to disambiguate.
--   - everywhere else: already 1:1 by name on both sides.
--
-- Bookkeeping columns (_legacy_rcs_course_id, _legacy_class_id) are added
-- temporarily to drive the enrollment repoint, then dropped at the end.

alter table public.courses add column if not exists _legacy_rcs_course_id uuid;
alter table public.courses add column if not exists _legacy_class_id uuid;

-- Step 1: evergreen non-academic placeholders (Chapel/Flex/Lunch) — no rcs equivalent.
insert into public.courses (name, block, type, room, sort_order, school_year, _legacy_class_id)
select c.name, c.block_label,
  case upper(c.block_label) when 'CHAPEL' then 'chapel' when 'FLEX' then 'flex' when 'LUNCH' then 'lunch' end,
  c.room, c.sort_order, null, c.id
from public.classes c
where c.school_year is null and upper(c.block_label) in ('CHAPEL', 'FLEX', 'LUNCH');

-- Step 2: academic courses from rcs.courses, one canonical row per (course, year) —
-- excludes the retired old combined courses (school_years = '{}') and the
-- block-G/2025-26 unsplit row (handled specially in step 3).
insert into public.courses (name, block, grade_years, school_year, type, _legacy_rcs_course_id)
select co.name, co.block, co.grade_years, sy.school_year, 'academic', co.id
from rcs.courses co
cross join lateral unnest(co.school_years) as sy(school_year)
where co.school_years <> '{}'
  and not (co.block = 'G' and sy.school_year = '2025-26');

-- Step 3: block G, 2025-26 special case — classes' existing quarter split wins.
insert into public.courses (name, block, grade_years, school_year, type, room, sort_order, _legacy_class_id)
select c.name, c.block_label, array[10], c.school_year, 'academic', c.room, c.sort_order, c.id
from public.classes c
where c.block_label = 'G' and c.school_year = '2025-26';

-- Step 4: backfill room/sort_order/quarters onto step-2 rows from the matching
-- classes row (by block+school_year) — covers every block except A/B/D/F's
-- per-grade split (no 1:1 classes row to match against, intentionally left null)
-- and block G/2025-26 (already carries room/sort_order directly from step 3).
update public.courses pc
set room = c.room, sort_order = c.sort_order, quarters = c.active_quarters
from public.classes c
where pc._legacy_rcs_course_id is not null
  and c.block_label = pc.block
  and c.school_year = pc.school_year;

-- Step 5: repoint public.enrollments from class_id to the new course_id.
-- The existing PK is (class_id, student_id), which would forbid the null class_id
-- needed for rows merged in from rcs.enrollments (step 6) — repoint the PK to the
-- already-populated `id` column first.
alter table public.enrollments drop constraint enrollments_pkey;
alter table public.enrollments add constraint enrollments_pkey primary key (id);
alter table public.enrollments alter column class_id drop not null;
alter table public.enrollments add column if not exists course_id uuid;

-- 5a. General case: exactly one canonical course for this classes row's (block, school_year) —
-- covers blocks C, CLE-adjacent, H, and G/2026-27 (already 1:1 by name/block/year).
update public.enrollments e
set course_id = pc.id
from public.classes c, public.courses pc
where e.class_id = c.id
  and pc.block = c.block_label
  and pc.school_year = c.school_year
  and pc.superseded_by is null
  and (select count(*) from public.courses pc2 where pc2.block = c.block_label and pc2.school_year = c.school_year and pc2.superseded_by is null) = 1;

-- 5b. Blocks A/B/D/F: classes row is unsplit, multiple canonical rows per block+year —
-- disambiguate by the enrolled student's grade.
update public.enrollments e
set course_id = pc.id
from public.classes c, public.students s, public.courses pc
where e.class_id = c.id
  and e.course_id is null
  and s.id = e.student_id
  and pc.block = c.block_label
  and pc.school_year = c.school_year
  and pc.superseded_by is null
  and s.grade_year = any(pc.grade_years);

-- 5c. Block G/2025-26: classes rows already ARE the canonical rows via _legacy_class_id.
update public.enrollments e
set course_id = pc.id
from public.courses pc
where e.course_id is null
  and pc._legacy_class_id = e.class_id;

-- Step 6: merge rcs.enrollments into public.enrollments.
-- 6a. General case: rcs.courses.id maps 1:1 to a canonical row per (course, school_year)
-- via _legacy_rcs_course_id; rcs.enrollments.school_year picks the right year's row directly.
insert into public.enrollments (class_id, student_id, school_year, course_id)
select null, re.student_id, re.school_year, pc.id
from rcs.enrollments re
join public.courses pc on pc._legacy_rcs_course_id = re.course_id and pc.school_year = re.school_year
where exists (select 1 from public.students s where s.id = re.student_id)  -- drops the known orphaned row
  and not exists (
    select 1 from public.enrollments existing
    where existing.student_id = re.student_id and existing.course_id = pc.id
  );

-- 6b. Block G/2025-26 special case: the single old rcs course's enrollments need to land on
-- whichever quarter-split canonical row that student is already enrolled in via classes.
insert into public.enrollments (class_id, student_id, school_year, course_id)
select null, re.student_id, '2025-26', pc.id
from rcs.enrollments re
join rcs.courses co on co.id = re.course_id and co.block = 'G'
join public.enrollments existing on existing.student_id = re.student_id
join public.courses pc on pc.id = existing.course_id and pc.block = 'G' and pc.school_year = '2025-26'
where re.school_year = '2025-26'
  and not exists (
    select 1 from public.enrollments e2 where e2.student_id = re.student_id and e2.course_id = pc.id
  );

alter table public.courses drop column _legacy_rcs_course_id;
alter table public.courses drop column _legacy_class_id;
