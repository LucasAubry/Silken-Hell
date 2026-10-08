# Préparation du Workshop Steam

Le Workshop en jeu utilise encore l’API HTTP Silken Hell. Ses étoiles sont des
votes positifs : une installation peut ajouter ou retirer une étoile par carte.
Ce ne sont ni des niveaux de difficulté, ni encore des votes de comptes Steam.

L’éditeur s’ouvre sur une bibliothèque de projets persistants. Il permet de partir
d’une carte vide, de copier une carte existante ou de créer dix niveaux vides.
Chaque projet possède un identifiant stable et ses propres cartes, sauvegardées
automatiquement et par **Enregistrer** dans `creator-project-<id>.json`. L’index
`creator-projects.json` permet de reprendre les travaux après fermeture. Les anciens
brouillons Workshop sont importés sans modifier leurs fichiers sources.
Les niveaux de campagne restent accessibles par **Niveaux dev**, hors de la
bibliothèque de projets. **Appliquer au jeu** enregistre leurs modifications dans
les niveaux actuels du jeu ; leurs brouillons sont conservés séparément.

**Publier un niveau**, dans l’éditeur, ouvre le nom, le pseudo et la difficulté du
niveau courant. **Terminer pour valider** lance une partie isolée dans le jeu. La
preuve de réussite est conservée par projet et niveau, avec l’empreinte exacte du
contenu et de la version du jeu. **Publier** utilise ensuite l’API Workshop existante ;
les erreurs remontent dans l’éditeur. Toute modification du contenu ou de la
difficulté exige une nouvelle validation. Une copie reçoit son propre identifiant.
Le menu Workshop du jeu propose **Créer une carte**, sans bouton de publication.

Dans la publication, **Préparer pour Steam** exporte une carte dont la version
actuelle a été terminée, puis ouvre le dossier `steam-workshop/<sha256>` dans les
sauvegardes du jeu. Aucun contenu n’est envoyé à Steam par ce bouton.

- `content/map.json` contient le niveau validé par `LayoutSchema`.
- `manifest.json` contient notre format versionné `silken-hell-map`, le titre,
  l’auteur, le biome, la difficulté, les tags stables et l’empreinte du niveau.
  C’est un format propre au jeu, pas un fichier SteamCMD.
- Le dossier `content` constitue le contenu à transférer avec `SetItemContent`.
  Les titres, tags et autres métadonnées se règlent séparément via Steam UGC.

## À raccorder dès que l’App ID et le SDK sont disponibles

1. Activer/configurer le Workshop dans Steamworks et intégrer une liaison native
   LÖVE/Lua vers le SDK pour chaque système distribué. Initialiser Steam et traiter
   ses callbacks régulièrement ; garder le service HTTP si Steam est indisponible.
2. Relier création et mise à jour à `CreateItem`, `StartItemUpdate`,
   `SetItemTitle`, `SetItemTags`, `SetItemContent`, puis `SubmitItemUpdate`.
   Afficher les échecs et l’accord légal Workshop lorsque Steam le demande.
   Conserver les `PublishedFileId_t` et Steam IDs en **chaînes**, jamais en nombres
   Lua, pour éviter une perte de précision. Garder les IDs HTTP séparés.
3. Relier les listes et filtres aux requêtes UGC ; les étoiles deviennent le
   nombre de votes positifs Steam, avec `SetUserItemVote` / `GetUserItemVote`.
4. Gérer abonnements et téléchargements avant de jouer ; lire les cartes comme
   des données JSON, les valider avec `LayoutSchema`, puis `Workshop.playLayout`.
   Ne jamais exécuter de code fourni par une carte téléchargée.
5. Tester publication, mise à jour, téléchargement et vote avec deux comptes
   autorisés sur l’App ID réel, puis les versions Windows/Linux/macOS livrées.

L’éditeur est intégré aux trois paquets desktop. Leur configuration SteamPipe
est décrite dans [STEAM-DISTRIBUTION.md](STEAM-DISTRIBUTION.md).

Références : [guide Workshop](https://partner.steamgames.com/doc/features/workshop/implementation),
[API UGC](https://partner.steamgames.com/doc/api/isteamugc),
[initialisation du SDK](https://partner.steamgames.com/doc/sdk/api).
