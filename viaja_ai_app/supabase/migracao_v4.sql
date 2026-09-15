-- =====================================================================
-- ViajAí Bolso — Migração v4 (rodar UMA VEZ no SQL Editor do Supabase)
-- Project > SQL Editor > New query > colar tudo abaixo > Run
--
-- Todos os comandos são seguros de rodar mais de uma vez, então não tem
-- problema se você rodar de novo por engano.
-- =====================================================================

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
-- replace"): como a coluna nova (moeda_local) entra no meio da lista de
-- colunas de "viagens" por causa do v.*, o Postgres entende isso como
-- "trocar o nome" de uma coluna já existente da view, o que não é
-- permitido. Removendo e recriando não tem esse problema.
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
