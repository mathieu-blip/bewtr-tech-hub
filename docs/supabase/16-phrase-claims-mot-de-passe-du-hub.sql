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
update hub.secrets
   set pass_hash = extensions.crypt('AQTIV DUO', extensions.gen_salt('bf', 10))
 where scope = 'claims';

-- Et la base normalise à son tour ce qu'on lui présente, pour que « aqtiv duo »
-- soit accepté quelle que soit la casse — y compris depuis l'écran de garde de
-- secours du bloc Claims, qui envoie la saisie telle quelle. La phrase exacte
-- est testée d'abord : « order » ne coûte pas un bcrypt de plus.
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

-- vérification : claims, claims, order, puis null, null
select public.hub_auth('aqtiv duo'),
       public.hub_auth('AQTiV  DUO'),
       public.hub_auth('order'),
       public.hub_auth('spare part'),
       public.hub_auth('mauvaise phrase');
