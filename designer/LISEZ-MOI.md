# Concepteur de niveaux Silken Hell

Ouvre **Concepteur Silken Hell.app** dans le dossier du projet (ou double-clique sur **Lancer le concepteur.command**).

1. Choisis le biome et le niveau en haut. Les 60 niveaux jouables sont déjà importés.
2. Sélectionne un monstre, un piège, un boss ou un élément de terrain dans la bibliothèque à gauche, puis clique sur le terrain.
3. Échap revient à la sélection. Glisse un objet pour le déplacer. Ses coordonnées, dimensions et sa vitesse se règlent à droite ; valide une valeur avec Entrée.
4. **Appliquer** enregistre le niveau dans le jeu. Recharge ce niveau dans le jeu pour voir le résultat.
5. **Tester** applique le niveau puis l’ouvre directement dans une partie sans classement. La fenêtre de test est réutilisée : les tests suivants rechargent la carte sans recharger les sprites.

⌘Z / ⌘⇧Z : annuler / rétablir. Suppr : supprimer. ⌘S : appliquer. La grille et l’aimant peuvent être désactivés. Les brouillons se conservent en quittant.

La bibliothèque affiche tous les biomes. Mélange librement créatures, pièges, terrain et boss, y compris plusieurs exemplaires du même boss. Les chevauchements sont autorisés. Les tunnels fonctionnent par paires ; les nids du Merle et les sources de lumière du Léviathan sont ajoutés automatiquement s’ils manquent. Une carte conserve un départ de joueur. Tous les boss doivent être vaincus pour libérer la larme.

Chaque application sauvegarde la version précédente dans le dossier de sauvegarde du jeu sous `custom_levels.backup-....json`. Une copie des niveaux personnalisés est aussi exportée dans `custom_levels.json` à la racine du projet. **Restaurer l’original** remet le niveau importé en brouillon ; clique ensuite sur Appliquer pour le conserver.

L’éditeur fonctionne hors ligne, séparément du jeu. Les versions personnalisées ne publient pas de scores au classement. Renaissance reste réservée.

Depuis le jeu, **Créer** ouvre cette application. Dans **Workshop → Publier ma carte**, choisis un niveau appliqué, indique son titre et ton pseudo, puis publie-le. Les autres joueurs peuvent le jouer et lui donner une étoile ; les cartes les plus étoilées apparaissent en tête. Republier le même emplacement met à jour sa carte.
