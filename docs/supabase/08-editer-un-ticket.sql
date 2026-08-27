-- ---------------------------------------------------------------------------
-- 08 — Corriger un ticket mal rempli
--
-- claim_update() ne touche qu'aux champs de suivi (statut, décision, note de
-- réparation…). Un ticket saisi de travers — mauvaise machine, numéro de série
-- absent, pays oublié — n'était donc rattrapable qu'en SQL.
--
-- claim_edit() ouvre les champs de saisie. Contrairement à claim_update(),
-- une clé présente avec une valeur vide EFFACE le champ : c'est le propre
-- d'une correction. Une clé absente laisse le champ tel quel.
--
-- « title » et « claim_date » sont NOT NULL en base : une valeur vide y est
-- ignorée plutôt que de faire échouer l'enregistrement complet.
-- ---------------------------------------------------------------------------

create or replace function public.claim_edit(p_pass text, p_id bigint, p jsonb)
returns public.claims
language plpgsql security definer set search_path = public as $$
declare v_claim public.claims;
begin
  perform public.hub_require(p_pass, 'claims');
  if p is null or jsonb_typeof(p) <> 'object' then
    raise exception 'objet attendu' using errcode = '22023';
  end if;

  update public.claims c set
    -- NOT NULL : on garde l'ancien titre si le champ arrive vide
    title            = case when p ? 'title'
                       then coalesce(nullif(btrim(p->>'title'), ''), c.title)
                       else c.title end,
    description      = case when p ? 'description'
                       then nullif(btrim(coalesce(p->>'description','')), '')
                       else c.description end,
    technician_name  = case when p ? 'technician_name'
                       then nullif(btrim(coalesce(p->>'technician_name','')), '')
                       else c.technician_name end,
    technician_email = case when p ? 'technician_email'
                       then nullif(btrim(coalesce(p->>'technician_email','')), '')
                       else c.technician_email end,
    company          = case when p ? 'company'
                       then nullif(btrim(coalesce(p->>'company','')), '')
                       else c.company end,
    country          = case when p ? 'country'
                       then nullif(btrim(coalesce(p->>'country','')), '')
                       else c.country end,
    product          = case when p ? 'product'
                       then nullif(btrim(coalesce(p->>'product','')), '')
                       else c.product end,
    serial_number    = case when p ? 'serial_number'
                       then nullif(btrim(coalesce(p->>'serial_number','')), '')
                       else c.serial_number end,
    install_date     = case when p ? 'install_date'
                       then nullif(btrim(coalesce(p->>'install_date','')), '')::date
                       else c.install_date end,
    -- NOT NULL également
    claim_date       = case when p ? 'claim_date'
                       then coalesce(nullif(btrim(coalesce(p->>'claim_date','')), '')::date, c.claim_date)
                       else c.claim_date end,
    units_impacted   = case when p ? 'units_impacted'
                       then least(9999, greatest(1,
                              nullif(btrim(coalesce(p->>'units_impacted','')), '')::integer))
                       else c.units_impacted end
  where c.id = p_id
  returning * into v_claim;

  if not found then raise exception 'claim % introuvable', p_id using errcode = '02000'; end if;
  return v_claim;
end $$;

grant execute on function public.claim_edit(text, bigint, jsonb) to anon, authenticated;

-- ---------------------------------------------------------------------------
-- « À renvoyer au fournisseur » quitte la liste des statuts saisissables.
-- Rien à faire en base : les statuts ne sont pas contraints côté Postgres,
-- c'est le hub qui décide de ce qu'il propose. Le bouton « Envoyer au
-- fournisseur » du panneau de détail reste le seul chemin vers ce statut.
-- ---------------------------------------------------------------------------
