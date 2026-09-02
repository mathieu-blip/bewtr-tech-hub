# BE WTR — Hub technicien

Le guide d'installation, de maintenance et de dépannage des systèmes BE WTR,
plus la plateforme des tickets de réparation. Site statique, publié par GitHub
Pages sur **service.bewtr.com**.

```
index.html                 tout le hub — structure, styles, textes, code
img/                       toutes les images (1 041 fichiers)
docs/supabase/*.sql        le schéma et l'API de la plateforme des tickets
docs/portal-snapshot/      l'état du portail technicien, relu par portal-sync
tools/portal-sync/         le robot qui rapporte les évolutions du portail
feedback-apps-script.gs    le collecteur de l'onglet « Signaler / suggérer »
```

## Les deux règles à connaître avant de toucher au fichier

**1. Aucune image en base64.** Les images vivent dans `img/` et se chargent au
clic. Le hub a longtemps porté 10 Mo d'images collées dans le HTML : elles
descendaient toutes avant même l'écran de mot de passe, ce qui, sur la 4G d'un
sous-sol, revenait à ne rien afficher. Une image ajoutée est un fichier ajouté.

**2. Aucun secret dans le dépôt.** Il est public. Le mot de passe du hub n'est
présent que sous forme de hash (`GATE_HASH`), et les phrases de passe Supabase
ne sont nulle part : les scripts SQL portent des marqueurs à remplacer au
moment de les jouer. Un secret écrit ici y reste, même effacé — l'historique
le garde.

## Le menu est la source de vérité

Le balisage `<nav id="nav">` décide de tout : `SECT_IDS` (le routeur d'onglets),
`FB_AREAS` (le menu « Section concernée » du formulaire de retour), l'index de
recherche et le menu flottant du mobile en sont tous dérivés. **Ajouter une
section, c'est ajouter un lien au menu et une `<section id="…">`, rien d'autre.**

## Les textes

Tous les textes visibles sont dans la constante `I18N` (le guide) et `CL_I18N`
(la plateforme des tickets), en français, anglais et allemand — les trois
toujours complètes. Un texte codé en dur dans le balisage est un bug : le
sélecteur de langue ne le verra pas.

## Le guide du portail

La constante `PORTAL_GUIDE` n'est **pas** écrite à la main : `tools/portal-sync`
la recompose depuis `docs/portal-snapshot/guide.json`. Avant d'y toucher :

    python3 tools/portal-sync/test_build.py

Ce test garantit que le robot sait refaire la constante à l'identique. Tant
qu'il passe, la mise à jour automatique ne peut rien effacer. Le workflow
`.github/workflows/portal-sync.yml` se lance à la main depuis l'onglet Actions.

## Vérifier une modification

Le hub n'a pas de build : ouvrir `index.html` suffit. Pour tester les chemins
d'images et le mode `#ticket`, mieux vaut un vrai serveur :

    python3 -m http.server 8000     # puis http://localhost:8000/

À contrôler après une modification de structure :

- le hub s'ouvre et le mot de passe est accepté ;
- `#ticket` sur un écran étroit ne montre **que** le formulaire — pas de menu
  flottant, pas d'autre section, même en appelant `showTab()` à la main ;
- toutes les images répondent (aucune 404 dans la console) ;
- les trois langues, y compris dans l'onglet des tickets.

## Mise en route des deux services

- Plateforme des tickets (Supabase) : `docs/CLAIMS-SETUP.md`
- Collecteur de retours (Google Apps Script) : `FEEDBACK-SETUP.md`
