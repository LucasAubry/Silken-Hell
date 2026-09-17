# Crabes du poulpe — imagegen intégré

Génération avec l’outil imagegen intégré, référence de style : `assets/sprites/directional/fish_down.png`.

- `sprites/crab_open.png` : Small monstrous ocean crab, rusty orange shell with dark teal creases, two black eyes, eight jointed legs and two prominent OPEN pincers. Elevated top-down front view facing down, centered complete silhouette, transparent alpha. Detailed crisp pixel-art dark fantasy 16-bit style matching the fish reference. No text.
- `sprites/crab_closed.png`, référence `crab_open.png` : Change ONLY the pincers to tightly CLOSED and walking legs into the alternate scuttling step. Preserve character, palette, pixel size, canvas, framing and down-facing view. Transparent alpha.
- `sprites/crab_dead.png`, référence `crab_open.png` : Show exactly this crab overturned ON ITS BACK, pale segmented underside, orange shell edges and teal joints, pincers folded inward, legs curled upward. No gore. Same pixel art style and centered framing. Transparent alpha.

Les trois PNG sont conservés avec leur transparence générée. Le jeu alterne les poses des pinces et anime la disparition du crabe sur le dos par découpage progressif, sans écraser sa silhouette. Les PNG existants du poulpe sont réutilisés ; un shader sépare sa tête orientée vers le joueur des tentacules en rotation.
