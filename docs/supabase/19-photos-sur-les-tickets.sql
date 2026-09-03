-- ---------------------------------------------------------------------------
-- 19 — Des photos sur les tickets
--
-- Une panne se décrit mal et se photographie bien : un raccord qui fuit, une
-- carte brûlée, un numéro de série illisible. Les photos manquaient, et le
-- technicien les envoyait par WhatsApp, hors du ticket.
--
-- Où elles vivent. Dans la base, pas dans un bucket Storage : le hub n'a
-- qu'une porte, les fonctions SECURITY DEFINER qui exigent la phrase de
-- passe. Un bucket demanderait ses propres règles d'accès, avec une clé
-- publique lisible dans la page — donc soit ouvert à tous, soit inutilisable.
-- Deux tailles sont stockées : la vignette, rendue avec la liste, et l'image,
-- chargée seulement quand on l'ouvre. Sans quoi ouvrir un ticket tirerait
-- plusieurs mégaoctets sur un téléphone en 4G.
--
-- La page réduit avant d'envoyer (1600 px, JPEG) : une photo de téléphone de
-- 4 Mo arrive autour de 300 Ko. Les plafonds ci-dessous ne sont donc pas la
-- norme mais la digue — ils arrêtent un appel direct, pas un usage normal.
--
-- Idempotent : rejouable sans dommage.
-- ---------------------------------------------------------------------------

create table if not exists public.claim_photos (
  id         bigint generated always as identity primary key,
  claim_id   bigint not null references public.claims(id) on delete cascade,
  mime       text   not null default 'image/jpeg',
  data       bytea  not null,          -- l'image réduite (1600 px environ)
  thumb      bytea  not null,          -- la vignette (320 px environ)
  bytes      integer not null,         -- taille de l'image, pour le plafond
  created_at timestamptz not null default now()
);
create index if not exists claim_photos_claim_id_idx
  on public.claim_photos (claim_id);

-- Comme les autres tables : RLS active, zéro policy. Rien n'est lisible sans
-- passer par une fonction qui vérifie la phrase de passe.
alter table public.claim_photos enable row level security;

-- --------------------------------------------------- l'écriture, en un point
-- Trois fonctions publiques insèrent une photo (dépôt externe, création,
-- ajout sur un ticket existant). Les contrôles vivent ici, une seule fois :
-- format accepté, taille, nombre par ticket. hub n'est pas exposé par
-- PostgREST, la fonction n'est donc appelable que depuis les autres.
create or replace function hub.photo_add(p_claim_id bigint, p jsonb,
                                         p_max_bytes integer default 4 * 1024 * 1024)
returns bigint
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_data bytea; v_thumb bytea; v_mime text; v_count integer; v_id bigint;
begin
  if p is null or jsonb_typeof(p) <> 'object' then
    raise exception 'photo attendue' using errcode = '22023';
  end if;

  -- Le JPEG est ce que produit la page ; PNG et WebP sont acceptés pour une
  -- capture d'écran déposée telle quelle. Rien d'autre : une photo n'est pas
  -- une pièce jointe, et un SVG s'exécute dans le navigateur qui l'ouvre.
  v_mime := lower(btrim(coalesce(p->>'mime', 'image/jpeg')));
  if v_mime not in ('image/jpeg', 'image/png', 'image/webp') then
    raise exception 'format d''image non accepté : %', v_mime using errcode = '22023';
  end if;

  begin
    v_data  := decode(coalesce(p->>'data',  ''), 'base64');
    v_thumb := decode(coalesce(p->>'thumb', ''), 'base64');
  exception when others then
    raise exception 'image illisible' using errcode = '22023';
  end;

  if length(v_data) = 0 then
    raise exception 'image vide' using errcode = '22023';
  end if;
  if length(v_data) > p_max_bytes then
    raise exception 'image trop lourde (% octets)', length(v_data) using errcode = '22023';
  end if;
  -- pas de vignette fournie : l'image sert des deux côtés
  if length(v_thumb) = 0 or length(v_thumb) > 512 * 1024 then v_thumb := v_data; end if;

  select count(*) into v_count from public.claim_photos where claim_id = p_claim_id;
  if v_count >= 12 then
    raise exception 'ce ticket porte déjà 12 photos' using errcode = '22023';
  end if;

  insert into public.claim_photos (claim_id, mime, data, thumb, bytes)
  values (p_claim_id, v_mime, v_data, v_thumb, length(v_data))
  returning id into v_id;
  return v_id;
end $$;

-- --------------------------------------------------- lire les vignettes
-- Les vignettes seulement : la liste d'un ticket doit rester légère. Le poids
-- part avec, pour que la page dise ce qu'elle s'apprête à télécharger.
create or replace function public.claim_photos_list(p_pass text, p_claim_id bigint)
returns table (id bigint, mime text, thumb text, bytes integer, created_at timestamptz)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  return query
    select ph.id, ph.mime, encode(ph.thumb, 'base64'), ph.bytes, ph.created_at
      from public.claim_photos ph
     where ph.claim_id = p_claim_id
     order by ph.id;
