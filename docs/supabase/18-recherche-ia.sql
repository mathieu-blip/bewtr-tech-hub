-- ============================================================
-- La recherche du guide passe par Claude.
--
-- Avant : « chercher » voulait dire « trouver les pages où ces
-- lettres-là apparaissent ». Un technicien qui tape « l'eau sort
-- tiède » ne tombait sur rien, parce que ces mots-là ne sont
-- écrits nulle part.
--
-- Après : la question part vers une fonction edge (`guide-search`)
-- qui la pose à Claude avec tout le guide sous les yeux, et qui
-- rend une réponse courte plus les pages à ouvrir.
--
-- Ce fichier prépare ce dont la fonction edge a besoin :
--   1. un dépôt pour le guide, pour que le navigateur ne le
--      renvoie pas à chaque question ;
--   2. un compteur d'appels, pour que la clé Anthropic ne serve
--      pas à faire tourner autre chose que le hub.
--
-- Rien ici n'est ouvert au navigateur : seule la fonction edge,
-- qui porte la clé de service, appelle ces trois fonctions.
-- ============================================================

-- ---------------------------------------------------------- le guide
-- Le hub calcule l'empreinte de son guide et n'envoie le texte
-- qu'une fois : la première question posée après une mise en ligne.
-- Les suivantes ne portent que l'empreinte.
create table if not exists hub.search_corpus (
  hash       text primary key,
  lang       text not null,
  entries    jsonb not null,
  created_at timestamptz not null default now(),
  used_at    timestamptz not null default now()
);

alter table hub.search_corpus enable row level security;

create or replace function public.hub_corpus_get(p_hash text)
returns jsonb
language plpgsql volatile security definer set search_path = hub, public as $$
declare v jsonb;
begin
  update hub.search_corpus set used_at = now()
   where hash = p_hash
   returning entries into v;
  return v;
end $$;

create or replace function public.hub_corpus_put(p_hash text, p_lang text, p_entries jsonb)
returns void
language sql volatile security definer set search_path = hub, public as $$
  insert into hub.search_corpus (hash, lang, entries)
  values (p_hash, p_lang, p_entries)
  on conflict (hash) do update set used_at = now();

  -- Une mise en ligne remplace le guide : les empreintes d'avant ne
  -- reviendront plus. On garde un mois, le temps qu'un onglet resté
  -- ouvert sur l'ancienne version finisse sa journée.
  delete from hub.search_corpus where used_at < now() - interval '30 days';
$$;

-- ------------------------------------------------------- le compteur
-- Le mot de passe du hub circule entre techniciens : il ouvre la
-- recherche, il ne la rend pas illimitée. Chaque poste a droit à son
-- quota de questions par jour, et la fonction edge fixe le plafond.
create table if not exists hub.search_calls (
  day  date not null,
  who  text not null,
  n    integer not null default 0,
  primary key (day, who)
);

alter table hub.search_calls enable row level security;

create or replace function public.hub_search_quota(p_who text, p_max integer)
returns boolean
language plpgsql volatile security definer set search_path = hub, public as $$
declare v integer;
begin
  insert into hub.search_calls (day, who, n)
  values (current_date, coalesce(nullif(p_who, ''), 'inconnu'), 1)
  on conflict (day, who) do update set n = hub.search_calls.n + 1
  returning n into v;

  delete from hub.search_calls where day < current_date - 7;
  return v <= p_max;
end $$;

-- ------------------------------------------------------ les verrous
-- Le navigateur ne connaît que la fonction edge ; ces trois-là ne
-- répondent qu'à la clé de service.
revoke execute on function public.hub_corpus_get(text)            from public, anon, authenticated;
revoke execute on function public.hub_corpus_put(text, text, jsonb) from public, anon, authenticated;
revoke execute on function public.hub_search_quota(text, integer)  from public, anon, authenticated;

grant  execute on function public.hub_corpus_get(text)            to service_role;
grant  execute on function public.hub_corpus_put(text, text, jsonb) to service_role;
grant  execute on function public.hub_search_quota(text, integer)  to service_role;
