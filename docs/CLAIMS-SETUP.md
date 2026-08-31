# Onglet « Claims » — plateforme pièces détachées

Remplace le board Monday **Technical troubleshooting** : déclaration d'un
retour machine, suivi du statut, liste des pièces à commander, bulletin de
commande fournisseur en Excel.

L'onglet n'apparaît pas dans le menu. Il s'ouvre en ajoutant `#claims` à
l'URL du hub, puis il faut la phrase de passe. Une fois ouvert, le lien
« Claims » se montre dans le menu pour le reste de la session.

---

## Les deux niveaux d'accès

| Phrase | Ce qu'elle ouvre |
|---|---|
| `spare part` | Les claims, le formulaire, et la liste des pièces à commander **avec la référence interne BW uniquement**. |
| `order` | Tout ce qui précède **plus** le bulletin de commande : références fournisseur, prix d'achat, remises, export Excel, historique des commandes. |

`order` ouvre aussi le niveau `claims` — inutile de saisir les deux.

### Changer une phrase de passe

Dans Supabase, **SQL Editor** :

```sql
update hub.secrets
   set pass_hash = extensions.crypt('nouvelle phrase', extensions.gen_salt('bf', 10))
 where scope = 'order';       -- ou 'claims'
```

Rien à modifier dans `index.html` : les phrases ne sont stockées que côté
base, sous forme de hash bcrypt.

---

## Ce qui protège réellement les données

Le hub est un site statique public. La clé `sb_publishable_…` inscrite dans
`index.html` est lisible par quiconque ouvre le code source de la page.
**C'est normal et sans danger ici**, parce que :

- les cinq tables ont RLS activé **et aucune policy** — la clé seule ne lit
  et n'écrit rien, en direct ;
- tout passe par des fonctions `SECURITY DEFINER` qui commencent par
  vérifier la phrase de passe ;
- le schéma `hub` (qui contient les hash) n'est pas exposé par l'API ;
- au niveau `claims`, les colonnes fournisseur et prix sont remplacées par
  `null` **côté serveur** — elles ne partent jamais sur le réseau.

Vérification faite en base, avec le rôle `anon` (celui du navigateur) :

| Test | Résultat |
|---|---|
| `select * from parts` en direct | 0 ligne |
| `select * from claims` en direct | 0 ligne |
| `parts_catalog('spare part')` | 294 lignes, **0 prix, 0 réf fournisseur** |
| `parts_catalog('order')` | 294 lignes, 283 réfs fournisseur |
| `order_pending('spare part')` | refusé — `order passphrase required` |
| `claims_list('mauvaise phrase')` | refusé — `unauthorized` |

> **Le point à garder en tête.** Une phrase courte comme `order` résiste mal
> à quelqu'un qui aurait la clé et voudrait la deviner par force brute. Tant
> que l'URL du hub reste interne, c'est proportionné. Si la plateforme
> s'ouvre plus largement, passez à des phrases longues (voir ci-dessus) —
> le changement prend une requête SQL et ne touche pas au code.

---

## Recréer la base depuis zéro

Si le projet Supabase est perdu, dans **SQL Editor**, dans l'ordre :

1. `docs/supabase/01-schema.sql` — tables, séquences, RLS, phrases de passe
2. `docs/supabase/02-api.sql` — les fonctions et les droits
3. `docs/supabase/03-seed-parts.sql` — les 294 pièces du catalogue

Puis, dans `index.html`, mettre à jour les deux constantes en tête du bloc
Claims :

```js
const CLAIMS_URL = "https://<projet>.supabase.co";
const CLAIMS_KEY = "sb_publishable_…";      // Settings ▸ API ▸ publishable key
```

Le projet actuel est `hgjitagsffudcvqwakwk` (région eu-west-1).

> **Attention au plan gratuit** : un projet Supabase inutilisé pendant une
> semaine passe en pause et le hub renvoie « Connexion impossible ». Il se
> relance depuis le tableau de bord Supabase en un clic.

---

## Le catalogue de pièces

294 SKU BW, repris de l'objet `SPAREPARTS` du hub et enrichis :

| Source | Références couvertes |
|---|---|
| Base `September 2022 - BE WTR spare parts list.xlsm` | 208 |
| BOM Italbedis récupérées sur SharePoint (voir plus bas) | 80 |
| **Sans référence fournisseur** | **6 + 5 Superinox** |

Les BOM Italbedis viennent de
`Technical/05 Aftersales/Techs/02 Spare parts/XX Spare parts list Italbedis` :

| Fichier | Modèle | Machine |
|---|---|---|
| `A90537.xlsx` | REFR. EUROS ICE 80 SOTTO BEWTR | BOX 80 I |
| `A90538.xlsx` | REFR. EUROS ICE 120 SOTTO BEWTR | BOX 120 I |
| `A90607.xlsx` | REFR. SLIM PLUS SOTTO BEWTR | BOX 20 |