end $$;

-- --------------------------------------------------- ouvrir une photo
create or replace function public.claim_photo_get(p_pass text, p_id bigint)
returns table (mime text, data text)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  return query
    select ph.mime, encode(ph.data, 'base64')
      from public.claim_photos ph
     where ph.id = p_id;
end $$;

-- --------------------------------------------------- ajouter sur un ticket
create or replace function public.claim_photo_add(p_pass text, p_claim_id bigint, p jsonb)
returns bigint
language plpgsql security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  if not exists (select 1 from public.claims where id = p_claim_id) then
    raise exception 'ticket % introuvable', p_claim_id using errcode = '02000';
  end if;
  return hub.photo_add(p_claim_id, p);
end $$;

-- --------------------------------------------------- retirer une photo
create or replace function public.claim_photo_delete(p_pass text, p_id bigint)
returns void
language plpgsql security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  delete from public.claim_photos where id = p_id;
end $$;

-- --------------------------------------------------- dépôt externe
-- Corps du script 18, à la boucle photos près.
create or replace function public.claim_submit(p jsonb)
returns text
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims; v_part jsonb; v_recent integer; v_title text;
        v_photo jsonb; v_n integer := 0;
begin
  -- L'objet a disparu du formulaire : la description est le seul texte saisi.
  -- title reste NOT NULL en base, on le dérive donc de sa première ligne, et
  -- l'exigence porte désormais sur la description.
  v_title := btrim(coalesce(p->>'title', ''));
  if v_title = '' then
    v_title := left(btrim(split_part(
                 replace(coalesce(p->>'description', ''), chr(13), ''), chr(10), 1)), 300);
  end if;
  if v_title = '' then
    raise exception 'description is required' using errcode = '22023';
  end if;

  -- Garde-fou : la fonction est ouverte, donc quelqu'un qui trouve la clé
  -- publique pourrait la marteler. Le plafond est très au-dessus d'un usage
  -- normal — il n'arrête que l'emballement.
  select count(*) into v_recent
    from public.claims where created_at > now() - interval '1 hour';
  if v_recent > 200 then
    raise exception 'too many submissions, try again later' using errcode = '53400';
  end if;

  insert into public.claims (title, description, technician_name, technician_email,
                             company, country, product, serial_number, install_date,
                             claim_date, units_impacted, status)
  values (v_title,
          nullif(btrim(coalesce(p->>'description','')), ''),
          nullif(btrim(coalesce(p->>'technician_name','')), ''),
          nullif(btrim(coalesce(p->>'technician_email','')), ''),
          nullif(btrim(coalesce(p->>'company','')), ''),
          nullif(btrim(coalesce(p->>'country','')), ''),
          nullif(btrim(coalesce(p->>'product','')), ''),
          nullif(btrim(coalesce(p->>'serial_number','')), ''),
          nullif(p->>'install_date','')::date,
          least(coalesce(nullif(p->>'claim_date','')::date, current_date), current_date),
          coalesce(nullif(p->>'units_impacted','')::integer, 1),
          case when jsonb_array_length(coalesce(p->'parts','[]'::jsonb)) > 0
               then 'Spare part to order' else 'New (to repair)' end)
  returning * into v_claim;

  for v_part in select * from jsonb_array_elements(coalesce(p->'parts', '[]'::jsonb))
  loop
    -- la référence doit exister au catalogue : pas de texte libre par cette porte
    insert into public.claim_parts (claim_id, part_ref, qty)
    select v_claim.id, pt.ref,
           greatest(1, least(999, coalesce(nullif(v_part->>'qty','')::integer, 1)))
      from public.parts pt
     where pt.ref = btrim(coalesce(v_part->>'ref',''));
  end loop;

  -- Les photos voyagent avec la déclaration : le lien externe ne rend que le
  -- numéro du ticket, jamais son id, donc rien ne pourrait les rattacher
  -- après coup. Trois au plus, la page les ayant déjà réduites.
  for v_photo in select * from jsonb_array_elements(coalesce(p->'photos', '[]'::jsonb))
  loop
    v_n := v_n + 1;
    exit when v_n > 3;
    perform hub.photo_add(v_claim.id, v_photo, 2 * 1024 * 1024);
  end loop;

  return v_claim.code;   -- le numéro seul, rien d'autre ne sort
end $$;

grant execute on function public.claim_photos_list(text, bigint)  to anon, authenticated;
grant execute on function public.claim_photo_get(text, bigint)    to anon, authenticated;
grant execute on function public.claim_photo_add(text, bigint, jsonb) to anon, authenticated;
grant execute on function public.claim_photo_delete(text, bigint) to anon, authenticated;
grant execute on function public.claim_submit(jsonb)              to anon, authenticated;

-- hub.photo_add n'est jamais appelée du dehors : elle n'est pas dans un schéma
-- exposé, et rien ne lui est accordé.
revoke all on function hub.photo_add(bigint, jsonb, integer) from public, anon, authenticated;

-- Contrôle : doit rendre 0 au premier passage.
select count(*) as photos_enregistrees from public.claim_photos;
