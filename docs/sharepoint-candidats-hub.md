# Ce qui reste à prendre sur SharePoint pour le hub

Relevé du 26/08/2026, site *Switzerland* → `Shared Documents/Technical/05 Aftersales/Techs`.

Périmètre retenu : **uniquement ce qui sert un technicien sur le terrain**. Tout ce
qui relève du HQ, des RH, du commercial ou de la R&D est listé en fin de document,
dans « Écarté et pourquoi », pour qu'on n'ait pas à re-trancher plus tard. Aucun
document contenant des prix n'est proposé à l'intégration.

Déjà dans le hub et donc absent d'ici : `03 Water line Schema`, `04 Electrical
schema`, `02 Spare parts`, les fiches techniques de `16 New Procedures/Technical
sheets` (voir `schemas-sharepoint-sync.md`, `audit-spare-parts-2022.md`,
`fiches-produits-langues.md`).

---

## Priorité 1 — manques francs, documents prêts à l'emploi

### 1. Le protocole de maintenance officiel

`14 OI - Operating Instructions/OI-0003 Maintenance protocol/`
→ `OI-0003 Protocole de maintenance Rev3 - FR.pdf`

Le hub a une section *Maintenance*, mais pas le protocole maison. Ce document
tient en deux planches : le déroulé illustré (nettoyage cartouche + 25 ml de
javel 2,5 %, attente 10 min, rinçage jusqu'à disparition du goût de chlore —
~3 L en plate, ~10 L en gazeuse, changement de filtre, contrôle pression CO₂,
grille de ventilation, fiche d'entretien) et la **liste des tâches obligatoires**
d'une maintenance. C'est exactement le format d'une page de hub.

Attention à la révision : le **Rev3 n'existe qu'en FR**. Les EN, DE et IT sont
restées en Rev2. Il faudra soit servir Rev3 en FR et Rev2 ailleurs (avec la
mention « traduction à venir » déjà en place pour les fiches produits), soit
faire traduire Rev3.

### 2. Les procédures de résolution — `15 RP - Resolution Procedure`

C'est le plus gros manque du hub : **aucune** de ces fiches n'y est. Ce sont des
pannes réelles, documentées une par une, avec photos. Toutes en PDF (+ .docx source).

| Fiche | Sujet |
|---|---|
| PR-0048 | BAR2 — pas d'eau plate |
| PR-0049 | BW-0074 — vibrations, eau dans le tube |
| PR-0051 | BAR2 double portion control — programmation |
| PR-0052 | Installer une recirculation |
| PR-0053 | AQTiV Tap — SAV *(106 Mo, contient des vidéos)* |
| PR-0054 | BOX 15 — changement de tubing |
| PR-0057 | BOX gelée |
| PR-0058 | AQTiV Taps — problèmes de gearbox |
| PR-0060 | Maintenance tips — tube de sortie *(+ vidéos `Maintenance tips BAR2.mp4`, `Maintenance tips PRO1.mp4`)* |
| PR-0061 | Solutions de filtration BE WTR *(.pptx, 26 Mo)* |
| PR-0062 | Fuite au détendeur de gaz |
| PR-0064 | AQTiV — compensateur eau plate |
| PR-0066 | Détection de fuite de gaz |
| PR-0067 | BOX 30 — isolation vernis de la sonde de niveau de carbonatation |

Et, à la racine du même dossier, deux procédures de remise à neuf :
`AQTiV Tap refurbishing - FR.pdf` et `BOX refurbishing - FR.pdf`.

Le hub a déjà des vidéos de dépannage courant (faible débit, pas d'eau plate,
pas de pétillant, changement de bouteille, doses BAR2). Les PR ne les doublent
pas : elles vont plus loin, machine par machine. Elles alimenteraient naturellement
la section *Dépannage*, et l'« arbre de décision symptôme → cause » listé dans
*À compléter* pourrait se construire par-dessus.

Deux nuances sur ce dossier :
- **PR-0050 « Commercials troubleshooting guide »** (FR/EN/DE/IT) est destiné au
  client et aux commerciaux, pas au technicien — il renvoie au service technique
  (021 312 41 27) à chaque impasse. Utile à connaître (le tech saura ce que le
  client a déjà tenté), mais à ranger comme tel, pas dans le dépannage technique.
- **PR-0056 « Salesforce intervention work type »** relève du process, voir §11.

### 3. `OI-0006 BAR2-80 Troubleshooting guide`

`14 OI - Operating Instructions/OI-0006 BAR2-80 Troubleshooting guide/OI-0006 BAR2-80 Troubleshooting guide.pdf`

Guide de dépannage dédié BAR2-80. Anglais seulement.

### 4. Le tableau de carbonatation

`01 Organization/After-Sales Service/Carbonation Table/Tableau Carbonatation.pdf`

Une page, en français. C'est typiquement le contenu de la section *Réglages &
valeurs*, qui existe déjà dans le hub. À croiser avec `OI-0011 Carbonation
measurement.pdf` (§12).

### 5. Les cotes d'encombrement

`01 Organization/Other support/BOX AND TAP Dimensions/`
→ `BOX - Dimensions.pdf` (7 Mo) et `TAP - Dimensions.pdf` (8,4 Mo)

Dimensions de toutes les BOX et de tous les robinets. Indispensable au repérage
avant installation, et aujourd'hui absent : le hub ne porte que les schémas de
ligne d'eau et électriques.

### 6. Le gabarit de découpe Be Connect

`01 Organization/Other support/BE CONNECT cutting template/BE CONNECT cutting template.pdf`

⚠️ **Cas particulier.** Le hub convertit les PDF en WebP pour l'aperçu écran
(voir `schemas-sharepoint-sync.md`), ce qui détruit l'échelle : un gabarit doit
s'imprimer en 1:1 ou il ne sert à rien. Soit on le sert en PDF téléchargeable par
exception, soit on l'affiche avec une règle de calibration imprimée dessus, soit
on ne le met pas. À trancher avant de l'intégrer.

---

## Priorité 2 — utile, demande un peu de travail

### 7. Le manuel technique complet

`16 New Procedures/Systems - Technical manual - Rev7.1 - FR.docx` (9,2 Mo)
*(une Rev07 en anglais existe aussi dans le même dossier)*

C'est la référence de fond. Trop volumineuse pour une tuile unique : à découper
par chapitre et à répartir dans les sections existantes du hub, plutôt qu'à
publier telle quelle.

### 8. Outillage et stock véhicule

- `14 OI - Operating Instructions/OI-0002 Technician tools/(EN) CAR STOCK REQUIRED.pdf`
- `14 OI - Operating Instructions/OI-0001 BE WTR Technician van accessories/OI-0001 BE WTR Accessoires van technicien - FR.pdf`

Ce qu'un tech doit avoir dans sa camionnette. Le PDF FR est la bonne source.

⚠️ Ne **pas** prendre les variantes `.xlsx` ni le fichier `EN Rev3 - supply` sans
les ouvrir d'abord : ce sont les versions d'approvisionnement, susceptibles de
porter des références fournisseur et des prix.

### 9. Les formulaires de terrain

- `OI-0008 Maintenance sheet/` → `Maintenance record - FR / EN / DE.pdf`
- `OI-0007 Machine return sheet/` → `Machine return.pdf`
- `01 Organization/Other support/Maintenance Sheet/(FR:DE:EN) Maintenance panel.pdf`

La fiche d'entretien que le protocole OI-0003 demande de remplir et signer sur la
BOX, la fiche de retour machine, et le panneau de maintenance trilingue. Disponibles
dans les trois langues du hub — donc directement compatibles avec `TECHSHEETS`.

### 10. Liste des pièces à sortir

`14 OI - Operating Instructions/Technical parts to outbound/technical parts list to outbound - FRA v3.pdf`

*(la v2 traîne aussi sous `01 Organization/Other support/List of parts to be
scanned at the customer's premises/` — prendre la v3)*

