# Skins du joueur

Le joueur utilise les trois PNG de `commun/` : `down.png` (face), `up.png` (dos) et `profil.png` (gauche, affiché en miroir pour la droite). Ils contiennent directement les motifs, les ombres et les yeux. La silhouette de face/dos reste celle de Perle et celle du profil reste celle de Soie.

Les motifs ne sont plus projetés par un shader. `player_skin.glsl` applique uniquement la palette du skin et la couleur des iris, en préservant les pupilles et les reflets blancs. Aucune araignée ne porte de couronne. Les instructions des retouches imagegen sont conservées dans `commun/generation.txt`.

Les anciens dessins sont conservés comme sources dans les dossiers suivants :

- `soie/` : marron de base et Soie couronnée.
- `perle/` : Perle, Auréole, Zéphyr, Ambre, Lanterne et leurs récompenses couronnées.
- `braise/` : Braise, Cendre et Cendre couronnée.
- `ecume/` : Écume, Corail et Corail couronnée.
- `royale/` : Royale, Renouveau, Gillou, Maxance, Renouveau couronné.
- `accessoires/` : couronne commune et icône démon.

Les teintes, noms, identifiants et conditions de déblocage restent dans `src/characters.lua`. Les 22 skins partagent les mêmes PNG et ne nécessitent pas de fichiers dupliqués pour leurs couleurs.

Les variantes de récompense 15–22 se distinguent uniquement par une orbite de particules dorées (`skin_reward_fx.lua`), sans contour ni couronne. Les identifiants historiques `crowned` restent compatibles avec les sauvegardes. Le réglage des effets désactive les particules.

Dans le menu, le portrait est préparé à sa résolution d’affichage puis déplacé comme une image unique, pour éviter le scintillement des détails lors de la réduction du PNG.
