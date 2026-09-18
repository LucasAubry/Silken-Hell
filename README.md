# Silken Hell

Jeu d’esquive en Lua avec LÖVE 11.5, éditeur de niveaux et classements/Workshop Cloudflare dédiés.

## Lancer le jeu

Double-cliquer **Jouer à Silken Hell.app** ou **Lancer Silken Hell.command**. Le lanceur utilise l’archive locale publiée et installe LÖVE au premier lancement si nécessaire. Pour publier des modifications des sources, exécuter `python3 tools/package.py`. Le cache se trouve dans `~/Library/Application Support/Silken Hell/Silken Hell.love`.

Flèches pour se déplacer à pleine vitesse, maintenir Espace pour ralentir, Échap pour la pause. Touches et volumes se règlent dans les paramètres ; F11 gère le plein écran. Le bouton de recommencement remet le monde courant au niveau 1. Le jeu se met en pause lorsqu’il perd le focus.

## Mondes et boss

Ordre : **Paradis → Ciel → Terre → Océan → Abysse → Enfer → Renaissance**. Les six premiers mondes ont dix niveaux ; Renaissance enchaîne leurs six boss, dans cet ordre, avec une ambiance rouge, noire et blanche.

- **Paradis** : anges, serpents, captures et roues. Attirer un porteur de larme dans un piège la libère. Le Merle noir reste au centre et tire des plumes en continu. Guider ses plumes vers l’œuf d’un nid le blesse ; ses salves s’accélèrent et deviennent triples à quatre PV.
- **Ciel** : vent variable, trous et rebords mortels, tornades, pluie et foudre. Les mouettes électrifiées deviennent jaunes et laissent une traînée dangereuse. Boss : le Séraphin des orages, vulnérable pendant ses accalmies.
- **Terre** : tunnels empruntables par le joueur et les monstres, vers et taupes. Le Hérisson a sept PV, douze piques par salve, deux rebonds et cinq taupes au maximum. Il est étourdi lorsqu’il perd une vie.
- **Océan** : poissons-lames, méduses et crabes. Le Poulpe lance des crabes et de l’encre. Les crabes noirs errent et peuvent être propulsés en fonçant dessus. Un impact de crabe sur un tentacule étourdit le boss trois secondes : attraper une extrémité puis la tirer dans un coin arrache le bras et retire une vie. À quatre PV, le boss accélère et lance une rafale d’encre. Les flaques durent sept secondes.
- **Abysse** : obscurité, lueurs bleues, poissons-lanternes et pieuvres lumineuses. Les fils bleus chargent l’araignée sans la tuer. Les poissons la poursuivent lorsqu’elle est éclairée. La queue du Léviathan apparaît au niveau 8, ses os au niveau 9 et sa tête au niveau 10. Entrer chargé dans sa bouche pendant l’aspiration lui retire une vie lorsqu’il recrache le joueur. Les cercles éclairent uniquement lorsqu’on reste dessus. Aucun oxygène à gérer.
- **Enfer** : lave, goules, serpents indépendants et nids de larves. Les nids sont inoffensifs au contact ; leurs larves poursuivent et explosent sans laisser de flaque. Les monstres traversent la lave, brûlent et laissent des traînées mortelles. Boss : **Les Trois Sœurs de braise**, trois abeilles à trois PV chacune. Elles chargent en séquence ; une seule se fatigue à la fois et peut alors être touchée. Chaque élimination accélère les survivantes. Seule la dernière invoque des mini-abeilles. Les lacs annoncent des éruptions de braises.

La lumière diminue progressivement au fil des mondes et des niveaux. La foudre ambiante est réservée au Ciel ; les attaques électriques des créatures conservent leurs mécaniques.

## Menu, sauvegardes et classements

Le menu suit l’ambiance du monde sélectionné. Cinq skins : Soie, Perle, Braise, Écume et Royale. Le bestiaire enregistre les découvertes, avec catégories Créatures, Boss et Pièges. Histoire et Succès attendent leur contenu.

Un pseudo est demandé avant la partie. Cloudflare détecte le pays de la connexion ; avec un VPN, il s’agit du pays de sortie. Les panneaux affichent les dix meilleurs scores mondiaux et nationaux, avec chrono, morts et skin. Un clic ouvre tous les scores paginés. Le meilleur score par pseudo est conservé.

Le classement et le chronomètre final incluent **une seconde pour trois morts (⅓ de seconde par mort)**. Le temps brut reste enregistré séparément pour éviter toute double pénalité. Renaissance utilise un seul chrono pour ses six combats.

Les réglages, découvertes, déblocages et scores locaux sont dans `~/Library/Application Support/LOVE/silken-hell`. Les scores démarrés hors ligne restent locaux. Une partie connectée interrompue peut reprendre ses envois en attente.

## Éditeur et Workshop

**Concepteur Silken Hell.app**, **Lancer le concepteur.command** ou le bouton **Créer** ouvrent l’éditeur. Il importe les 66 niveaux et permet de mélanger créatures, boss, décors et biomes. Les propriétés incluent les vitesses de déplacement et d’attaque des boss ainsi que le délai et l’intervalle des nids de larves.

**Appliquer** enregistre les niveaux personnalisés ; les aperçus rechargent leurs données sans redémarrage. Le Workshop permet de publier une carte, de jouer aux cartes partagées et de leur attribuer une étoile.

Les fichiers `custom_levels.json` et `designer/default_levels.json` sont des données utiles : ne pas les supprimer lors d’un nettoyage.

