# Skins du joueur

Chaque modèle contient `down.png` (face), `up.png` (dos sans losange) et `profil.png` (gauche). Le jeu affiche le même profil en miroir pour la droite : aucune seconde image différente à maintenir.

- `soie/` : marron de base et Soie couronnée.
- `perle/` : Perle, Auréole, Zéphyr, Ambre, Lanterne et leurs récompenses couronnées.
- `braise/` : Braise, Cendre et Cendre couronnée.
- `ecume/` : Écume, Corail et Corail couronnée.
- `royale/` : Royale, Renouveau, Gillou, Maxance, Renouveau couronné.
- `accessoires/` : couronne commune et icône démon.

Les teintes, noms, identifiants et conditions de déblocage restent dans `src/characters.lua`. Les couleurs ne nécessitent pas de PNG dupliqués. Le modèle Royale inclut sa couronne ; les autres récompenses utilisent l'accessoire séparé.
