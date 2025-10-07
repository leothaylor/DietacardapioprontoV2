-- Extensão para UUIDs (se ainda não estiver ativa)
create extension if not exists "pgcrypto";

create table if not exists public.user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  profile jsonb not null default '{}'::jsonb,
  all_days jsonb not null default '{}'::jsonb,
  slot_keys jsonb not null default '[]'::jsonb,
  current_day_id text not null default 'day-1',
  updated_at timestamptz not null default now(),
  unique(user_id)
);

alter table public.user_state enable row level security;

drop policy if exists "select_own_state" on public.user_state;
create policy "select_own_state"
  on public.user_state
  for select
  using (auth.uid() = user_id);

drop policy if exists "insert_own_state" on public.user_state;
create policy "insert_own_state"
  on public.user_state
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "update_own_state" on public.user_state;
create policy "update_own_state"
  on public.user_state
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
