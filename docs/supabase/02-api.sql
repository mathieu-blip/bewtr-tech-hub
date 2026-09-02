-- ============================================================
-- API publique du hub. Chaque fonction exige la phrase de passe.
-- 'order' ouvre aussi tout ce que 'claims' ouvre.
-- ============================================================

-- La phrase exacte est essayée d'abord — « order » ne coûte rien. Sinon on
-- retente normalisé comme l'écran de garde du hub normalise (trim, espaces
-- réduits, majuscules), pour que la phrase du hub ouvre les tickets quelle que
-- soit la casse saisie.
create or replace function public.hub_scope(p_pass text)
returns text
language plpgsql stable security definer set search_path = hub, public, extensions as $$
declare v text;
begin
  select s.scope into v from hub.secrets s
   where s.pass_hash = extensions.crypt(p_pass, s.pass_hash)
   order by case s.scope when 'order' then 0 else 1 end
   limit 1;
  if v is not null then return v; end if;

  select s.scope into v from hub.secrets s
   where s.pass_hash = extensions.crypt(
           upper(regexp_replace(btrim(p_pass), '\s+', ' ', 'g')), s.pass_hash)
   order by case s.scope when 'order' then 0 else 1 end
   limit 1;
  return v;
end $$;

-- Renvoie le niveau ouvert par la phrase, ou null. Sert à l'écran de garde.
create or replace function public.hub_auth(p_pass text)
returns text language sql stable security definer set search_path = public as $$
  select public.hub_scope(p_pass);
$$;

create or replace function public.hub_require(p_pass text, p_min text)
returns text language plpgsql stable security definer set search_path = public as $$
declare v text := public.hub_scope(p_pass);
begin
  if v is null then raise exception 'unauthorized' using errcode = '28000'; end if;
  if p_min = 'order' and v <> 'order' then
    raise exception 'order passphrase required' using errcode = '28000';
  end if;
  return v;
end $$;

-- ------------------------------------------------------------ catalogue
-- Niveau « claims » : réf interne et désignation seulement.
-- Les réfs fournisseur et les prix ne sortent qu'avec la phrase « order ».
create or replace function public.parts_catalog(p_pass text)
returns table (ref text, name text, machines text[], supplier text,
               supplier_ref text, supplier_desc text, price numeric,
               currency text, discount numeric)
language plpgsql stable security definer set search_path = public as $$
declare v text := public.hub_require(p_pass, 'claims');
begin
  return query
    select p.ref, p.name, p.machines,
           case when v = 'order' then p.supplier end,
           case when v = 'order' then p.supplier_ref end,
           case when v = 'order' then p.supplier_desc end,
           case when v = 'order' then p.price end,
           case when v = 'order' then p.currency end,
           case when v = 'order' then p.discount end
      from public.parts p
     where p.active
     order by p.ref;
end $$;

-- ------------------------------------------------------------ claims
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
                      'name', pt.name, 'qty', cp.qty, 'ordered', cp.order_id is not null)
                    order by cp.id)
               from public.claim_parts cp
               left join public.parts pt on pt.ref = cp.part_ref
              where cp.claim_id = c.id), '[]'::jsonb)
      from public.claims c
     order by c.claim_date desc, c.id desc;
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
          coalesce(nullif(p->>'claim_date','')::date, current_date),
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
    restock_location = coalesce(nullif(btrim(coalesce(p->>'restock_location','')), ''), c.restock_location)
  where c.id = p_id
  returning * into v_claim;
  if not found then raise exception 'claim % not found', p_id using errcode='02000'; end if;
  return v_claim;
end $$;

create or replace function public.claim_add_part(p_pass text, p_claim_id bigint,
                                                 p_ref text, p_qty integer default 1,
                                                 p_free_text text default null)
returns bigint language plpgsql security definer set search_path = public as $$
declare v_id bigint;
begin
  perform public.hub_require(p_pass, 'claims');
  insert into public.claim_parts (claim_id, part_ref, free_text, qty)
  values (p_claim_id, nullif(btrim(coalesce(p_ref,'')), ''),
          nullif(btrim(coalesce(p_free_text,'')), ''), greatest(1, coalesce(p_qty,1)))
  returning id into v_id;
  return v_id;
end $$;

create or replace function public.claim_remove_part(p_pass text, p_id bigint)
returns void language plpgsql security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'claims');
  -- une pièce déjà commandée reste tracée : on ne la supprime pas
  delete from public.claim_parts where id = p_id and order_id is null;
end $$;

-- ------------------------------------------------------------ commandes (phrase « order »)
-- Ce qui reste à commander, prêt à être groupé par fournisseur.
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
     where cp.order_id is null
     order by coalesce(pt.supplier, 'zzz'), cp.part_ref, c.code;
