# Révision des mondes — 17 septembre 2026

- Paradis : poursuite sans pause liée à un chemin épuisé ; cercles de larmes de 44 pixels ; larmes portées décalées derrière leur monstre ; captures et trajectoires complètes des roues écartées des destinations des larmes.
- Ciel : particules de vent faible plus visibles ; pluie mortelle dès le niveau 5, nuages grisés ; mouettes attirées par la larme puis en orbite ; foudre et transformation permanente en mouette électrique ; tornades projetant à 1 050 pixels/seconde jusqu’au rebord.
- Terre : séparation des corps des vers et taupes, y compris sous terre ; larme marron ; hérisson sans murs intérieurs, 15 piques par salve et trajectoire en boule réorientée vers le joueur.
- Océan : poulpe entier en rotation, tête solidaire des tentacules ; silhouette agrandie à 520 pixels ; vitesse périphérique plafonnée sous le dash ; crabes projetés près des côtés de l’arène.
- Abysses : aucun banc de poissons-lames ; nouveaux poissons et méduses révélatrices. Les fils de lumière marquent le joueur pendant six secondes : tous les poissons chargent alors au lieu de l’éviter.
- Léviathan d’ivoire : grande créature des niveaux 7 à 10 des Abysses, assemblée avec cinq PNG indépendants (crâne fermé/ouvert, côte, vertèbre, nageoire caudale). Les espaces entre les os sont traversables ; les collisions suivent leurs pixels opaques. Les os sont dessinés devant le joueur, avec ombres décalées et points lumineux. Sa bouche s’ouvre pendant 3,5 secondes toutes les neuf secondes et aspire joueur, créatures, lumière, bulles et larme.
- Menu : couleurs, particules, boutons et shader de fond adaptés au monde sélectionné.

## Assets

Les six nouveaux PNG se trouvent dans `assets/sprites/` : `skeleton_head.png`, `skeleton_open.png`, `skeleton_rib.png`, `skeleton_spine.png`, `skeleton_tail.png`, `abyss_fish.png`. Les prompts complets imagegen intégré sont dans `assets/abyss-parts-prompts.md`.

## Vérifications

Suite LÖVE complète et régressions dans `tests/world_revision.lua` : poursuite, emplacement des pièges, début de la pluie, foudre, collisions entre monstres, réaction des poissons à la lumière, passage entre les os, collision mortelle et aspiration. Captures dédiées via `SILKEN_TEST=1 SILKEN_WORLD_QA=1`.

## Ajustement hérisson et mouettes électriques
- Hérisson : une taupe par manche jusqu’à cinq ; un rebond par manche jusqu’à trois.
- Salves divisées par deux : 15 piques au lieu de 30.
- Mouettes électriques : plumage et aura jaunes.

## Bulle et hérisson
- Océan et Abysses : suppression de la jauge, des recharges et de la mort par manque d’oxygène ; bulle autour de la tête.
- Hérisson : maximum trois rebonds et cinq taupes ; pause de 0,35 seconde entre les rebonds avant de recharger.

## Fonds élémentaires et combat
- Fonds procéduraux : terre et racines, eau et reflets animés, eaux profondes, roche brûlée, marbre lumineux du Paradis. Ciel conservé.
- Vent : petits traits fins et discrets sur toute la fenêtre.
- Hérisson : stun de 0,45 seconde seulement à la perte de PV ; salves de 12 piques à 300 px/s (contre 15 à 205 px/s).

## Poulpe : combat par vagues
- Taille 360 au lieu de 520 ; sens constant, inversé à chaque PV perdu.
- Vagues de trois crabes (quatre à partir de 4 PV), lancés vers le joueur puis en poursuite. Une vague entièrement éliminée retire un PV.
- Accrochage aux tentacules : rotation accélérée 1,6 seconde ; dash directionnel pour sortir plus tôt. Le contact direct avec un crabe reste mortel, y compris accroché.
- Zones d’arrivée annoncées, délai entre vagues et encre atténuée pour garder le combat lisible.

## Correction lancement des biomes
- Correction du crash `drawBubble` absent : le rendu charge directement le module dédié `breathing_bubble.lua`, indépendant de l’ancien fichier d’oxygène.

## Crabes, Abysses et concepteur indépendant
- Crabes orientés vers le joueur, ajoutés aux niveaux Océan ; 8 à 12 crabes par vague du poulpe. Ils gardent leur direction pendant l’accrochage et accélèrent de 75 % sous l’effet de l’encre, désormais noire devant la vue.
- Cercles teintés par biome, séparés des dangers. Les cercles des Abysses chargent le joueur en lumière et attirent les poissons.
- Méduse lumineuse et quatre phases PNG de l’anémone électrique.
- Léviathan du niveau 10 : huit PV, os espacés, nage ondulante, dégâts par contact lumineux avec consommation de la lumière et courte protection de sortie.
- Concepteur indépendant : soixante niveaux importés, palettes, glisser-déposer, propriétés, duplication, annuler/rétablir, brouillons persistants, application avec sauvegarde et test direct sans classement.

## Tentacules destructibles et sortie du jeu
- Échap au menu ouvre une confirmation Quitter / Rester, dans le style du jeu ; Échap annule.
- Huit tentacules avec huit impacts de crabes chacune : elles rougissent puis disparaissent et perdent leur collision. La destruction d’un bras retire un PV ; les huit bras détruits libèrent la larme.
- Les crabes contournent le corps du poulpe. Les vagues se renouvellent quand elles sont éliminées ; toucher un crabe reste mortel pour le joueur.

## Vie des Abysses et mouettes électriques
- Petite pieuvre abyssale avec nouveau PNG transparent et nage ondulante ; lueur discrète des yeux des poissons agressifs quand le joueur est illuminé (poissons-lanternes inchangés).
- Retrait des anémones/pièges des niveaux des Abysses, y compris les anciens niveaux personnalisés, et de la bibliothèque.
- Aura des mouettes électriques réduite de 49 à 30 pixels ; traînée électrique mortelle persistante 2,2 secondes, effacée au redémarrage du niveau.

## Workshop et création libre
- Workshop connecté au serveur Silken Hell : publication, téléchargement, cartes jouables sans classement, une étoile par installation et tri par nombre d’étoiles.
- Boutons Créer (application de conception) et Succès (écran volontairement vide).
- Plusieurs boss indépendants, même de même espèce, et créatures/terrain de tous les biomes dans les niveaux personnalisés ; victoire après tous les boss.
- Cache des données des sprites (chargement mesuré 16,8 s → 4,7 s) et fenêtre de test réutilisable.
- Halo et cercle de lumière renforcés dans les Abysses.
- Correction du poisson solitaire qui cherchait un deuxième membre inexistant dans son banc.
