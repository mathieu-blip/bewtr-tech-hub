# Module de dépannage — audit d'écart et intégration de la plateforme troubleshooting

Date : 26 août 2026 · Périmètre : `index.html` (hub technicien) + plateforme
`bewtr-troubleshooting.netlify.app` · Cible : un module de dépannage utilisable
**par les techniciens sur le terrain** et **par le Customer Success à distance**.

---

## 0. Accès à la plateforme externe — bloquant

La session n'a pas pu ouvrir `https://bewtr-troubleshooting.netlify.app/` : la
politique d'egress de l'environnement refuse le domaine (403 sur le CONNECT,
confirmé côté proxy). Aucune ligne de ce document ne décrit donc le contenu réel
de cette plateforme.

Pour lever le blocage, au choix :

| Option | Ce qu'elle donne | Effort |
|---|---|---|
| Autoriser le domaine dans la politique réseau de l'environnement | lecture directe du site | admin, 5 min |
| Pousser la source sur GitHub (repo accessible à la session) | lecture du code **et** du modèle de données | le mieux |
| Coller ici l'export HTML / le JSON des pannes | lecture du contenu seul | dépannage rapide |
| Capture d'écran de chaque écran + export du contenu | lecture partielle | dernier recours |

Le repo source est de loin le plus utile : l'intégration ne se joue pas sur le
rendu mais sur **la forme des données** (§2).

---

## 1. État des lieux — ce que le hub sait faire aujourd'hui

Chiffres relevés dans `index.html` (11,7 Mo, fichier unique, sans build).

### Sections (14)

`home · overview · beconnect · install · settings · maintenance · safety ·
troubleshoot · experience · tutorials · schemas · glossary · gaps · feedback`

### Dépannage (§6) — l'existant

- **25 fiches** au total : 7 symptômes généraux + 18 fiches produit réparties sur
  5 onglets (`box`, `tap`, `pro`, `beconnect`, `divers`).
- Format : `<details>` HTML **écrits en dur** dans le dictionnaire `I18N`
  (clé `s6.body`, ~12 000 caractères), **dupliqués à la main en FR / EN / DE**.
- Chaque fiche = un titre de symptôme + une liste de causes + parfois un lien
  vidéo YouTube. Pas de champ structuré.

### Le reste du socle

| Bloc | Contenu | Couverture |
|---|---|---|
| `MACHINES` | 11 BOX + 10 taps = **21 modèles** | référentiel produit |
| `SCHEMAS` | 13 produits × (eau / élec), PDF base64 | **13 / 21 modèles** |
| `SPAREPARTS` | 16 machines, 380 lignes, **294 réfs BW** uniques | 100 % de la base sept. 2022 |
| `EXPLODED` | 14 vues éclatées | 2 annoncées manquantes (AQTiV ONE, AQTiV COMBI) |
| `TECHSHEETS` | 8 fiches techniques (taps uniquement) | aucune pour les BOX |
| `tutorials` | 38 entrées : 27 PDF SharePoint, 8 YouTube, 3 « bientôt » | 10 en catégorie dépannage |
| Recherche globale | indexe sections + pièces + **titres** de tutos | ne cherche pas dans les symptômes |
| Accès | gate SHA-256 **côté client** | cosmétique (§5.2) |
| Retours | formulaire → Google Apps Script | 13 champs, opérationnel |

---

## 2. Intégrer la plateforme troubleshooting — ce qu'il faut décider et obtenir

Ces points sont indépendants du contenu du site : ils se posent quel que soit ce
qu'il contient.

### 2.1 Ce que je dois récupérer

1. **Le modèle de données des pannes** — le schéma exact (champs, types,
   identifiants). C'est la pièce qui conditionne tout le reste.
2. **La source** — repo Git, ou export statique, ou API.
3. **Le back-end éventuel** — la plateforme a-t-elle une base, un CMS, une
   fonction Netlify ? Si oui, le hub (100 % statique aujourd'hui) ne peut pas
   l'absorber tel quel.
4. **Le mode d'authentification** de la plateforme (aucun / Netlify Identity /
   SSO) et s'il doit être conservé.
