# Silken Hell

Jeu d’esquive en Lua avec LÖVE 11.5, éditeur de niveaux et classements/Workshop Cloudflare dédiés.

## Lancer le jeu

Double-cliquer **Jouer à Silken Hell.app** ou **Lancer Silken Hell.command**. Le lanceur utilise l’archive locale publiée et installe LÖVE au premier lancement si nécessaire. Pour publier des modifications des sources, exécuter `python3 tools/package.py`. Le cache se trouve dans `~/Library/Application Support/Silken Hell/Silken Hell.love`.

Flèches pour se déplacer à pleine vitesse, maintenir Espace pour ralentir, Échap pour la pause. Touches et volumes se règlent dans les paramètres ; F11 gère le plein écran. Le bouton de recommencement remet le monde courant au niveau 1. Le jeu se met en pause lorsqu’il perd le focus.

## Mondes et boss

Ordre : **Paradis → Ciel → Terre → Océan → Abysse → Enfer → Renaissance**. Les six premiers mondes ont dix niveaux ; Renaissance enchaîne leurs six boss, dans cet ordre, avec une ambiance rouge, noire et blanche.

- **Paradis** : anges, serpents, captures et roues. Attirer un porteur de larme dans un piège la libère. Le Merle noir reste au centre et tire des plumes en continu. Guider ses plumes vers l’œuf d’un nid le blesse ; ses salves s’accélèrent et deviennent triples à quatre PV.
- **Ciel** : vent variable, trous et rebords mortels, tornades, pluie et foudre. Les mouettes électrifiées deviennent jaunes et laissent une traînée dangereuse. Boss : le Merle noir des orages ; les plumes jaunes récupérées se retournent contre lui.
- **Terre** : tunnels empruntables par le joueur et les monstres, vers et taupes. Le Hérisson a sept PV, quatorze piques par salve, deux rebonds et cinq taupes au maximum. Il est étourdi lorsqu’il perd une vie.
- **Océan** : poissons-lames, méduses et crabes. Le Poulpe lance des crabes et de l’encre. Les crabes noirs errent et peuvent être propulsés en fonçant dessus. Un impact de crabe sur un tentacule étourdit le boss trois secondes : attraper une extrémité puis la tirer dans un coin arrache le bras et retire une vie. À quatre PV, le boss accélère et lance une rafale d’encre. Les flaques durent sept secondes.
- **Abysse** : obscurité, lueurs bleues, poissons-lanternes et pieuvres lumineuses. Les fils bleus chargent l’araignée sans la tuer. Les poissons la poursuivent lorsqu’elle est éclairée. La queue du Léviathan apparaît au niveau 8, ses os au niveau 9 et sa tête au niveau 10. Entrer chargé dans sa bouche pendant l’aspiration lui retire une vie lorsqu’il recrache le joueur. Les cercles éclairent uniquement lorsqu’on reste dessus. Aucun oxygène à gérer.
- **Enfer** : lave, goules, serpents indépendants et nids de larves. Les nids sont inoffensifs au contact ; leurs larves poursuivent et explosent sans laisser de flaque. Les monstres traversent la lave, brûlent et laissent des traînées mortelles. Boss : **Les Trois Sœurs de braise**, trois abeilles à trois PV chacune. Elles chargent en séquence ; elles peuvent être touchées pendant leur KO après un impact contre un mur. Chaque élimination accélère les survivantes. Seule la dernière invoque des mini-abeilles. Les lacs annoncent des éruptions de braises.

La lumière diminue progressivement au fil des mondes et des niveaux. La foudre ambiante est réservée au Ciel ; les attaques électriques des créatures conservent leurs mécaniques.

## Menu, sauvegardes et classements

Le menu suit l’ambiance du monde sélectionné. Cinq skins : Soie, Perle, Braise, Écume et Royale. Le bestiaire enregistre les découvertes, avec catégories Créatures, Boss et Pièges. L’histoire reste à écrire. Les succès affichent leur condition et leur état, avec les filtres Tous, À faire et Obtenus.

