-- ============================================================
-- BE WTR — Hub technicien : plateforme Claims & Spare parts
-- Remplace le board Monday "Technical troubleshooting".
--
-- Le hub est un site statique public : la clé anon est lisible
-- dans la page. Aucune table n'est donc accessible directement
-- (RLS active, zéro policy). Tout passe par des fonctions
-- SECURITY DEFINER qui exigent la phrase de passe (02-api.sql).
-- ============================================================

create extension if not exists pgcrypto with schema extensions;

-- Schéma privé : non exposé par PostgREST, donc invisible de l'extérieur.
create schema if not exists hub;

create table hub.secrets (
  scope     text primary key,          -- 'claims' | 'order'
  pass_hash text not null
);

-- 'claims' porte le mot de passe de l'écran de garde du hub, normalisé
-- comme index.html le normalise (trim, espaces réduits, majuscules) : la
-- plateforme des tickets n'a pas de phrase à elle. 'order' garde la sienne,
-- parce qu'elle seule ouvre les réfs fournisseur et les prix d'achat.
--
-- Les deux phrases ne sont PAS écrites ici. Ce dépôt est public : une phrase
-- posée dans un fichier versionné est une phrase publiée, et le rester même
-- après l'avoir retirée — l'historique la garde. Remplacer les deux
-- marqueurs ci-dessous au moment de jouer le script, dans l'éditeur SQL de
-- Supabase, et ne pas recoller le résultat dans le dépôt.
--
--   'claims' doit valoir le mot de passe du hub NORMALISÉ : sans espaces aux
--            bords, espaces intérieurs réduits à un, tout en majuscules.
--            C'est cette forme-là qu'index.html envoie.
--   'order'  est libre, et gagne à être longue : elle seule ouvre les prix.
insert into hub.secrets(scope, pass_hash) values
  ('claims', extensions.crypt('REMPLACER-phrase-du-hub',  extensions.gen_salt('bf', 10))),
  ('order',  extensions.crypt('REMPLACER-phrase-commande', extensions.gen_salt('bf', 10)));

-- Garde-fou : le script joué sans remplacer les marqueurs laisserait une base
-- ouverte à qui a lu le dépôt. Mieux vaut qu'il échoue bruyamment.
do $$
begin
  if exists (select 1 from hub.secrets
              where pass_hash = extensions.crypt('REMPLACER-phrase-du-hub', pass_hash)
                 or pass_hash = extensions.crypt('REMPLACER-phrase-commande', pass_hash))
  then
    raise exception 'les phrases de passe n''ont pas été remplacées dans 01-schema.sql';
  end if;
end $$;

-- ------------------------------------------------------------ catalogue
create table public.parts (
  ref           text primary key,       -- SKU interne BW-xxxx
  name          text not null,
  machines      text[] not null default '{}',
  supplier      text,
  supplier_ref  text,                   -- null = « réf à confirmer »
  supplier_desc text,
  price         numeric(12,2),
  currency      text,
  discount      numeric(4,3),           -- remise contractuelle (Italbedis : 0.60)
  active        boolean not null default true
);
create index on public.parts using gin (machines);

-- ------------------------------------------------------------ claims
create sequence public.claim_code_seq start 1;

create table public.claims (
  id               bigint generated always as identity primary key,
  code             text unique not null default 'CLM-' || lpad(nextval('public.claim_code_seq')::text, 5, '0'),
  title            text not null,
  description      text,
  technician_name  text,
  technician_email text,
  company          text,
  country          text,
  product          text,
  serial_number    text,
  install_date     date,
  claim_date       date not null default current_date,
  units_impacted   integer default 1,
  status           text not null default 'New (to repair)',
  decision         text,
  repair_notes     text,
  repair_date      date,
  restock_location text,
  monday_id        text unique,          -- traçabilité de la reprise Monday
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  -- même règle que la formule Monday : < 730 jours entre install et claim
  under_warranty   boolean generated always as (
                     case when install_date is not null
                       then (claim_date - install_date) < 730 end) stored
);
create index on public.claims (status);
create index on public.claims (claim_date desc);

-- search_path figé : une fonction qui laisse l'appelant le choisir peut se
-- voir substituer ses opérateurs.
create or replace function public.touch_updated_at() returns trigger
language plpgsql set search_path = public, pg_temp as $$
begin new.updated_at = now(); return new; end $$;

create trigger claims_touch before update on public.claims
  for each row execute function public.touch_updated_at();

-- ------------------------------------------------------------ pièces demandées
create table public.claim_parts (
  id         bigint generated always as identity primary key,
  claim_id   bigint not null references public.claims(id) on delete cascade,
  part_ref   text references public.parts(ref),
  free_text  text,                       -- pièce hors catalogue
  qty        integer not null default 1 check (qty > 0),
  order_id   bigint,                     -- null = pas encore commandée
  created_at timestamptz not null default now(),
  check (part_ref is not null or free_text is not null)
);
create index on public.claim_parts (claim_id);
create index on public.claim_parts (order_id);

-- ------------------------------------------------------------ commandes
create sequence public.order_code_seq start 1;

create table public.orders (
  id         bigint generated always as identity primary key,
  code       text unique not null default 'CMD-' || lpad(nextval('public.order_code_seq')::text, 5, '0'),
  supplier   text not null,
  status     text not null default 'sent',
  currency   text,
  total      numeric(12,2),
  created_by text,
  note       text,
  created_at timestamptz not null default now()
);

create table public.order_lines (
  id           bigint generated always as identity primary key,
  order_id     bigint not null references public.orders(id) on delete cascade,
  part_ref     text,
  supplier_ref text,
  designation  text,
  qty          integer not null,
  unit_price   numeric(12,2),
  line_total   numeric(12,2),
  claim_id     bigint
);
create index on public.order_lines (order_id);

alter table public.claim_parts
  add constraint claim_parts_order_fk foreign key (order_id) references public.orders(id) on delete set null;

-- ------------------------------------------------------------ verrouillage
alter table public.parts       enable row level security;
alter table public.claims      enable row level security;
alter table public.claim_parts enable row level security;
alter table public.orders      enable row level security;
alter table public.order_lines enable row level security;
-- Aucune policy : anon et authenticated ne lisent ni n'écrivent rien en direct.

revoke all on all tables in schema hub from anon, authenticated;
revoke all on schema hub from anon, authenticated;
