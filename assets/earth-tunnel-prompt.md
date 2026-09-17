# Tunnel de terre — imagegen intégré

## Variante finale retenue

Create a transparent-background PNG game sprite: a small overhead earthen burrow entrance, an opaque black oval opening encircled by chunky brown stones, dirt and a few twisted roots. Pixel art in the style of the attached transparent root sprite, but a tunnel opening rather than a trap. Single isolated object, centered. Use a real alpha transparency channel for all pixels outside the stones and roots. Keep the hole itself black and opaque. No backdrop or ground plane.

## Détourage final

Background extraction ONLY. Erase the entire gray and white checkerboard surrounding this burrow and all gaps between loose stones, replacing it with actual alpha=0 transparent pixels. Output RGBA PNG with TRUE transparent background, not a drawn checkerboard. Keep every brown rock/root detail and the central opaque black tunnel hole exactly unchanged. Do NOT make the black tunnel interior transparent. No new background, no white backdrop, no checkerboard.

Fichier : `assets/sprites/earth_tunnel.png`. Référence de style : `assets/sprites/root_snare.png`.

One isolated top-down pixel art game sprite of a burrow tunnel entrance cut into brown soil: dark oval hole descending underground, chunky raised rim of broken earth and stones, exposed twisted roots, a few loose pebbles, warm ochre highlights, NO teeth or trap mechanisms. Slight overhead RPG perspective, readable at 95px, gothic woodland animal game style matching reference. The central hole is opaque near-black; outside the whole entrance is genuine transparent alpha PNG, no ground rectangle, no scene, no checkerboard, no text. Centered complete asset with margin. Reference is style only, create an earthen tunnel rather than a root ring.
