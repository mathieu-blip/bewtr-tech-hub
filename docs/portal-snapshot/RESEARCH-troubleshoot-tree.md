# Le mode guidé du portail — comment il est construit, et l'arbre complet de « L'eau ne coule pas ? »

## Méthode et ce qu'on peut affirmer avec certitude

Toute cette recherche vient de la lecture du code source livré par
`https://tec-portal.tec-bewtr.workers.dev/` (page HTML + JavaScript, récupérée par
`curl` anonyme, sans mot de passe — aucun blocage rencontré). Aucun navigateur
piloté n'a été nécessaire : la page contient, en clair dans son JavaScript, la
logique complète du mode guidé et les questions qui s'y posent. Ce n'est donc
pas une observation « en cliquant », mais une lecture directe du mécanisme —
ce qui est plus fiable qu'un relevé d'écrans, à condition de bien comprendre
le code, ce que ce document détaille.

Point clé, qui répond à la question posée au départ : **cette structure de
questions/choix n'est pas une donnée du canal `guide` de `tec-data`**. Elle
est écrite en dur dans le JavaScript du portail lui-même, sous forme de
constantes (`PRE_SEED`, `ASK_SEED`, `END_SEED`, `ACTOR_SEED`), et elle
s'applique par-dessus les fiches du guide (qui, elles, viennent bien de
`tec-data` et sont déjà connues du hub) au moment où la page les charge. C'est
la fonction `cloudGuideApply()` (ligne ~33054 du script) qui fait cette
« greffe » juste après avoir récupéré les données du canal `guide` :

```js
try{ if(askSeed()) fiches = true; }catch(e){}   // ligne 33082
```

`askSeed()` appelle à son tour `preSeed()`, `endSeed()`, et applique
`ASK_SEED`/`ACTOR_SEED` — tout cela recalculé **côté client, à chaque
chargement de page**, par comparaison du texte exact des fiches (`p.problem`)
avec les listes ci-dessous. Rien de tout cela n'est visible dans
`docs/portal-snapshot/guide.json`, ce qui confirme ce que les deux
vérifications automatiques du script de synchro avaient déjà conclu : il n'y
a rien de nouveau à récupérer côté `tec-data`, parce que ce n'est pas là que
ça vit.

Une conséquence pratique : ce mécanisme ne concerne, à ce jour, **que le
groupe de fiches « Pas d'eau plate ni gazeuse »** (catégorie `no-water`,
symptôme « L'eau ne coule pas ? »). Les autres symptômes de la tuile
d'accueil (mauvais goût, fuite, débit faible, bruit, etc.) utilisent le même
mécanisme générique de mode guidé pas-à-pas (une vérification à la fois,
boutons « Ça remarche ! » / « Toujours en panne »), mais **aucun n'a
aujourd'hui de question d'identification (`pre`) ni de question de
diagnostic (`ask`) codée en dur** — `PRE_SEED`, `ASK_SEED` et `END_SEED` ne
contiennent que des entrées pour `no-water`. Je ne l'ai vérifié que par
lecture du code, pas en cliquant chaque symptôme un par un (voir « Ce qui
reste incertain » en fin de document).

## Vue d'ensemble : où on entre dans ce parcours

1. Écran d'accueil des pannes (« Qu'est-ce qui ne va pas ? ») : une grille de
   tuiles, une par symptôme, construite depuis la constante `PANNES_TREE`
   (deux groupes : « pannesGroupWater » et « pannesGroupOther »). Chaque tuile
   montre une icône SVG (pas une photo, sauf si un manager a mis une image
   personnalisée) et un libellé. Le libellé exact de la tuile qui nous
   intéresse est **« L'eau ne coule pas ? »** (`labelKey: symWaterNotFlowing`,
   `catId: 'no-water'`).
2. Toucher cette tuile ouvre la catégorie `no-water` directement en **mode
   guidé** (`view = {type:'category', id:'no-water'}` puis rendu par
   `pwRender()`).
3. La catégorie `no-water` n'a qu'un seul groupe de fiches (« Pas d'eau plate
   ni gazeuse », 9 fiches) : l'écran intermédiaire « Qu'est-ce que vous
   constatez exactement ? » (qui ne sert que s'il y a plusieurs groupes dans
   la catégorie) est donc **sauté automatiquement**.
4. On arrive directement sur la question d'identification décrite ci-dessous.

## Étape 1 — Question d'identification : « Quel filtre est installé ? »

Correspond exactement à la première capture de Mathieu. Définie par la
constante `PRE_SEED` (ligne ~41484 du script) :

- **Question** : « Quel filtre est installé ? »
- **Aide affichée sous la question** : « Regardez le filtre fixé au mur ou
  dans le meuble, puis touchez celui qui ressemble au vôtre. »
