# Silken Hell

## Lancer sur Mac
Double-cliquer **Jouer à Silken Hell.app** dans le Finder pour reconstruire et ouvrir la version actuelle du projet à chaque clic. **Lancer Silken Hell.command** fait la même chose. Le premier lancement installe le moteur officiel LÖVE 11.5 si nécessaire. Le lanceur met à jour `~/Library/Application Support/Silken Hell/Silken Hell.love`, hors iCloud, pour garder toutes les textures disponibles. Il n'utilise pas l'ancien export web du dossier `game/`.

Le jeu démarre en plein écran. **F11** ou le bouton dans **Paramètres** permet de passer en fenêtre. La largeur réelle du terrain suit celle de l’écran, avec des murs sur ses bords. Le timer et les morts sont accompagnés d’un sablier et d’un crâne ; aucune consigne ne recouvre le bas du terrain.

## Jouer
Saisir un pseudo avant chaque partie. Le pays est détecté automatiquement depuis la connexion Internet par le serveur Cloudflare. Aucun code pays à saisir. Avec un VPN, le pays correspond à sa sortie Internet. Si la connexion est indisponible, on peut jouer et conserver un score local.

Flèches pour se déplacer, Espace pour le dash, Échap pour la pause. Le dash nécessite une touche de déplacement : seul, il ne déclenche aucun mouvement ni traînée. Les touches et les volumes se règlent dans Paramètres. F11 et Échap restent réservées. Le bouton en haut à droite remet le monde courant au niveau 1, avec temps et morts à zéro. La pause et la perte de focus arrêtent le chronomètre et l’oxygène.

Le Paradis conserve ses dispositions sans murs intérieurs. Les niveaux 8 et 9 sont complétés : anges, serpents, lames tournantes et pièges forment deux épreuves distinctes avant le Merle. Les niveaux 5, 7, 8 et 9 contiennent un ange porteur : l’attirer dans un piège libère sa larme, qui reste au sol. Les cercles indiquent toutes les destinations des larmes ordinaires.

Au niveau 10 du Paradis, **le Merle noir** reste au centre. Ses yeux sont noirs cerclés de jaune. Il tire des plumes noires en continu ; sa cadence accélère tous les deux PV perdus. À quatre PV ou moins, il tire trois plumes en largeur. Les nids éloignés ralentissent le joueur et divisent les tirs. Un seul nid contient un œuf : guider une plume sur cet œuf retire une vie au boss, invoque un petit merle qui tourne autour du nid natal et fait apparaître un œuf dans un autre nid. La larme apparaît après sa défaite.

Au niveau 10 de l’Enfer, **le Serpent des mues** rampe, se roule en boule en tournant, puis se déplie pour charger. Après la charge, son contour doré indique une ouverture : le toucher retire un PV sans tuer le joueur. À cinq PV, il mue et devient violet/vert. Sa peau abandonnée reste au sol et immobilise pendant 1,5 seconde. Sa seconde forme crache du poison et charge plus vite ; les flaques mortelles rétrécissent puis disparaissent en sept secondes. La défaite libère la larme.

Les six biomes jouables comportent chacun dix niveaux. Ordre : **Paradis → Ciel → Terre → Océan → Abysse → Enfer → Renaissance**. Renaissance est réservée. Les identifiants internes des anciens mondes restent stables pour conserver les scores. Les anciennes sauvegardes migrent vers une progression par position dans cet ordre, en préservant les mondes déjà accessibles.

