-- =====================================================================
-- Viajaí Bolso — Schema do Supabase (Postgres)
-- Rode este script inteiro no SQL Editor do seu projeto Supabase
-- (Project > SQL Editor > New query > colar > Run) para um projeto NOVO.
--
-- Se o seu projeto já existe (como é o caso aqui), NÃO rode este arquivo
-- inteiro de novo — rode só o bloco "6. MIGRAÇÃO INCREMENTAL (v4)" no
-- final, que foi escrito para ser seguro de aplicar em cima do banco que
-- já está no ar.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PERFIS (dados extras do usuário, além do que o Supabase Auth guarda)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  nome text not null,
  email text not null,
  foto_url text,
  moeda_padrao text not null default 'BRL',
  viagem_ativa_id uuid,
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "usuário vê o próprio perfil"
  on public.profiles for select
  using (auth.uid() = id);

create policy "usuário edita o próprio perfil"
  on public.profiles for update
  using (auth.uid() = id);

-- Cria automaticamente uma linha em profiles sempre que alguém se cadastra
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, nome, email)
  values (new.id, coalesce(new.raw_user_meta_data->>'nome', ''), new.email);
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- 2. CATEGORIAS (lista compartilhada, leitura pública)
-- ---------------------------------------------------------------------
create table if not exists public.categorias (
  id uuid primary key default gen_random_uuid(),
  nome text not null,
  icone text not null
);

alter table public.categorias enable row level security;

create policy "qualquer usuário autenticado lê categorias"
  on public.categorias for select
  to authenticated
  using (true);

insert into public.categorias (nome, icone) values
  ('Alimentação', 'restaurant'),
  ('Transporte', 'directions_car'),
  ('Hospedagem', 'hotel'),
  ('Lazer', 'attractions'),
  ('Compras', 'shopping_bag'),
  ('Saúde', 'medical_services'),
  ('Outros', 'category')
on conflict do nothing;

-- ---------------------------------------------------------------------
-- 3. VIAGENS
-- ---------------------------------------------------------------------
create table if not exists public.viagens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  nome text not null,
  destino text not null,
  foto_url text,
  data_inicio date not null,
  data_fim date not null,
  orcamento numeric(12, 2) not null default 0,
  moeda_local text not null default 'BRL',
  created_at timestamptz not null default now()
);

alter table public.viagens enable row level security;

create policy "usuário gerencia as próprias viagens"
  on public.viagens for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- profiles.viagem_ativa_id referencia viagens, então o FK só pode ser
-- criado depois que a tabela viagens existe.
alter table public.profiles
  drop constraint if exists profiles_viagem_ativa_id_fkey;
alter table public.profiles
  add constraint profiles_viagem_ativa_id_fkey
  foreign key (viagem_ativa_id) references public.viagens (id) on delete set null;

-- ---------------------------------------------------------------------
-- 4. DESPESAS
-- ---------------------------------------------------------------------
create table if not exists public.despesas (
  id uuid primary key default gen_random_uuid(),
  viagem_id uuid not null references public.viagens (id) on delete cascade,
  categoria_id uuid not null references public.categorias (id),
  descricao text not null,
  valor numeric(12, 2) not null,
  data date not null,
  hora time,
  forma_pagamento text not null default 'Cartão de crédito',
  foto_url text,
  created_at timestamptz not null default now()
);

alter table public.despesas enable row level security;

-- despesa só é visível/editável por quem é dono da viagem associada
create policy "usuário gerencia despesas das próprias viagens"
  on public.despesas for all
  using (
    exists (
      select 1 from public.viagens v
      where v.id = despesas.viagem_id and v.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.viagens v
      where v.id = despesas.viagem_id and v.user_id = auth.uid()
    )
  );

-- ---------------------------------------------------------------------
-- 5. VIEW com totais calculados (substitui os campos totalGasto /
--    percentualGasto que antes vinham prontos do backend antigo)
-- ---------------------------------------------------------------------
create or replace view public.viagens_resumo
  with (security_invoker = true) as
select
  v.*,
  coalesce(sum(d.valor), 0) as total_gasto,
  case when v.orcamento > 0
       then round(coalesce(sum(d.valor), 0) / v.orcamento * 100, 2)
       else 0
  end as percentual_gasto