Complète la base pièces détachées déjà présente : ici, ce qui se scanne et se
sort chez le client.

### 11. Salesforce Field Service — le guide FR

`01 Organization/HELP GUIDE SF _ FS/FR/`
→ `(FR) Ouvrir un case.pdf`, `(FR) Dispatcher et préparer l'installation.pdf`,
`(FR) Programmer et Dispatcher une Maintenance.pdf`
*(un dossier `EN` parallèle existe)*

C'est l'outil quotidien du technicien, et le protocole de maintenance se termine
par « enregistrer l'intervention dans Salesforce ». À compléter par
`15 RP/PR-0056 - Salesforce intervention work type` (quel work type choisir).

Attention : trois dossiers homonymes coexistent (`HELP GUIDE SF _ FS`,
`…_old`, `…-Kevin's Macbook`, plus un `HELP GUIDE SF : FS` vide). Le bon est
`HELP GUIDE SF _ FS`.

### 12. `OI-0011 Carbonation measurement.pdf`

`14 OI - Operating Instructions/OI-0011 Carbonation measurement/`
*(également à la racine de `16 New Procedures/`)*

Le hub a déjà la vidéo « Mesurer le taux de CO₂ dans l'eau ». Le PDF donne la
procédure écrite, à mettre en regard de la vidéo et du tableau de carbonatation.

