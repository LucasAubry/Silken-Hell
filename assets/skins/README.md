# Skins du joueur

Les skins classiques utilisent les trois PNG de `commun/` : `down.png` (face), `up.png` (dos) et `profil.png` (gauche, affiché en miroir pour la droite). Ils contiennent directement les motifs, les ombres et les yeux. La silhouette de face/dos reste celle de Perle et celle du profil reste celle de Soie.

Les motifs ne sont plus projetés par un shader. `player_skin.glsl` applique uniquement la palette du skin et la couleur des iris, en préservant les pupilles et les reflets blancs. Aucune araignée ne porte de couronne. Les instructions des retouches imagegen sont conservées dans `commun/generation.txt`.

Deux skins disposent de leurs propres dessins dans les trois mêmes poses :

- `maxance/` : Maxance (ID 14), avec une patte cassée, des lunettes, des yeux marron et une moustache.
- `cocon/` : Cocon (ID 23), l’araignée couverte de soie du trophée « Un fil sans faute », débloquée avec ce succès.

Ces deux modèles conservent les couleurs finales de leurs PNG sans passer par le shader de recoloration. Comme les modèles communs, ils utilisent le maillage de marche de `brown_walk.lua`. La transparence des trois modèles est normalisée au chargement pour supprimer les résidus des contours sans modifier les PNG sources. Les petites vignettes sont réduites avec des mipmaps et conservent les couleurs de leurs yeux.

Les anciens dessins sont conservés comme sources dans les dossiers suivants :

- `soie/` : marron de base et Soie couronnée.
- `perle/` : Perle, Auréole, Zéphyr, Ambre, Lanterne et leurs récompenses couronnées.
- `braise/` : Braise, Cendre et Cendre couronnée.
- `ecume/` : Écume, Corail et Corail couronnée.
- `royale/` : Royale, Renouveau, Gillou, Maxance, Renouveau couronné.
- `accessoires/` : couronne commune et icône démon.

Les teintes, noms, identifiants et conditions de déblocage restent dans `src/characters.lua`. Le catalogue propose 15 skins : les IDs 1–14 et 23. La liste explicite `Characters.baseIndices` sert à la sélection et aux notifications de récompense. Les IDs historiques 1–22 restent inchangés pour les profils, classements et replays.

Les variantes de récompense 15–22 se distinguent par une orbite de grandes particules dorées et des rayons tournants derrière le joueur équipé en jeu et dans le menu principal (`skin_reward_fx.lua`), sans contour ni couronne. Les identifiants historiques `crowned` restent compatibles avec les sauvegardes. Le réglage des effets désactive les particules et les rayons.

Dans le menu, le portrait est préparé à sa résolution d’affichage puis déplacé comme une image unique, pour éviter le scintillement des détails lors de la réduction du PNG.