5. **La langue de référence** du contenu et l'état des traductions EN / DE.
6. **Le référentiel produit utilisé** — s'il ne parle pas la même langue que
   `MACHINES` (« BOX 30 B » vs « BOX 30B » vs « Box30B »), il faut une table de
   correspondance avant toute fusion.
7. **Les identifiants de pièces** — la plateforme référence-t-elle les SKU `BW-xxxx` ?
8. **Qui possède et met à jour** le contenu aujourd'hui, et à quelle fréquence.
9. **L'analytics existant** — s'il y a des chiffres d'usage, ils disent quelles
   pannes comptent vraiment.

### 2.2 La décision d'architecture à trancher

Trois voies, à choisir avant d'écrire une ligne :

| Voie | Description | Coût | Risque |
|---|---|---|---|
| **A. Lien externe** | une entrée « Dépannage » du hub ouvre le site Netlify | quasi nul | deux bases à maintenir, deux mots de passe, pas de recherche croisée, rupture hors ligne |
| **B. Fusion des données** | on importe le contenu dans un objet `FAULTS[]` du hub, la plateforme disparaît | moyen | migration + traduction à faire une fois |
| **C. Le hub consomme un JSON publié** | la plateforme reste l'outil d'édition et publie `faults.json`, le hub le charge | moyen | dépendance réseau, cache à gérer |

**Recommandation : B**, sauf si la plateforme sert aussi d'outil d'édition à
des non-développeurs — dans ce cas C. A est à écarter : elle ne résout aucun
des écarts du §3 et double la charge de maintenance.

---

## 3. Écarts pour un module de dépannage complet

### 3.1 Socle données & navigation

1. **Le dépannage n'est pas structuré.** Il est en HTML figé, en triple
   exemplaire. Conséquences directes : impossible de filtrer par machine, de
   trier par gravité, de compter, de traduire automatiquement, de lier une
   panne à une pièce. **Il faut un objet `FAULTS[]`** avec au minimum :
   `id · symptôme · alias/synonymes · produits[] · gravité · sécurité ·
   causes[{cause, test, action}] · pièces[SKU] · tutos[] · durée estimée ·
   niveau requis · résolvable à distance (oui/non) · dernière revue`.
   Tout le reste de cette liste en découle.

2. **Pas d'arbre de décision symptôme → cause.** Déjà identifié par le hub
   lui-même (§12 « À compléter », ligne *Dépannage — Partiel*). Manque un
   parcours guidé question/réponse dont la sortie est : diagnostic + pièce à
   emporter + tuto + décision (client seul / tech / remplacement).

3. **Pas d'entrée « pannes » par machine.** Le sélecteur d'accueil propose
   schéma eau, schéma élec, pièces, fiche technique, maintenance, Be Connect,
   tuto — mais **pas** « pannes connues de ce modèle ». C'est le chemin le plus
   naturel pour un tech devant une machine.

4. **Aucune table de codes d'erreur / alarmes.** Le seul repère existant est la
   signification des LED Be Connect (§2). Manquent : codes PRO 2 / PRO 3,
   alarmes BOX, alertes de la webapp client, alarme du bidon de récupération —
   et leur renvoi vers la fiche panne correspondante. C'est ce que le CS lit en
   premier au téléphone.

5. **Pièces et pannes ne sont pas reliées.** 294 SKU d'un côté, 25 fiches de
   l'autre, zéro lien. Il manque le « cette panne consomme `BW-xxxx` », et la
   liste de ce qu'il faut avoir dans le van par symptôme.

6. **La recherche ne trouve pas les pannes.** `buildSearchIndex()` indexe le
   texte des sections, les SKU/noms de pièces et les **titres** de tutos. Une
   recherche « fuite gearbox » tombe sur la section entière, pas sur la fiche.
   Manquent aussi les mots que disent les clients : « ça fait du bruit »,
   « l'eau est tiède », « ça mousse », « ça goutte ».

