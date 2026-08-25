# Audit pièces détachées — base septembre 2022 vs hub technicien

Rapprochement référence par référence entre :

- `September_2022_BE_WTR_spare_parts_list.xlsm`, onglet **Database** (blocs de colonnes D→P et T→AF, dédoublonnés sur le SKU BW) — **211 références uniques** ;
- l'objet `SPAREPARTS` de `index.html` — **264 références uniques**, 337 lignes, 14 listes machine.

Détail ligne par ligne : [`audit-spare-parts-2022.csv`](./audit-spare-parts-2022.csv).

## Chiffres clés

| | |
|---|---|
| Références de la base | 211 |
| Reprises dans le hub | 182 (86 %) |
| **Absentes de toute liste du hub** | **29** |
| **Sans SKU interne BW** | **4** |
| Références du hub absentes de la base | 82 (BOX 20 / BOX 80 I / BOX 120 I) |
| Lignes du hub avec photo | 85 / 337 (25 %) |

## 1. Pièces sans SKU interne BW (4)

Ces lignes portent une référence fournisseur en guise de SKU. Le hub étant indexé sur le SKU BW,
aucune n'a été reprise.

| Réf. | Désignation | Machines (base) | Fournisseur |
|---|---|---|---|
| `701157` | Carb level probe | BOX 30, BOX 30E | Borg&Overström |
| `720023` | Temp probe | BOX 30, BOX 30E | Borg&Overström |
| `604022` | U2 Tap Twin Port 285 mm — Mounting Gasket 35 mm | BAR1 | Borg&Overström |
| `810327` | Recirculation pump 230 V | BOX 80 | Blupura |

## 2. Pièces de la base absentes du hub (29)

### a. Famille AQTiV — produit entier non publié (13)

`BW-0012` AiR System · `BW-0342` AQTiV ONE - Drip tray grid · `BW-0343` Fixation set AQTiV ONE ·
`BW-0344` Fixation set AQTiV COMBI · `BW-0345` Gearbox · `BW-0346` Gearbox nozzle ·
`BW-0347` Gearbox aerator · `BW-0348` NBR O-ring · `BW-0349` Honeycomb plastic aerator with O-ring ·
`BW-0635` AQTiV flow compensator · `BW-0973` Gearbox - Handle (x10) ·
`BW-0974` Gearbox - Hat without handle (x5) · `BW-0975` Gearbox - Lever (x10)

AQTiV COMBI (BW-0042), COMBI H (BW-0045) et ONE (BW-0050) figurent dans la base et dans l'onglet
Exploded Views, mais aucune des trois n'existe dans le hub.

### b. Lignes de la base sans machine rattachée (11)

| SKU | Désignation | Machine probable | Cause |
|---|---|---|---|
| `BW-0159` | PRO1 - PCB Control Board | BOX PRO1 2021 | SKU produit = « PRO1 » |
| `BW-0161` | PRO1 - Connection cable | BOX PRO1 2021 | SKU produit = « PRO1 » |
| `BW-0280` | PRO1 touch panel 30E - B | BOX PRO1 2021 / 30E | SKU produit = « PRO1 » |
| `BW-0291` | ELV 2 in 6 - out 8 | BAR2 | SKU produit vide |
| `BW-0294` | BAR2 - Touch free push buttons | BAR2 touchless | SKU produit vide |
| `BW-0396` | BAR2 - Touchfree button | BAR2 touchless | SKU produit vide |
| `BW-0399` | BAR2 - Front glass (touchless) | BAR2 touchless | SKU produit vide |
| `BW-0401` | BAR2 - Rear carter (touchless) | BAR2 touchless | SKU produit vide |
| `BW-0402` | BAR2 - Solenoid bracket | BAR2 touchless | SKU produit vide |
| `BW-0403` | BAR2 - Inverter UV | BAR2 touchless | SKU produit vide |
| `BW-0408` | BAR2 - Transformer | BAR2 touchless | SKU produit vide |

### c. Autres (5)

`BW-0783` PRO2 - Loom solenoids Rev2 (seule pièce rattachée à « PRO2.1 »), plus les 4 pièces
sans SKU BW de la section 1.

## 3. Incohérences

