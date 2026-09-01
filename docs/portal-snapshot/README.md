# Instantané des données du portail technicien

Le portail `tec-portal.tec-bewtr.workers.dev` ne garde plus son contenu dans le
fichier déposé : il le lit et l'enregistre sur un second service Cloudflare,
`tec-data`. Les fichiers de ce dossier en sont une copie, prise le
**1er septembre 2026**, qui sert de référence au hub.

## Les canaux

| Fichier | Canal | Contenu |
| --- | --- | --- |
| `guide.json` | `/state/guide` | Le guide complet en fr / en / de : 22 catégories, 76 fiches, l'outillage et le matériel |
| `planning.json` | `/state/planning` | Planning des congés 2025 → 2028, les techniciens, les codes d'absence |
| `fleet.json` | `/state/fleet` | Parc véhicules 2024 → 2027 : kilométrages mensuels et notes |
| `suggestions.json` | `/state/suggestions` | Les retours envoyés depuis le portail |

Les canaux `tickets`, `claims` et `stock` répondent `{"rev":0,"data":null}` :
ils n'ont jamais été alimentés.

## Reprendre une copie fraîche

```sh
for n in guide planning fleet suggestions; do
  curl -s "https://tec-data.tec-bewtr.workers.dev/state/$n" -o "$n.json"
done
```

Chaque réponse a la forme `{"rev":…, "at":…, "data":{…}}` : `rev` monte d'un cran
à chaque enregistrement, `at` est la date du dernier.

## Les photos

Pour ne pas renvoyer les images à chaque enregistrement, le portail ne stocke
en ligne qu'une **empreinte** à leur place, de la forme
`##<longueur>|<24 premiers caractères>|<16 derniers>`. Les images elles-mêmes
sont les fichiers `img/NNNN.jpg|webp` du portail, et la table de correspondance
est la constante `IMG_REFS` de sa page :

```sh
curl -s https://tec-portal.tec-bewtr.workers.dev/ -o portal.html
# IMG_REFS[i] est l'empreinte de l'image IMGS[i]
```

Les fichiers de ce dossier ont déjà les empreintes remplacées par le chemin de
l'image (`img/0123.webp`). Les photos utilisées par les tutos d'installation du
hub ont été copiées dans le dossier `img/` du dépôt ; les quelques images
ajoutées après la mise en ligne du portail, encore stockées en clair dans le
canal, sont devenues `img/inline-*.jpg`.

## Ce que le hub en reprend

La constante `INSTALL_TUTOS` de `index.html` reprend la catégorie
**Installation** de `guide.json` : 13 produits, leur outillage, leur matériel,
chaque étape avec ses photos, la vidéo et les schémas, dans les trois langues.
Les autres catégories du guide ne sont pas reprises pour l'instant.