## Développement et vérification

- `love .` : jouer depuis les sources.
- `make package` : construire `game.love`, y compris l’éditeur intégré.
- `SILKEN_TEST=1 love game.love` : tests isolés du jeu.
- `SILKEN_DESIGNER_TEST=1 SILKEN_PROJECT="$PWD" love designer` : tests de l’éditeur.
- `cd server && npm test` : tests API et Workshop.

Les tests utilisent des sauvegardes séparées. `SILKEN_ONLINE_TEST=1` active un test réel de l’API qui crée un score `SilkenGameQA` à nettoyer après validation.

## Serveur

Worker : `silken-hell-api`. Base D1 : `silken-hell-scores`. API : https://silken-hell-api.leafco-dev.workers.dev

La configuration, les migrations et les instructions sont dans `server/`. Ces ressources sont indépendantes de GET OUT. `npm run deploy` depuis `server/` déploie le Worker ; un push Git ne déclenche pas cette commande.

Le serveur vérifie l’ordre des niveaux, les compteurs, le temps et les soumissions répétées. Le moteur reste côté client : ces contrôles ne garantissent pas l’absence de triche.

## Organisation et assets

- Modules Lua à la racine ; dispositions du Paradis dans `levels/`.
- `assets/sprites/` : PNG actifs ; vues directionnelles dans `directional/`.
- `assets/art-metadata.json` : limites alpha et masques précalculés.
- `texture/` : textures d’origine encore utilisées.
- `designer/`, `server/`, `tests/`, `tools/` : éditeur, API, vérifications et empaquetage.

Les prompts des images sont conservés dans `assets/` pour pouvoir les reproduire. Les anciennes poses du poulpe, sprites remplacés, interfaces inutilisées et l’export web obsolète ont été retirés. Les archives générées, métadonnées Finder et caches ne sont pas versionnés.

## Manettes et Steam

Les manettes reconnues par SDL/LÖVE sont détectées au démarrage et lors du branchement. La dernière manette utilisée devient active. Stick gauche ou croix : déplacement ; A (bouton du bas), gâchettes ou boutons d’épaule : ralentir ; Start : pause ; B : retour. Les menus disposent d’un focus visible et la saisie du pseudo d’un clavier à l’écran. Débrancher la manette active met le combat en pause. Une zone morte évite la dérive du stick.

La prise en charge utilise le gamepad standard, qui peut être émulé par Steam Input. Pour la publication Steam, configurer un modèle de contrôleur Gamepad par défaut dans Steamworks puis tester chaque plateforme avec une vraie manette et Steam Deck. Il ne s’agit pas d’une intégration de l’API native Steam Input, et la configuration du partenaire Steam n’est pas effectuée par ce dépôt. Documentation : https://partner.steamgames.com/doc/features/steam_controller/steam_input_gamepad_emulation_bestpractices?language=english

## Le Sanctuaire et succès

Le Sanctuaire est le huitième choix de monde, accessible sans débloquer les autres mondes. Se déplacer librement dans son arène et toucher une miniature lance le boss hardcore correspondant. Les records de chaque combat restent séparés.

Maxance : terminer le Paradis avec au moins 95 morts et un temps final au moins égal à son record (552,732 secondes brutes + 95/3 secondes de pénalité, affiché 9:44.40). Les anciens déblocages sont réévalués à partir des scores sauvegardés.

### Révision du Sanctuaire

Sélectionner le Sanctuaire dans les mondes, puis cliquer sur Jouer. La salle normale propose six boss et toutes les créatures du catalogue ; les rencontres de créatures sont des survies de 20 secondes contre un seul adversaire. La porte de droite alterne avec la salle hardcore, qui contient uniquement les Sœurs de lave pour le moment. À la manette, Y change la catégorie et les boutons d’épaule changent de page.

Les abeilles marquent une pause fixe de 0,4 seconde avant de charger. La première charge abyssale est faible ; la lumière augmente avec les charges suivantes. Le contour lumineux de la bulle d’air est purement visuel. Le joueur est invulnérable sur tout le trajet d’éjection du Léviathan et perd sa charge lumineuse en étant recraché.

### Compteurs et lumière abyssale

L’écran Succès conserve le total de larmes collectées, de morts et d’essais. Un départ de combat, un redémarrage manuel ou une reprise après mort compte comme un essai ; les changements de niveau et le Sanctuaire n’en ajoutent pas. Les anciens records locaux initialisent les totaux connus une seule fois. Les parties abandonnées avant cette version ne peuvent pas être reconstituées.

Le Léviathan possède 10 PV. Les charges plafonnent à 3 et éclairent autour du joueur. La larme est bleu sombre et reste cachée par l’obscurité : elle se révèle sous la lumière, y compris après le boss. Le Sanctuaire utilise la même surface de jeu que les niveaux, un sol infernal aux fissures blanches et des miniatures ancrées avec une respiration discrète.

### Vérification du nouveau Poulpe

`SILKEN_TEST=1 SILKEN_REWORK_TEST=1 love game.love` vérifie les morts/réapparitions dans les dix niveaux océaniques, la réutilisation du décor, les crabes noirs propulsés, les explosions contre les murs, l’étourdissement, les trois secondes de traction, la rage, la victoire et la larme abyssale cachée. Le bouton « i » ouvre la fiche du boss présent ; molette, touches haut/bas et stick droit font défiler le texte.