Un pseudo est demandé avant la partie. Cloudflare détecte le pays de la connexion ; avec un VPN, il s’agit du pays de sortie. Les panneaux affichent les dix meilleurs scores mondiaux et nationaux, avec chrono, morts et skin. Un clic ouvre tous les scores paginés. Le meilleur score par pseudo est conservé.

Le classement et le chronomètre final incluent **une seconde pour trois morts (⅓ de seconde par mort)**. Le temps brut reste enregistré séparément pour éviter toute double pénalité. Renaissance utilise un seul chrono pour ses six combats.

Les réglages, découvertes, déblocages et scores locaux sont dans `~/Library/Application Support/LOVE/silken-hell`. Les scores démarrés hors ligne restent locaux. Une partie connectée interrompue peut reprendre ses envois en attente.

## Éditeur et Workshop

**Concepteur Silken Hell.app**, **Lancer le concepteur.command** ou le bouton **Créer** ouvrent l’éditeur. Il importe les 66 niveaux et permet de mélanger créatures, boss, décors et biomes. Les propriétés incluent les vitesses de déplacement et d’attaque des boss ainsi que le délai et l’intervalle des nids de larves.

**Appliquer** enregistre les niveaux personnalisés ; les aperçus rechargent leurs données sans redémarrage. Le Workshop permet de publier une carte, de jouer aux cartes partagées et de leur attribuer une étoile.

Les fichiers `custom_levels.json` et `designer/default_levels.json` sont des données utiles : ne pas les supprimer lors d’un nettoyage.

## Développement et vérification

- `love .` : jouer depuis les sources.
- `make package` : construire `dist/game.love`, y compris l’éditeur intégré.
- `python3 tools/build_icons.py` : reconstruire les deux icônes macOS avec l’araignée marron actuelle, le même cadre et les mêmes marges, puis signer et actualiser les lanceurs. Relancer ensuite `python3 tools/package.py` pour le jeu et l’éditeur embarqués.
- `SILKEN_TEST=1 love dist/game.love` : tests isolés du jeu.
- `SILKEN_DESIGNER_TEST=1 SILKEN_PROJECT="$PWD" love designer` : tests de l’éditeur.
- `cd server && npm test` : tests API et Workshop.

Les tests utilisent des sauvegardes séparées. `SILKEN_ONLINE_TEST=1` active un test réel de l’API qui crée un score `SilkenGameQA` à nettoyer après validation.

## Serveur

Worker : `silken-hell-api`. Base D1 : `silken-hell-scores`. API : https://silken-hell-api.leafco-dev.workers.dev

La configuration, les migrations et les instructions sont dans `server/`. Ces ressources sont indépendantes de GET OUT. `npm run deploy` depuis `server/` déploie le Worker ; un push Git ne déclenche pas cette commande.

Le serveur vérifie l’ordre des niveaux, les compteurs, le temps et les soumissions répétées. Le moteur reste côté client : ces contrôles ne garantissent pas l’absence de triche.

## Organisation et assets

- `src/` : modules du jeu, comportements dans `src/mobs/`, niveaux dans `src/levels/`.
- `assets/` : ressources actives, avec images par biome dans `monstres/`, skins dans `skins/`, décors dans `environments/`, textures dans `textures/`, sons dans `audio/`, shaders dans `shaders/` et polices dans `fonts/`.
- `assets/art-metadata.json` : limites alpha et masques précalculés.
- `docs/` : notes de développement et besoins audio ; `docs/art/` conserve les prompts des images pour les reproduire.
- `designer/`, `server/`, `tests/`, `tools/` : éditeur, API, vérifications et empaquetage.
- `dist/game.love` : archive générée par `make package`, utilisée par les lanceurs.
- `output/` : créations locales conservées (vidéos, sources graphiques et leurs outils), exclues du jeu et de Git.

Seuls les points d’entrée LÖVE (`main.lua`, `conf.lua`), les lanceurs, le `Makefile`, ce guide et les niveaux personnalisés restent à la racine. Les noms des modules Lua restent stables grâce au chemin de recherche `src/` ; `src/asset_paths.lua` résout les anciens noms des images encore utilisés par les chargeurs dynamiques.

Les anciennes archives numérotées, copies de travail et captures de vérification ont été retirées. Les fichiers générés, métadonnées Finder et caches ne sont pas versionnés. Conserver `custom_levels.json` et `designer/default_levels.json`, qui contiennent les niveaux éditables.

