# Lignes d'eau & schémas électriques — correspondance SharePoint ↔ hub

Source SharePoint (site *Switzerland*, bibliothèque *Shared Documents*) :

- `Technical/05 Aftersales/Techs/03 Water line Schema`
- `Technical/05 Aftersales/Techs/04 Electrical schema`

Relevé du 26/08/2026. Chaque dossier produit contient le PDF (et, pour la
plupart, le `.pptx` source, qui n'est pas repris dans le hub). Les tailles
ci-dessous sont celles du PDF SharePoint ; elles correspondent octet pour
octet aux fichiers publiés dans le hub.

## Ligne d'eau — `03 Water line Schema`

| Dossier SharePoint | Fichier | Octets | Clé hub |
|---|---|---|---|
| `BW-0596 BOX20` | `impianto idraulico euros.pdf` | 130 430 | BOX 20 |
| `BW-0074 BOX 30` | `BW-0074 BOX 30 water line schema.pdf` | 205 153 | BOX 30 |
| `BW-0067 BOX 30B` | `BOX 30 45 Fizz Schema Flusso.pdf` | 304 248 | BOX 30B |
| `BW-0072E BOX 30E` | `BW-0072E BOX 30E water line schema.pdf` | 221 990 | BOX 30E |
| `BW-0552 BOX 45` | `BOX 30 45 Fizz Schema Flusso.pdf` | 304 248 | BOX 45 *(alias BOX 30B)* |
| `BW-0004 BOX 15` | `BW-0004 BOX 15 water line schema.pdf` | 271 295 | BOX 15 |
| `BW-0001 BOX 80` | `BW-0001 BOX 80 water line schema.pdf` | 218 586 | BOX 80 |
| `BW-0006 BOX 150` | `BW-0006 BOX 150 water line schema.pdf` | 196 032 | BOX 150 |
| `601516 BOX BAR1` | `601516 BOX BAR1 water line schema.pdf` | 91 087 | BAR1 |
| `BW-0069 BAR2 Touchless` | `BW-0069 BAR2 water line schema.pdf` | 130 887 | BAR2 Touchless |
| `BW-0136 BAR2 Double portion control` | *(raccourci `.lnk` vers BW-0069)* | — | BAR2 Double |
| `BW-0271 PRO2` | `BW-0271 PRO2 water line schema.pdf` | 145 948 | PRO2 |

12 produits sur 12. Aucune ligne d'eau n'existe côté SharePoint pour le
BOX 80 ITBD — la tuile correspondante reste donc absente du hub.

## Le BOX 45 partage les plans du BOX 30B

Blupura ne publie pas de plans propres au BOX 45 : un seul jeu couvre le
BOX 30 Fizz et le BOX 45, d'où les noms de fichiers `BOX 30 45 Fizz Schema
Flusso.pdf` et `BOX 30 45 Fizz Schema Elettrico.pdf`. Le plan de ligne d'eau
déposé dans `BW-0552 BOX 45` est d'ailleurs identique à celui du BOX 30B, au
même sha256 et aux mêmes 304 248 octets.

Dans `index.html`, le BOX 45 pointe donc sur les documents du BOX 30B plutôt
que d'en porter une seconde copie :

```js
SCHEMAS['BOX 45'] = { water: SCHEMAS['BOX 30B'].water, elec: SCHEMAS['BOX 30B'].elec };
var SCHEMA_ALIAS = { 'BOX 45': 'BOX 30B' };
```

La tuile reste libellée « BOX 45 » — c'est la machine que le technicien
cherche — mais la visionneuse affiche « BOX 30B » en titre, pour qu'il sache
quel plan il consulte. Deux conséquences :

- le BOX 45 gagne un schéma électrique, qu'il n'avait pas jusqu'ici ;
- la duplication des images disparaît (~190 Ko de base64 en moins).

Si un jeu de plans spécifique au BOX 45 arrive un jour sur SharePoint, il
suffit de réintégrer ses images dans `SCHEMAS` et de retirer son entrée de
`SCHEMA_ALIAS`.

## Clés techniques et libellés affichés

Les clés de `SCHEMAS`, `SPAREPARTS` et `EXPLODED` reprennent le nom des
fichiers source, où le suffixe est collé au numéro : `BOX 30B`, `BAR2 Double`,
`PRO2`, `BOX 80 ITBD`. Le sélecteur de machine, lui, affiche depuis toujours la
forme espacée — « BOX 30 B », « BOX 80 I », « BAR 2 Double » — et c'est elle
qui fait foi à l'écran.

`PRODUCT_LABEL` fait le pont : les clés ne bougent pas (elles servent aux
lookups et aux ancres de la recherche globale), seul l'affichage est normalisé.
Une clé absente de la table est déjà bien orthographiée.

| Clé | Affiché |
|---|---|
| `BOX 30B` | BOX 30 B |
| `BOX 30E` | BOX 30 E |
| `BOX 80 ITBD` | BOX 80 I |
| `BAR1` | BAR 1 |
| `BAR2 Touchless` | BAR 2 Touchless |
| `BAR2 Double` | BAR 2 Double |
| `PRO1` | PRO 1 |
| `PRO2` | PRO 2 |

La table couvre les tuiles (schémas, vues éclatées, fiches techniques), les
titres des visionneuses et le sous-libellé des résultats de recherche. Les
désignations de pièces dans `SPAREPARTS` (« PRO2 - Cup Stand », etc.) viennent
du catalogue fournisseur et sont laissées telles quelles.

## Schéma électrique — `04 Electrical schema`

| Dossier SharePoint | Fichier | Octets | Clé hub |
|---|---|---|---|
| `BW-0596 BOX20` | `Schema PLUS H2ONDA-SLIM.pdf` | 78 668 | BOX 20 |
| `BW-0074 BOX 30` | `BW-0074 BOX 30 electrical schema.pdf` | 156 930 | BOX 30 |
| `BW-0067 BOX 30B` | `BOX 30 45 Fizz Schema Elettrico.pdf` | 154 377 | BOX 30B |
| `BW-0072E BOX 30E` | `BW-0072E BOX 30E electrical schema.pdf` | 305 208 | BOX 30E |
| `BW-0004 BOX 15` | `BW-0004 BOX 15 electrical schema.pdf` | 115 079 | BOX 15 |
| `BW-0001 BOX 80` | `BW-0001 BOX 80 electrical schema.pdf` | 115 493 | BOX 80 |
| `BW-0352 BOX80 ITBD` | `Schema JET20 ICE40 ICE80 ICE120.pdf` | 54 402 | BOX 80 ITBD |
| `BW-0006 BOX 150` | `BW-0006 BOX 150 electrical schema.pdf` | 121 901 | BOX 150 |
| `601516 BOX BAR1` | `601516 BOX BAR1 electrical schema.pdf` | 69 833 | BAR1 |
| `BW-0069 BAR2 Touchless` | `BW-0069 BAR2 Touchless.pdf` | 167 932 | BAR2 Touchless |
| `BW-0136 BAR2 Double portion control` | `BW-0136 BAR2 Double portion control.pdf` | 120 053 | BAR2 Double |
| `BW-0271 PRO2` | `BW-0271 PRO2 electrical schema.pdf` | 84 069 | PRO2 |
| `BW-0552 BOX 45` | *(dossier vide — voir BOX 30B)* | 0 | BOX 45 *(alias BOX 30B)* |

13 produits sur 13, via l'alias décrit ci-dessous. Le dossier
`BW-0552 BOX 45` est vide côté SharePoint, mais le schéma du BOX 30B
(`BOX 30 45 Fizz Schema Elettrico.pdf`) couvre les deux machines : il est donc
servi pour le BOX 45 aussi.

## Publication dans le hub : aperçu seul

Les schémas ne sont plus servis au navigateur sous forme de PDF. Chaque page
est convertie en image WebP (216 dpi, qualité 85, 2 600 px max) et affichée
dans la visionneuse `#schemabox` :

- pas de barre PDF native, donc pas de bouton « télécharger » ni « imprimer » ;
- aucun lien de sortie dans la visionneuse (le bouton « ouvrir dans un nouvel
  onglet » a été retiré) ;
- clic droit et glisser-déposer neutralisés sur l'aperçu, appui long désactivé
  sur mobile (`-webkit-touch-callout`) ;
- zoom 100 → 400 %, avec un palier de départ calculé pour que le schéma reste
  lisible sur téléphone.

Une capture d'écran reste évidemment possible : il s'agit d'une consultation
maîtrisée, pas d'un verrouillage.

## Régénérer après une mise à jour SharePoint

Les images sont produites à partir des PDF, avec PyMuPDF + Pillow :

```python
pix = page.get_pixmap(matrix=pymupdf.Matrix(z, z), alpha=False)   # z = 3.0, plafonné à 2600 px
Image.frombytes("RGB", (pix.width, pix.height), pix.samples) \
     .save(buf, "WEBP", quality=85, method=6)
```

Le résultat alimente `const SCHEMAS = {...}` dans `index.html` sous la forme
`{ "<produit>": { "water": [<data URI par page>], "elec": [...] } }`.

## Note sur le BOX 20 (électrique)

Les 3 pages de `Schema PLUS H2ONDA-SLIM.pdf` sont dessinées de travers dans le
fichier fournisseur (pas d'attribut `/Rotate`), et s'affichent donc en biais —
comme dans n'importe quel lecteur PDF. Corriger l'orientation demanderait de
faire pivoter les images à la génération, ce qui s'écarterait du fichier source.
