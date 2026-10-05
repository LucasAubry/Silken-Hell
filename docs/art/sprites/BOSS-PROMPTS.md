# Boss et dangers — génération intégrée imagegen

PNG sauvegardés dans ce dossier. Référence : raven.png, puis wasp.png pour la forme posée. Alpha conservé ; cadrage au rendu dans art.lua.

## merle.png

Use case: precise-object-edit. Edit target reference: existing Silken Hell boss sprite. Change ONLY both eyes to black eyes clearly surrounded by yellow rings, like a male blackbird (merle noir). Preserve the spread wings, shape, dark indigo plumage, gold beak and ornaments, chunky stepped pixel clusters. Transparent PNG alpha, no scene, no text. Keep all other pixels visually consistent.

## wasp.png

Use case: stylized-concept. One solitary wasp boss sprite for Silken Hell, top-down slightly frontal dungeon view, head upward and long pointed stinger at bottom, slender narrow waist, black and ochre yellow segmented abdomen, six legs, two pairs of spread pale smoky wings. Menacing insect, no crown. Match reference chunky dark fantasy pixel art, crisp stepped square clusters, limited palette, readable at 110 pixels. Centered full body on genuinely transparent PNG alpha. Reference STYLE ONLY. No text, background, frame or ground.

## nest.png

Use case: stylized-concept. One empty blackbird nest floor trap sprite, overhead dungeon view, round woven dark brown twigs with a hollow center and sparse straw gold highlights. Match reference chunky dark fantasy pixel art with crisp stepped square clusters, readable at 75 pixels wide. Centered on genuinely transparent PNG alpha, no eggs, no bird, no text, no background. Reference STYLE ONLY.

## black_feather.png

Use case: stylized-concept. One blackbird flight feather projectile sprite, horizontal with sharp tip pointing RIGHT, charcoal black and indigo feather barbs, thin gray shaft and dark outline. Match reference chunky dark fantasy pixel art with crisp square clusters, readable at 30 pixels long. Centered on genuinely transparent PNG alpha, no glow, no text, no other objects. Reference STYLE ONLY.

## lava.png

Use case: stylized-concept. One small irregular oval lava puddle floor hazard, overhead view, molten orange and gold center with red rim and dark cracked obsidian crust edge, flat floor sprite. Match reference chunky dark fantasy pixel art, crisp stepped square clusters, readable at 100 pixels wide. Centered on genuinely transparent PNG alpha, no scenery, no text. Reference STYLE ONLY.

## wasp_ground.png

Use case: precise-object-edit. Create the LANDED form of this exact solitary wasp game boss. Keep black and yellow head, eyes, abdomen, six legs and long downward stinger unchanged. Fold all four wings tightly backward along its body so the silhouette is distinctly narrow instead of spread. Grounded top-down insect pose, head up, stinger down. Same chunky pixel art and palette. Truly transparent PNG alpha, no shadow plane, no checkerboard, no background, no text.

## Correction alpha du Merle

Use case: background-extraction. Edit this sprite: remove the entire gray and white checkerboard background, make the background genuinely transparent alpha=0, including holes between wings and legs. Keep the blackbird sprite, its BLACK eyes surrounded by YELLOW rings, gold beak, stepped pixel art and every body detail unchanged. Output transparent PNG. Do not draw a checkerboard.


## Correction alpha de la guêpe posée

Use case: background-extraction. Remove the gray and white checkerboard background completely from this existing sprite. Replace it with truly transparent alpha=0 pixels, including spaces between the insect’s legs and antennae. Keep the solitary wasp exactly unchanged with wings folded, head up, stinger down, black and gold pixel art. Transparent PNG output, NO painted checkerboard.
