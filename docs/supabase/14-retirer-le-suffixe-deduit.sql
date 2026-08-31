-- ---------------------------------------------------------------------------
-- 14 — Retirer le suffixe « (déduit) »
--
-- Les scripts 12 et 13 écrivaient « Ventilateur (déduit) ». À l'écran c'est
-- lourd, et répété sur chaque ligne du rapport et de chaque ticket ça mange
-- la lecture pour un renseignement qu'on n'a besoin de voir qu'une fois.
--
-- Ce qui distingue une pièce déduite d'un relevé n'a pas besoin d'un suffixe :
-- c'est l'absence de référence catalogue. Une pièce nommée par Monday ou
-- choisie dans le hub porte un part_ref ; une pièce lue dans le texte n'en a
-- pas. La requête de contrôle ci-dessous s'appuie là-dessus.
--
-- Rejouable : sans effet si le suffixe a déjà été retiré.
-- ---------------------------------------------------------------------------

update public.claim_parts
   set free_text = btrim(replace(free_text, '(déduit)', ''))
 where free_text like '%(déduit)%';

-- Contrôle : plus aucun suffixe, et la répartition des pièces sans référence.
select count(*) as reste_du_suffixe
  from public.claim_parts where free_text like '%(déduit)%';

select free_text, count(*) as n
  from public.claim_parts
 where part_ref is null and free_text is not null
 group by free_text order by n desc, free_text;
