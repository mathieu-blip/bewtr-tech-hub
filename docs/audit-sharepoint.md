# SharePoint dans le hub — ce qui a été remplacé, ce qui reste

Relevé du 03/09/2026 sur `index.html`, puis remplacement des doublons par les
équivalents du portail technicien.

|  | Documents | Liens | Fichiers |
|---|---|---|---|
| Avant | 31 | 93 | 91 |
| **Après** | **5** | **15** | **13** |

Le détail adresse par adresse — retirées comme conservées — est dans
`docs/liens-sharepoint.md` (à lire) et `docs/liens-sharepoint.csv` (à filtrer
sur la colonne `statut`).

## Pourquoi ce ménage

Les 91 fichiers partaient tous du OneDrive **personnel** de
`charles_epert@bewtradmin.onmicrosoft.com` :

```
https://bewtradmin-my.sharepoint.com/:b:/g/personal/charles_epert_bewtradmin_onmicrosoft_com/…?e=…
```

Un compte personnel, pas une bibliothèque d'équipe, et un jeton de partage `?e=`
par lien. Ce compte désactivé ou ses partages régénérés, tout tombait ensemble.
Le hub avait pourtant déjà son propre contenu pour 26 de ces 31 documents : il
affichait les deux.

## Les 26 documents retirés

### Bibliothèque — 21 cartes (`tutorials`)

`LIB_FICHE` apparie une carte à une fiche du portail ; quand la fiche a du
contenu, c'est le tuto pas à pas qui s'affiche. Le PDF ne redescend plus dans
« À voir aussi » : ces 21 entrées n'ont plus d'`url` du tout, et passent en
`type:"soon"` — la convention du fichier pour une carte sans document propre.
Si une reprise du portail vidait leur fiche, la carte repasserait en
« bientôt » au lieu de planter.

Installation : AQTiV Combi, AQTiV One, AQTiV Tower, BAR 1, BAR 2, PRO 3,
BOX 20 — Home, BOX 30, BOX 80 / 120 / 150, BOX avec recirculation, Kit Mullex,
Be Connect (schéma, pannes & infos), BOX 80 — Kit de ventilation.
Maintenance : Faire une maintenance (avec Be Connect).
Mesures & tests : Mesure de tension, Test fusible / continuité, Mesurer le taux
de CO₂ dans l'eau. Astuces : Agrandir un trou de scie cloche, Transformation
meuble coulissant avec charnières, Faire un joint téflon.
Configuration : Configuration doses BAR 2.

Sont partis avec : la fonction `installFichePdf`, l'appel qui poussait le PDF en
tête de « À voir aussi », et le libellé `itut.pdf` (« Guide PDF (SharePoint) »).

### Documentation → Mesures produits — 4 tuiles (`MEASURES`)

Le panneau montrait 17 tuiles de cotes redessinées dans la page
(`PRODUCT_DIMS`, images annotées de `img/`) **et**, en dessous, les quatre PDF
d'origine. Les tuiles restent, la constante `MEASURES`, son bloc « Les documents
d'origine, en PDF » et la clé i18n `schema.measures.pdf` sont supprimés.

- *Mesures BOX* → les 7 BOX cotés dans la page
- *Mesures TAP* → les 11 TAP cotés dans la page
- *Mesures bouteilles CO₂ (par pays)* → fiche portail, carte de bibliothèque
- *Visite technique B2C — BOX 20 + Mullex* → fiche portail, carte de bibliothèque

### « Expérience client & remise » — 1 lien (`s7.body` ×3)

Le « mémo d'origine, en PDF » était lié sous six cartes qui réécrivent le mémo
en entier. Le lien est retiré dans les trois langues.

## Les 5 documents conservés

SharePoint reste leur seule source — aucune fiche du portail ne couvre le sujet :

1. **Montage Air System** — Gearbox *(un seul fichier pour les trois langues)*
2. **Remplacement Gearbox** — Gearbox
3. **Remplacement joints** — Gearbox
4. **Changement piston (V2)** — Gearbox
5. **Configuration Be Connect** — la fiche portail existe mais n'a jamais été
   rédigée ; `ficheEmpty` la rejette, la carte garde donc son PDF

Le groupe « Gearbox (technique) » est le seul de la bibliothèque à ne vivre
qu'ailleurs. Le jour où ces cinq fiches sont écrites côté portail, elles
prennent la place des cartes toutes seules — il suffit d'ajouter leur titre à
`LIB_FICHE` — et le hub n'appelle plus rien à l'extérieur.

## Au passage

Le BOX 45 ne pointait déjà plus SharePoint : il réutilise les schémas du BOX 30B
via `SCHEMA_ALIAS`, déjà internalisés — voir `docs/schemas-sharepoint-sync.md`.
