# Monstres par biome

Les sept dossiers suivent les mondes : paradis, ciel, terre, ocean, abysse, enfer, renaissance. Chaque créature ou boss a son dossier ; les œufs, projectiles et éléments de son corps sont rangés avec lui. La reine, ses bébés et ses toiles sont dans `renaissance/reine/`.

Le sanctuaire réutilise ces mêmes images. Les identifiants du bestiaire et du concepteur ne changent pas. Les comportements Lua sont dans `src/mobs/` ; ce dossier organise les images. `src/asset_paths.lua` résout les anciens chemins construits dynamiquement sans dupliquer les PNG.
