# Audit SharePoint — ce que le hub va encore chercher dehors

Relevé du 03/09/2026 sur `index.html`.

## Le compte

**93 liens SharePoint, 91 fichiers distincts, 31 documents** (chacun décliné
FR / EN / DE — un seul, *Montage Air System*, sert le même fichier aux trois
langues).

Tous pointent la **même adresse** :

```
https://bewtradmin-my.sharepoint.com/:b:/g/personal/charles_epert_bewtradmin_onmicrosoft_com/…?e=…
```

C'est le OneDrive **personnel** de `charles.epert@bewtradmin.onmicrosoft.com`,
pas une bibliothèque d'équipe. Chaque lien porte un jeton de partage `?e=`.
Le jour où ce compte est désactivé, déplacé, ou ses partages régénérés, les
91 liens tombent en même temps. C'est le point le plus fragile du hub : à part
ces liens, tout le reste (schémas, éclatés, fiches techniques, photos de cotes)
est déjà embarqué dans le dépôt.

## Où ils se trouvent

| Endroit | Ligne | Documents | Liens |
|---|---|---|---|
| `tutorials` — cartes de la bibliothèque | 1542-1584 | 26 | 78 (76 fichiers) |
| `MEASURES` — Documentation → Mesures produits | 2832 | 4 | 12 (12 fichiers) |
| `I18N` `s7.body` — « Expérience client & remise » | 1641 / 1769 / 1897 | 1 | 3 (3 fichiers) |

## Le doublon non-SharePoint : 26 documents sur 31 en ont déjà un

Le hub a deux mécanismes qui recouvrent un PDF SharePoint par du contenu local :

- **`LIB_FICHE`** (ligne 2235) apparie une carte de la bibliothèque à une fiche
  du portail. Si la fiche a du contenu, c'est le tuto pas à pas qui s'affiche et
  le PDF redescend dans « À voir aussi » sous le libellé « Guide PDF
  (SharePoint) » (`installFichePdf`, ligne 2286).
- **`PRODUCT_DIMS`** (ligne 2092) sort les blocs de cotes de la catégorie
  « mesures » du portail et en fait 18 tuiles produit, images annotées servies
  depuis `img/`. Les PDF d'origine restent listés dessous, explicitement, sous
  « Les documents d'origine, en PDF ».

### Bibliothèque (26 documents)

| Section | Document | Doublon non-SharePoint |
|---|---|---|
| Installation | AQTiV Combi | Oui — fiche « AQTiV COMBI » (2 chap., 2 listes matériel, vidéo) |
| Installation | AQTiV One | Oui — fiche « AQTiV ONE » (1 chap., 2 listes, vidéo) |
| Installation | BAR 1 | Oui — fiche « BAR 1 » (1 chap., 2 listes, vidéo) |
| Installation | BAR 2 | Oui — fiche « BAR 2 » (1 chap., 2 listes, vidéo) |
| Installation | PRO 3 | Oui — fiche « PRO 3 » (2 chap., 3 listes, vidéo) |
| Installation | AQTiV Tower | Oui — fiche « AQTiV TOWER » (1 chap., 3 listes, vidéo) |
| Installation | BOX 20 — Home | Oui — fiche « BOX 20 - HOME » (1 chap., 2 listes, 1 schéma, vidéo) |
| Installation | BOX 30 | Oui — fiche « BOX 30 » (1 chap., 2 listes, 1 schéma, vidéo) |
| Installation | BOX 80 / 120 / 150 | Oui — fiche « BOX 80/120/150 » (2 chap., 2 listes, 1 schéma, vidéo) |
| Installation | BOX avec recirculation | Oui — fiche « BOX avec recirculation » (3 chap., 2 listes) |
| Installation | Kit Mullex | Oui — fiche « KIT MULLEX » (3 chap., 1 liste, vidéo) |
| Installation | Be Connect (schéma, pannes & infos) | Oui — fiche « BE CONNECT » (2 schémas, 3 blocs) |
| Installation | BOX 80 — Kit de ventilation | Oui — fiche « BOX 80 - kit de ventilation » (1 chap., 2 listes, vidéo) |
| Maintenance | Faire une maintenance (avec Be Connect) | Oui — fiche « Faire une maintenance (avec BE CONNECT) » (2 chap., 3 listes, vidéo) |
| **Dépannage** | **Montage Air System** | **Aucun** |
| **Dépannage** | **Remplacement Gearbox** | **Aucun** |
| **Dépannage** | **Remplacement joints** | **Aucun** |
| **Dépannage** | **Changement piston (V2)** | **Aucun** |
| Mesures & tests | Mesure de tension | Oui — fiche « Mesure de tension » (1 chap., 2 listes, vidéo) |
| Mesures & tests | Test fusible / continuité | Oui — fiche « Test fusible ou continuité » (1 chap., 2 listes, vidéo) |
| Mesures & tests | Mesurer le taux de CO₂ dans l'eau | Oui — fiche « Mesurer le taux de CO2 dans l'eau » (2 chap., 1 liste, vidéo) |
| Astuces | Agrandir un trou de scie cloche | Oui — fiche « Agrandir un trou de scie cloche » (2 chap., 1 liste, vidéo) |
| Astuces | Transformation meuble coulissant avec charnières | Oui — fiche « Transformation d'un meuble coulissant… » (1 chap., 1 liste, vidéo) |
| Astuces | Faire un joint téflon | Oui — fiche « Faire un joint téflon » (1 chap., 2 listes, vidéo) |
| **Configuration** | **Configuration Be Connect** | **Non** — la fiche « Configuration BE CONNECT » existe mais est vide (titre seul) |
| Configuration | Configuration doses BAR 2 | Oui — fiche « Configuration des doses BAR 2 » (1 chap., 1 liste, vidéo) |

