# La recherche du guide, tenue par Claude

## Ce qui change

La barre de recherche du hub cherchait des lettres. Un technicien qui tapait
`BW-0159` trouvait sa pièce ; le même technicien qui tapait *l'eau sort tiède*
ne trouvait rien, parce que ces quatre mots ne sont écrits nulle part.

Depuis, la barre porte deux recherches :

* **la recherche mot à mot**, qui répond pendant la frappe. C'est elle qui
  trouve une référence, un nom de produit, un mot exact ;
* **la recherche de Claude**, qui lit tout le guide et répond à la question.
  Elle part sur `Entrée`, ou d'elle-même une seconde et demie après la
  dernière touche.

Ce qu'elle cherche, et dans quel ordre elle le rend :

| Groupe | Ce qu'il porte | Sur quoi il est cherché |
|---|---|---|
| Tutos | Les 73 fiches pas à pas et la bibliothèque | Titre, catégorie et toutes les étapes |
| Cotes & fiches techniques | Les 17 blocs de cotes produit et les 9 fiches techniques | Le produit, ses mesures, et les mots qu'on tape pour les chercher — *dimensions, cotes, encombrement, hauteur…*, en trois langues |
| Sections | Les rubriques du hub | **Leur titre seulement.** Cherchée sur son corps, une rubrique répondait à presque tout : sept rubriques sortaient pour « box 80 » sans rien apprendre à personne |
| Pièces détachées | Les 376 références | Référence, désignation, produit |

Trois choses la rendent moins littérale qu'avant :

* **les accents ne décident plus** — `depannage` trouve *Dépannage*, `maße`
  trouve les cotes ;
* **plusieurs mots valent plusieurs mots** — `dimensions box 80` retrouve les
  deux blocs de cotes du BOX 80, alors qu'aucun texte ne porte cette suite de
  caractères ;
* **les résultats sont classés** — la phrase entière avant les mots pris un à
  un, le titre avant le corps. `hauteur pro 3` sort les cotes du PRO 3 avant
  celles des seize autres produits, qui parlent toutes de hauteur.

Claude rend deux choses : une réponse de deux ou trois phrases, et la liste
des pages à ouvrir — une fiche pas à pas, une rubrique, une pièce détachée —
chacune avec la raison pour laquelle elle est là. Un clic ouvre la page, comme
avant.

Si Claude ne répond pas — clé absente, quota atteint, réseau coupé —, la
recherche mot à mot reste affichée et un message dit ce qui s'est passé. Le
hub ne perd jamais sa recherche.

## Comment c'est fait

Le hub est un site statique : il ne peut pas porter de clé Anthropic, elle
serait lisible par quiconque ouvre la page. Elle est donc posée sur une
fonction edge Supabase, `guide-search`, qui parle à Claude pour lui.

```
navigateur ──► guide-search ──► hub_auth        (le mot de passe du hub)
   │                        ──► hub_search_quota (les questions du jour)
   │                        ──► hub_corpus_get   (le guide, déjà déposé)
   └── empreinte du guide   ──► API Anthropic
```

Le guide pèse environ 137 ko de texte : 14 rubriques, 73 fiches pas à pas,
376 pièces détachées, 17 blocs de cotes et 9 fiches techniques. Le navigateur ne l'envoie pas à chaque question. Il en
calcule l'empreinte (SHA-256) et n'envoie qu'elle ; le serveur retrouve le
texte qu'il a déposé sous cette empreinte. Le guide ne remonte donc qu'une
fois : à la première question posée après une mise en ligne du hub, celle qui
change l'empreinte. Les questions suivantes tiennent en 150 octets.

Côté Anthropic, le guide part marqué pour le cache : d'une question à
l'autre il ne bouge pas, et il est relu à un dixième du prix. La question,
elle, passe après le repère — sinon chaque question ferait un cache neuf.

Trois précautions avant d'appeler Claude :

1. **le mot de passe du hub** — celui de l'écran de garde, que le navigateur
   garde en mémoire. Seule la base sait s'il est bon (`hub_auth`) ;
2. **un quota** de questions par poste et par jour (120 par défaut) ;
3. **les clés rendues par Claude sont vérifiées** contre le guide, des deux
   côtés : une page qui n'existe pas ne s'affiche jamais.

## Ce qu'il faut poser une fois

La fonction est déployée ; il lui manque sa clé.

```bash
supabase secrets set ANTHROPIC_API_KEY=sk-ant-… --project-ref hgjitagsffudcvqwakwk
```

ou, sans la ligne de commande : **Supabase → Edge Functions → guide-search →
Secrets**. Tant que la clé n'est pas là, la fonction répond `config` et le hub
affiche « La recherche par IA n'est pas ouverte sur ce poste ».

Réglages facultatifs, à poser au même endroit :

| Secret | Défaut | À quoi ça sert |
|---|---|---|
| `GUIDE_SEARCH_MODEL` | `claude-opus-5` | Le modèle. `claude-haiku-4-5` répond plus vite et coûte moins ; il lit moins finement. |
| `GUIDE_SEARCH_EFFORT` | `low` | La profondeur de réflexion : `low`, `medium`, `high`. Plus haut = plus lent. |
| `GUIDE_SEARCH_QUOTA` | `120` | Questions par poste et par jour. |

## Les morceaux

| Où | Quoi |
|---|---|
| `supabase/functions/guide-search/index.ts` | La fonction edge : mot de passe, quota, guide, appel à Claude. |
| `docs/supabase/18-recherche-ia.sql` | Les deux tables (`hub.search_corpus`, `hub.search_calls`) et les trois fonctions, réservées à la clé de service. |
| `index.html` — `// ---- global search ----` | Le corpus envoyé, l'appel, l'affichage de la réponse, le repli mot à mot. |

## Si ça ne répond pas

Les journaux de la fonction sont dans **Supabase → Edge Functions →
guide-search → Logs**. Les messages rendus au navigateur :

| Réponse | Ce que ça veut dire |
|---|---|
| `config` | La clé `ANTHROPIC_API_KEY` n'est pas posée. |
| `auth` | Le mot de passe du hub n'a pas été reconnu — l'écran de garde a-t-il bien été passé sur ce poste ? |
| `quota` | Le poste a épuisé ses questions du jour. |
| `amont` | Anthropic ou la base n'a pas répondu ; le détail est dans les journaux. |

À rejouer si le mot de passe du hub change : `docs/supabase/16-…sql`, comme
pour les tickets — la recherche s'appuie sur le même `hub_auth`.