Après un déplacement de fichiers, lancer `make package`, puis `SILKEN_TEST=1 SILKEN_ORGANIZATION_TEST=1 love dist/game.love` pour vérifier les ressources, les modules, les boss, les skins et le chargement du thread réseau sans requête externe.

## Manettes et Steam

Les manettes reconnues par SDL/LÖVE sont détectées au démarrage et lors du branchement. La dernière manette utilisée devient active. Stick gauche ou croix : déplacement ; A (bouton du bas), gâchettes ou boutons d’épaule : ralentir ; Start : pause ; B : retour. Les menus disposent d’un focus visible et la saisie du pseudo d’un clavier à l’écran. Débrancher la manette active met le combat en pause. Une zone morte évite la dérive du stick.

La prise en charge utilise le gamepad standard, qui peut être émulé par Steam Input. Pour la publication Steam, configurer un modèle de contrôleur Gamepad par défaut dans Steamworks puis tester chaque plateforme avec une vraie manette et Steam Deck. Il ne s’agit pas d’une intégration de l’API native Steam Input, et la configuration du partenaire Steam n’est pas effectuée par ce dépôt. Documentation : https://partner.steamgames.com/doc/features/steam_controller/steam_input_gamepad_emulation_bestpractices?language=english

## Le Sanctuaire et succès

Le Sanctuaire est le huitième choix de monde, accessible après avoir terminé les sept mondes. En mode normal, on parcourt horizontalement une galerie de trônes pour choisir un boss ou une créature. En mode hardcore, on enchaîne les sept boss, du Paradis à Renaissance. Chaque mort ramène au boss précédent, avec un minimum au premier ; le chrono et les morts restent cumulés sur tout le parcours.

Maxance : terminer le Paradis avec au moins 95 morts et un temps final au moins égal à son record (552,732 secondes brutes + 95/3 secondes de pénalité, affiché 9:44.40). Les anciens déblocages sont réévalués à partir des scores sauvegardés.

### Révision du Sanctuaire

Sélectionner le Sanctuaire dans les mondes, puis cliquer sur Jouer. La salle normale propose sept boss et toutes les créatures du catalogue ; les rencontres de créatures sont des survies de 20 secondes contre un seul adversaire. La branche hardcore lance directement le parcours des boss après la saisie du pseudo. Devant un trône, appuyer vers le haut ouvre une confirmation avec le nom de l’adversaire. « Oui » lance un décompte 3–2–1 pendant lequel le combat et le chrono restent figés. À la manette, Y change la catégorie, les boutons d’épaule passent au trône voisin, gauche/droite choisissent Oui/Non et A confirme.

Les Guêpes retrouvent leur délai court (0,20 s, puis 0,18 s au rebond, modulés par leur cadence) et restent immobiles dès leur arrivée au mur. La Gardienne a 13 vies : chaque bébé écrasé lui coûte une vie et chaque œuf touché prend un cran par dash. Le boss des Abysses retrouve ses traversées, volées d’os, aspiration et expiration. Le système de charges lumineuses est retiré : l’aspiration est suivie d’une expulsion sans dégâts. Il entre sur le côté à mi-hauteur et accélère en poursuivant le joueur. Les bombes explosent au contact du joueur ou lorsqu’il les avale (un dégât au boss). Pendant la poursuite, il tire ses côtes vers le joueur à 640 pixels par seconde toutes les 1,2 seconde : côté supérieur ou inférieur selon la position du joueur, les deux côtés simultanément si le joueur est devant sa tête. Les os lancés restent manquants tant qu’ils ne sont pas récupérés. Les côtes épuisées, il lance sa queue puis ses vertèbres, jusqu’à ne conserver que sa tête. Les os retombés restent dans l’arène ; ceux qui le touchent se plantent au point d’impact et peuvent être relancés. L’aspiration remet chaque os récupéré à sa place d’origine. Son corps horizontal lance ses côtes depuis le haut de l’arène ; la tête ne tire plus d’éclairs. Deux os visent le joueur toutes les 1,05 seconde à 680 pixels par seconde. La vitesse dépend uniquement de la quantité d’os restante : de 190 pixels par seconde avec tout le squelette à 105 % de la vitesse maximale du joueur lorsqu’il ne reste que la tête. Les bombes n’accélèrent plus le boss et leur disposition change à chaque nouvelle salve. Le combat commence par une expulsion de particules et de bombes qui envoie le joueur au fond du terrain, dans une zone libre de bombes. Le boss revient directement à gauche après chaque expulsion. Chaque transition de combat passe par une sortie rapide hors écran. L’expulsion disperse les particules dans toute l’arène et projette six nouvelles bombes. Les éclairs diffusent une brume lumineuse et les particules ambiantes réagissent au passage du joueur. Le Sanctuaire affiche les boss à leur taille de jeu, avec une alcôve élargie pour le squelette.

