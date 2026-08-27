-- ============================================================
-- Évolution 5 — marquer une pièce « commandée » sans passer par un bon
--
-- Une machine peut être réparée avec une pièce prise en stock : la pièce
-- reste à commander pour reconstituer ce stock, alors même que le claim est
-- clos. Le fait qu'une pièce soit commandée devient donc une propriété de
-- la ligne, indépendante de l'état du claim et de l'existence d'un bon.
-- ============================================================

alter table public.claim_parts
  add column if not exists ordered_manual boolean not null default false;

-- --------------------------------------------------- liste des claims
-- « ordered » vaut désormais : partie sur un bon, OU cochée à la main.
create or replace function public.claims_list(p_pass text)
returns table (id bigint, code text, title text, description text,
               technician_name text, technician_email text, company text,
               country text, product text, serial_number text,
               install_date date, claim_date date, units_impacted integer,
               status text, decision text, repair_notes text, repair_date date,
               restock_location text, under_warranty boolean,
               created_at timestamptz, parts jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  return query
    select c.id, c.code, c.title, c.description, c.technician_name,
           c.technician_email, c.company, c.country, c.product, c.serial_number,
           c.install_date, c.claim_date, c.units_impacted, c.status, c.decision,
           c.repair_notes, c.repair_date, c.restock_location, c.under_warranty,
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

-- --------------------------------------------------- reste à commander
-- Une pièce cochée à la main sort du bulletin, comme si elle était partie.
create or replace function public.order_pending(p_pass text)
returns table (line_id bigint, claim_id bigint, claim_code text, claim_status text,
               country text, part_ref text, name text, free_text text, qty integer,
               supplier text, supplier_ref text, supplier_desc text,
               price numeric, currency text, discount numeric)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'order');
  return query
    select cp.id, c.id, c.code, c.status, c.country,
           cp.part_ref, pt.name, cp.free_text, cp.qty,
           coalesce(pt.supplier, 'À déterminer'), pt.supplier_ref, pt.supplier_desc,
           pt.price, pt.currency, pt.discount
      from public.claim_parts cp
      join public.claims c on c.id = cp.claim_id
      left join public.parts pt on pt.ref = cp.part_ref
     where cp.order_id is null and not cp.ordered_manual
     order by coalesce(pt.supplier, 'zzz'), cp.part_ref, c.code;
end $$;

-- --------------------------------------------------- cocher / décocher
-- Prend plusieurs lignes d'un coup : cocher une pièce dans la vue agrégée
-- doit cocher tous les tickets qui la demandent.
create or replace function public.claim_parts_set_ordered(p_pass text,
                                                          p_ids bigint[],
                                                          p_ordered boolean)
returns integer
language plpgsql security definer set search_path = public as $$
declare v_count integer;
begin
  perform public.hub_require(p_pass, 'claims');
  if p_ids is null or array_length(p_ids, 1) is null then return 0; end if;

  -- une ligne déjà partie sur un bon n'est pas décochable ici : c'est le bon
  -- qui fait foi, et le décocher laisserait croire qu'elle est à recommander
  update public.claim_parts
     set ordered_manual = coalesce(p_ordered, false)
   where id = any(p_ids) and order_id is null;

  get diagnostics v_count = row_count;
  return v_count;
end $$;

grant execute on function public.claim_parts_set_ordered(text, bigint[], boolean)
  to anon, authenticated;
