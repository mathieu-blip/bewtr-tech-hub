-- ---------------------------------------------------------------------------
-- 10 — La date d'un claim ne peut pas être dans le futur
--
-- Le navigateur borne déjà le champ — attribut max, plus un contrôle à
-- l'envoi, car le formulaire est en novalidate et max n'y bloque rien tout
-- seul. Mais claim_submit() est ouvert : c'est la fonction que le lien
-- #ticket donne aux externes, et une borne côté page ne tient pas contre un
-- appel direct. Une date de demain fausse l'ancienneté d'un claim comme le
-- calcul de garantie.
--
-- Le parti pris : on RAMÈNE au jour même plutôt que de refuser. Un technicien
-- qui se trompe d'un jour dans le sélecteur ne doit pas perdre sa déclaration
-- — surtout par le formulaire ouvert, où il n'a pas de seconde chance.
--
-- Les trois corps ci-dessous sont ceux des scripts 02, 05 et 08, à une
-- expression près : le least(..., current_date) sur claim_date. Rien d'autre
-- n'est touché.
--
-- À exécuter APRÈS 09 : la reprise Monday contient un ticket daté 2027-01-17,
-- que le rattrapage de fin ramènera au jour même.
-- ---------------------------------------------------------------------------

create or replace function public.claim_submit(p jsonb)
returns text
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims; v_part jsonb; v_recent integer;
begin
  if coalesce(btrim(p->>'title'), '') = '' then
    raise exception 'title is required' using errcode = '22023';
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
  values (btrim(p->>'title'),
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
declare v_claim public.claims; v_part jsonb;
begin
  perform public.hub_require(p_pass, 'claims');

  if coalesce(btrim(p->>'title'), '') = '' then
    raise exception 'title is required' using errcode = '22023';
  end if;

  insert into public.claims (title, description, technician_name, technician_email,
                             company, country, product, serial_number, install_date,
                             claim_date, units_impacted, status)
  values (btrim(p->>'title'),
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

create or replace function public.claim_edit(p_pass text, p_id bigint, p jsonb)
returns public.claims
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims;
begin
  perform public.hub_require(p_pass, 'claims');
  if p is null or jsonb_typeof(p) <> 'object' then
    raise exception 'objet attendu' using errcode = '22023';
  end if;

  update public.claims c set
    -- NOT NULL : on garde l'ancien titre si le champ arrive vide
    title            = case when p ? 'title'
                       then coalesce(nullif(btrim(p->>'title'), ''), c.title)
                       else c.title end,
    description      = case when p ? 'description'
                       then nullif(btrim(coalesce(p->>'description','')), '')
                       else c.description end,
    technician_name  = case when p ? 'technician_name'
                       then nullif(btrim(coalesce(p->>'technician_name','')), '')
                       else c.technician_name end,
    technician_email = case when p ? 'technician_email'
                       then nullif(btrim(coalesce(p->>'technician_email','')), '')
                       else c.technician_email end,
    company          = case when p ? 'company'
                       then nullif(btrim(coalesce(p->>'company','')), '')
                       else c.company end,
    country          = case when p ? 'country'
                       then nullif(btrim(coalesce(p->>'country','')), '')
                       else c.country end,
    product          = case when p ? 'product'
                       then nullif(btrim(coalesce(p->>'product','')), '')
                       else c.product end,
    serial_number    = case when p ? 'serial_number'
                       then nullif(btrim(coalesce(p->>'serial_number','')), '')
                       else c.serial_number end,
    install_date     = case when p ? 'install_date'
                       then nullif(btrim(coalesce(p->>'install_date','')), '')::date
                       else c.install_date end,
    -- NOT NULL également
    claim_date       = case when p ? 'claim_date'
                       then least(coalesce(nullif(btrim(coalesce(p->>'claim_date','')), '')::date,
                                           c.claim_date), current_date)
                       else least(c.claim_date, current_date) end,
    units_impacted   = case when p ? 'units_impacted'
                       then least(9999, greatest(1,
                              nullif(btrim(coalesce(p->>'units_impacted','')), '')::integer))
                       else c.units_impacted end
  where c.id = p_id
  returning * into v_claim;

  if not found then raise exception 'claim % introuvable', p_id using errcode = '02000'; end if;
  return v_claim;
end $$;

grant execute on function public.claim_submit(jsonb)             to anon, authenticated;
grant execute on function public.claim_create(text, jsonb)       to anon, authenticated;
grant execute on function public.claim_edit(text, bigint, jsonb) to anon, authenticated;

-- Rattrapage des claims déjà saisis avec une date future.
update public.claims set claim_date = current_date where claim_date > current_date;

-- Contrôle : doit rendre 0.
select count(*) as claims_dans_le_futur from public.claims where claim_date > current_date;
