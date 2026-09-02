-- ============================================================
-- La référence fournisseur descend au niveau « claims »
--
-- L'export Excel des tickets porte une colonne « Réf. fournisseur » : c'est
-- elle qu'on commande, et le fichier part chez le fournisseur. Elle sortait
-- vide, parce que parts_catalog ne la rendait qu'à la phrase « order ».
--
-- Ce qui change : le code de commande suit désormais le nom du fournisseur,
-- déjà visible dès « claims » depuis l'évolution 2. Ce qui ne change pas :
-- les prix, les remises, la désignation fournisseur et l'ancien code restent
-- réservés à « order ». Le secret commercial, c'est le tarif — pas le numéro
-- d'article, qui figure sur la pièce et sur son emballage.
--
-- Le type de retour ne bouge pas : un « create or replace » suffit, sans
-- drop, donc sans perte de droits.
-- ============================================================

create or replace function public.parts_catalog(p_pass text)
returns table (ref text, name text, machines text[], supplier text,
               supplier_ref text, supplier_desc text, price numeric,
               currency text, discount numeric, supplier_ref_legacy text)
language plpgsql stable security definer set search_path = public as $$
declare v text := public.hub_require(p_pass, 'claims');
begin
  return query
    select p.ref, p.name, p.machines,
           p.supplier,                                        -- visible dès « claims »
           p.supplier_ref,                                    -- idem, pour l'export
           case when v = 'order' then p.supplier_desc end,
           case when v = 'order' then p.price end,
           case when v = 'order' then p.currency end,
           case when v = 'order' then p.discount end,
           case when v = 'order' then p.supplier_ref_legacy end
      from public.parts p
     where p.active
     order by p.ref;
end $$;

-- Vérification : les deux niveaux ramènent le même nombre de références,
-- et le niveau claims continue de ne voir aucun prix.
-- select count(*) filter (where supplier_ref is not null) as refs,
--        count(*) filter (where price is not null)        as prix
--   from public.parts_catalog('<phrase du hub>');
