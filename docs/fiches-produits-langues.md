# Fiches produits — état par langue

Le hub sert désormais les fiches produits dans la langue de l'interface.
`TECHSHEETS` est indexé par langue (`{fr, en, de}`), `techSheet()` choisit la
langue courante et retombe sur le français quand la traduction manque — avec,
dans ce cas, une mention visible dans la visionneuse (« Document en français —
traduction à venir »), pour que le technicien sache ce qu'il lit.

## Couverture

| Fiche | FR | EN | DE |
|---|:--:|:--:|:--:|
| AQTiV One *(fiche produit, 2 p.)* | ✅ | ✅ | ✅ |
| AQTiV One Home *(fiche technique, 8 p.)* | ✅ 08/25 | ✅ 08/26 | ✅ 08/25 |
| AQTiV One S | ✅ | ❌ | ❌ |
| AQTiV Combi Home | ✅ | ❌ | ❌ |
| AQTiV Duo | ✅ | ❌ | ❌ |
| BAR 1 | ✅ | ❌ | ❌ |
| BAR 2 | ✅ | ❌ | ❌ |
| PRO 2 | ✅ | ❌ | ❌ |
| PRO 3 | ✅ | ❌ | ❌ |

L'AQTiV One Home est complet dans les trois langues. Les autres versions EN et
DE manquantes existent pour la plupart sur SharePoint, dans
`Technical/05 Aftersales/Techs/16 New Procedures/Technical sheets/{FR,EN,DE}` :
BAR 1, BAR 2, PRO2, PRO3, AQTiV COMBI HOME et AQTiV Duo y sont dans les trois
langues. Il suffit de les fournir pour compléter le tableau — c'est une
insertion de données, le code n'a plus à bouger.

## ✅ Corrigé — la fiche technique AQTiV ONE 20 « EN »

La première version anglaise n'avait que ses titres traduits : le tableau de la
page 1 était resté en français (`Hauteur de distribution`, `Eau fraîche, plate
et gazeuse filtrée`, `Technologie AQTiV`, `Trou à percer`, et tout le
paragraphe). La révision **08/26** corrige l'ensemble — plus une seule chaîne
française dans les 8 pages, vérifié — et ajoute la seconde phrase du paragraphe
AQTiV, que les versions EN et DE précédentes omettaient.

Les cotes concordent avec les versions FR et DE (`H: 521, W: 110, D: 185` face à
`L/P` en français et `B/T` en allemand, `H: 288 or 126`, `Ø 35`).

À noter : l'anglais est désormais en révision 08/26, le français et l'allemand
restent en 08/25. Si la mise à jour ne portait que sur la traduction, rien à
faire ; sinon, les deux autres langues sont à repasser.

## ⚠️ Un défaut restant dans les fichiers source

### La fiche AQTiV ONE S porte le mauvais titre en page 2

Le bandeau de la page 2 annonce **AQTiV ONE HOME** alors que le document est
celui de l'AQTiV ONE S (page 1 : « AQTiV ONE S », H: 422 mm). Vraisemblablement
un report de gabarit.

## Traduction de l'AQTiV ONE S (FR → EN → DE)

Prête à être reversée dans le gabarit. Sauf mention contraire, les formulations
EN et DE sont **reprises telles quelles des fiches BE WTR existantes** (fiche
produit AQTiV One EN, fiche technique AQTiV ONE 20 DE) plutôt que traduites
librement, pour rester cohérent avec la terminologie maison.

### Page 1

