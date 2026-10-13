# Skins du joueur

État actuel : Braise a été retiré du sélecteur et ses PNG supprimés. Son ancien ID 3 reste réservé aux scores/replays et utilise le dessin de Cendre. Ambre reçoit une teinte légèrement plus brune dans `custom_skin_material.glsl`, appliquée uniquement au corps pour conserver les piques ivoire et les motifs dorés. L’ombre du joueur est une ellipse douce au sol, indépendante des pixels du sprite.

Les skins classiques utilisent les trois PNG de `commun/` : `down.png` (face), `up.png` (dos) et `profil.png` (gauche, affiché en miroir pour la droite). Ils contiennent directement les motifs, les ombres et les yeux. La silhouette de face/dos reste celle de Perle et celle du profil reste celle de Soie.

Les motifs ne sont plus projetés par un shader. `player_skin.glsl` applique uniquement la palette du skin et la couleur des iris, en préservant les pupilles et les reflets blancs. Aucune araignée ne porte de couronne. Les instructions des retouches imagegen sont conservées dans `commun/generation.txt`.

Deux skins disposent de leurs propres dessins dans les trois mêmes poses :

- `maxance/` : Maxance (ID 14), avec une patte cassée, des lunettes, des yeux marron et une moustache.
- `cocon/` : Cocon (ID 23), l’araignée couverte de soie du trophée « Un fil sans faute », débloquée avec ce succès.

Ces deux modèles conservent les couleurs de leurs PNG avec leur propre matériau de finition, sans passer par les palettes communes. Comme les modèles communs, ils utilisent le maillage de marche de `brown_walk.lua`. La transparence des trois modèles est normalisée au chargement pour supprimer les résidus des contours sans modifier les PNG sources. Les petites vignettes sont réduites avec des mipmaps et conservent les couleurs de leurs yeux.

Les anciens dessins sont conservés comme sources dans les dossiers suivants :

- `soie/` : marron de base et Soie couronnée.
- `perle/` : Perle, Auréole, Zéphyr, Ambre, Lanterne et leurs récompenses couronnées.
- `braise/` : Braise, Cendre et Cendre couronnée.
- `ecume/` : Écume, Corail et Corail couronnée.
- `royale/` : Royale, Renouveau, Gillou, Maxance, Renouveau couronné.
- `accessoires/` : couronne commune et icône démon.

Les teintes, noms, identifiants et conditions de déblocage restent dans `src/characters.lua`. Le catalogue propose 18 skins : les IDs 1–14 et 23–26. Les trois palettes immédiatement disponibles Champagne (24), Sauge (25) et Pétrole (26) réutilisent les sprites `commun/`, leurs ombres, leurs motifs et leur animation ; le shader adapte la soie, l'or et les iris aux couleurs du menu. Les miniatures et effets reprennent ces couleurs. La liste explicite `Characters.baseIndices` sert à la sélection et aux notifications de récompense. Les IDs historiques 1–23 restent inchangés pour les profils, classements et replays.

Les variantes de récompense 15–22 se distinguent par une orbite de grandes particules dorées et des rayons tournants derrière le joueur équipé en jeu et dans le menu principal (`skin_reward_fx.lua`), sans contour ni couronne. Les identifiants historiques `crowned` restent compatibles avec les sauvegardes. Le réglage des effets désactive les particules et les rayons.

Dans le menu, le portrait est préparé à sa résolution d’affichage puis déplacé comme une image unique, pour éviter le scintillement des détails lors de la réduction du PNG.

Les textures actives sont de nouveau les dessins précédents sous `commun/`, `maxance/` et `cocon/`, dans le menu comme en jeu. Les huit pattes, les poses et les accessoires sont conservés. Les sprites et le portrait du menu utilisent un filtrage au plus proche sans lissage des pixels. Les petites vignettes de classement conservent leur réduction dédiée pour garder les yeux lisibles. L’alpha est nettoyé à l’import.

Les variantes dessinées abandonnées ont été supprimées ; seuls les sprites utilisés par le jeu sont conservés.

Les palettes classiques Perle à Gillou utilisent la même finition ivoire et or que les trois skins du menu, avec leurs couleurs distinctives. `Characters.silkPalettes` est séparé des conditions de déblocage : cette retouche visuelle ne débloque aucune récompense. Soie conserve son brun validé.

