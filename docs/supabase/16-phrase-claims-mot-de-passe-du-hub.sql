-- ============================================================
-- La plateforme des tickets n'a plus de phrase à elle.
--
-- Avant : « spare part » ouvrait les tickets, en plus du mot de passe de
-- l'écran de garde du hub. Deux mots de passe pour la même population —
-- les techniciens BE WTR — donc un de trop.
--
-- Après : le mot de passe du hub (normalisé par l'écran de garde : trim,
-- espaces réduits, majuscules) ouvre les tickets. Le bulletin de commande
-- garde « order » : lui seul montre les références fournisseur et les prix.
--
-- À rejouer si le mot de passe du hub change dans index.html.
-- ============================================================

update hub.secrets
   set pass_hash = extensions.crypt('AQTIV DUO', extensions.gen_salt('bf', 10))
 where scope = 'claims';

-- vérification : 'claims', puis null, puis 'order'
select public.hub_auth('AQTIV DUO'),
       public.hub_auth('spare part'),
       public.hub_auth('order');