7. **Pas de gravité ni de priorité visible.** L'avertissement le plus grave de
   toute la base — *cartes électroniques PRO 2 / PRO 3, risque d'incendie,
   « priorité absolue »* — est enfoui dans un `<details>` replié de l'onglet
   `pro`. Il faut un niveau de criticité porté par la donnée et remonté en tête.

### 3.2 Couverture de contenu — trous identifiés

**Pannes manquantes par produit** (5 groupes de fiches pour 21 modèles) :
aucune fiche propre à **AQTiV ONE, AQTiV COMBI, AQTiV Tower**, aux **BOX 15 /
20 / 45 / 120 I**, au **BAR 2 Touchless**, au **PRO 3** (traité seulement en
grappe avec le PRO 2), au **kit Mullex**, ni aux installations **avec
recirculation (Python)**.

**Familles de symptômes jamais couvertes** : goût / odeur de l'eau, eau trouble
ou blanche, bruit anormal (pompe, ventilateur, compresseur), eau tiède alors que
la BOX tourne, fuite d'eau (seule la fuite de gaz et la fuite gearbox existent),
disjonction / coupure électrique, machine qui ne s'allume pas, hors ligne
Be Connect / perte de réseau, débit irrégulier, problème après coupure d'eau du
bâtiment, gel en hiver (mentionné en cause, jamais en symptôme).

**Documents manquants déjà connus du hub** : tutos *AQTiV Duo*, *PRO 2 (gen 2026)*,
*trou scie cloche* ; schémas absents pour **8 modèles sur 21**
(BOX 30 (2021), BOX 120 I, AQTiV ONE, AQTiV Tower, AQTiV COMBI, AQTiV Duo,
PRO 1, PRO 3) ; schéma élec manquant BOX 45 ; schéma eau manquant BOX 80 ITBD ;
vues éclatées AQTiV ONE et AQTiV COMBI listées mais absentes ; aucune fiche
technique pour les BOX.

### 3.3 Volet Customer Success — aujourd'hui inexistant

Le hub est écrit **uniquement pour un technicien déjà sur place**. Rien ne
s'adresse à quelqu'un qui diagnostique au téléphone ou par écrit. Manquent :

1. **Un parcours de triage à distance** : les mêmes symptômes, mais avec les
   questions à poser au client et ce qu'on peut lui faire vérifier lui-même.
2. **Le critère de décision** « résolvable par le client » / « intervention
   technicien » / « remplacement », posé sur chaque panne.
3. **La formulation client** de chaque panne — le tech lit « préfiltre saturé »,
   le CS doit dire « le filtre arrive en fin de vie, on passe le changer ».
4. **La checklist d'informations à collecter** avant d'escalader : modèle,
   n° de série, date d'installation, date de dernière maintenance, photo de
   l'écran / du raccord, symptôme depuis quand, progressif ou brutal.
   (Le hub contient déjà l'indice de diagnostic clé — *dégradation progressive =
   filtre, panne brutale = pompe* — mais rien ne dit au CS de poser la question.)
5. **Les modèles de réponse** WhatsApp / e-mail par panne courante.
6. **Le lien avec le bot WhatsApp** : la §7 demande au tech de le présenter au
   client, mais aucune section n'explique au CS comment il fonctionne, ce qu'il
   sait faire, ni ce qui remonte quand il échoue.
7. **La règle garantie / facturable** par type de panne.
8. **Les SLA et priorités** : quoi traiter en urgence (cartes PRO 2), quoi peut
   attendre la prochaine maintenance.
9. **Une section « Support » — elle est référencée et n'existe pas.** Le texte
   d'accueil dit *« Bloqué ? Voir Dépannage §6 et Support §9 »*, or il n'y a pas
   de section 9 : `SECT_IDS` n'en contient aucune. Lien mort dans le tout
   premier écran. Il faut la créer : contacts, escalade, hotline, horaires,
   qui appeler pour quoi.