- **Choix 1** — image `img/0460.webp` (déjà dans le dépôt du hub) — libellé
  **« BE CONNECT »**, identifiant interne `bc`.
- **Choix 2** — image `img/ask-tete-bwt.webp` (récupérée, voir
  `RESEARCH-img/`) — libellé **« Tête de filtre BWT »**, identifiant interne
  `bwt`.

Cette question n'apparaît que parce que le groupe contient la fiche
« Vérifier si le voyant du water-stop BE CONNECT est jaune » (c'est le
déclencheur codé dans `PRE_SEED.trigger`). Le choix fait ici (`bc` ou `bwt`)
sert ensuite de filtre : certaines fiches ne s'affichent que pour un choix
donné (champ `need` par fiche, voir tableau plus bas). Un bouton « Choisir »
permet de revenir en arrière et changer de filtre à tout moment
(`PW.pre === '*'` = « non précisé », auquel cas toutes les étapes s'affichent
sans filtrage).

## Étape 2 — Première vérification, avec sa question de diagnostic

C'est la fiche connue n°1, **« Vérifier si le voyant du water-stop BE CONNECT
est jaune »**, qui s'affiche en premier (à condition qu'elle soit visible —
elle ne l'est que si « BE CONNECT » a été choisi à l'étape 1, `need: ['bc']`).
Avant d'afficher sa procédure, une question de diagnostic est posée
(constante `ASK_SEED`, premier élément) — **c'est exactement la deuxième
capture de Mathieu** :