- **Océan** : poissons-lames en bancs et méduses électriques. Une réserve d’oxygène de cinq secondes est affichée au-dessus de l’araignée. De petites bulles la remplissent puis se rechargent en trois secondes. Elles sont placées à distance de toutes les positions de larmes ; une bulle se décale si une larme est déposée dessus. À zéro, l’araignée meurt. Le niveau 10 accueille le **Poulpe des marées** : tentacules toujours dépliés, inversions fréquentes et accélération plafonnée sous la vitesse du dash. La tête suit le joueur, qui commence devant lui. Les jets d’encre visent le joueur et couvrent presque tout l’écran pendant quatre secondes. Il libère des crabes aux pinces animées : ils marchent de côté au hasard. Chaque crabe touchant un tentacule retire un des huit PV, se retourne sur le dos puis s’enfonce dans le sol. Toucher directement le poulpe ne le blesse pas.
- **Abysse** : dix niveaux plongés dans une obscurité presque totale, avec de vrais poissons-lanternes qui éclairent localement le décor et 150 minuscules lueurs bleues errantes qui disparaissent au contact. L’oxygène fonctionne comme dans l’Océan. Les larmes sont récupérables au sol. Les évents annoncent des éruptions mortelles.
- **Terre** : vers ondulant en zigzag, poursuivant le joueur et signalés par une minuscule ombre sous terre, puis crachant des œufs. Un œuf heurtant un mur libère trois petits vers de 26 pixels. Les taupes disparaissent sous terre ; une motte annonce leur remontée. Deux animations distinctes montrent leur sortie et leur enfouissement avec des projections de terre.
- **Ciel** : sol de nuages, rebords et trous irréguliers mortels avec animation de chute. Les collisions suivent les contours des trous. Des averses denses frappent des positions fixes, annoncées par une ombre au sol. Le vent pousse le joueur et les monstres avec des directions changeantes, des rafales de force variable et des accalmies. Les mouettes suivent des courbes aléatoires légèrement attirées vers le joueur et tournent avant les bords.

Le bestiaire sépare les **Créatures**, les **Boss** et les **Pièges**. Les petites guêpes invoquées possèdent quatre nouveaux sprites cuivrés aux yeux verts, distincts du boss (prompts dans `assets/waspling-prompts.md`).

## Menu et histoire
Deux flèches autour de l’araignée permettent de choisir Soie, Perle, Braise, Écume ou Royale ; ce choix est sauvegardé. Le bestiaire enregistre les créatures rencontrées et explique leurs comportements. Un « i » signale les nouvelles découvertes et disparaît à l’ouverture. Le bouton **Histoire** ouvre un écran vide : ajouter le texte dans `story.lua` activera son défilement.

## Classements Cloudflare
- Worker dédié : `silken-hell-api`.
- API : https://silken-hell-api.leafco-dev.workers.dev
- Base D1 dédiée : `silken-hell-scores`.
- Configuration et migrations dans `server/` ; aucun lien avec les ressources GET OUT.

Les classements sont séparés par monde. Le panneau de droite regroupe les pays ; celui de gauche filtre le pays détecté. Les dix meilleurs joueurs sont affichés avec pseudo, chrono, morts et skin utilisé pendant la partie. Cliquer sur un panneau ouvre tous les joueurs, par pages de dix. Le meilleur score de chaque pseudo est retenu, même sur plusieurs installations : plusieurs pseudos joués sur le même PC restent visibles. Le tri utilise le chrono puis les morts. Les vues sont rafraîchies toutes les trente secondes et à la fin d’un monde.

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

Les murs et les dispositions de l’Enfer sont rétablis. Le premier côté des larmes ordinaires varie entre les niveaux ; une mort conserve ce choix. La charge des goules dure trois secondes. Les serpents se déplacent indépendamment de la position du joueur et rebondissent sur les murs en tournant sur eux-mêmes. Les roues tournent au bout d’une chaîne autour d’un pivot, avec une collision sur leur tête mobile. Les larmes sont toujours dessinées derrière les monstres. En Enfer, les larmes et les effets sont rouges. Les ennemis du Paradis sont accélérés de 8 %.

