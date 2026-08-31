-- ---------------------------------------------------------------------------
-- 13 — Second passage sur les pièces déduites
--
-- Le script 12 n'écrivait que les tickets dont le texte décrit un geste
-- (« fan ko, changed »). Il laissait de côté les ventilateurs annoncés sans
-- verbe : « The radiator cooling fan doesn't work », décision « Spare parts
-- used ». Une pièce a servi, une seule famille est citée — c'est le
-- ventilateur, et il n'y a pas d'autre lecture.
--
-- La règle de ce passage : UNE SEULE famille de pièce citée dans tout le
-- ticket, et rien qui dise qu'aucune pièce n'a été posée.
--
-- Ce qui fait sortir un ticket, relevé sur vos tickets et pas imaginé :
--   · la décision dit « Set up modification » — c'est un réglage ;
--   · le texte dit le réglage lui-même : spray sur la sonde, ruban isolant,
--     thermostat remis sur 4, reset de la carte ;
--   · le texte dit une remise en état sans pièce : pompe débloquée,
--     ventilateur mal branché puis rebranché, nettoyage, « the fun is ok » ;
--   · la pièce a été changée ailleurs (« pump already changed ») ;
--   · c'est un bon d'achat et pas une réparation (« Acheter 2 drip tray BAR2
--     en spare pour la France », « 5x recirculation pumps blupura 760633 ») ;
--   · la machine est démontée, au rebut ou passée en avoir.
--
-- Justesse mesurée sur les tickets où Monday nomme la pièce : 42 sur 44,
-- soit 95 %. Le ventilateur, la famille la plus attendue, y est juste
-- 15 fois sur 15.
--
-- À passer après le 12. Rejouable : un claim qui porte déjà une pièce est
-- laissé tel quel. Pour tout annuler, 12 et 13 ensemble :
--   delete from public.claim_parts where free_text like '%(déduit)';
-- ---------------------------------------------------------------------------

with src(monday_id, piece) as (values
  ('4266608135', 'Pompe (déduit)'),
  ('5398526793', 'Ventilateur (déduit)'),
  ('5670073134', 'Ventilateur (déduit)'),
  ('5670906253', 'Ventilateur (déduit)'),
  ('4625905523', 'Compresseur (déduit)'),
  ('5930383392', 'Carrosserie / habillage (déduit)'),
  ('2861331198', 'Pompe (déduit)'),
  ('2861541737', 'Pompe (déduit)'),
  ('2861884415', 'Carte électronique HMI (déduit)'),
  ('3101968156', 'Pompe (déduit)'),
  ('3174743901', 'Pompe (déduit)'),
  ('3441365811', 'Gearbox / robinet (déduit)'),
  ('3854229301', 'Gearbox / robinet (déduit)'),
  ('3942638651', 'Gearbox / robinet (déduit)'),
  ('4159504578', 'Pompe (déduit)'),
  ('4334120914', 'Carrosserie / habillage (déduit)'),
  ('4916319588', 'Carte électronique HMI (déduit)'),
  ('4802153503', 'Compresseur (déduit)'),
  ('4770197726', 'Câble / connecteur (déduit)'),
  ('4334109822', 'Sonde / thermostat (déduit)'),
  ('6060706715', 'Gearbox / robinet (déduit)'),
  ('6453959861', 'Gearbox / robinet (déduit)'),
  ('7945057025', 'Pompe (déduit)')
)
insert into public.claim_parts (claim_id, free_text, qty, ordered_manual)
select c.id, src.piece, 1, true
  from src
  join public.claims c on c.monday_id = src.monday_id
 where not exists (select 1 from public.claim_parts cp where cp.claim_id = c.id);

-- Contrôle : les deux passages réunis, par famille.
select free_text, count(*) as n
  from public.claim_parts
 where free_text like '%(déduit)'
 group by free_text order by n desc, free_text;

-- Et la couverture : combien d'archives portent enfin une pièce.
select count(*) filter (where p.claim_id is not null) as avec_piece,
       count(*)                                       as archives
  from public.claims c
  left join lateral (select 1 as claim_id from public.claim_parts x
                      where x.claim_id = c.id limit 1) p on true
 where c.status in ('Repaired and restocked', 'Spare Parts (Bin)');
