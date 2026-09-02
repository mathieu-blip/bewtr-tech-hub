# L'agent qui suit le portail

Le hub reprend le guide technique du portail technicien. Jusqu'ici, ce report se
faisait à la main. `.github/workflows/portal-sync.yml` le fait maintenant tous
les matins, à 6 h 15 UTC — 8 h 15 à Paris l'été, 7 h 15 l'hiver.

## Ce qu'il fait

1. Il lit les quatre canaux du portail sur `tec-data` : `guide`, `planning`,
   `fleet`, `suggestions`.
2. Il remet les photos à leur place : le portail ne garde en ligne qu'une
   empreinte, le dépôt veut le chemin du fichier (`img/0123.webp`).
3. Il compare le tout à `docs/portal-snapshot/`, la copie de référence.
4. S'il n'y a rien de neuf, il s'arrête là, sans bruit.
5. Sinon il enregistre la nouvelle copie, rapatrie les photos qui manquent,
   recompose la constante `PORTAL_GUIDE` d'`index.html`, ouvre une proposition
   sur la branche `portal-sync` et envoie un courrier à mathieu@bewtr.com.

Rien ne part en ligne tout seul : c'est la fusion de la proposition qui met le
hub à jour.

## Ce qu'il ne fera jamais tout seul

Le script sait refaire `PORTAL_GUIDE`, rien d'autre. Avant d'écrire dans
`index.html`, il recompose la constante à partir de l'**ancienne** copie et
vérifie qu'elle est mot pour mot celle que la page contient déjà. Si ce n'est
pas le cas — parce que la page a été retouchée à la main depuis — il laisse
`index.html` tranquille et le dit dans son compte rendu : le report est alors à
refaire à la main, sinon les retouches seraient perdues.

Il prévient aussi, sans y toucher, quand :

- une **catégorie apparaît ou disparaît** : le hub décide où l'afficher dans la
  constante `GUIDE_PLACEMENT`, juste sous `PORTAL_GUIDE`, et cela ne se devine
  pas ;
- une **rubrique nouvelle** arrive dans le guide du portail — le glossaire, par
  exemple : il n'y a pas encore de bout de page pour l'afficher ;
- de **nouveaux textes d'interface** apparaissent.

La branche `portal-sync` est refaite chaque matin depuis `main`. Il ne faut donc
rien y ajouter à la main : si le script y trouve un commit qui n'est pas le
sien, il ne la touche plus et le signale, le temps que la proposition en cours
soit fusionnée ou fermée.

## Ce qu'il faut autoriser une fois

Dans **Settings → Actions → General** du dépôt :

- **Workflow permissions** : « Read and write permissions », sans quoi l'agent
  ne peut pas déposer sa branche ;
- **Allow GitHub Actions to create and approve pull requests** : coché, sans
  quoi il dépose la branche mais n'ouvre pas la proposition.

## Le courrier

Le workflow envoie le compte rendu par SMTP, avec `tools/portal-sync/send_mail.py`.
Il faut lui donner un compte d'envoi, dans **Settings → Secrets and variables →
Actions** du dépôt :

| Secret | Ce que c'est |
| --- | --- |
| `MAIL_HOST` | le serveur d'envoi, `smtp.gmail.com` par exemple |
| `MAIL_PORT` | son port ; 465 par défaut, en SSL |
| `MAIL_USER` | le compte qui envoie |
| `MAIL_PASSWORD` | son mot de passe d'application |
| `MAIL_FROM` | l'expéditeur affiché, si différent de `MAIL_USER` |

Le destinataire est `mathieu@bewtr.com` ; pour en changer, poser une *variable*
(pas un secret) nommée `MAIL_TO`, plusieurs adresses séparées par des virgules.

Tant que ces réglages manquent, tout le reste fonctionne : la proposition est
ouverte, seul le courrier est sauté.

## À la main

```sh
python3 tools/portal-sync/sync.py --check   # regarde et raconte, sans rien écrire
python3 tools/portal-sync/sync.py           # met le dépôt à jour
python3 tools/portal-sync/test_build.py     # le hub est-il refaisable à l'identique ?
```

`test_build.py` est le filet : tant qu'il passe, la mise à jour automatique ne
peut rien effacer. S'il échoue, c'est qu'`index.html` et l'instantané ont
divergé, et il faut les remettre d'accord avant de laisser l'agent écrire.

Le workflow se lance aussi à la demande, depuis l'onglet **Actions** du dépôt.
