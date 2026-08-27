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
   les pièces de la machine choisie remontent en tête). La garantie
   s'affiche en direct dès que les deux dates sont saisies. Un ticket créé
   avec des pièces part directement en « Spare part to order ».
2. **Claims** — le tableau, groupé par statut comme les groupes Monday.
   Clic sur une ligne : panneau de détail, changement de statut, décision,
   note de réparation, lieu de restockage, ajout/retrait de pièces.
3. **Pièces à commander** — toutes les pièces en attente, agrégées par
   référence interne, avec les claims concernés. Pas de prix à ce niveau.
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
