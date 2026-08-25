# Pièces détachées — rapprochement base septembre 2022 / hub technicien

Rapprochement référence par référence entre :

- `September_2022_BE_WTR_spare_parts_list.xlsm`, onglet **Database** (blocs de colonnes D→P et T→AF,
  dédoublonnés sur le SKU BW) — **211 références uniques** ;
- l'objet `SPAREPARTS` de `index.html`.

Détail ligne par ligne : [`audit-spare-parts-2022.csv`](./audit-spare-parts-2022.csv).

| | Avant | Après |
|---|---:|---:|
| Références de la base présentes dans le hub | 182 / 211 (86 %) | **211 / 211 (100 %)** |
| Collisions de SKU (un SKU, deux désignations) | 1 | **0** |
| Machines avec liste de pièces | 14 | **16** |
| Lignes du hub | 337 | 377 |
| Références uniques | 264 | 294 |

## Corrections appliquées

### SKU attribués aux 4 pièces qui n'en avaient pas

Ces pièces ne portaient qu'une référence fournisseur ; le hub étant indexé sur le SKU BW,
aucune n'y figurait.

| Ancienne réf. | Nouveau SKU | Désignation | Ajoutée à |
|---|---|---|---|
| `701157` | `BW-1068` | Carb level probe | BOX 30, BOX 30E |
| `720023` | `BW-1069` | Temp probe | BOX 30, BOX 30E |
| `604022` | `BW-1070` | U2 Tap Twin Port 285 mm - Mounting Gasket 35 mm | BAR1 |
| `810327` | `BW-1071` | Recirculation pump 230 V | BOX 80 |

### Collision de SKU levée

`BW-1031` désignait deux pièces différentes selon la machine. Répartition retenue :

| SKU | Désignation | Machine |
|---|---|---|
| `BW-1031` | Agitator / stirrer MIR B 4L | BOX 120 I *(inchangé)* |
| `BW-1032` | Agitator / stirrer MIR A | BOX 80 I *(inchangé)* |
| `BW-1072` | Capillary tube | BOX 80 I *(nouveau SKU)* |

`BW-1068` étant réattribué à la sonde de niveau, le **flow regulator** des BOX 80 I et BOX 120 I
passe de `BW-1068` à **`BW-0158`**.

### Pièces rattachées à leur machine

La base laissait 11 lignes sans machine renseignée (colonne SKU produit vide ou invalide) :

| SKU | Désignation | Rattachée à | Motif |
|---|---|---|---|
| `BW-0159` | PRO1 - PCB Control Board | PRO1 | « PRO1 » en spare part = tap PRO1 |
| `BW-0161` | PRO1 - Connection cable | PRO1 | idem |
| `BW-0280` | PRO1 touch panel 30E - B | PRO1 | idem |
| `BW-0291` | ELV 2 in 6 - out 8 | BAR2 Double, BAR2 Touchless | lignes voisines communes aux deux BAR2 |
| `BW-0294` | BAR2 - Touch free push buttons | BAR2 Touchless | désignation explicite |
| `BW-0396` | BAR2 - Touchfree button | BAR2 Touchless | bloc touchless de la base |
| `BW-0399` | BAR2 - Front glass (touchless) | BAR2 Touchless | idem |
| `BW-0401` | BAR2 - Rear carter (touchless) | BAR2 Touchless | idem |
| `BW-0402` | BAR2 - Solenoid bracket | BAR2 Touchless | idem |
| `BW-0403` | BAR2 - Inverter UV | BAR2 Touchless | idem |
| `BW-0408` | BAR2 - Transformer | BAR2 Touchless | idem |

`BW-0783` (PRO2 - Loom solenoids Rev2), seule pièce rattachée à la variante « PRO2.1 »
dans la base, rejoint la liste PRO2.

### Famille AQTiV publiée

Les robinets AQTiV ONE et AQTiV COMBI existaient déjà dans le sélecteur de machines mais
sans liste de pièces. Les 13 références AQTiV de la base sont désormais publiées :

- **AQTiV COMBI** (11 pièces, couvre aussi AQTiV COMBI H) : `BW-0344`, `BW-0345` *(gearbox)*,
  `BW-0346`, `BW-0347`, `BW-0348`, `BW-0349`, `BW-0012`, `BW-0635`, `BW-0973`, `BW-0974`, `BW-0975`
- **AQTiV ONE** (10 pièces) : `BW-0342`, `BW-0343`, `BW-0345` *(gearbox)*, `BW-0346`, `BW-0347`,
  `BW-0012`, `BW-0635`, `BW-0973`, `BW-0974`, `BW-0975`

L'onglet Exploded Views du classeur ne contient qu'une image « pas de visuel » pour ces trois
produits : `openSpare()` affiche donc le tableau seul quand aucune vue éclatée n'est disponible.

## Points laissés en l'état

### BW-0288 n'est pas une pièce du BOX 80 — vérification

La base se contredit sur ce point, et c'est la colonne PRODUCT qui a tort :

| | `BW-0287` | `BW-0288` |
|---|---|---|
| Désignation | Carbonator bowl 1L **- 80** | Carbonator bowl 1L |
| Colonne SKU (pilote la BOM) | `BW-0001` → BOX 80 | `BW-0006` → BOX 150 |
| Colonne PRODUCT (saisie à la main) | *(vide)* | `BOX 150/BOX 80/` |
| Réf. fournisseur | 130009 | 130008 |
| Prix catalogue | 132 CHF | 160 CHF |

La **BOM générée pour BW-0001 (BOX 80) liste `BW-0287`, pas `BW-0288`**. Références fournisseur
et prix différents confirment deux pièces distinctes. Le hub était déjà correct : `BW-0287` sous
BOX 80, `BW-0288` sous BOX 150. **Aucune modification.** C'est la colonne PRODUCT de la ligne
`BW-0288` qui est à corriger dans le classeur.

### Photos non reprises

Les 40 lignes ajoutées le sont sans photo. Le classeur contient bien 210 images ancrées dans
l'onglet Database, mais leur ancrage ne suit pas les lignes de données : sur 82 références déjà
illustrées dans le hub, 18 seulement correspondent à l'image ancrée sur leur ligne. Le mappage
n'est pas exploitable automatiquement — une photo erronée en face d'un numéro de pièce coûte plus
cher qu'une absence de photo.

### Écarts restants dans le classeur, sans effet sur le hub

- Les BOX 20, BOX 80 I et BOX 120 I (82 SKU, `BW-0987` → `BW-1072`) n'existent pas dans la base
  de septembre 2022 : elle ne peut plus servir de référence prix / fournisseur pour ces machines.
- L'onglet Database duplique 21 références dans un second bloc de colonnes (T→AF) : 232 lignes
  pour 211 pièces réelles.
- `BW-0416` → `BW-0420` affichent `#N/A` en référence fournisseur dans le Bill of material.
- Libellés machines divergents entre les deux sources : « BOX 30 (2021) » vs « BOX BAR1 2021 » /
  « BOX PRO1 2021 », « BAR2 Double » vs « BAR2 Double portion control », « PRO2 » vs
  « PRO2 white » / « PRO2 black » / « PRO2.1 ».
