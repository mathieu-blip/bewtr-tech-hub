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
| `BW-0552 BOX 45` | `BOX 30 45 Fizz Schema Flusso.pdf` | 304 248 | BOX 45 |
| `BW-0004 BOX 15` | `BW-0004 BOX 15 water line schema.pdf` | 271 295 | BOX 15 |
| `BW-0001 BOX 80` | `BW-0001 BOX 80 water line schema.pdf` | 218 586 | BOX 80 |
| `BW-0006 BOX 150` | `BW-0006 BOX 150 water line schema.pdf` | 196 032 | BOX 150 |
| `601516 BOX BAR1` | `601516 BOX BAR1 water line schema.pdf` | 91 087 | BAR1 |
| `BW-0069 BAR2 Touchless` | `BW-0069 BAR2 water line schema.pdf` | 130 887 | BAR2 Touchless |
| `BW-0136 BAR2 Double portion control` | *(raccourci `.lnk` vers BW-0069)* | — | BAR2 Double |
| `BW-0271 PRO2` | `BW-0271 PRO2 water line schema.pdf` | 145 948 | PRO2 |

12 produits sur 12. Aucune ligne d'eau n'existe côté SharePoint pour le
BOX 80 ITBD — la tuile correspondante reste donc absente du hub.

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
| `BW-0552 BOX 45` | *(dossier vide)* | 0 | — |

12 produits sur 13. Le dossier `BW-0552 BOX 45` est vide côté SharePoint :
tant qu'un schéma n'y est pas déposé, le BOX 45 n'apparaît pas dans la
catégorie « Schéma électrique ».

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
