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
-- laissé tel quel.
-- ---------------------------------------------------------------------------

with src(monday_id, piece) as (values
  ('4266608135', 'Pompe'),
  ('5398526793', 'Ventilateur'),
  ('5670073134', 'Ventilateur'),
  ('5670906253', 'Ventilateur'),
  ('4625905523', 'Compresseur'),
  ('5930383392', 'Carrosserie / habillage'),
  ('2861331198', 'Pompe'),
  ('2861541737', 'Pompe'),
  ('2861884415', 'Carte électronique HMI'),
  ('3101968156', 'Pompe'),
  ('3174743901', 'Pompe'),
  ('3441365811', 'Gearbox / robinet'),
  ('3854229301', 'Gearbox / robinet'),
  ('3942638651', 'Gearbox / robinet'),
  ('4159504578', 'Pompe'),
  ('4334120914', 'Carrosserie / habillage'),
  ('4916319588', 'Carte électronique HMI'),
  ('4802153503', 'Compresseur'),
  ('4770197726', 'Câble / connecteur'),
  ('4334109822', 'Sonde / thermostat'),
  ('6060706715', 'Gearbox / robinet'),
  ('6453959861', 'Gearbox / robinet'),
  ('7945057025', 'Pompe')
)
insert into public.claim_parts (claim_id, free_text, qty, ordered_manual)
select c.id, src.piece, 1, true
  from src
  join public.claims c on c.monday_id = src.monday_id
 where not exists (select 1 from public.claim_parts cp where cp.claim_id = c.id);

-- Contrôle : les deux passages réunis, par famille.
select free_text, count(*) as n
  from public.claim_parts
 where part_ref is null and free_text is not null
 group by free_text order by n desc, free_text;

-- Et la couverture : combien d'archives portent enfin une pièce.
select count(*) filter (where p.claim_id is not null) as avec_piece,
       count(*)                                       as archives
  from public.claims c
  left join lateral (select 1 as claim_id from public.claim_parts x
                      where x.claim_id = c.id limit 1) p on true
 where c.status in ('Repaired and restocked', 'Spare Parts (Bin)');
