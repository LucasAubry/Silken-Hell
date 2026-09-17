# Silken Hell

Jeu d’esquive en Lua avec LÖVE 11.5, éditeur de niveaux et classements/Workshop Cloudflare dédiés.

## Lancer le jeu

Double-cliquer **Jouer à Silken Hell.app** ou **Lancer Silken Hell.command**. Le lanceur reconstruit le jeu depuis les sources à chaque ouverture et installe LÖVE au premier lancement si nécessaire. Le cache se trouve dans `~/Library/Application Support/Silken Hell/Silken Hell.love`.

Flèches pour se déplacer, Espace pour le dash, Échap pour la pause. Un dash nécessite une direction. Touches et volumes se règlent dans les paramètres ; F11 gère le plein écran. Le bouton de recommencement remet le monde courant au niveau 1. Le jeu se met en pause lorsqu’il perd le focus.

## Mondes et boss

Ordre : **Paradis → Ciel → Terre → Océan → Abysse → Enfer → Renaissance**. Les six premiers mondes ont dix niveaux ; Renaissance enchaîne leurs six boss, dans cet ordre, avec une ambiance rouge, noire et blanche.

- **Paradis** : anges, serpents, captures et roues. Attirer un porteur de larme dans un piège la libère. Le Merle noir reste au centre et tire des plumes en continu. Guider ses plumes vers l’œuf d’un nid le blesse ; ses salves s’accélèrent et deviennent triples à quatre PV.
- **Ciel** : vent variable, trous et rebords mortels, tornades, pluie et foudre. Les mouettes électrifiées deviennent jaunes et laissent une traînée dangereuse. Boss : le Séraphin des orages, vulnérable pendant ses accalmies.
- **Terre** : tunnels empruntables par le joueur et les monstres, vers et taupes. Le Hérisson a sept PV, douze piques par salve, deux rebonds et cinq taupes au maximum. Il est étourdi lorsqu’il perd une vie.
- **Océan** : poissons-lames, méduses et crabes. Une bulle entoure l’araignée ; aucune jauge d’oxygène. Le Poulpe invoque régulièrement des crabes qui poursuivent le joueur en évitant ses bras. Son encre tombe au sol : un crabe encré devient fou puis explose et projette ses voisins. Huit impacts de crabes détruisent une tentacule. Le joueur peut s’accrocher à une tentacule, mais toucher un crabe reste mortel.
- **Abysse** : obscurité, lueurs bleues, poissons-lanternes et pieuvres lumineuses. Les fils bleus chargent l’araignée sans la tuer. Les poissons la poursuivent lorsqu’elle est éclairée. La queue du Léviathan apparaît au niveau 8, ses os au niveau 9 et sa tête au niveau 10. Entrer chargé dans sa bouche pendant l’aspiration lui retire une vie lorsqu’il recrache le joueur. Les cercles éclairent uniquement lorsqu’on reste dessus. Aucun oxygène à gérer.
- **Enfer** : lave, goules, serpents indépendants et nids de larves. Les nids sont inoffensifs au contact ; leurs larves poursuivent et explosent sans laisser de flaque. Les monstres traversent la lave, brûlent et laissent des traînées mortelles. Boss : **Les Trois Sœurs de braise**, trois abeilles à trois PV chacune. Elles chargent en séquence ; une seule se fatigue à la fois et peut alors être touchée. Chaque élimination accélère les survivantes. Seule la dernière invoque des mini-abeilles. Les lacs annoncent des éruptions de braises.

La lumière diminue progressivement au fil des mondes et des niveaux. La foudre ambiante est réservée au Ciel ; les attaques électriques des créatures conservent leurs mécaniques.

## Menu, sauvegardes et classements

Le menu suit l’ambiance du monde sélectionné. Cinq skins : Soie, Perle, Braise, Écume et Royale. Le bestiaire enregistre les découvertes, avec catégories Créatures, Boss et Pièges. Histoire et Succès attendent leur contenu.

Un pseudo est demandé avant la partie. Cloudflare détecte le pays de la connexion ; avec un VPN, il s’agit du pays de sortie. Les panneaux affichent les dix meilleurs scores mondiaux et nationaux, avec chrono, morts et skin. Un clic ouvre tous les scores paginés. Le meilleur score par pseudo est conservé.

Le classement et le chronomètre final incluent **0,05 seconde par mort**. Le temps brut reste enregistré séparément pour éviter toute double pénalité. Renaissance utilise un seul chrono pour ses six combats.

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