### Compteurs et lumière abyssale

L’écran Succès conserve le total de larmes collectées, de morts et d’essais. Un départ de combat, un redémarrage manuel ou une reprise après mort compte comme un essai ; les changements de niveau et le Sanctuaire n’en ajoutent pas. Les anciens records locaux initialisent les totaux connus une seule fois. Les parties abandonnées avant cette version ne peuvent pas être reconstituées.

Le Monstre d’os possède 18 PV. Seules les bombes avalées le blessent ; son corps reste dangereux. Les inscriptions murales minuscules et dorées apparaissent après la mort et la libération de chaque boss, y compris au Sanctuaire et en hardcore. Les messages d’un même biome partagent la progression des succès.

`SILKEN_TEST=1 SILKEN_SANCTUARY_REVISION_TEST=1 love dist/game.love` vérifie les trônes, la confirmation au clavier, à la souris et à la manette, le décompte, les délais des Guêpes, le nouveau combat abyssal et les inscriptions après les sept boss.

### Vérification du nouveau Poulpe

`SILKEN_TEST=1 SILKEN_REWORK_TEST=1 love dist/game.love` vérifie les morts/réapparitions dans les dix niveaux océaniques, la réutilisation du décor, les crabes noirs propulsés, les explosions contre les murs, l’étourdissement, les trois secondes de traction, la rage, la victoire et la larme abyssale cachée. Le bouton « i » ouvre la fiche du boss présent ; molette, touches haut/bas et stick droit font défiler le texte.


## Révision : la Descente

Le bouton de monde du menu ouvre une carte verticale (molette, haut/bas ou boutons Haut/Bas). Cliquer sur un cercle déplace l’araignée avec son skin et affiche les records et les niveaux disponibles. Les mondes fermés restent sous des nuages teintés ; chaque monde exige la victoire dans le précédent. Le Sanctuaire exige les sept victoires. Les classements restent voilés jusqu’à la première victoire dans le monde concerné.

Chaque victoire débloque un skin de biome. Les récompenses apparaissent en gris et tournent sur la carte avant leur déblocage. Gillou et Maxance débloquent aussi chacun un skin. Gillou demande de toucher les trois abeilles pendant le même KO, avant le réveil d’une sœur ; l’ancien critère chronométré ne débloque plus ce succès. Les filtres des succès séparent les objectifs à faire et ceux déjà obtenus.

Les niveaux atteints sont sauvegardés pour l’entraînement indépendant, sans progression ni score de classement. Après le dernier boss présent, les créatures disparaissent en étincelles et les dangers ne tuent plus. Des inscriptions sur le mur invitent à regarder ; aucun récit n’a été inventé (contenu futur dans `Story.worlds`).

Le Poulpe attaque un peu plus vite, conserve ses crabes sans cercles d’atterrissage et dispose d’un PNG de tentacule étiré. Les abeilles signalent leurs invocations, avec 0,85 s de grâce après un coup. Les créatures capturées sont inoffensives ; celles enfouies ignorent les pièges et cachent leur larme. Chaque œuf donne un petit ver à son impact ou expiration. Les tunnels animent aussi les monstres.

La Terre utilise des parois PNG de formations calcaires à la taille des collisions existantes, une lumière plus lisible et des gouttes de grotte. Les autres biomes bénéficient de détails de parois et de lumière ; le menu du Sanctuaire possède son propre fond violet.

