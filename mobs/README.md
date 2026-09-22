# Monstres et boss

- Chaque monstre possède son dossier et son `init.lua` : apparition, déplacement et/ou rendu.
- `bosses/<nom>/init.lua` contient l'état et le combat du boss. Ses dessins spécifiques sont à côté (œuf, tête, tentacules).
- `bosses/instances.lua` crée les boss indépendants des cartes du workshop.
- `shared/` rassemble uniquement les textures, déplacements, collisions et rendus communs.
- `init.lua` enregistre les monstres historiques ; `infernal.lua` enregistre ceux des enfers.
- `realms.lua`, à la racine, orchestre les décors et les groupes des biomes.
- Les textures restent dans `assets/sprites/` et `texture/mob/` pour préserver les références des cartes et de l'éditeur.

Le packaging inclut récursivement `mobs/`. L'empreinte des replays inclut tous ses scripts.