| FR | EN | DE |
|---|---|---|
| AQTiV ONE S | AQTiV ONE S | AQTiV ONE S |
| FICHE TECHNIQUE | TECHNICAL SHEET | TECHNISCHES DATENBLATT |
| ROBINET | TAP | WASSERHAHN |
| Versions | Versions | Ausführungen |
| Dimensions (mm) | Dimensions (mm) | Abmessungen (mm) |
| H: 422, L: 110, P: 185 | H: 422, W: 110, D: 185 | H: 422, B: 110, T: 185 |
| Hauteur de distribution (mm) | Dispensing height (mm) | Spendehöhe (mm) |
| H: 288 or 126 | H: 288 or 126 | H: 288 or 126 |
| Eau | Water | Wasser |
| Eau fraîche, plate et gazeuse filtrée | Filtered fresh, still and sparkling water | Gefiltertes frisches Wasser mit und ohne Kohlensäure |
| Technologie AQTiV | AQTiV Technology | AQTiV-Technologie |
| Trou à percer (mm) | Drilling hole (mm) | Bohrloch (mm) |
| Ø 35 | Ø 35 | Ø 35 |

Paragraphe « Technologie AQTiV », première phrase — formulation BE WTR existante :

- **FR** — Une technologie innovante combinant: un mécanisme de vortex accélérant le mouvement de l'eau, 18 micro-jets permettant une aération optimale, et une protection de l'air garantissant son hygiène.
- **EN** — Through an innovative system combining a vortex mechanism, 18 micro-jets for optimal water aeration, and annular air protection around the nozzle extremity, the water flows in an accelerated movement, resulting in improved aeration and oxygenation.
- **DE** — Dank einem innovativen System, das einen Wirbelmechanismus, 18 Mikrodüsen für optimale Wasserbelüftung und einen ringförmigen Luftschutz um das Düsenende herum umfasst, wird der Wasserfluss beschleunigt, was eine verbesserte Belüftung und Sauerstoffversorgung ermöglicht.

Seconde phrase — **aucune version EN/DE n'existe dans les fiches BE WTR** (les
fiches anglaise et allemande de l'AQTiV ONE s'arrêtent à la première phrase).
Proposition, à valider :

- **FR** — Grâce à la technologie AQTiV, profitez d'une eau sublimée et délicieuse et à la texture soyeuse. Une eau fraîche, plate ou gazeuse à la demande.
- **EN** *(proposé)* — With AQTiV technology, enjoy water at its best: delicious, with a silky texture. Fresh water, still or sparkling, on demand.
- **DE** *(proposé)* — Dank der AQTiV-Technologie genießen Sie Wasser in seiner besten Form: köstlich und mit seidiger Textur. Frisches Wasser, still oder mit Kohlensäure, auf Knopfdruck.

### Page 2

| FR | EN | DE |
|---|---|---|
| ROBINET – AQTIV ONE | TAP – AQTIV ONE | WASSERHAHN – AQTIV ONE |
| FICHE TECHNIQUE | TECHNICAL SHEET | TECHNISCHES DATENBLATT |
| DISTANCE CONSEILLÉE ENTRE LE TROU DANS LE COMPTOIR ET LA SORTIE DU ROBINET 100 MM *(proposé)* | RECOMMENDED DISTANCE BETWEEN THE HOLE IN THE COUNTERTOP AND THE TAP OUTLET 100 MM | EMPFOHLENER ABSTAND ZWISCHEN DEM LOCH IN DER ARBEITSPLATTE UND DEM AUSLAUF DES WASSERHAHNS 100 MM |

Le bandeau « AQTiV ONE HOME » de cette page est à corriger en « AQTiV ONE S »
au passage (voir défaut 2 ci-dessus).

## Pourquoi les PDF EN/DE ne sont pas générés ici

Le PDF de l'AQTiV ONE S embarque ses polices **en sous-ensemble** : 61 glyphes,
ceux du texte français uniquement. Il n'y contient ni `ä`, ni `ö`, ni `ü`, ni
`ß`. Un « Ausführungen » ou un « Spendehöhe » composé dans ce fichier sortirait
avec des trous, ou dans une police de substitution visiblement différente — sur
un document qui porte le logo BE WTR et des cotes d'installation.

La version anglaise passerait, elle, sans glyphe manquant. Mais livrer l'EN et
pas le DE, sur un document d'apparence officielle, vaut moins qu'un passage
propre par le gabarit d'origine : le tableau ci-dessus s'y reverse en quelques
minutes, avec les polices complètes et une relecture humaine.