| # | Constat | Gravité |
|---|---|---|
| 01 | `BW-1031` désigne deux pièces différentes dans le hub : « Capillary tube » (BOX 80 I) et « Agitator / stirrer MIR B 4L » (BOX 120 I). Un des deux SKU est faux. | Bloquant |
| 02 | 4 pièces sans SKU interne BW, donc invisibles dans le hub (section 1). | Bloquant |
| 03 | `BW-0288` « Carbonator bowl 1L » est rattachée à BOX 150 **et** BOX 80 dans la base, mais n'apparaît que sous BOX 150 dans le hub. | À corriger |
| 04 | `BW-0287` « Carbonator bowl 1L - 80 » (132 CHF, fourn. 130009) et `BW-0288` « Carbonator bowl 1L » (160 CHF, fourn. 130008) ne se distinguent que par un suffixe ; la ligne BW-0287 n'a pas de PRODUCT résolu alors que sa colonne SKU vaut `BW-0001/`. Risque d'erreur de commande. | À corriger |
| 05 | Trois lignes portent « PRO1 » en colonne SKU produit, valeur inexistante dans l'onglet Products (`601527`, `BW-0329`, `BW-0330`). La recherche échoue et les pièces ne sont rattachées à rien. | À corriger |
| 06 | 8 lignes ont la colonne SKU produit vide (pièces BAR2 touchless + ELV) : aucune compatibilité machine renseignée. | À corriger |
| 07 | BOX 20, BOX 80 I et BOX 120 I (82 SKU, `BW-0987` → `BW-1068`) n'existent pas dans la base de septembre 2022 : c'est la base qui doit être mise à jour. | À suivre |
| 08 | Famille AQTiV absente du hub (3 produits, 13 pièces, vue éclatée déjà prévue). | À suivre |
| 09 | L'onglet Database duplique 21 références dans un second bloc de colonnes (T→AF) : 232 lignes pour 211 pièces réelles. | À suivre |
| 10 | `BW-0416` → `BW-0420` affichent `#N/A` en référence fournisseur dans le Bill of material. | À suivre |
| 11 | Libellés machines divergents : « BOX 30 (2021) » vs « BOX BAR1 2021 » / « BOX PRO1 2021 » ; « BAR2 Double » vs « BAR2 Double portion control » ; « PRO2 » vs « PRO2 white » / « PRO2 black » / « PRO2.1 ». | À suivre |
| 12 | Couverture photo à 25 % (85/337). Aucune photo sur BOX 30, BOX 30E, BOX 20, BOX 80 I, BOX 120 I. | À suivre |

## 4. Couverture machine par machine

| Liste du hub | Pièces | Produit(s) en base | Base | Manquantes |
|---|---:|---|---:|---|
| PRO1 | 16 | BOX PRO1 2021 (robinet) + Tap PRO1 black/steel | 40 | reste couvert par « BOX 30 (2021) » |
| BOX 30 (2021) | 30 | BOX BAR1 2021 + BOX PRO1 2021 | 35 | 0 |
| BOX 30E | 11 | BOX 30E | 13 | 2 — `701157`, `720023` |
| BOX 30 | 9 | BOX 30 | 11 | 2 — `701157`, `720023` |
| BAR1 | 4 | BAR1 | 5 | 1 — `604022` |
| PRO2 | 30 | PRO2 white + black (+ PRO2.1) | 31 | 1 — `BW-0783` |
| BOX 80 | 20 | BOX 80 | 21 | 2 — `810327`, `BW-0288` |
| BOX 150 | 32 | BOX 150 | 32 | 0 |
| BAR2 Double | 32 | BAR2 Double portion control | 32 | 0 |
| BAR2 Touchless | 28 | BAR2 touchless | 28 | 0 |
| BOX 15 | 16 | BOX 15 | 16 | 0 |
| BOX 20 | 38 | — (absent de la base) | — | — |
| BOX 80 I | 35 | — (absent de la base) | — | — |
| BOX 120 I | 36 | — (absent de la base) | — | — |
| — | — | AQTiV COMBI / COMBI H / ONE | 13 | 13 — famille non publiée |

**Note PRO1.** La base range sous « BOX PRO1 2021 » à la fois les pièces du robinet et les
24 raccords hydrauliques du caisson (`BW-0461` → `BW-0485`). Le hub les a séparés en deux listes,
« PRO1 » et « BOX 30 (2021) ». Réunies, elles couvrent 100 % du produit : aucune pièce perdue,
mais le technicien doit ouvrir deux listes pour un seul appareil.

## 5. Ce qui est conforme

- **Désignations : 0 écart** sur les 182 références communes aux deux sources.
- **Aucun doublon de SKU** à l'intérieur d'une même liste du hub.
- **4 machines couvertes à 100 %** : BOX 150, BAR2 Double, BAR2 Touchless, BOX 15.
- **Aucune référence inventée** : les 82 références du hub absentes de la base correspondent
  toutes aux trois machines postérieures à septembre 2022, sur une plage de SKU dédiée et continue.
