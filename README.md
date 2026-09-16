# Silken Hell

## Lancer sur Mac
Double-cliquer **Jouer à Silken Hell.app** dans le Finder pour reconstruire et ouvrir la version actuelle du projet à chaque clic. **Lancer Silken Hell.command** fait la même chose. Le premier lancement installe le moteur officiel LÖVE 11.5 si nécessaire. Le lanceur met à jour `~/Library/Application Support/Silken Hell/Silken Hell.love`, hors iCloud, pour garder toutes les textures disponibles. Il n'utilise pas l'ancien export web du dossier `game/`.

Le jeu démarre en plein écran. **F11** ou le bouton dans **Paramètres** permet de passer en fenêtre. La largeur réelle du terrain suit celle de l’écran, avec des murs sur ses bords. Le timer et les morts sont accompagnés d’un sablier et d’un crâne ; aucune consigne ne recouvre le bas du terrain.

## Jouer
Saisir un pseudo avant chaque partie. Le pays est détecté automatiquement depuis la connexion Internet par le serveur Cloudflare. Aucun code pays à saisir. Avec un VPN, le pays correspond à sa sortie Internet. Si la connexion est indisponible, on peut jouer et conserver un score local.

Flèches pour se déplacer, Espace pour le dash, Échap pour la pause. Les touches et les volumes se règlent dans Paramètres. F11 et Échap restent réservées. Le bouton en haut à droite remet le monde courant au niveau 1, avec temps et morts à zéro. La pause et la perte de focus arrêtent le chronomètre.

Les dispositions originales du Paradis sont rétablies, sans murs intérieurs. Les niveaux 5, 7, 8 et 9 contiennent un ange porteur : l’attirer dans un piège libère sa larme, qui reste au sol. Des diablotins portent aussi une larme aux niveaux 5 et 7 de l’Enfer. Les cercles indiquent toutes les destinations des larmes ordinaires.

Au niveau 10 du Paradis, **le Merle noir** reste au centre. Ses yeux sont noirs cerclés de jaune. Il lance rapidement des plumes noires mortelles, puis accélère. Les nids ralentissent fortement le joueur ; une plume qui touche un nid se coupe en deux fragments légèrement divergents. Les plumes dorées au sol permettent de blesser le boss en y guidant ses tirs. La larme apparaît après sa défaite.

Au niveau 10 de l’Enfer, **la Guêpe solitaire** alterne vol et repos au sol. En vol, elle survole le joueur, reste invulnérable, tire des dards mortels et invoque de petites guêpes. Au sol, toucher son corps de n’importe quel côté lui retire une vie sans tuer le joueur, même sans sprint. Elle redécolle après le coup ou après quelques secondes. Son venin ralentit trois secondes et colore l’araignée en vert. Ses tirs accélèrent avec les dégâts. Les flaques de lave sont mortelles.

Chaque monde comporte dix niveaux. La progression débloque Paradis → Enfer → Océan → Terre → Ciel. Renaissance (numéro 3) reste réservée. L’Océan contient poissons-lames, méduses électriques et courants ; la Terre contient vers et taupes ; le Ciel contient mouettes, nuages ralentissants et pluie annoncée avant l’impact. Les niveaux finaux des nouveaux mondes utilisent un porteur de larme à attirer dans un piège.

## Menu et histoire
Deux flèches autour de l’araignée permettent de choisir Soie, Perle, Braise, Écume ou Royale ; ce choix est sauvegardé. Le bestiaire enregistre les créatures rencontrées et explique leurs comportements. Un « i » signale les nouvelles découvertes et disparaît à l’ouverture. Le bouton **Histoire** ouvre un écran vide : ajouter le texte dans `story.lua` activera son défilement.

## Classements Cloudflare
- Worker dédié : `silken-hell-api`.
- API : https://silken-hell-api.leafco-dev.workers.dev
- Base D1 dédiée : `silken-hell-scores`.
- Configuration et migrations dans `server/` ; aucun lien avec les ressources GET OUT.

Les classements sont séparés par monde. Le panneau de droite regroupe les pays ; celui de gauche filtre le pays détecté. Les dix meilleurs joueurs sont affichés avec pseudo, chrono, morts et skin utilisé pendant la partie. Un meilleur score par installation est conservé, par temps croissant puis nombre de morts. Les vues sont rafraîchies toutes les trente secondes et à la fin d’un monde.

Chaque partie connectée reçoit un identifiant serveur. Les dix larmes sont déclarées dans l'ordre ; le score n'est publié qu'à la dixième. Le serveur contrôle l'ordre, les compteurs, le format des données, le temps écoulé et les soumissions répétées. Ces contrôles ne remplacent pas un moteur de jeu autoritaire côté serveur et n'empêchent pas toute triche d'un client modifié.

Les requêtes HTTPS s'exécutent dans un thread séparé via le `curl` fourni sur Mac. Une coupure après la création d'une partie met les checkpoints en attente et les conserve pour réessayer, y compris au prochain lancement. Une partie démarrée sans serveur reste locale. Les anciennes parties locales ne sont pas publiées rétroactivement.

Seuls le pseudo, le code pays, le monde, le temps, les morts et une empreinte de l'identité anonyme du jeu sont stockés dans D1. L'application ne stocke pas l'adresse IP dans D1. Le service utilise l'IP transmise à Cloudflare pour le pays et la limitation des requêtes. Les parties abandonnées sont nettoyées après deux jours ; les scores terminés sont conservés.

## Sauvegarde
LÖVE sauvegarde réglages, déblocages, scores locaux, identité anonyme et envois en attente dans `~/Library/Application Support/LOVE/silken-hell`. L'identité anonyme permet d'associer les meilleurs scores à cette installation ; elle n'est pas partagée avec GET OUT.

## Développement et tests
- `love .` : lancer les sources (elles doivent être disponibles localement si le dossier est dans iCloud).
- `make package` : produire `game.love` à partir des sources et assets.
- `SILKEN_TEST=1 love game.love` : tests isolés de la progression, de la sauvegarde, des écrans et du terrain.
- `cd server && npm test` : tests API avec une base SQLite éphémère.
- `cd server && npx wrangler deploy` : déployer uniquement le Worker Silken Hell.

`SILKEN_ONLINE_TEST=1` active un test HTTPS réel avec une identité de sauvegarde isolée. Il crée un score `SilkenGameQA` ; le run ID est sauvegardé dans le dossier de test pour permettre son nettoyage ciblé après validation.

## Ajustements de l’Enfer et vues directionnelles

Les murs et les dispositions de l’Enfer sont rétablis. Le premier côté des larmes ordinaires varie entre les niveaux ; une mort conserve ce choix. La charge des goules dure deux secondes. Les serpents se déplacent indépendamment de la position du joueur et rebondissent sur les murs en tournant sur eux-mêmes. Les roues tournent au bout d’une chaîne autour d’un pivot, avec une collision sur leur tête mobile. Les larmes sont toujours dessinées derrière les monstres. En Enfer, les larmes et les effets sont rouges. Les ennemis du Paradis sont accélérés de 8 %.

Les nouveaux personnages utilisent quatre PNG distincts (face, dos, gauche, droite), dans `assets/sprites/directional/`. La guêpe possède quatre vues en vol et quatre au sol. Les petites guêpes réutilisent les vues en vol. L’araignée originale conserve ses quatre textures d’origine.

`SILKEN_TEST=1 SILKEN_ASSET_QA=1 love .` vérifie l’alpha et affiche une planche des 24 vues.
