-- =====================================================================
-- ViajAí Bolso — Migração v5: Assistente de IA (RF33–RF40)
-- Rodar UMA VEZ no SQL Editor do Supabase
-- Project > SQL Editor > New query > colar tudo abaixo > Run
--
-- Cria as tabelas que guardam o histórico de conversas do assistente de
-- IA. Todos os comandos são seguros de rodar mais de uma vez.
-- =====================================================================

-- Cada conversa pertence a um usuário. Por enquanto o app usa sempre a
-- conversa mais recente (um "histórico contínuo" por usuário), mas já
-- fica modelado como lista para permitir múltiplas conversas no futuro.
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

-- Mensagens de uma conversa (tanto do usuário quanto do assistente).
create table if not exists public.mensagens (
  id uuid primary key default gen_random_uuid(),
  conversa_id uuid not null references public.conversas (id) on delete cascade,
  papel text not null check (papel in ('user', 'assistant')),
  conteudo text not null,
  created_at timestamptz not null default now()
);

alter table public.mensagens enable row level security;

-- A política verifica o dono pela conversa (não existe user_id direto na
-- tabela de mensagens). Isso vale tanto para a mensagem do usuário
-- (inserida pelo app) quanto para a resposta do assistente (inserida
-- pelo app depois que a Edge Function devolve o texto gerado).
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
