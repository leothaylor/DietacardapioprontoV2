-- Extensão para UUIDs (se ainda não estiver ativa)
-- Extensões necessárias ----------------------------------------------------
create extension if not exists "pgcrypto";

-- Função utilitária para atualizar timestamps -----------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Estado do usuário --------------------------------------------------------
create table if not exists public.user_state (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users on delete cascade,
  profile jsonb not null default '{}'::jsonb,
  all_days jsonb not null default '{}'::jsonb,
  slot_keys jsonb not null default '[]'::jsonb,
  current_day_id text not null default 'day-1',
  favorites jsonb not null default '[]'::jsonb,
  usage jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(user_id)
  unique (user_id)
);

drop trigger if exists set_timestamp_user_state on public.user_state;
create trigger set_timestamp_user_state
  before update on public.user_state
  for each row
  execute function public.set_updated_at();

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

-- Biblioteca colaborativa de refeições ------------------------------------
create table if not exists public.refeicoes_biblioteca (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  kcal numeric not null default 0,
  proteina numeric not null default 0,
  carboidrato numeric not null default 0,
  gordura numeric not null default 0,
  bloco text not null default '250',
  tags text[] not null default '{}',
  created_by uuid references auth.users on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists refeicoes_biblioteca_created_by_idx
  on public.refeicoes_biblioteca (created_by);

create index if not exists refeicoes_biblioteca_tags_idx
  on public.refeicoes_biblioteca using gin (tags);

drop trigger if exists set_timestamp_refeicoes_biblioteca on public.refeicoes_biblioteca;
create trigger set_timestamp_refeicoes_biblioteca
  before update on public.refeicoes_biblioteca
  for each row
  execute function public.set_updated_at();

alter table public.refeicoes_biblioteca enable row level security;

drop policy if exists "public_read" on public.refeicoes_biblioteca;
create policy "public_read"
  on public.refeicoes_biblioteca
  for select
  using (true);

drop policy if exists "insert_own_meal" on public.refeicoes_biblioteca;
create policy "insert_own_meal"
  on public.refeicoes_biblioteca
  for insert
  with check (auth.role() = 'authenticated' and auth.uid() = created_by);

drop policy if exists "update_own_meal" on public.refeicoes_biblioteca;
create policy "update_own_meal"
  on public.refeicoes_biblioteca
  for update
  using (auth.uid() = created_by)
  with check (auth.uid() = created_by);

drop policy if exists "delete_own_meal" on public.refeicoes_biblioteca;
create policy "delete_own_meal"
  on public.refeicoes_biblioteca
  for delete
  using (auth.uid() = created_by);