### 13. `AP-0001 Aftersales AQTiV Tap flow Rev1.pdf`

`10 AP - Aftersales Procedure/AP-0001 Aftersales AQTiV Tap flow/`

Le seul des trois AP qui soit vraiment orienté terrain : le parcours SAV d'un
robinet AQTiV. Les deux autres (AP-0002 claims, AP-0003 gestion des pièces) sont
des process ADV/HQ.

---

## Priorité 3 — niche BiG250

Utile seulement aux techs qui interviennent sur l'embouteilleuse BiG250. À ne
sortir que si ce périmètre entre dans le hub :

- `OI-0005 BiG250 Bottling process`
- `OI-0009 BiG250 Printer`
- `OI-0010 Manual capper setting`
- `15 RP/PR-0059 - BiG250 Bottle washer recommendation`

---

## Écarté et pourquoi

**RH / paie / administratif** — hors sujet pour un hub technique :
`01 Organization/` → `Expense reports and Advance`, `Vacation Planning`,
`Internal Regulations Swiss Technician`, `Annual work clothers order`,
`Piquet (permanent troubleshooting)` (contrats et planning 2025), `Team photos`,
`Vehicles` (cartes grises, leasing), `Checklist Onboarding Technicien` (vide, ne
contient qu'un gabarit `Original (Empty)`). Idem pour tout ce qui est sous
`Personal files/Salaire techs` (salaires, primes) — à ne jamais approcher.

**Commercial** — `01 Organization/After-Sales Service/Guidelines sales.pptx` (22 Mo).

**Process HQ / ADV** — `10 AP/AP-0002 Aftersales claims process`,
`10 AP/AP-0003 Spare parts management`.

**R&D / tests** — `15 RP/PR-0065 - AQTiV+ serigraphy test`.

**Archives** — chaque dossier a son `XX Archive` / `Archives`. Le plus gros du
site y est d'ailleurs (`14 OI/XX Archive` pèse 6,4 Go à lui seul, sur les 6,4 Go
du dossier OI). Rien à en tirer pour le hub, et à ne pas confondre avec les
courants.

**Divers égaré** — `10 AP/2024-03-28-carte-grise-voilier-Wolf (1).heic` traîne à
la racine des procédures après-vente ; ce n'est pas un document technique.

---

## Deux remarques de méthode

1. **Les révisions ne sont pas alignées entre langues.** OI-0003 est en Rev3 pour
   le FR et en Rev2 partout ailleurs ; OI-0001 a une Rev3 EN et pas d'équivalent
   FR/DE/IT. Le mécanisme de repli déjà en place pour les fiches produits
   (français servi avec la mention « traduction à venir ») couvre le cas, mais il
   faut le décider document par document plutôt que de mélanger les révisions.

2. **Les PR et les OI sont en `.pdf` + `.docx`/`.pptx` source.** Comme pour les
   schémas, seul le PDF est à reprendre ; le source reste sur SharePoint.
