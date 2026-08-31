-- ---------------------------------------------------------------------------
-- 15 — Renumérotation des deux premières pièces du BOX 20
--
-- Italbedis a renuméroté le réservoir inox et le ventilateur axial du BOX 20 :
--
--   BW-0987  Stainless-steel tank      ->  BW-1072
--   BW-0988  Axial fan 120x120x25      ->  BW-1073
--
-- BW-1072 n'était pas libre : il portait le « Capillary tube » du BOX 80 I, un
-- SKU créé par l'audit 2022 pour lever la collision BW-1031, sans référence
-- fournisseur ni prix. Décision : on l'écrase. Le capillary tube sort du
-- catalogue ; il devra recevoir un SKU neuf pour redevenir commandable.
--
-- Les tickets et les commandes déjà saisis sur les anciennes références sont
-- rattachés aux nouvelles : rien ne doit pointer sur une référence morte.
-- claim_parts.part_ref porte une FK vers parts(ref) sans ON UPDATE CASCADE,
-- d'où l'ordre insérer / rattacher / supprimer plutôt qu'un update du SKU.
--
-- Rejouable : sans effet une fois la renumérotation faite.
-- ---------------------------------------------------------------------------

begin;

-- 1. libérer BW-1072. Le garde-fou sur la désignation évite d'effacer le
--    réservoir inox si le script est rejoué.
delete from public.parts
 where ref = 'BW-1072' and name = 'Capillary tube';

-- 2. créer les nouvelles références à l'identique des anciennes
insert into public.parts (ref,name,machines,supplier,supplier_ref,supplier_desc,price,currency,discount,active)
select r.new_ref, p.name, p.machines, p.supplier, p.supplier_ref, p.supplier_desc,
       p.price, p.currency, p.discount, p.active
  from public.parts p
  join (values ('BW-0987','BW-1072'),
               ('BW-0988','BW-1073')) as r(old_ref,new_ref) on r.old_ref = p.ref
    on conflict (ref) do nothing;

-- 3. rattacher les lignes de tickets et de commandes
update public.claim_parts set part_ref = 'BW-1072' where part_ref = 'BW-0987';
update public.claim_parts set part_ref = 'BW-1073' where part_ref = 'BW-0988';
update public.order_lines set part_ref = 'BW-1072' where part_ref = 'BW-0987';
update public.order_lines set part_ref = 'BW-1073' where part_ref = 'BW-0988';

-- 4. retirer les anciennes références du catalogue
delete from public.parts where ref in ('BW-0987','BW-0988');

commit;

-- Contrôle : les deux nouvelles références existent, les anciennes et le
-- capillary tube ont disparu, et plus aucune ligne ne pointe sur BW-0987/0988.
--
--   select ref, name, machines from public.parts
--    where ref in ('BW-0987','BW-0988','BW-1072','BW-1073') order by ref;
--
--   select 'claim_parts' as t, count(*) from public.claim_parts
--    where part_ref in ('BW-0987','BW-0988')
--   union all
--   select 'order_lines', count(*) from public.order_lines
--    where part_ref in ('BW-0987','BW-0988');
