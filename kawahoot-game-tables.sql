-- ============================================================
-- Kawahoot Game Tables — run once in your shared Supabase project
-- All statements are safe to run multiple times (IF NOT EXISTS).
-- ============================================================

-- Games
create table if not exists games (
  id uuid default gen_random_uuid() primary key,
  pin text not null unique,
  host_id text,
  title text not null,
  status text not null default 'waiting'
    check (status in ('waiting', 'question', 'answer_reveal', 'leaderboard', 'finished', 'paused')),
  mode text not null default 'individual' check (mode in ('individual', 'teams')),
  current_question_index integer not null default -1,
  current_question_started_at timestamptz,
  next_game_id uuid,
  created_at timestamptz default now()
);

-- Quiz questions
create table if not exists quiz_questions (
  id uuid default gen_random_uuid() primary key,
  game_id uuid not null references games(id) on delete cascade,
  question_text text not null,
  option_a text not null,
  option_b text not null,
  option_c text not null,
  option_d text not null,
  correct_answer char(1) not null check (correct_answer in ('A','B','C','D')),
  time_limit integer not null default 20,
  order_index integer not null,
  created_at timestamptz default now()
);

-- Players
create table if not exists players (
  id uuid default gen_random_uuid() primary key,
  game_id uuid not null references games(id) on delete cascade,
  nickname text not null,
  score integer not null default 0,
  team_id uuid,
  is_pre_registered boolean not null default false,
  real_name text,
  is_claimed boolean not null default false,
  joined_at timestamptz default now()
);

-- Answers
create table if not exists answers (
  id uuid default gen_random_uuid() primary key,
  game_id uuid not null references games(id) on delete cascade,
  player_id uuid not null references players(id) on delete cascade,
  question_id uuid not null references quiz_questions(id) on delete cascade,
  selected_answer char(1) not null check (selected_answer in ('A','B','C','D')),
  is_correct boolean not null default false,
  response_time_ms integer not null default 0,
  points_earned integer not null default 0,
  answered_at timestamptz default now(),
  unique(player_id, question_id)
);

-- Teams
create table if not exists teams (
  id uuid default gen_random_uuid() primary key,
  game_id uuid not null references games(id) on delete cascade,
  name text not null,
  color text not null default 'purple',
  created_at timestamptz default now()
);

-- FK from players to teams (add after teams table exists)
alter table players add column if not exists team_id uuid references teams(id) on delete set null;

-- Indexes
create index if not exists idx_games_pin on games(pin);
create index if not exists idx_games_status on games(status);
create index if not exists idx_quiz_questions_game_id on quiz_questions(game_id);
create index if not exists idx_players_game_id on players(game_id);
create index if not exists idx_players_team_id on players(team_id);
create index if not exists idx_answers_question_id on answers(question_id);
create index if not exists idx_answers_player_id on answers(player_id);
create index if not exists idx_teams_game_id on teams(game_id);

-- RLS (open access — intentional for a no-auth classroom game)
alter table games enable row level security;
alter table quiz_questions enable row level security;
alter table players enable row level security;
alter table answers enable row level security;
alter table teams enable row level security;

drop policy if exists "kawahoot_games_all" on games;
create policy "kawahoot_games_all" on games for all using (true) with check (true);

drop policy if exists "kawahoot_quiz_questions_all" on quiz_questions;
create policy "kawahoot_quiz_questions_all" on quiz_questions for all using (true) with check (true);

drop policy if exists "kawahoot_players_all" on players;
create policy "kawahoot_players_all" on players for all using (true) with check (true);

drop policy if exists "kawahoot_answers_all" on answers;
create policy "kawahoot_answers_all" on answers for all using (true) with check (true);

drop policy if exists "kawahoot_teams_all" on teams;
create policy "kawahoot_teams_all" on teams for all using (true) with check (true);

-- Realtime
alter publication supabase_realtime add table games;
alter publication supabase_realtime add table players;
alter publication supabase_realtime add table answers;
alter publication supabase_realtime add table teams;
alter publication supabase_realtime add table quiz_questions;

alter table games replica identity full;
alter table players replica identity full;
alter table answers replica identity full;
alter table quiz_questions replica identity full;
alter table teams replica identity full;