L’éditeur permet d’enregistrer des **variantes de créatures et de boss** : sélectionner un adversaire, régler ses paramètres, choisir « Créer ce monstre/boss », nommer puis valider avec Entrée. Ces modèles réutilisables conservent le comportement du type choisi. Les vers et taupes proposent un départ en surface ou sous terre. Les petits vers ont un rendu distinct et plus petit.

La publication Workshop propose un biome distinct du niveau de départ et une difficulté de 1 à 5 larmes ; au niveau 5, un supplément rouge de 0 à 999. Les listes filtrent par biome/difficulté et trient par étoiles ou difficulté. Les métadonnées sont validées côté client et serveur.

Vérifications de cette révision : `SILKEN_TEST=1 SILKEN_GOAL_TEST=1 love dist/game.love`, tests de l’éditeur et `npm test` dans `server`. La migration serveur `0007_biome_skins.sql` doit être appliquée avant de déployer le Worker pour activer les nouveaux identifiants de skins. Les nouvelles fonctions serveur restent locales tant que ce déploiement n’est pas effectué.


## Replays, coquille et corrections visuelles

Chaque partie terminée conserve localement un replay de commandes dans `replays/` : simulation fixe à 60 Hz, graine dédiée, skin, dimensions, cartes et points de contrôle. Le classement propose « Visionner » pour les nouvelles parties ; espace met en pause, gauche/droite règle la vitesse, Échap quitte. Une version de simulation différente est signalée ; aucune vidéo n’est enregistrée. Les replays classés sont envoyés après le score, avec reprise après coupure réseau. Le mode spectateur n’accorde ni score, ni succès, ni progression.

Une carte Workshop doit être terminée dans sa version exacte avant publication. Le formulaire propose le biome sans choix de monde/niveau de campagne. Toute modification de la disposition ou des paramètres invalide le test. Le serveur exige aussi un justificatif associé au créateur et à la carte (migration 0008).

Le premier boss est un gros œuf à six vies. Chaque impact de dash libère six oiseaux aux mêmes nids : trois tireurs et trois chargeurs. Les nouveaux tireurs lancent immédiatement une plume ; les tirs suivants sont espacés de 4,6 s minimum. Les charges ne montrent aucune ligne de visée. Le poulpe conserve sa tête PNG, détourée selon sa silhouette par un maillage texturé, sans masque circulaire. Les tentacules vectoriels reprennent les bleus de la tête et leur base passe derrière elle. Les skins respectent l’opacité des traces, le halo du menu s’estompe progressivement, les sons fournis sont chargés, et chaque monde possède un succès pour une victoire sans mourir. Le menu des succès est paginé.

Vérification : `SILKEN_TEST=1 SILKEN_REPLAY_TEST=1 love dist/game.love` (partie réellement terminée/rejouée, divergence, isolation du spectateur, échantillons physiques de tous les biomes/boss et du mode Démon, boss œuf et opacité des skins), `SILKEN_TEST=1 SILKEN_GOAL_TEST=1 love dist/game.love` (66 niveaux), et `node --test server/worker.test.mjs`.

### Classements hardcore

Le bouton « Mode hardcore » affiche les parcours hardcore des sept mondes et du Sanctuaire, séparés des parcours normaux dans les classements mondiaux, nationaux et locaux. Le chrono inclut les retours en arrière et la pénalité habituelle de mort. Les nouveaux scores locaux hardcore sont enregistrés dans `hardcore-scores.json` ; les anciens records de boss isolés sont conservés sans être transformés en parcours complets.

Le fond conserve le biome sélectionné et un contour rouge animé indique le mode hardcore, dans le menu, la carte, le classement et en jeu, même lorsque les effets décoratifs sont désactivés. Le Sanctuaire hardcore enchaîne : Œuf du Merle, Merle noir, Hérisson, Pieuvre, Monstre d’os, Guêpes brûlées, Gardienne de la Soie.

Vérification : `SILKEN_TEST=1 SILKEN_HARDCORE_MODES_TEST=1 love dist/game.love`, puis `npm test --prefix server`. Le classement en ligne nécessite la migration `0010_hardcore_rankings.sql` et le Worker correspondant.