Le rapprochement s'est fait par désignation (les libellés BW-10xx du hub
sont la traduction directe des libellés italiens). Les prix Italbedis sont
en **EUR catalogue**, avec la **remise business de 60 %** portée dans la
colonne `discount` : le bulletin de commande affiche et totalise le prix
net, pas le prix catalogue.

### Les 11 références encore à confirmer

Elles apparaissent quand même dans le bulletin, marquées « réf. à
confirmer » — rien n'est masqué silencieusement.

| SKU | Désignation | Machine | Fournisseur |
|---|---|---|---|
| `BW-0158` | Flow regulator | BOX 80 I, BOX 120 I | — |
| `BW-0990` | Solenoid valve (per schema) | BOX 20 | — |
| `BW-1072` | Capillary tube | BOX 80 I | — |
| `BW-0973` | Gearbox - Handle (x10) | AQTiV | — |
| `BW-0974` | Gearbox - Hat without handle (x5) | AQTiV | — |
| `BW-0975` | Gearbox - Lever (x10) | AQTiV | — |
| `BW-0342` | AQTiV ONE - Drip tray grid | AQTiV ONE | Superinox |
| `BW-0343` | Fixation set AQTiV ONE | AQTiV ONE | Superinox |
| `BW-0344` | Fixation set AQTiV COMBI | AQTiV COMBI | Superinox |
| `BW-0346` | Gearbox nozzle | AQTiV | Superinox |
| `BW-0347` | Gearbox aerator | AQTiV | Superinox |

Pour compléter une référence :

```sql
update public.parts
   set supplier = 'Superinox', supplier_ref = 'R0…', price = 12.50, currency = 'CHF'
 where ref = 'BW-0342';
```

Le fichier `docs/supabase/catalogue-pieces.csv` donne l'état complet du
catalogue, lisible dans Excel.

---

## La reprise depuis Monday

### Mise à jour du 2026-08-28 — script 09

Le board « Technical troubleshooting » (2470912823) compte **321 items**.
`docs/supabase/09-reprise-monday.sql` les reprend tous :

| Groupe Monday | Items | Devient |
|---|---|---|
| New claims + In progress HQ | 57 | claims ouverts |
| Done (Repaired and returned to stock) | 264 | **archivés** |

Le script est **rejouable**. `monday_id` est unique et le conflit ne fait
*rien* : le hub est la source de vérité, un claim corrigé dans le hub ne doit
pas être réécrit par une reprise. Seuls les tickets absents entrent, ce qui
permet de relancer la reprise à volonté.

Les statuts Monday sont normalisés à l'entrée :

| Monday | Hub |
|---|---|
| `✅ Repaired and restocked` | `Repaired and restocked` *(archivé)* |
| `❌ Spare Parts (Bin)` | `Spare Parts (Bin)` *(archivé)* |
| `➡️ In progress (repair in progress)` | `In progress (repair)` |
| `Stucked` | `Stuck` |
| `At supplier` | `Needs to go back to supplier` |

**Huit valeurs mises à `null`.** Le champ « nb d'unités impactées » a servi de
champ libre : on y trouve des numéros de série (`754085`, `2603111957`, …).
Au-delà de 999 ce n'est plus un compte de machines — et `2603111957`
dépasserait la capacité d'un `integer`. Même traitement quand la valeur est
identique au numéro de série de la ligne (`00459`).

Une date de claim `0024-03-14` a été lue `2024-03-14` : l'année avait perdu
ses deux premiers chiffres à la saisie. Les dates d'installation
manifestement conventionnelles (`1999-01-01`, `2000-01-01`) sont laissées
telles quelles — ce sont des données, pas des fautes de frappe.

Les pièces ne sont **pas** reprises : aucune des descriptions importées ici
n'a le format `BW-0416 5PC …` que le premier import savait lire.



Les **54 claims non clôturés** du board ont été importés (les 264 du groupe
« Done » sont restés dans Monday comme archive). La correspondance des
colonnes :