### Documentation → Mesures produits (4 documents)

| Document | Doublon non-SharePoint |
|---|---|
| Mesures BOX | Oui — 7 produits en tuiles `PRODUCT_DIMS` (BOX 15, 20, 30, BE BOX 30G, BOX 80 B, BOX 80 I, BOX 150), images annotées dans `img/` |
| Mesures TAP | Oui — 11 produits en tuiles `PRODUCT_DIMS` (Aqtiv One / One S / Combi / Combi H, BAR 1, BAR 2, PRO 2, PRO 3, TOWER, AQTIV DUO) |
| Mesures bouteilles CO₂ (par pays) | Oui — fiche portail (2 chap.), affichée comme carte de bibliothèque via `LIB_FICHE` |
| Visite technique B2C — BOX 20 + Mullex | Oui — fiche portail (2 chap.), idem |

### Mémo « Expérience client & remise » (1 document)

Le PDF « Le mémo d'origine » est lié en bas de la section `s7.body`, dans les
trois langues (3 fichiers distincts). Le contenu du mémo est **entièrement
réécrit dans le hub** juste au-dessus (6 cartes : goûter et valider, comment ça
marche, au quotidien, en cas de problème, BE CONNECT, suivi). Doublon complet,
assumé.

## Les 5 documents sans filet

Ce sont les seuls pour lesquels un lien SharePoint mort voudrait dire un
contenu perdu :

1. **Montage Air System** — Gearbox
2. **Remplacement Gearbox** — Gearbox
3. **Remplacement joints** — Gearbox
4. **Changement piston (V2)** — Gearbox
5. **Configuration Be Connect** — la fiche portail existe mais n'a jamais été
   rédigée (`ficheEmpty` la rejette, la carte garde donc son PDF)

Les quatre premiers n'ont pas d'entrée dans `LIB_FICHE` et aucune fiche
correspondante côté portail : le groupe « Gearbox (technique) » est le seul de
la bibliothèque à ne vivre que sur SharePoint.

## Deux points de détail relevés au passage

- **Les deux cartes « Mesures bouteilles CO₂ » et « Visite technique B2C »**
  sont déclarées `type:"soon"` sans `url` dans `tutorials` (lignes 1569-1570).
  Elles s'affichent bien, parce que `LIB_FICHE` leur trouve une fiche pleine —
  mais comme elles n'ont pas d'`url`, `installFichePdf` ne renvoie rien et leur
  PDF d'origine **n'apparaît pas dans « À voir aussi »**. Il n'est joignable que
  par la section Documentation. Les 21 autres cartes, elles, gardent le lien.
- **Le BOX 45** ne pointe plus SharePoint du tout : il réutilise les schémas du
  BOX 30B (`SCHEMA_ALIAS`), déjà internalisés — voir
  `docs/schemas-sharepoint-sync.md`.
