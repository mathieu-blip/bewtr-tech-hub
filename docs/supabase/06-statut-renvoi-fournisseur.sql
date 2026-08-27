-- ============================================================
-- Évolution 4 — « At supplier » devient « Needs to go back to supplier »
--
-- Le statut décrivait un état (la machine est chez le fournisseur) là où
-- l'équipe a besoin d'une action (elle doit y retourner). C'est ce statut
-- qui alimente l'onglet « Renvoi fournisseur ».
--
-- Le hub sait lire les deux : tant que ce script n'est pas passé, les
-- claims restés en « At supplier » s'affichent et se rangent au bon
-- endroit. Le script aligne simplement la base sur le libellé retenu.
-- ============================================================

update public.claims
   set status = 'Needs to go back to supplier'
 where status = 'At supplier';

-- Contrôle : doit renvoyer 0 sur la première colonne.
select count(*) filter (where status = 'At supplier')                  as restes_ancien_libelle,
       count(*) filter (where status = 'Needs to go back to supplier')  as en_renvoi_fournisseur
  from public.claims;
