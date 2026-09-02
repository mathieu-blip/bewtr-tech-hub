-- ============================================================
-- La plateforme des tickets n'a plus de phrase à elle.
--
-- Avant : « spare part » ouvrait les tickets, en plus du mot de passe de
-- l'écran de garde du hub. Deux mots de passe pour la même population —
-- les techniciens BE WTR — donc un de trop.
--
-- Après : le mot de passe du hub ouvre les tickets. Le bulletin de commande
-- garde « order » : lui seul montre les références fournisseur et les prix.
--
-- À rejouer si le mot de passe du hub change dans index.html.
-- ============================================================

-- La phrase du niveau claims devient le mot de passe du hub, normalisé comme
-- l'écran de garde le normalise : trim, espaces réduits, majuscules.
--
-- Le mot de passe n'est pas écrit ici : ce dépôt est public. Remplacer le
-- marqueur par la forme normalisée du mot de passe (majuscules, espaces
-- réduits) au moment de jouer la requête, et ne pas recoller le résultat.
update hub.secrets
   set pass_hash = extensions.crypt('REMPLACER-phrase-du-hub', extensions.gen_salt('bf', 10))
 where scope = 'claims';

-- Et la base normalise à son tour ce qu'on lui présente, pour que la phrase du
-- hub soit acceptée quelle que soit la casse — y compris depuis l'écran de
-- garde de secours du bloc Claims, qui envoie la saisie telle quelle. La
-- phrase exacte est testée d'abord : la phrase commande, qui n'est pas
-- normalisée, ne coûte pas un bcrypt de plus.
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

-- hub_scope reste interne : le navigateur ne l'appelle jamais en direct.
revoke execute on function public.hub_scope(text) from public, anon, authenticated;

-- Vérification, avec les vraies phrases saisies à la main dans l'éditeur —
-- jamais recollées ici. Attendu, dans l'ordre : claims, claims, order, null.
--
--   select public.hub_auth('<phrase du hub, telle qu'on la tape>'),
--          public.hub_auth('<la même, casse et espaces au hasard>'),
--          public.hub_auth('<phrase commande>'),
--          public.hub_auth('mauvaise phrase');
select public.hub_auth('mauvaise phrase');   -- doit rendre null