### 3.4 Traçabilité de l'intervention

10. **Le rapport d'intervention n'existe nulle part.** La §5 se termine par
    « remplir le rapport d'intervention » sans gabarit ni lien. Manquent : le
    formulaire, des **codes cause / résolution normalisés** (sans lesquels on ne
    saura jamais quelle panne coûte le plus cher), la photo, et le lien vers
    l'outil qui porte les *Case / Service / Intervention* du glossaire — outil
    jamais nommé.
11. **Pas de retour du terrain vers la base.** Le formulaire « Signaler /
    suggérer » collecte des bugs de documentation, pas des cas de panne. Une
    panne résolue sur le terrain et absente de la base n'a aucun chemin pour y
    entrer.

### 3.5 Plateforme & exploitation

12. **Rien ne fonctionne hors ligne.** Ni service worker, ni manifest PWA. Un
    local technique en sous-sol, une cave d'hôtel, un parking : le hub est
    inutilisable. Pour un outil de dépannage terrain, c'est le premier défaut.
13. **11,7 Mo dans un seul fichier**, PDF encodés en base64 dans le HTML.
    Tout est téléchargé à chaque visite, avant même le mot de passe. À découper
    (assets externes + chargement à la demande) avant d'ajouter du contenu.
14. **Le contrôle d'accès est cosmétique.** Le gate compare un SHA-256 en
    JavaScript, sur un site public : la totalité du contenu est déjà dans le
    navigateur avant la saisie du mot de passe, et le hash est lisible dans la
    source. Acceptable pour de la doc technique, **insuffisant dès qu'on ajoute
    du CS** (éléments contractuels, garantie, tarifs). Il manque aussi des
    **rôles** : le tech et le CS n'ont pas besoin de la même vue.
15. **Aucune mesure d'usage.** On ne sait pas quelles pannes sont consultées, ce
    qui est cherché sans résultat, ni si une fiche a résolu le problème.
    Manquent un compteur de consultation, les recherches à zéro résultat, et un
    « cette fiche vous a aidé ? oui / non ».
16. **Pas de gouvernance de contenu.** Un fichier HTML édité à la main, du
    contenu traduit trois fois manuellement, des PDF hébergés sur un OneDrive
    **personnel** (`charles_epert_bewtradmin...`) et un Apps Script sur un
    compte personnel. Manquent : un propriétaire par domaine, une date de
    dernière revue par fiche, et une migration des liens vers un espace
    d'équipe. Le jour où cette personne part, les 27 PDF tombent.
17. **Trois langues seulement** (FR / EN / DE), sans process de traduction —
    à confirmer par rapport aux pays réellement servis (IT, ES, NL ?).

---

## 4. Séquencement proposé

**Lot 0 — débloquer (≤ 1 j)**
Obtenir l'accès à la plateforme, trancher la voie A/B/C du §2.2, croiser son
contenu avec les 25 fiches existantes.

**Lot 1 — le socle (le plus rentable)**
Sortir le dépannage du HTML : construire `FAULTS[]`, migrer les 25 fiches +
l'apport de la plateforme, brancher la recherche dessus, ajouter la puce
« pannes » sur le sélecteur de machine, poser gravité et SKU. Tout le reste en
dépend.

**Lot 2 — combler**
Arbre de décision, table des codes d'erreur, familles de symptômes manquantes,
couverture des 8 modèles sans schéma.

**Lot 3 — Customer Success**
Triage à distance, critère client/tech, formulations client, checklist
d'escalade, modèles de réponse, **section Support (lien mort à réparer)**.

**Lot 4 — exploitation**
PWA hors ligne + découpage des 11,7 Mo, accès serveur avec rôles tech/CS,
rapport d'intervention et codes de résolution, analytics et boucle de retour,
migration des PDF vers un espace d'équipe.

---

*Les §1, §3 et §4 sont établis par lecture du code du hub. Le §2 liste ce qui
reste à obtenir : le contenu de la plateforme Netlify n'a pas pu être lu.*