- **Question** : « Le voyant du water-stop est-il jaune ou blanc ? »
- **Aide** : « Comment trouver le BE CONNECT : c'est le boîtier gris « BE WTR
  » fixé au mur, avec le filtre blanc en dessous. Le voyant se trouve sur le
  dessus du boîtier. » (avec une photo d'aide, `img/0460.webp`)
- **Choix 1** — image `img/ask-bc-blanc.webp` — **« Blanc »** → `go: 'next'`
- **Choix 2** — image `img/ask-bc-jaune.webp` — **« Jaune »** → `go: 'fix'`
- **Choix 3, ajouté automatiquement à toutes les questions de diagnostic**
  (sauf désactivation explicite par un manager) — pas d'image, emoji 🚫 —
  **« Je n'en ai pas dans mon installation »** → `go: 'next'`

C'est la fonction `askOpts()` qui ajoute ce troisième choix par défaut ; il
n'est donc pas propre à cette question précise, mais à toute question de
diagnostic du portail.

### Ce que chaque réponse déclenche

Le sens de `go` (lu dans `pwWire()`, action `'ans'`) :

- **`go: 'next'`** → la vérification est marquée « passée » (réglée
  silencieusement, sans montrer sa procédure) et le parcours **saute
  directement à la fiche suivante** du groupe.
- **`go: 'fix'`** (ou l'absence de question de diagnostic) → la **procédure
  de la fiche** s'affiche (le texte de solution + les photos + la vidéo, tels
  qu'ils sont dans `guide.json`), suivie des boutons de fin d'étape (par
  défaut « 🎉 Ça remarche ! » / « ➡️ Toujours en panne », sauf si la fiche a
  des boutons personnalisés — voir fiche n°5 plus bas).
  - « Ça remarche ! » → écran de victoire (parcours terminé, ce problème est
    résolu).
  - « Toujours en panne » → passe à la fiche suivante.

Donc pour la fiche n°1 : « Blanc » et « Je n'en ai pas... » sautent la
procédure et passent à la fiche n°2 ; « Jaune » affiche la procédure de la
fiche n°1 (essuyer la sonde, réenclencher le bouton jaune, retester).

## Étape 3 et suivantes — le reste du parcours, fiche par fiche

Le groupe compte 9 fiches, dans l'ordre où `guide.json` les liste
aujourd'hui. Les 4 premières sont classées « utilisateur », les 5 suivantes
« technicien » (champ `actor` de chaque fiche dans `guide.json` — voir la
mise en garde plus bas sur la fiche n°4). Le mode guidé montre d'abord
**toutes** les fiches « utilisateur », une à la fois ; une fois épuisées, un
écran de relais (« Vous avez testé tout ce qui était possible de votre côté
») invite à basculer sur les fiches « technicien », montrées ensuite une à
la fois de la même façon (dans un volet dépliable).

| # | Fiche (texte exact de `guide.json`) | Acteur (`guide.json`) | Visible seulement si filtre = | Question de diagnostic (`ASK_SEED`) | Choix → suite |
|---|---|---|---|---|---|
| 1 | Vérifier si le voyant du water-stop BE CONNECT est jaune | utilisateur | `bc` (BE CONNECT) | « Le voyant du water-stop est-il jaune ou blanc ? » | Blanc / Je n'en ai pas → suivante ; **Jaune → procédure fiche 1** |
| 2 | Vérifier si le water-stop ancienne génération s'est déclenché | utilisateur | toutes | « Repérez le water-stop ancienne génération : s'est-il déclenché ? » (avec, si filtre = BE CONNECT, un avertissement rouge : « Avec un BE CONNECT, ce water-stop n'est normalement pas installé... mais sur certaines installations, il y a parfois les deux ») | Non, il est normal / Je n'en ai pas → suivante ; **Oui, il est déclenché → procédure fiche 2** |
| 3 | Vérifier si le robinet d'arrivée d'eau est bien ouvert | utilisateur | toutes | « Le robinet d'arrivée d'eau est-il ouvert ? » | Oui, ouvert / Je n'en ai pas → suivante ; **Non, fermé → procédure fiche 3** |
| 4 | Vérifier si le BOX est gelé (givre visible, eau bloquée) | utilisateur *(voir remarque ci-dessous)* | toutes | « Voyez-vous du givre ou de la glace sur la BOX ? » | Non / Je n'en ai pas → suivante ; **Oui, il y a du givre → procédure fiche 4** |
| 5 | Vérifier le sens de montage du réducteur de pression (flèche dans le sens de l'eau) | technicien | toutes | *aucune* — la procédure s'affiche directement, avec des boutons de fin personnalisés (`END_SEED`) : « ✅ Je confirme qu'il est monté dans le bon sens » et « 🚫 Je n'en ai pas trouvé sur mon installation », **les deux menant simplement à la fiche suivante** (pas de bouton « toujours en panne » ni « réparé » sur cette étape — elle est purement informative) |
| 6 | Vérifier la date et l'état du filtre | technicien | toutes | *aucune* — procédure directe, boutons standards Ça remarche / Toujours en panne |
| 7 | Vérifier l'état du préfiltre (technicien uniquement, sur les systèmes concernés) | technicien | toutes | *aucune* — procédure directe, boutons standards |
| 8 | Vérifier si le BE CONNECT est bloqué (technicien uniquement, après diagnostic) | technicien | `bc` (BE CONNECT) | *aucune* — procédure directe, boutons standards |
| 9 | Vérifier que les tuyaux ne sont ni pincés ni écrasés | technicien | toutes | *aucune* — procédure directe, boutons standards |

Si toutes les fiches sont épuisées sans qu'« Ça remarche ! » ait été cliqué,
un écran final apparaît : « Toujours en panne ? Toutes les vérifications ont
été faites. Passez le relais au SAV. », avec un lien vers
`https://service.bewtr.com/#claims`, un bouton « Poser la question à
l'assistant » et un bouton pour recommencer à zéro.

### ⚠️ Remarque sur la fiche n°4 (BOX gelé) — incertitude à signaler

Le code contient une **quatrième constante**, `ACTOR_SEED`, qui prévoit de
reclasser cette fiche en `actor: 'technicien'` et de la **déplacer en toute
dernière position** du groupe (commentaire dans le code : « à faire
uniquement si tout le reste a échoué »). Mais l'instantané actuel du hub
(`docs/portal-snapshot/guide.json`) montre encore cette fiche avec
`actor: 'utilisateur'`, à sa position d'origine (4ᵉ sur 9). Comme tous ces
« seeds » sont recalculés **côté navigateur, à chaque chargement**, et ne
s'écrivent dans `tec-data` que si quelqu'un ouvre le mode Manager et
enregistre, il est possible que :
- ce changement soit déjà actif pour tout visiteur du portail (calculé en
  mémoire à la volée) sans être encore repris par la synchro (parce que
  personne n'a rouvert le mode Manager depuis) ; ou
- ce changement n'ait en réalité pas encore été appliqué du tout côté
  portail (code présent mais peut-être très récent).

Je n'ai pas de moyen, depuis la seule lecture du code, de trancher entre ces
deux cas — seul un test en direct sur le portail (bouton "Autre problème" →
"L'eau ne coule pas ?", dérouler jusqu'à la fiche BOX gelé) le confirmerait.
Concrètement, l'ordre et le classement utilisateur/technicien indiqués dans
le tableau ci-dessus reflètent ce que `guide.json` contient aujourd'hui, qui
est probablement — mais pas certainement — ce qu'un visiteur voit en ce
moment.

## Les images des cartes de réponse

Toutes récupérées anonymement (aucun mot de passe rencontré) et déposées
dans `docs/portal-snapshot/RESEARCH-img/` :

- `ask-tete-bwt.webp` — carte « Tête de filtre BWT » (question filtre)
- `ask-bc-blanc.webp` — carte « Blanc » (voyant water-stop)
- `ask-bc-jaune.webp` — carte « Jaune » (voyant water-stop)
- `ask-ws-normal.webp` — carte « Non, il est normal » (water-stop ancienne génération)
- `ask-ws-declenche.webp` — carte « Oui, il est déclenché » (water-stop ancienne génération)
- `ask-vanne-ouverte.webp` — carte « Oui, ouvert » (robinet)
- `ask-vanne-fermee.webp` — carte « Non, fermé » (robinet)
- `ask-box-normal.webp` — carte « Non » (givre BOX)
- `ask-box-gel.webp` — carte « Oui, il y a du givre » (givre BOX)

(La carte « BE CONNECT » de la question filtre réutilise `img/0460.webp`,
déjà présente dans le dépôt.) Ces images ne font pas partie du système de
photos du guide (`IMGS`/`IMG_REFS`) que `tools/portal-sync/sync.py` sait déjà
rapatrier : elles sont servies comme fichiers statiques du portail, à leur
chemin littéral (`img/ask-*.webp`), indépendamment du canal `guide`.

## Schéma texte récapitulatif

```
Tuile « L'eau ne coule pas ? » (accueil pannes)
  -> catégorie no-water, groupe unique "Pas d'eau plate ni gazeuse"
  -> [Q0] Quel filtre est installé ?
       - BE CONNECT (bc)
       - Tête de filtre BWT (bwt)
       |
       v
  -> [Fiche 1 — need:bc] Voyant water-stop BE CONNECT
       [Q1] Le voyant est-il jaune ou blanc ?
         - Blanc            -> passe à la fiche 2
         - Jaune             -> procédure fiche 1 -> Ça remarche ?/Toujours en panne
         - Je n'en ai pas    -> passe à la fiche 2
       |
       v
  -> [Fiche 2] Water-stop ancienne génération
       [Q2] S'est-il déclenché ?
         - Non, normal       -> passe à la fiche 3
         - Oui, déclenché    -> procédure fiche 2 -> Ça remarche ?/Toujours en panne
         - Je n'en ai pas    -> passe à la fiche 3
       |
       v
  -> [Fiche 3] Robinet d'arrivée d'eau
       [Q3] Est-il ouvert ?
         - Oui, ouvert       -> passe à la fiche 4
         - Non, fermé        -> procédure fiche 3 -> Ça remarche ?/Toujours en panne
         - Je n'en ai pas    -> passe à la fiche 4
       |
       v
  -> [Fiche 4] BOX gelée
       [Q4] Voyez-vous du givre ?
         - Non               -> fin des étapes "utilisateur" -> écran de relais technicien
         - Oui, givre         -> procédure fiche 4 -> Ça remarche ?/Toujours en panne
         - Je n'en ai pas    -> fin des étapes "utilisateur"
       |
       v  (bascule technicien)
  -> [Fiche 5] Sens du réducteur de pression (pas de question — procédure directe)
       - Je confirme le bon sens     -> passe à la fiche 6
       - Je n'en ai pas trouvé       -> passe à la fiche 6
       |
       v
  -> [Fiche 6] Date/état du filtre (pas de question)
       Ça remarche ? / Toujours en panne -> fiche 7
       v
  -> [Fiche 7] État du préfiltre (pas de question)
       Ça remarche ? / Toujours en panne -> fiche 8
       v
  -> [Fiche 8 — need:bc] BE CONNECT bloqué (pas de question)
       Ça remarche ? / Toujours en panne -> fiche 9
       v
  -> [Fiche 9] Tuyaux pincés (pas de question)
       Ça remarche ? / Toujours en panne -> écran final "Passez le relais au SAV"
```

## Ce qui reste incertain

- L'ordre et le classement utilisateur/technicien de la fiche n°4 (BOX gelée)
  — voir la remarque dédiée ci-dessus.
- Le comportement exact des autres symptômes (mauvais goût, fuite, débit
  faible, bruit, consommation CO2, système chaud, redémarrage, réglage) : le
  code ne contient aucune question `pre`/`ask`/`end` codée en dur pour eux
  (seul `no-water` en a), mais je ne les ai pas parcourus un par un en
  direct pour vérifier qu'aucun manager n'a ajouté de telles questions
  directement dans les données du guide entretemps (le mécanisme
  `pre`/`ask`/`end` peut aussi être ajouté à la main via le mode Manager, pas
  seulement par les constantes `*_SEED` codées en dur — dans ce cas il
  vivrait dans `guide.json` et serait détecté par la synchro normale).
- Rien de tout cela n'a été vérifié par un clic réel dans le portail (pas de
  capture d'écran prise en direct) : c'est une reconstruction à partir du
  code source, jugée suffisamment fiable pour ne pas justifier l'usage d'un
  navigateur piloté, mais une vérification visuelle rapide resterait un bon
  complément si quelqu'un a l'occasion d'ouvrir le portail.