end $$;

-- Enregistre le bon de commande et bascule les claims concernés.
create or replace function public.order_create(p_pass text, p_supplier text,
                                               p_line_ids bigint[], p_by text default null,
                                               p_note text default null)
returns public.orders
language plpgsql security definer set search_path = public as $$
declare v_order public.orders; v_total numeric := 0; v_currency text;
begin
  perform public.hub_require(p_pass, 'order');
  if p_line_ids is null or array_length(p_line_ids, 1) is null then
    raise exception 'no line selected' using errcode = '22023';
  end if;

  select max(pt.currency) into v_currency
    from public.claim_parts cp left join public.parts pt on pt.ref = cp.part_ref
   where cp.id = any(p_line_ids);

  insert into public.orders (supplier, currency, created_by, note)
  values (p_supplier, v_currency, nullif(btrim(coalesce(p_by,'')), ''),
          nullif(btrim(coalesce(p_note,'')), ''))
  returning * into v_order;

  insert into public.order_lines (order_id, part_ref, supplier_ref, designation,
                                  qty, unit_price, line_total, claim_id)
  select v_order.id, cp.part_ref, pt.supplier_ref,
         coalesce(pt.name, cp.free_text), cp.qty,
         round(pt.price * (1 - coalesce(pt.discount, 0)), 2),
         round(pt.price * (1 - coalesce(pt.discount, 0)) * cp.qty, 2),
         cp.claim_id
    from public.claim_parts cp
    left join public.parts pt on pt.ref = cp.part_ref
   where cp.id = any(p_line_ids) and cp.order_id is null;

  update public.claim_parts set order_id = v_order.id
   where id = any(p_line_ids) and order_id is null;

  select coalesce(sum(line_total), 0) into v_total
    from public.order_lines where order_id = v_order.id;
  update public.orders set total = v_total where id = v_order.id returning * into v_order;

  -- les claims dont toutes les pièces sont parties passent en « commandé »
  update public.claims c set status = 'Spare part ordered'
   where c.id in (select distinct claim_id from public.order_lines where order_id = v_order.id)
     and c.status in ('New (to repair)', 'Spare part to order')
     and not exists (select 1 from public.claim_parts cp
                      where cp.claim_id = c.id and cp.order_id is null);

  return v_order;
end $$;

create or replace function public.orders_list(p_pass text)
returns table (id bigint, code text, supplier text, status text, currency text,
               total numeric, created_by text, note text, created_at timestamptz,
               lines jsonb)
language plpgsql stable security definer set search_path = public as $$
begin
  perform public.hub_require(p_pass, 'order');
  return query
    select o.id, o.code, o.supplier, o.status, o.currency, o.total, o.created_by,
           o.note, o.created_at,
           coalesce((select jsonb_agg(jsonb_build_object(
                       'part_ref', l.part_ref, 'supplier_ref', l.supplier_ref,
                       'designation', l.designation, 'qty', l.qty,
                       'unit_price', l.unit_price, 'line_total', l.line_total,
                       'claim_id', l.claim_id) order by l.id)
                      from public.order_lines l where l.order_id = o.id), '[]'::jsonb)
      from public.orders o
     order by o.created_at desc;
end $$;

-- ------------------------------------------------------------ droits
-- Les fonctions sont SECURITY DEFINER : elles franchissent RLS, mais
-- refusent tout sans la bonne phrase de passe.
grant execute on function public.hub_auth(text)            to anon, authenticated;
grant execute on function public.parts_catalog(text)       to anon, authenticated;
grant execute on function public.claims_list(text)         to anon, authenticated;
grant execute on function public.claim_create(text, jsonb) to anon, authenticated;
grant execute on function public.claim_update(text, bigint, jsonb) to anon, authenticated;
grant execute on function public.claim_add_part(text, bigint, text, integer, text) to anon, authenticated;
grant execute on function public.claim_remove_part(text, bigint) to anon, authenticated;
grant execute on function public.order_pending(text)       to anon, authenticated;
grant execute on function public.order_create(text, text, bigint[], text, text) to anon, authenticated;
grant execute on function public.orders_list(text)         to anon, authenticated;

-- Postgres accorde EXECUTE à PUBLIC par défaut : révoquer sur anon et
-- authenticated ne suffit pas, le droit resterait et ces deux fonctions
-- internes seraient appelables via /rest/v1/rpc.
revoke execute on function public.hub_scope(text)        from public, anon, authenticated;
revoke execute on function public.hub_require(text, text) from public, anon, authenticated;
