-- ---------------------------------------------------------------------------
-- 12 — Les pièces déduites du texte des tickets archivés
--
-- La reprise 11 a posé les pièces que Monday nomme explicitement (97). Restait
-- le reste : des tickets dont seul le texte dit ce qui a été remplacé.
--
-- CE SCRIPT N'ÉCRIT QUE CE QUI EST SÛR. Un ticket n'entre que si :
--   · son texte décrit un remplacement FAIT — « fan ko, changed »,
--     « Remplacement de la carte électronique » — et pas un symptôme
--     (« the radiator cooling fan doesn't work »), un réglage (« j'ai rajouté
--     du spray sur la sonde »), un reset (« I reset main board and now is ok »)
--     ni une réparation sans pièce (« la pompe était bloquée, débloquée ») ;
--   · la famille déduite du geste et celle déduite du ticket concordent ;
--   · la machine n'est ni démontée pour pièces, ni mise au rebut, ni passée
--     en avoir — ces machines-là ont FOURNI des pièces, elles n'en ont pas reçu.
--
-- Justesse mesurée : sur les tickets où Monday nomme la pièce, ce même filtre
-- tombe juste 65 fois sur 66, soit 98 %. La seule erreur confond un kit
-- d'installation avec un robinet.
--
-- Deux règles métier viennent de Mathieu, pas du texte :
--   « panneau de contrôle » = carte électronique (un seul et même composant) ;
--   un panneau tactile qui lâche = carte électronique HMI.
--
-- Les pièces entrent en « commandée » : elles ont été POSÉES, pas demandées.
-- Le suffixe « (déduit) » les distingue à l'écran d'un relevé. Pour tout
-- annuler :  delete from public.claim_parts where free_text like '%(déduit)';
-- ---------------------------------------------------------------------------

with src(monday_id, piece) as (values
  ('4255438162', 'Ventilateur (déduit)'),
  ('4294494404', 'Pompe (déduit)'),
  ('6812073464', 'Câble / connecteur (déduit)'),
  ('6812130393', 'Câble / connecteur (déduit)'),
  ('7407205406', 'Ventilateur (déduit)'),
  ('7823759358', 'Pompe (déduit)'),
  ('12345718594', 'Carte électronique HMI (déduit)'),
  ('12346297618', 'Pompe (déduit)'),
  ('12526209007', 'Carte électronique (déduit)'),
  ('12345200032', 'Carte électronique (déduit)'),
  ('12771108992', 'Carte électronique (déduit)'),
  ('2861165766', 'Pompe (déduit)'),
  ('3477695378', 'Ventilateur (déduit)'),
  ('3924847644', 'Gearbox / robinet (déduit)'),
  ('4334124423', 'Pompe (déduit)'),
  ('4997151331', 'Pompe (déduit)'),
  ('4655904553', 'Carte électronique HMI (déduit)'),
  ('5710897685', 'Pompe (déduit)'),
  ('6818838623', 'Kit / divers (déduit)'),
  ('5607530948', 'Gearbox / robinet (déduit)'),
  ('6453949208', 'Gearbox / robinet (déduit)'),
  ('6453964750', 'Gearbox / robinet (déduit)'),
  ('6693416186', 'Gearbox / robinet (déduit)')
)
insert into public.claim_parts (claim_id, free_text, qty, ordered_manual)
select c.id, src.piece, 1, true
  from src
  join public.claims c on c.monday_id = src.monday_id
 where not exists (select 1 from public.claim_parts cp where cp.claim_id = c.id);

-- Contrôle : 23 lignes attendues, et la répartition.
select free_text, count(*) as n
  from public.claim_parts
 where free_text like '%(déduit)'
 group by free_text order by n desc, free_text;
