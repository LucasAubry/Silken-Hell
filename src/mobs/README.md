# Monstres et boss

- Chaque monstre possède son dossier et son `init.lua` : apparition, déplacement et/ou rendu.
- `bosses/<nom>/init.lua` contient l'état et le combat du boss. Ses dessins spécifiques sont à côté (œuf, tête, tentacules).
- `bosses/instances.lua` crée les boss indépendants des cartes du workshop.
- `shared/` rassemble uniquement les textures, déplacements, collisions et rendus communs.
- `init.lua` enregistre les monstres historiques ; `infernal.lua` enregistre ceux des enfers.
- `src/realms.lua`, orchestre les décors et les groupes des biomes.
- Les images sont classées par biome et par créature dans `assets/monstres/`. `src/asset_paths.lua` maintient les anciens chemins utilisés par les chargeurs.

Le packaging inclut récursivement `src/`. L'empreinte des replays inclut tous ses scripts.