from public.viagens v
left join public.despesas d on d.viagem_id = v.id
group by v.id;

-- A view herda a segurança das tabelas base (viagens/despesas já têm RLS),
-- então cada usuário só enxerga o resumo das próprias viagens.

-- ---------------------------------------------------------------------
-- 6. MIGRAÇÃO INCREMENTAL (v4) — rode SÓ ESTE BLOCO em um projeto que já
--    existia antes da v4. Todos os comandos são seguros de rodar mais de
--    uma vez (idempotentes).
-- ---------------------------------------------------------------------
alter table public.viagens
  add column if not exists moeda_local text not null default 'BRL';

alter table public.despesas
  add column if not exists foto_url text;

alter table public.profiles
  add column if not exists viagem_ativa_id uuid;

alter table public.profiles
  drop constraint if exists profiles_viagem_ativa_id_fkey;
alter table public.profiles
  add constraint profiles_viagem_ativa_id_fkey
  foreign key (viagem_ativa_id) references public.viagens (id) on delete set null;

-- A view precisa ser recriada do zero (não dá pra usar "create or
-- replace"): como moeda_local entra no meio da lista de colunas de
-- "viagens" por causa do v.*, o Postgres entende isso como "trocar o
-- nome" de uma coluna já existente da view, o que não é permitido.
drop view if exists public.viagens_resumo;

create view public.viagens_resumo
  with (security_invoker = true) as
select
  v.*,
  coalesce(sum(d.valor), 0) as total_gasto,
  case when v.orcamento > 0
       then round(coalesce(sum(d.valor), 0) / v.orcamento * 100, 2)
       else 0
  end as percentual_gasto
from public.viagens v
left join public.despesas d on d.viagem_id = v.id
group by v.id;

-- ---------------------------------------------------------------------
-- 7. STORAGE — bucket para fotos (perfil, viagens, comprovantes de
--    despesa e exportações de CSV)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('fotos', 'fotos', true)
on conflict (id) do nothing;

create policy "usuário envia as próprias fotos"
  on storage.objects for insert
  to authenticated
  with check (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "qualquer um lê as fotos (bucket público)"
  on storage.objects for select
  using (bucket_id = 'fotos');

create policy "usuário substitui/apaga as próprias fotos"
  on storage.objects for update
  to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

create policy "usuário apaga as próprias fotos"
  on storage.objects for delete
  to authenticated
  using (bucket_id = 'fotos' and (storage.foldername(name))[1] = auth.uid()::text);

-- ---------------------------------------------------------------------
-- 8. ASSISTENTE DE IA (v5) — histórico de conversas do chat (RF33–RF40)
--    Se o seu projeto já existia antes da v5, rode só o arquivo
--    supabase/migracao_v5.sql (mesmo conteúdo deste bloco).
-- ---------------------------------------------------------------------
create table if not exists public.conversas (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  titulo text not null default 'Assistente de viagem',
  created_at timestamptz not null default now()
);

alter table public.conversas enable row level security;

drop policy if exists "usuário gerencia as próprias conversas" on public.conversas;
create policy "usuário gerencia as próprias conversas"
  on public.conversas for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

create table if not exists public.mensagens (
  id uuid primary key default gen_random_uuid(),
  conversa_id uuid not null references public.conversas (id) on delete cascade,
  papel text not null check (papel in ('user', 'assistant')),
  conteudo text not null,
  created_at timestamptz not null default now()
);

alter table public.mensagens enable row level security;

drop policy if exists "usuário gerencia mensagens das próprias conversas" on public.mensagens;
create policy "usuário gerencia mensagens das próprias conversas"
  on public.mensagens for all
  using (
    exists (
      select 1 from public.conversas c
      where c.id = mensagens.conversa_id and c.user_id = auth.uid()
    )
  )
  with check (
    exists (
      select 1 from public.conversas c
      where c.id = mensagens.conversa_id and c.user_id = auth.uid()
    )
  );

create index if not exists mensagens_conversa_id_idx
  on public.mensagens (conversa_id, created_at);
