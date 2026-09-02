-- ---------------------------------------------------------------------------
-- 18 — Un seul texte par ticket, et « réparé par »
--
-- Deux changements demandés sur le terrain :
--
-- 1. L'objet du ticket disparaît. Les techniciens remplissaient deux champs
--    qui disaient la même chose, et le tableau n'affichait que le plus court
--    des deux. La description devient le texte du ticket. La colonne title
--    reste (NOT NULL, et elle porte l'intitulé Monday des 321 tickets
--    repris) : elle est désormais dérivée de la première ligne de la
--    description à la création, et laissée telle quelle ensuite.
--
--    Les tickets sans description reçoivent leur ancien objet : c'est la
--    seule phrase qu'ils portent, et sans ce rattrapage leur ligne serait
--    vide à l'écran.
--
-- 2. « Réparé par » : le suivi disait quand la machine avait été réparée,
--    jamais par qui. Le champ est dans le formulaire de suivi, pas dans la
--    création — au moment d'ouvrir un ticket, personne ne l'a encore réparé.
--
-- Idempotent : rejouable sans dommage.
-- ---------------------------------------------------------------------------

alter table public.claims add column if not exists repaired_by text;

-- Le ticket qui n'a qu'un objet le garde comme description.
update public.claims
   set description = title
 where description is null or btrim(description) = '';

-- --------------------------------------------------- liste des claims
-- Une colonne de plus dans le retour : PostgreSQL refuse de remplacer une
-- fonction dont le type de retour change, il faut la supprimer d'abord.
drop function if exists public.claims_list(text);

create or replace function public.claims_list(p_pass text)
returns table (id bigint, code text, title text, description text,
               technician_name text, technician_email text, company text,
               country text, product text, serial_number text,
               install_date date, claim_date date, units_impacted integer,
               status text, decision text, repair_notes text, repair_date date,
               repaired_by text, restock_location text, under_warranty boolean,
               created_at timestamptz, parts jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  return query
    select c.id, c.code, c.title, c.description, c.technician_name,
           c.technician_email, c.company, c.country, c.product, c.serial_number,
           c.install_date, c.claim_date, c.units_impacted, c.status, c.decision,
           c.repair_notes, c.repair_date, c.repaired_by, c.restock_location,
           c.under_warranty,
           c.created_at,
           coalesce((
             select jsonb_agg(jsonb_build_object(
                      'id', cp.id, 'ref', cp.part_ref, 'free_text', cp.free_text,
                      'name', pt.name, 'qty', cp.qty,
                      'ordered', (cp.order_id is not null or cp.ordered_manual))
                    order by cp.id)
               from public.claim_parts cp
               left join public.parts pt on pt.ref = cp.part_ref
              where cp.claim_id = c.id), '[]'::jsonb)
      from public.claims c
     order by c.claim_date desc, c.id desc;
end $$;

-- --------------------------------------------------- suivi de réparation
create or replace function public.claim_update(p_pass text, p_id bigint, p jsonb)
returns public.claims
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims;
begin
  perform public.hub_require(p_pass, 'claims');
  update public.claims c set
    status           = coalesce(nullif(btrim(coalesce(p->>'status','')), ''), c.status),
    decision         = coalesce(nullif(btrim(coalesce(p->>'decision','')), ''), c.decision),
    repair_notes     = coalesce(nullif(btrim(coalesce(p->>'repair_notes','')), ''), c.repair_notes),
    repair_date      = coalesce(nullif(p->>'repair_date','')::date, c.repair_date),
    -- Seul champ du suivi qu'on puisse vider : « réparé par » se corrige, et
    -- un nom mis par erreur doit pouvoir partir. La clé absente ne touche à
    -- rien, la clé présente et vide efface.
    repaired_by      = case when p ? 'repaired_by'
                       then nullif(btrim(coalesce(p->>'repaired_by','')), '')
                       else c.repaired_by end,
    restock_location = coalesce(nullif(btrim(coalesce(p->>'restock_location','')), ''), c.restock_location)
  where c.id = p_id
  returning * into v_claim;
  if not found then raise exception 'claim % not found', p_id using errcode='02000'; end if;
  return v_claim;
end $$;

-- --------------------------------------------------- création d'un ticket
-- Corps des scripts 05/10, à la garde sur l'objet près.
create or replace function public.claim_submit(p jsonb)
returns text
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims; v_part jsonb; v_recent integer; v_title text;
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

  return v_claim.code;   -- le numéro seul, rien d'autre ne sort
end $$;

create or replace function public.claim_create(p_pass text, p jsonb)
returns public.claims
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims; v_part jsonb; v_title text;
begin
  perform public.hub_require(p_pass, 'claims');

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
          coalesce(nullif(btrim(coalesce(p->>'status','')), ''), 'New (to repair)'))
  returning * into v_claim;

  for v_part in select * from jsonb_array_elements(coalesce(p->'parts', '[]'::jsonb))
  loop
    insert into public.claim_parts (claim_id, part_ref, free_text, qty)
    values (v_claim.id,
            nullif(btrim(coalesce(v_part->>'ref','')), ''),
            nullif(btrim(coalesce(v_part->>'free_text','')), ''),
            greatest(1, coalesce(nullif(v_part->>'qty','')::integer, 1)));
  end loop;

  return v_claim;
end $$;

grant execute on function public.claims_list(text)               to anon, authenticated;
grant execute on function public.claim_update(text, bigint, jsonb) to anon, authenticated;
grant execute on function public.claim_submit(jsonb)             to anon, authenticated;
grant execute on function public.claim_create(text, jsonb)       to anon, authenticated;

-- Contrôles : les deux doivent rendre 0.
select count(*) as tickets_sans_description from public.claims
 where description is null or btrim(description) = '';
select count(*) as tickets_sans_objet from public.claims
 where title is null or btrim(title) = '';
