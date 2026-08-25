# Onglet « Signaler / suggérer » — mise en route

L'onglet est déjà dans le guide. Il ne lui manque qu'une adresse où déposer les
retours. Compter **5 minutes**, une seule fois.

Tant que l'adresse n'est pas renseignée, le formulaire s'affiche normalement mais
répond « Le formulaire n'est pas encore relié à la base de retours » au lieu
d'envoyer.

---

## 1. Créer le classeur

1. Aller sur [sheets.new](https://sheets.new) et nommer le classeur, par exemple
   **Retours — Guide Technicien**.
2. Rien d'autre à faire : l'onglet `Retours` et sa ligne d'en-têtes sont créés
   automatiquement au premier envoi.

## 2. Coller le script

1. Dans le classeur : **Extensions ▸ Apps Script**.
2. Effacer le contenu de `Code.gs`, puis coller l'intégralité de
   [`feedback-apps-script.gs`](feedback-apps-script.gs).
3. Enregistrer (icône disquette).

## 3. Déployer en application web

1. **Déployer ▸ Nouveau déploiement**.
2. Type (roue dentée) : **Application web**.
3. Renseigner :
   - **Exécuter en tant que** : *Moi*
   - **Qui a accès** : **Tout le monde**  ← indispensable, le guide est un site public
4. **Déployer**, puis autoriser l'accès quand Google le demande.
   Google affiche un avertissement « Application non validée » : c'est normal pour
   un script personnel — **Paramètres avancés ▸ Accéder à … (non sécurisé)**.
5. Copier l'**URL de l'application web**. Elle se termine par `/exec`.

> Pour vérifier : ouvrir cette URL dans un navigateur. Elle doit afficher
> `{"ok":true,"service":"bewtr-feedback"}`.

## 4. Brancher le guide

Dans `index.html`, en haut du premier `<script>` :

```js
const FEEDBACK_ENDPOINT = "https://script.google.com/macros/s/AKfy.../exec";
```

Enregistrer, commiter, pousser. C'est tout — le prochain retour envoyé depuis le
guide apparaît dans le classeur.

---

## Options

Trois réglages facultatifs, à modifier des deux côtés quand c'est indiqué.

| Réglage | Où | Effet |
|---|---|---|
| `NOTIFY_EMAIL` | script `.gs` | Envoie un email à chaque nouveau retour. `''` = aucun email. |
| `SHARED_TOKEN` / `FEEDBACK_TOKEN` | script `.gs` **et** `index.html` | Mot de passe partagé qui décourage les envois automatisés. Les deux valeurs doivent être **identiques**. Les deux vides = vérification désactivée. |
| `FEEDBACK_MAILTO` | `index.html` | Adresse de repli. Si l'envoi échoue (technicien hors réseau), le formulaire propose « Envoyer par email à la place » avec un message pré-rempli. `""` = pas de repli. |

## Après une modification du script

Un `.gs` modifié n'est **pas** actif tant qu'il n'est pas redéployé :
**Déployer ▸ Gérer les déploiements ▸ ✏️ ▸ Version : Nouvelle version ▸ Déployer**.
L'URL `/exec`, elle, ne change pas.

---

## Comment les retours voyagent

Le guide envoie en **GET**, avec les données dans l'URL, et c'est `doGet` qui écrit la ligne.

Ce n'est pas un choix esthétique. Apps Script répond par une redirection interne, et une redirection **abandonne le corps d'une requête POST** en route : `doPost` recevait une requête vide et n'avait rien à écrire. Les paramètres d'URL, eux, traversent la redirection intacts.

Conséquence pratique : le message est plafonné à **2000 caractères**, pour que l'URL reste sous les limites de Google. Le champ du formulaire applique la même limite, donc rien n'est tronqué en silence — ce qui est tapé est ce qui part.

`doPost` reste accepté pour compatibilité, mais n'est plus la voie normale.

Si la réponse est illisible à cause du CORS, le guide rejoue l'envoi une fois en `no-cors` : la ligne est bien écrite, seul l'accusé de réception est perdu.

---

## Ce qui arrive dans le classeur

Une ligne par retour, douze colonnes :

| Colonne | Contenu |
|---|---|
| Date | Horodatage de l'envoi |
| Type | `Bug` ou `Suggestion` |
| Section | Section du guide choisie dans la liste |
| Machine | Modèle concerné, s'il est précisé |
| Message | Le retour du technicien |
| Nom / Email | Facultatifs, saisis par le technicien |
| Langue | Langue d'affichage du guide au moment de l'envoi (`fr`, `en`, `de`) |
| Statut | `Nouveau` — colonne prévue pour votre suivi (Traité, Rejeté…) |
| Page / Écran / Navigateur | Contexte technique, utile pour reproduire un bug |

La colonne **Statut** est là pour être éditée à la main : c'est le suivi des
retours. Un filtre sur `Nouveau` donne la liste de ce qui reste à traiter.

## Dépannage

| Symptôme | Cause probable |
|---|---|
| « Le formulaire n'est pas encore relié… » | `FEEDBACK_ENDPOINT` est resté vide dans `index.html`. |
| « Envoi impossible. Vérifiez votre connexion… » | URL incorrecte, déploiement non public (**Qui a accès** ≠ *Tout le monde*), ou technicien réellement hors réseau. |
| Envoi accepté mais aucune ligne | Le déploiement pointe une ancienne version du script — redéployer en *Nouvelle version*. C'est la cause la plus fréquente : modifier le `.gs` ne suffit pas. |
| `{"ok":false,"error":"bad token"}` | `FEEDBACK_TOKEN` et `SHARED_TOKEN` diffèrent. |