Gillou conserve son dessin et utilise une palette rouge orangé, avec des motifs cuivrés. Les six PNG complets de `integrated/` contiennent directement le corps et ses accessoires : ailes pour Auréole, piques pour Ambre, cornes pour Braise et Cendre, bulle de tête pour Écume et Corail. Chaque PNG regroupe les poses face, dos et profil, sélectionnées par les rectangles de `integrated/frames.json` ; le profil droit est réfléchi. Ils sont chargés avant le jeu par `integrated_skins.lua`, sans assemblage d’accessoires au rendu. Les prompts imagegen sont dans `integrated/generation.txt`.

Les ailes d’Auréole recouvrent l’abdomen de dos ; les deux ailes sont visibles de profil. Les motifs dorés sont retournés à 180° dans les poses de dos, y compris les bases communes et Maxance. Ambre utilise deux PNG complets dédiés, `integrated/ambre_up.png` et `integrated/ambre_profil.png`, pour conserver quatre pattes distinctes par côté ; `frames.json` peut préciser un chemin par pose. Les retouches ont été réalisées avec ImageGen intégré et leurs prompts sont conservés dans `integrated/pose-corrections.json`.

`skin_accessories.lua` conserve uniquement la lanterne animée de Lanterne. Les skins Écume et Corail gardent leur bulle intégrée dans tous les biomes : aucune seconde bulle n’est dessinée en jeu ou sur la carte. L’Abysse leur ajoute uniquement sa lanterne lumineuse. Les skins verrouillés restent des silhouettes noires avec un point d’interrogation. Les collisions et conditions de déblocage restent inchangées.

Les poses dédiées `*_up.png` et `*_profil.png` indiquées dans `frames.json` remplacent les cases correspondantes des planches : huit piques uniquement sur l’abdomen d’Ambre, deux cornes distinctes sur les profils Braise/Cendre, deux ailes parallèles sur le profil Auréole, bulle autour du segment supérieur (tête) de dos pour Écume/Corail. Les prompts de ces retouches ImageGen sont dans `integrated/anatomy-corrections.json`. La lanterne est une petite antenne courbe de poisson avec un leurre rond ; elle utilise désormais le même dessin de face, de dos et de profil (miroir vers la gauche). Les bulles ajoutées par les biomes utilisent des positions de tête adaptées au skin et à l’orientation ; elles sont désactivées pour les skins ayant déjà une bulle dans leur PNG.

Les poses face/profil d’Auréole et Ambre prennent la vue de dos comme référence anatomique : ailes repliées attachées près de la jonction tête–abdomen, plumes le long des flancs ; huit petits piques en deux rangées latérales de quatre, sans couronne sur le bord arrière. `aureole_down.png` remplace aussi la case face de la planche. `cendre_profil.png` est le PNG fourni par Lucas, copié sans retouche. Prompts : `integrated/placement-corrections.json`.

Dernier ajustement : Auréole a des ailes plus grandes de face ; celles de profil reprennent la référence de Lucas et sont déplacées ensemble au niveau de la tête, sans changer leur inclinaison. La pose de dos est conservée. Ambre retrouve sa disposition en couronne autour de l’abdomen, avec huit piques (quatre de chaque côté), sans piques sur la tête. Les PNG face/profil Ambre sont restaurés depuis les variantes précédemment générées ; prompts des ailes dans `integrated/wing-size-corrections.json`.

Auréole : les trois poses utilisent désormais des PNG dédiés (`aureole_down.png`, `aureole_up.png`, `aureole_profil.png`). Les ailes de dos et de profil sont agrandies pour correspondre à la taille de face. Leurs attaches et orientations sont conservées ; les points de tête de la bulle suivent les nouvelles découpes. Le facteur `renderScale` de la pose de dos compense sa silhouette plus large dans les portraits, les animations et les ombres. Prompts ImageGen intégré : `integrated/equal-wing-sizes.json`.

Refonte actuelle d’Ambre, Braise et Cendre : leurs anciennes planches ont été supprimées et leurs neuf poses dédiées remplacées à partir du skin `commun`. Ambre est marron clair avec exactement huit piques ivoire, quatre de chaque côté du pourtour de l’abdomen. Braise est orange à ombres rouges, Cendre rouge à reflets orange ; chacun porte deux cornes sur la tête dans les trois vues. Les poses de profil droit restent les miroirs des profils gauches. Cette refonte remplace notamment l’ancien profil Cendre fourni précédemment. Sources et prompts ImageGen intégré : `integrated/base-rebuild.json`. La lanterne conserve sa courbe, avec une tige plus lisible et un leurre plus lumineux ; l’effet d’auréole descend de 4 % de la taille du portrait.
