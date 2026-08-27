-- ============================================================
-- Évolution 3 — le formulaire de déclaration sans phrase de passe
--
-- Un technicien qui constate une panne doit pouvoir la déclarer sans rien
-- retenir. Deux fonctions seulement sont ouvertes, et elles ne donnent
-- accès à rien d'autre :
--
--   parts_public()  -> réf interne, désignation, machines. Pas de
--                      fournisseur, pas de référence de commande, pas de prix.
--   claim_submit()  -> crée un claim et renvoie son seul numéro.
--                      Ne lit aucun claim existant.
--
-- Tout le reste (liste des claims, bulletin, prix) continue d'exiger une
-- phrase de passe. À exécuter après 04-evolutions.sql.
-- ============================================================

-- ------------------------------------------- catalogue en lecture nue
create or replace function public.parts_public()
returns table (ref text, name text, machines text[])
language sql stable security definer set search_path = public as $$
  select p.ref, p.name, p.machines
    from public.parts p
   where p.active
   order by p.ref;
$$;

-- ------------------------------------------- dépôt d'une déclaration
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
          coalesce(nullif(p->>'claim_date','')::date, current_date),
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

grant execute on function public.parts_public()       to anon, authenticated;
grant execute on function public.claim_submit(jsonb)  to anon, authenticated;
