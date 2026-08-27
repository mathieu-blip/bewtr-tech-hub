-- ============================================================
-- Évolution 2 — à exécuter une fois dans Supabase ▸ SQL Editor
--
-- 1. Le nom du fournisseur devient visible au niveau « claims »
--    (les références fournisseur et les prix restent protégés)
-- 2. Saisie et correction d'un prix depuis le bulletin de commande
-- 3. Colonne pour l'ancien code fournisseur
-- 4. Tarif Blupura REV00 du 08.11.2024
-- ============================================================

-- ------------------------------------------------------- 1. colonne
alter table public.parts add column if not exists supplier_ref_legacy text;

-- --------------------------------------- 2. catalogue : fournisseur visible
-- Filtrer les claims par fournisseur suppose de connaître le fournisseur.
-- Le nom seul (« Blupura ») n'est pas une information commerciale : il est
-- écrit sur la machine. La référence de commande et le prix, eux, restent
-- réservés à la phrase « order ».
-- parts_catalog gagne une colonne de sortie : Postgres refuse un simple
-- « create or replace » quand le type de retour change, il faut la supprimer
-- d'abord. Qui dit drop dit perte des droits : le grant est réémis plus bas,
-- sans quoi le hub ne pourrait plus lire le catalogue.
drop function if exists public.parts_catalog(text);

create function public.parts_catalog(p_pass text)
returns table (ref text, name text, machines text[], supplier text,
               supplier_ref text, supplier_desc text, price numeric,
               currency text, discount numeric, supplier_ref_legacy text)
language plpgsql stable security definer set search_path = public as $$
declare v text := public.hub_require(p_pass, 'claims');
begin
  return query
    select p.ref, p.name, p.machines,
           p.supplier,                                             -- visible dès « claims »
           case when v = 'order' then p.supplier_ref end,
           case when v = 'order' then p.supplier_desc end,
           case when v = 'order' then p.price end,
           case when v = 'order' then p.currency end,
           case when v = 'order' then p.discount end,
           case when v = 'order' then p.supplier_ref_legacy end
      from public.parts p
     where p.active
     order by p.ref;
end $$;

-- ------------------------------------------- 3. saisir / corriger un prix
-- Le bulletin de commande porte souvent le prix réellement pratiqué avant
-- que le catalogue ne soit à jour. On l'enregistre pour les fois suivantes.
create or replace function public.part_set_price(p_pass text, p_ref text,
                                                 p_price numeric,
                                                 p_currency text default null,
                                                 p_supplier_ref text default null)
returns public.parts
language plpgsql security definer set search_path = public as $$
declare v_part public.parts;
begin
  perform public.hub_require(p_pass, 'order');
  if p_price is not null and p_price < 0 then
    raise exception 'price must not be negative' using errcode = '22023';
  end if;

  update public.parts p set
    price        = coalesce(p_price, p.price),
    -- un prix saisi à la main est un prix net : la remise ne s'y applique plus
    discount     = case when p_price is not null then 0 else p.discount end,
    currency     = coalesce(nullif(btrim(coalesce(p_currency,'')), ''), p.currency),
    supplier_ref = coalesce(nullif(btrim(coalesce(p_supplier_ref,'')), ''), p.supplier_ref)
  where p.ref = p_ref
  returning * into v_part;

  if not found then raise exception 'part % not found', p_ref using errcode = '02000'; end if;
  return v_part;
end $$;

grant execute on function public.parts_catalog(text) to anon, authenticated;
grant execute on function public.part_set_price(text, text, numeric, text, text)
  to anon, authenticated;

-- ------------------------------------------------------------------
-- Tarif Blupura, révision REV00 du 08.11.2024
-- Source : Technical/05 Aftersales/Techs/02 Spare parts/
--          XX Spare parts Blupura/File Trascodifica Blupura REV00 08112024.xlsx
--
-- Blupura a renuméroté son catalogue : le code de commande n'est plus
-- celui de 2022. L'ancien est conservé en supplier_ref_legacy pour
-- pouvoir relire les anciens bons et les anciennes factures.
-- Prix nets unitaires en EUR (remise déjà déduite, donc discount = 0).
-- ------------------------------------------------------------------
update public.parts p set
  supplier_ref_legacy = coalesce(p.supplier_ref_legacy, v.old_ref),
  supplier_ref        = v.new_ref,
  price               = coalesce(v.price, p.price),
  currency            = case when v.price is not null then 'EUR' else p.currency end,
  discount            = case when v.price is not null then 0 else p.discount end
from (values
('BW-0183','760253','810320',11.55),
('BW-0184','760513','130049',75.6),
('BW-0185','760173','140194',17),
('BW-0186','760041','150031',13.4),
('BW-0187','760060','150385',54.1),
('BW-0188','760499','130005A',92.9),
('BW-0189','760481','750066',32.65),
('BW-0190','760230','150068',49.5),
('BW-0191','760032','120232',24.8),
('BW-0192','760033','130053',152.85),
('BW-0193','760074','140092',17),
('BW-0194','760051','150525',12.15),
('BW-0195','760049','750243',23.8),
('BW-0287','760035','130009',79.3),
('BW-0288','760037','130008',97.65),
('BW-0290','760560','150576',54.1),
('BW-0291','760136','150551',26.7),
('BW-0292','760205','150388',28.55),
('BW-0293','760053','150016',21.75),
('BW-0294','760241','810620',70),
('BW-0295','760622','750309',51.9),
('BW-0367','760620','810439',6.4),
('BW-0371','760621','150074',8.75),
('BW-0372','760083','140366',1.75),
('BW-0376','760534','810618',66),
('BW-0381','760086','150356',20.3),
('BW-0383','760206','140251',2.35),
('BW-0385','760173','140194',17),
('BW-0389','760498','150708',78.2),
('BW-0396','760044','150146',13),
('BW-0401','760683','111110',39.05),
('BW-0403','760061','150205',42),
('BW-0408','760065','150071',30.7),
('BW-0409','760504','150204',46.65),
('BW-0417','760062','130048A',86.5),
('BW-0419','760137','110138',30.1),
('BW-0420','760138','110137',102.7),
('BW-0421','760120','140118',5),
('BW-0423','760064','150087',7.3),
('BW-0424','760073','140099',28),
('BW-0425','760080','150094',1.65),
('BW-0426','760217','150072',4.1),
('BW-0428','760131','150052',3.7),
('BW-0432','760108','140296',33),
('BW-0435','760219','140561',25.75),
('BW-0436','760221','110954',14.85),
('BW-0439','760058','150157',4.1),
('BW-0440','760220','140562',25.75),
('BW-0442','760647','110053',20.6),
('BW-0445','760652','110052',35.1),
('BW-0446','760544','120014',55.5),
('BW-0449','760510','120001',174.6),
('BW-0451','760291','130006',75.6),
('BW-0457','760810','150082',6.7),
('BW-1071','760633','810327',69.2)
) as v(ref, new_ref, old_ref, price)
where p.ref = v.ref;
-- fin