Les nouveaux personnages utilisent quatre PNG distincts (face, dos, gauche, droite), dans `assets/sprites/directional/`. La guêpe possède quatre vues en vol et quatre au sol. Elle redécolle depuis sa position courante et approche progressivement son point d’atterrissage. Les petites guêpes possèdent leurs propres vues et restent jusqu’à la fin du niveau, même après la mort du boss. L’araignée originale conserve ses quatre textures d’origine.

Le niveau 10 de Terre accueille le **Hérisson des profondeurs** : 10 PV, seize piques par salve debout, puis neuf séries de 1 à 9 rebonds en boule. Une série achevée retire un PV ; le neuvième impact de la dernière série est fatal (les deux PV restants). Le nombre de taupes suit les PV perdus : 0 à 10 PV, 2 à 9 PV, 4 à 8 PV, etc. Les pauses durent 1,15 seconde après chaque série et les rebonds vont de 480 à 656 pixels par seconde. Les rebonds n’ajoutent aucune taupe supplémentaire. La larme apparaît à sa mort. Les huit PNG et leurs prompts imagegen sont dans `assets/sprites/directional/hedgehog*.png` et `assets/hedgehog-prompts.md`. Les huit PNG du poulpe sont conservés, mais le combat utilise maintenant uniquement la forme dépliée, avec la tête et les tentacules animés séparément. Ses collisions suivent la silhouette transparente des tentacules et leur rotation. L’encre utilise un vrai sprite de projection irrégulière. Prompts de la refonte : `assets/marine-revision-prompts.md`.

`SILKEN_TEST=1 SILKEN_ASSET_QA=1 love .` vérifie l’alpha et affiche une planche des 24 vues.

## Pièges et passages
Les captures et les roues restent uniquement au Paradis. Les porteurs des autres mondes sont remplacés par des larmes ordinaires, afin que chaque niveau reste terminable. La lave et les attaques des monstres restent dangereuses.

Dans le Ciel, le PNG du tourbillon forme une tornade animée. Elle fait tourner le joueur pendant 0,65 seconde, puis le projette brièvement sur le côté, perpendiculairement à sa direction d’arrivée. En Terre, chaque niveau contient deux tunnels PNG reliés. Le joueur et les monstres y entrent et en sortent avec une animation de 0,44 seconde. Une fois téléporté, il faut quitter la sortie avant de pouvoir revenir, ce qui évite les boucles. Le placement respecte les murs et les points des larmes. Les taupes sont 40 % plus rapides au sol et sous terre, y compris celles invoquées par le hérisson.

## Terrain et Serpent des mues

La Terre contient davantage de murs. Leur placement réserve les empreintes des captures, roues, lave, points de larmes et départ ; les murs sont déplacés ou omis lorsqu’ils se chevaucheraient. Les ennemis poursuivants calculent un chemin autour des murs et de la lave. Les pièges restent traversables afin de les capturer. Le graphe de navigation est partagé et mis en cache par taille de monstre. Les cercles de larmes font 70 pixels visibles (sans les marges transparentes de la texture) dans tous les mondes ; ils sont masqués pendant les niveaux de boss.

Le serpent utilise 28 PNG directionnels : ramper, boule et charge dans chaque forme, plus le crachat en seconde forme. Une image supplémentaire représente la mue. Les images sont créées avec imagegen ; les prompts sont dans `assets/hell-serpent-prompts.md`. L’ancienne guêpe reste disponible dans le code et dans les découvertes du bestiaire, mais n’est plus le boss de l’Enfer.

Le Merle noir tire à nouveau en continu : la pause de 1,5 seconde après dix plumes est supprimée. Le hérisson lance seize piques par salve. PNG du tunnel : `assets/sprites/earth_tunnel.png` ; prompt : `assets/earth-tunnel-prompt.md`.

Sprites des crabes : `assets/sprites/crab_open.png`, `crab_closed.png`, `crab_dead.png`. Générés avec imagegen intégré ; prompts dans `assets/crab-prompts.md`. Vérifications spécifiques : `tests/octopus_revision.lua`.