| Monday | Base |
|---|---|
| Name | `title` |
| Description | `description` |
| Technician Name / Mail / Company name | `technician_name` / `technician_email` / `company` |
| Country | `country` |
| Product | `product` |
| Serial numbers | `serial_number` |
| Installation Date / Claim date | `install_date` / `claim_date` |
| Under warranty *(formule)* | `under_warranty` — colonne calculée, même règle des 730 jours |
| Status | `status` |
| Decision | `decision` |
| repair status (by the repairer) | `repair_notes` |
| restocking location | `restock_location` |
| *(id de l'item)* | `monday_id` — évite tout doublon si l'import est rejoué |

`under_warranty` n'est plus une formule à recopier : c'est une colonne
générée par Postgres, toujours juste, y compris sur les tickets créés
depuis le hub.

### Sept valeurs mises à `null` volontairement

Sept claims avaient un **numéro de série saisi dans le champ « Nb of units
impacted »** (jusqu'à `2 603 111 957`, une valeur qui ne tient même pas dans
un entier). Elles ont été importées à `null` plutôt que de propager la
saisie fausse — le champ est à ressaisir dans le hub :

`Pas d'eau pétillante` · `Défaut Box 30` · `Pro 2` · `À contrôler` ·
`Box Hs` · `Fuite` · `Fuite box`

Le claim **`order spare parts france`** portait sa liste de pièces dans la
description, avec des réfs BW explicites : ses 14 lignes ont été chargées
comme vraies lignes de commande. Le claim **`spare parts suisse`** décrit
ses pièces en texte libre, sans réf — à saisir à la main depuis le panneau
de détail.

---

## Le parcours au quotidien

1. **Nouveau ticket** — le technicien décrit la panne, choisit la machine et
   ajoute les pièces nécessaires (recherche par réf BW ou par désignation ;
   le bloc pièces suit le produit, dont il dépend). La garantie
   s'affiche en direct dès que les deux dates sont saisies. Un ticket créé
   avec des pièces part directement en « Spare part to order ».
2. **Claims** — le tableau, groupé par statut comme les groupes Monday.
   Clic sur une ligne : panneau de détail, changement de statut, note de
   réparation, lieu de restockage, ajout/retrait de pièces. Le bouton
   **Modifier**, à côté du numéro `CLM-`, rouvre la fiche telle que le
   technicien l'a remplie — machine, série, dates, pays, contact — pour un
   ticket saisi de travers. Demande `docs/supabase/08-editer-un-ticket.sql`.
   Le bloc **pièces** est placé sous la description, sur la fiche comme en
   modification et comme sur un nouveau ticket : propositions collées à la description, vue éclatée, recherche et
   liste choisie. Tout suit ce qu'on corrige — changer la machine change ce
   qui est proposé. Ajouter ou retirer une pièce enregistre d'abord la fiche,
   sinon le rechargement du claim écraserait la correction en cours.
3. **Pièces à commander** — toutes les pièces en attente, agrégées par
   référence interne, avec les claims concernés. Pas de prix à ce niveau.
   Une pièce quitte cette liste dès que le bon de commande est enregistré.
4. **Bulletin de commande** (`order`) — un bloc par fournisseur. On décoche
   ce qu'on ne commande pas, on exporte **un classeur Excel par
   fournisseur**, puis « Enregistrer la commande ».
5. L'enregistrement crée un numéro `CMD-00001`, fige les prix pratiqués dans
   `order_lines`, et **bascule automatiquement en « Spare part ordered »**
   les claims dont toutes les pièces sont parties. C'est l'automatisation
   qui manquait dans Monday.

Les commandes passées restent consultables dans « Commandes passées », avec
le détail des lignes et les prix du jour de la commande.

---

## L'export Excel

Le classeur est écrit par le hub lui-même — pas de bibliothèque externe, pas
de CDN, le fichier `index.html` reste autonome. Un `.xlsx` est un zip de
fichiers XML : le code les assemble en mémoire (méthode « stored », sans
compression, qu'Excel accepte).

Nom du fichier : `BEWTR_commande_<Fournisseur>_<AAAA-MM-JJ>.xlsx`.
Colonnes : réf. fournisseur, réf. interne, désignation, quantité, prix
unitaire net, total ligne, claim d'origine — plus le total de la commande.

Les quantités et les prix sont écrits comme de **vrais nombres**, pas du
texte : les totaux se recalculent dans Excel sans retouche.

---

## État de la base

### Le contrôle de santé

Une requête à coller dans l'éditeur SQL après chaque reprise, ou quand un
chiffre du hub semble faux :

```sql
select
  (select count(*) from public.claims)                                   as claims,
  (select count(*) from public.claims
     where status in ('Repaired and restocked','Spare Parts (Bin)'))     as archives,
  (select count(*) from public.claims
     where status not in ('Repaired and restocked','Spare Parts (Bin)')) as ouverts,
  (select count(*) from public.claims where monday_id is not null)       as repris_de_monday,
  (select count(*) from public.claims where claim_date > current_date)   as dates_futures,
  (select count(*) from public.claims where units_impacted > 999)        as unites_aberrantes,
  (select count(*) from public.parts)                                    as pieces,
  (select count(*) from public.claim_parts
     where order_id is null and not ordered_manual)                      as pieces_a_commander,
  (select count(*) from public.orders)                                   as commandes;
```

`dates_futures` et `unites_aberrantes` doivent valoir **0**. Une date future
signale que le script 10 n'a pas tourné, ou qu'il a tourné avant le 09.


Tous les scripts sont appliqués sur le projet `hgjitagsffudcvqwakwk`. Vérifié
avec le rôle `anon`, celui du navigateur :

| Contrôle | Résultat |
|---|---|
| `select * from parts` / `claims` en direct | **0 ligne** — RLS tient |
| `parts_public()` sans phrase | 294 pièces, ni fournisseur ni prix |
| `parts_catalog('spare part')` | 294 pièces, fournisseur visible, **0 prix** |
| `parts_catalog('order')` | 182 pièces tarifées *(149 avant Blupura 2024)* |
| `hub_scope()` / `hub_require()` | refusées — fonctions internes |
| Dépôt anonyme d'un claim | crée le claim et sa pièce, rejette une réf inventée |
| `claim_edit()` | corrige, efface un champ vidé, garde titre et date de claim (NOT NULL), refuse une mauvaise phrase |

**À exécuter, dans cet ordre :**

1. `docs/supabase/09-reprise-monday.sql` — la reprise Monday du 2026-08-28.
2. `docs/supabase/10-date-claim-pas-dans-le-futur.sql` — la borne sur la date
   de claim. Après 09, dont un ticket est daté `2027-01-17` : le rattrapage
   de fin de script le ramènera au jour même.
3. `docs/supabase/11-pieces-des-archives.sql` — les pièces posées sur les
   tickets archivés, sans quoi le rapport annonce 264 tickets fermés et zéro
   pièce utilisée. Après 09, dont il complète les claims.
4. `docs/supabase/12-pieces-deduites.sql` — 23 pièces de plus, déduites du
   texte des tickets. Voir ci-dessous.

### Les pièces déduites du texte — script 12

Monday ne nomme la pièce que sur 97 des 264 tickets archivés. Pour le reste,
seul le texte dit ce qui a été remplacé. Le script 12 écrit **les 23 cas où
c'est sûr**, et rien d'autre.

Un ticket n'entre que si son texte décrit un remplacement **fait** :

| Texte | Entre ? | Pourquoi |
|---|---|---|
| « fan ko, changed » | oui | le geste est décrit |
| « Remplacement de la carte électronique » | oui | idem |
| « The radiator cooling fan doesn't work » | non | symptôme, pas geste |
| « J'ai rajouté du spray sur la sonde » | non | réglage, aucune pièce |
| « I reset main board and now is ok » | non | reset, aucune pièce |
| « La pompe était bloquée, débloquée » | non | réparée, pas remplacée |

Les machines démontées pour pièces, mises au rebut ou passées en avoir sont
exclues d'office : elles ont **fourni** des pièces, elles n'en ont pas reçu.

**Justesse mesurée : 65 sur 66, soit 98 %.** Le contrôle est possible parce
que 97 tickets portent la réponse : on applique le même filtre à ceux-là et
on compare. La seule erreur confond un kit d'installation avec un robinet.

Deux règles métier viennent de Mathieu, pas du texte :

- « panneau de contrôle » désigne **la carte électronique**, pas une pièce à part ;
- un **panneau tactile qui lâche** est une **carte électronique HMI**.

Elles ont fait passer la justesse moyenne de 83 % à 93 %.

Les pièces entrent en « commandée » — elles ont été *posées*, pas demandées —
et portent le suffixe `(déduit)` pour se distinguer d'un relevé à l'écran.
Pour tout annuler :

```sql
delete from public.claim_parts where free_text like '%(déduit)';
```

Le détail ticket par ticket est dans `docs/estimation.csv`.

### Second passage — script 13

Le script 12 exigeait un verbe : « fan ko, **changed** ». Il laissait donc de
côté les ventilateurs annoncés sans verbe — « The radiator cooling fan
doesn't work », décision `Spare parts used`. Une pièce a servi, une seule
famille est citée : c'est le ventilateur, il n'y a pas d'autre lecture.

Le script 13 retient ces cas-là : **une seule famille citée dans tout le
ticket**, et rien qui dise qu'aucune pièce n'a été posée. Ce qui fait sortir
un ticket, relevé sur les tickets eux-mêmes :

- la décision dit `Set up modification` — c'est un réglage ;
- le texte décrit le réglage : spray sur la sonde, ruban isolant, thermostat
  remis sur 4, reset de la carte ;
- le texte décrit une remise en état sans pièce : pompe débloquée,
  ventilateur mal branché puis rebranché, nettoyage, « the fun is ok » ;
- la pièce a été changée ailleurs (« pump already changed ») ;
- c'est un bon d'achat (« Acheter 2 drip tray BAR2 en spare pour la France ») ;
- la machine est démontée, au rebut ou passée en avoir.

**Justesse mesurée : 42 sur 44, soit 95 %.** Le ventilateur, la famille la
plus attendue, y tombe juste **15 fois sur 15**.

23 tickets de plus, ce qui porte les archives avec pièce de 120 à 143.

### La date d'un claim ne peut pas être dans le futur

Le navigateur borne le champ — attribut `max`, plus un contrôle à l'envoi,
car les deux formulaires sont en `novalidate` et `max` n'y bloque rien tout
seul. Le champ est aussi **pré-rempli au jour même**, recalculé à chaque
ouverture de l'onglet plutôt qu'au chargement de la page, sans quoi un poste
resté ouvert la nuit daterait de la veille.

`clToday()` lit le fuseau de l'appareil. `toISOString()` rend de l'UTC : un
technicien à Singapour aurait vu la veille toute la matinée.

Côté serveur, `claim_submit()`, `claim_create()` et `claim_edit()` **ramènent**
au jour même au lieu de refuser. Une borne côté page ne tient pas contre un
appel direct, et `claim_submit()` est la fonction ouverte du lien `#ticket` :
un externe qui se trompe d'un jour ne doit pas perdre sa déclaration, il n'a
pas de seconde chance.

La date d'**installation**, elle, n'est pas bornée : une machine peut être
enregistrée avant sa pose.
| Case « Commandée » d'un ticket | la ligne sort du bulletin, décocher la ramène |

### Deux durcissements après analyse

L'analyseur de Supabase a relevé deux points que les scripts initiaux
laissaient passer :

- **`hub_scope` et `hub_require` restaient appelables.** Le `revoke` de
  `02-api.sql` visait `anon` et `authenticated`, mais Postgres accorde
  `EXECUTE` à `PUBLIC` par défaut : le droit tenait toujours. Corrigé — il
  faut révoquer sur `public` aussi.
- **`touch_updated_at` n'avait pas de `search_path` figé.** Une fonction qui
  laisse l'appelant choisir son `search_path` peut se voir substituer ses
  opérateurs.

Les avertissements restants (« SECURITY DEFINER exécutable par anon »,
« RLS enabled, no policy ») décrivent **l'architecture voulue** : c'est
précisément ainsi que le hub fonctionne sans compte utilisateur. Les tables
sont fermées, et chaque fonction vérifie la phrase avant de rendre quoi que
ce soit.

### Annuler une commande

Il n'y a pas de bouton : un bon enregistré est une pièce comptable, pas un
brouillon. Pour effacer un essai, passer par l'éditeur SQL de Supabase.

```sql
begin;
delete from public.orders where code = 'CMD-00001';
-- si le bon avait basculé des claims en « Spare part ordered »,
-- les remettre à la main :
update public.claims set status = 'Spare part to order' where id = 46;
-- rendre le numéro au compteur (uniquement si c'est le dernier bon)
select setval('public.order_code_seq', 1, false);
commit;
```

La suppression du bon suffit à libérer les lignes : `claim_parts.order_id`
est en `on delete set null`, les pièces repartent donc d'elles-mêmes dans
« Pièces à commander ». Le statut du claim, lui, ne se rembobine pas tout
seul — `order_create` l'a écrit, rien ne le relit.

---

## Deux liens pour déclarer un ticket

| À qui | Lien | Mot de passe |
|---|---|---|
| Techniciens BE WTR | **https://service.bewtr.com/#claims-new** | celui du hub, une fois par appareil |
| Externes — installateurs, clients, prestataires | **https://service.bewtr.com/#ticket** | **aucun** |

### Le lien technicien

Il ouvre le formulaire de déclaration **sans la phrase claims**. Le technicien
saisit le mot de passe du hub (une fois par appareil, comme pour le reste du
guide) et se retrouve directement sur le formulaire, hub complet autour.

### Le lien externe

`#ticket` ne demande **rien du tout** : ni le mot de passe du hub, ni la
phrase claims. En contrepartie la page se réduit au seul formulaire — menu
latéral, recherche globale, tutoriels et schémas disparaissent. Un externe
déclare sa panne, reçoit son numéro `CLM-`, et n'a accès à rien d'autre.

Le mot de passe du hub n'est pas mémorisé au passage : le reste du site
reste fermé sur son appareil. Un bouton **Accès équipe** rend la page
entière à qui connaît la phrase.

Les deux liens partagent la même mécanique côté serveur.

En mode déclaration, il ne voit que ça : pas d'onglets, pas de liste de
claims, pas de prix. Deux fonctions seulement lui sont ouvertes —
`parts_public()` (réf interne, désignation, machines) et `claim_submit()`
(dépose un claim, renvoie son numéro). Il ne peut lire aucun claim existant,
pas même le sien.

> **Ce script est indispensable.** Sans `05-formulaire-public.sql`, le lien
> retombe sur l'écran de passe. À exécuter avant de diffuser le lien.

Un bouton **Accès équipe** ouvre la plateforme complète pour qui a la phrase.
Une fois saisie, elle est mémorisée par appareil. La phrase du bulletin de
commande (`order`) n'est **jamais** mémorisée.

### Le garde-fou du formulaire ouvert

`claim_submit()` refuse au-delà de **200 déclarations par heure**, tous
techniciens confondus. Un usage normal n'approche pas ce plafond ; il n'est
là que pour qu'une clé publique trouvée ne serve pas à remplir la base. Les
quantités sont bornées à 999 et les pièces doivent exister au catalogue :
pas de texte libre par cette porte. C'est ce plafond qui rend le lien
`#ticket` diffusable hors de l'entreprise.

### Les désignations suivent la langue

Le catalogue est stocké en anglais — c'est la valeur des exports et des bons
de commande. À l'écran, les désignations passent par `PARTTR` et s'affichent
en français ou en allemand : propositions, recherche, pièces d'un ticket,
pièces à commander, bulletin, historique. La recherche accepte les deux, on
peut taper « ventilateur » comme « fan ». Une pièce absente du dictionnaire
garde son nom anglais plutôt qu'une traduction inventée.

Le **classeur Excel** reste en anglais : c'est le fournisseur qui le lit.

---

## L'onglet Rapport

Trois compteurs — tickets **ouverts**, tickets **fermés**, **pièces posées** —
puis trois lectures :

| Section | Ce qu'elle montre |
|---|---|
| Les tickets ouverts, par statut | une puce colorée par statut, dans l'ordre du tableau |
| Tickets fermés, par produit | fermés, dont réparés, dont démontés pour pièces — **cliquer une ligne déplie ses tickets** |
| Pièces utilisées sur les tickets fermés | réf interne, désignation, quantité, nombre de tickets |

Le périmètre est **le filtre pays global**, celui du haut de page : le rapport
n'a pas son propre sélecteur, sinon deux filtres se contrediraient à l'écran.

### Le détail d'un produit

Cliquer une ligne du tableau déplie ses tickets sous elle : réf, objet,
description, note de réparation, date du claim, date de réparation. Les plus
récemment réparés d'abord, à défaut le claim le plus récent.

Un seul produit reste ouvert à la fois — en ouvrir un referme le précédent,
sinon la page devient un mur. Les lignes dépliées ne se cliquent pas : elles
se lisent, et leur survol reste neutre pour ne pas promettre une action qui
n'existe pas.

### Les noms de machines sont dictés, pas devinés

On retire le SKU de tête, puis on applique la table `CL_PRODUCT_GROUPS` — et
rien d'autre. Ce n'est pas un regroupement par ressemblance mais la liste des
noms tels que l'équipe les emploie.

| Libellé Monday | Devient |
|---|---|
| `PRO2 White` | **PRO2 V1** |
| `PRO2 Black` · `PRO2 Silver` | **PRO2 V2** |
| `AQTiV COMBI` · `AQTiV COMBI H` | **AQTiV COMBI** |
| `BOX 20 Home` | **BOX 20** |
| `BOX 80` | **BOX 80 B** |
| `BOX 80 Italbedis` | **BOX 80 I** |
| `BOX 30` | **BOX 30 O** |
| `BOX 30E` | **BOX 30 E** |
| `BOX30 B` | **BOX 30 B** |
| `BOX 120 Italbedis` | **BOX 120 I** |
| `PRO1 Black` | **PRO1** |

`BAR2 double portion control` garde son nom entier : c'est celui de la
machine, pas un libellé à raccourcir.

La PRO2 blanche et la noire ne sont pas deux finitions d'une même machine :
ce sont **deux générations**, V1 et V2, et elles ne prennent pas les mêmes
pièces. Le « H » de l'AQTiV COMBI, lui, ne change rien à ce qu'on y monte.

Tout ce qui n'est pas dans la table s'affiche tel quel. Deviner par préfixe
fondrait la `BOX 30 E` dans la `BOX 30 O` et ferait mentir le rapport.

### Une cellule Monday peut porter deux machines

Le champ produit est une liste à choix multiple. On trouve
`AQTiV COMBI H, BW-0042 AQTiV COMBI` — deux libellés du même produit, qui
retombent sur une seule étiquette — et `PRO1 Black, BW-0072 BOX 30E`, un
ticket danois sur un robinet **et** son groupe froid. Le second s'affiche
`PRO1 Black + BOX 30E` : deux machines, on ne choisit pas à la place du
technicien.

### Les pièces reprises de Monday sont en texte libre

Elles se regroupent **sans tenir compte de la casse** : `fun`, `Fun` et `FUN`
font une ligne. `fun` et `ventilateur` en font deux — deviner qu'il s'agit de
la même pièce n'est pas à la machine de le faire.

---

## Le parcours en six onglets

L'ordre suit le flux de travail, de gauche à droite.

| Onglet | À quoi il sert |
|---|---|
| **Nouveau ticket** | Le technicien déclare. C'est la cible du lien ci-dessus. |
| **Claims à qualifier** | Les claims **sans pièce**. C'est la pile de tri. |
| **Claims avec pièces** | Dès qu'une pièce est attachée, le claim bascule ici. |
| **Renvoi fournisseur** | Le claim est parti chez le fournisseur : il sort des deux piles précédentes et n'encombre plus le tri. |
| **Pièces à commander** | Le besoin agrégé, réf. interne seulement. |
| **Bulletin de commande** | Par fournisseur, avec prix. Phrase `order`. |
| **Commandes passées** | L'historique, prix figés au jour de la commande. |

Le passage d'un onglet à l'autre est **automatique** : il n'y a rien à
cocher ni à déplacer. Un claim ouvert vit dans **exactement un** onglet —
parti chez le fournisseur, sinon avec pièces, sinon à qualifier. Le bouton
« Renvoyer au fournisseur » du panneau de détail l'y envoie.

Les compteurs suivent le périmètre pays : choisir « France » ne cadre pas
seulement les tableaux, il recalcule aussi les chiffres au-dessus.

### Une réparation commencée passe avant un ticket neuf

Dans **Claims à qualifier** et **Claims avec pièces**, le groupe « Réparation
en cours » s'affiche en tête, avant « Nouveau (à réparer) ». L'ordre du
tableau ne suit donc pas le cycle de vie mais l'urgence : ce qui est déjà
ouvert sur l'établi se termine avant qu'on en entame un autre.

La liste déroulante d'un ticket, elle, garde l'ordre du cycle — on y choisit
une étape, on n'y trie rien. C'est `CL_BOARD_ORDER` qui porte l'ordre
d'affichage, séparément de `CL_STATUS`.

### Trier vite

Ouvrir un claim de la pile « à qualifier » affiche des **pièces probables**
déduites de la description, et un bouton **Vue éclatée** quand la machine en
a une. Un clic attache la pièce, le statut passe à « pièce à commander », et
le claim quitte la pile. C'est le geste du tri.

### Le pays est un périmètre, pas un filtre

Le sélecteur de pays est en haut, au-dessus des onglets, et vaut pour
**tous** : choisir « France » cadre les claims, les pièces à commander, le
bulletin et l'historique d'un seul coup.

---

## Commander pour reconstituer le stock

Une machine réparée avec une pièce prise en stock laisse une pièce **à
racheter**. Ce n'est donc pas l'état du claim qui décide si une pièce reste
à commander, mais la case **« Commandée »** de la ligne.

Concrètement : un claim en « Réparé et remis en stock » garde ses pièces
dans l'onglet **Pièces à commander** tant qu'on ne les a pas cochées. Un
claim en renvoi fournisseur aussi.

Deux gestes cochent une ligne :

| Quoi | Effet |
|---|---|
| **Enregistrer le bon de commande** | Coche toutes les lignes retenues, d'un coup. C'est le geste normal : la liste des pièces à commander se vide d'elle-même. |
| **Panneau de détail d'un ticket**, une case par pièce | Ne touche que cette ligne. Sert à corriger, ou à sortir une pièce de la liste sans passer de bon (reprise sur stock, commande faite ailleurs). |

L'onglet **Pièces à commander** n'a volontairement pas de case : cocher là
revenait à marquer commandé sans trace de commande, alors que
l'enregistrement du bon fait le même travail en laissant un `CMD-`.

Une pièce partie sur un **bon de commande** enregistré est cochée
automatiquement et n'est pas décochable : c'est le bon qui fait foi.
Décocher laisserait croire qu'elle est à recommander.

Demande `docs/supabase/07-piece-commandee.sql`.

---

### Le produit d'un claim n'est pas une clé du catalogue

La reprise Monday donne « BW-0596 BOX 20 Home », « PRO2 White » ou
« BW-0067 BOX30 B » là où les pièces sont rangées sous `BOX 20`, `PRO2` et
`BOX 30`. Sur les **14 produits distincts** portés par les claims, **10 ne
tombent pas juste**. Une égalité stricte vidait donc la liste des pièces
candidates et le ticket n'avait aucune proposition — alors qu'un nouveau
ticket, dont le produit sort d'une liste déroulante, en avait toujours.

`clMachineKey()` retire le SKU de tête puis retient la machine la plus longue
qui commence la désignation, avec un second passage sans les espaces pour
rattraper `BOX30 B`. Même règle que `clSpareKey()` pour la vue éclatée.

---

## Les statuts

Ils sont **stockés en anglais** — c'est la valeur canonique, celle qu'on
retrouve en base, dans les exports et dans les requêtes SQL. L'écran, lui,
les affiche dans la langue du hub. Changer de langue ne change donc rien à
la donnée.

| Valeur en base | Français | Deutsch |
|---|---|---|
| `New (to repair)` | Nouveau (à réparer) | Neu (zu reparieren) |
| `Spare part to order` | Pièce à commander | Ersatzteil zu bestellen |
| `Spare part ordered` | Pièce commandée | Ersatzteil bestellt |
| `In progress (repair)` | Réparation en cours | Reparatur läuft |
| `Needs to go back to supplier` *(bouton seul)* | À renvoyer au fournisseur | Zurück an Lieferant |
| `Need to go back to Switzerland` | À renvoyer en Suisse | Zurück in die Schweiz |
| `Stuck` | Bloqué | Blockiert |
| `Repaired and restocked` | Réparé et remis en stock | Repariert und eingelagert |
| `Spare Parts (Bin)` | Démonté pour pièces | Für Ersatzteile ausgeschlachtet |

### Deux statuts hors de la liste déroulante

`Needs to go back to supplier` et son ancien nom `At supplier` ne sont plus
**proposés** à la saisie. Ils restent traduits, colorés et groupés comme les
autres, et un claim qui en porte un le garde : la liste déroulante d'un tel
claim inclut toujours son propre statut, sinon le premier enregistrement
l'écraserait en silence. On en sort par la liste, comme d'habitude.

Pour y **entrer**, il reste le bouton **« Envoyer au fournisseur »** du
panneau de détail. C'est lui qui alimente l'onglet **Renvoi fournisseur** —
le statut décrivait un état (la machine *est* chez le fournisseur) là où
l'équipe a besoin d'une action (elle *doit* y retourner).

`docs/supabase/06-statut-renvoi-fournisseur.sql` aligne les claims restés sur
l'ancien libellé. Il n'est pas urgent, et à ce jour aucun claim ne le porte.

### La décision a été retirée des tickets

La liste **Décision** doublonnait le statut sans rien décider : 49 claims sur
55 étaient à `TBD (to be defined)`. Elle a disparu du panneau de détail.

La colonne `decision` reste en base, avec les valeurs reprises de Monday —
rien n'est perdu, et `claim_update()` sait toujours l'écrire si le besoin
revient. Deux d'entre elles (`Back to the supplier`, `Box repaired by
supplier`) rangent encore un claim dans l'onglet Renvoi fournisseur.

---

## Évolution 2 — script à exécuter

`docs/supabase/04-evolutions.sql` **doit être exécuté une fois** dans
Supabase ▸ SQL Editor. Sans lui le hub fonctionne, mais en retrait :

| Fonction | Sans le script | Avec |
|---|---|---|
| Filtre fournisseur (claims, pièces à commander) | le menu se masque | actif |
| Prix saisi dans le bulletin | appliqué à la commande, **non enregistré** | enregistré au catalogue |
| Codes et prix Blupura 2024 | anciens codes 2022 | à jour |

Le script fait quatre choses :

1. **Le nom du fournisseur devient visible au niveau « claims »**, pour
   pouvoir filtrer dessus. La référence de commande et le prix, eux, restent
   réservés à la phrase « order » — c'est ce qui était protégé, et ça le
   reste. Un nom de fournisseur est écrit sur la machine.
2. **`part_set_price()`** : saisir ou corriger un prix depuis le bulletin,
   et le garder pour les commandes suivantes. Un prix tapé à la main est un
   prix **net** — la remise contractuelle ne s'y applique plus, la fonction
   met donc `discount` à 0.
3. **`supplier_ref_legacy`** : conserve l'ancien code fournisseur.
4. **Tarif Blupura REV00 du 08.11.2024.**

### Blupura a renuméroté son catalogue

C'est le point important. Le fichier
`XX Spare parts Blupura/File Trascodifica Blupura REV00 08112024.xlsx`
donne, pour chaque pièce, un **nouveau code de commande** : les références
de 2022 ne sont plus celles à écrire sur un bon.

| | |
|---|---:|
| Références Blupura au catalogue | 105 |
| Retrouvées dans le fichier de transcodification | **55** |
| dont sans aucun prix jusqu'ici | 33 |
| Restant sur l'ancien code, sans prix | 50 |

Exemples : le gazeur 1 L passe de `130009` à `760035` (79,30 €), le
ventilateur 120×120 de `120232` à `760032` (24,80 €), la pompe du BOX 15 de
`130053` à `760033` (152,85 €). Les prix sont **nets, en euros** — souvent
bien en dessous des montants CHF de 2022 qui figuraient jusqu'ici.

Les 50 non retrouvées sont surtout des pièces BAR2 : le fichier de
transcodification ne les couvre pas toutes. Elles gardent leur ancien code
et restent sans prix — à demander à Blupura.

---

## Limites connues

- **Pas de pièces jointes.** Le board Monday a une colonne « Files » ; le hub
  ne gère pas encore l'upload de photos. Supabase Storage le permettrait.
- **Pas de notification.** Aucun e-mail n'est envoyé à la création d'un
  ticket. Un trigger Postgres + Edge Function le ferait.
- **Pas de sous-éléments.** La colonne « Sous-éléments » du board n'a pas
  d'équivalent — elle était peu utilisée.
- **Les 6 statuts Monday** sont repris, mais « ❌ Spare Parts (Bin) » et
  « ✅ Repaired and restocked » ne servent qu'à clôturer : les claims clos
  restent dans la liste, il n'y a pas encore d'archivage automatique.
