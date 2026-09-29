# Silken Hell — liste des sons à créer

Inventaire du 28 septembre 2026. Cette liste propose les sons manquants ; elle ne les active pas dans le jeu. Les sons de boss devront suivre leurs animations définitives. Le boss des Abysses reste en chantier et le boss final reste à créer.

## Déjà disponibles et utilisés — inutile de les refaire

- `music et song/music/menu paradi.mp3` : musique des menus, coupée en partie et sur les résultats.
- `music et song/song/menu/go.mp3` : navigation, changement de monde, Échap.
- `music et song/song/menu/back.mp3` : boutons de retour.
- `music et song/song/menu/selection niveau.mp3` : Jouer, commencer un monde, choisir un niveau.
- `music et song/song/editeur start.mp3` : lancement du concepteur.

Les sons de mort, certaines interactions et la montée/descente de niveau hardcore sont encore synthétiques. Le jeu n'a pas encore de bibliothèque de bruitages propre à chaque créature. L'appel `abyssRoar` existe mais son fichier n'est pas chargé : il peut retomber sur le clic générique.

## Priorité 1 — retours de jeu essentiels

| Nom de fichier proposé | Son à produire | Durée indicative |
|---|---|---|
| joueur_mort_01 à 03.wav | Mort courte de l'araignée, trois variations douces, sans son agressif à chaque essai | 0,2–0,6 s |
| joueur_reapparition.wav | Retour du joueur après la mort | 0,2–0,5 s |
| joueur_chute.wav | Chute dans un trou, mouvement descendant | 0,4–0,9 s |
| niveau_termine.wav | Transition vers le niveau suivant | 0,4–0,9 s |
| monde_victoire.wav | Jingle de victoire d'un monde, pas la musique du menu | 3–6 s |
| boss_apparition.wav | Entrée en combat, impact bref | 1–2 s |
| boss_vaincu.wav | Défaite du boss, relâchement de tension | 1–3 s |
| hardcore_montee.wav | Passage au niveau supérieur, remplace la suite de notes actuelle | 0,3–0,6 s |
| hardcore_descente.wav | Retour au niveau inférieur après une mort | 0,3–0,6 s |
| erreur_action.wav | Action impossible ou donnée invalide | 0,15–0,3 s |
| succes_debloque.wav | Succès ou nouveau skin débloqué | 0,8–1,5 s |

Ne pas remettre de bip de larme ni de bip générique quand un boss est touché : ils ont été supprimés à ta demande. Les craquements physiques listés plus bas sont des options à valider séparément.

## Priorité 2 — boss

Prévoir une attaque distincte pour chaque mécanique, avec si nécessaire trois fichiers : préparation, attaque, fin. Les boucles de charge, d'aspiration ou de souffle doivent pouvoir s'arrêter proprement.

### Paradis — Merle noir

- `merle_cri.wav` : cri d'entrée ou début d'attaque.
- `merle_ailes_01 à 03.wav` : battements courts.
- `merle_plumes_tir.wav` : départ d'une salve de plumes.
- `merle_plume_fragmentation.wav` : plume qui se divise au contact d'un nid.
- `merle_oeuf_casse_01 à 03.wav` : coquille qui se brise.
- `merle_defaite.wav` : cri final, en remplacement du son de défaite générique.

### Ciel — Merle des orages

- `orage_cri.wav` : cri chargé d'électricité.
- `orage_dash.wav` : passage rapide de l'oiseau.
- `orage_plumes_noires.wav` : salve dangereuse.
- `orage_plume_doree_retour.wav` : plume jaune touchée, puis envol vers le boss.
- `orage_charge.wav` : préparation électrique.
- `orage_eclair.wav` : claquement d'éclair.
- `orage_defaite.wav` : extinction électrique et cri final.

### Terre — Hérisson

- `herisson_charge.wav` : mise en boule et accélération.
- `herisson_roulade_loop.wav` : roulement, boucle courte.
- `herisson_choc.wav` : arrêt ou collision lourde.
- `herisson_piquants.wav` : projection de piquants.
- `herisson_piquants_sol.wav` : impact des piquants.
- `herisson_defaite.wav` : fin du combat.

### Océan — Poulpe

- `poulpe_tentacule_leve.wav` : tentacule qui se déploie.
- `poulpe_tentacule_frappe_01 à 03.wav` : impact humide et lourd.
- `poulpe_encre.wav` : projection d'encre.
- `poulpe_deplacement.wav` : propulsion dans l'eau.
- `poulpe_defaite.wav` : mouvement final et bulles.

### Abysse — Léviathan, à finaliser après ses mécaniques

- `abysse_cri.wav` : grondement d'entrée / repoussement.
- `abysse_passage.wav` : corps immense traversant le niveau.
- `abysse_os_tir.wav` : départ des pointes.
- `abysse_os_impact.wav` : os qui frappe le sol.
- `abysse_os_casse_01 à 03.wav` : os qui se brise.
- `abysse_queue_detachee.wav` : détachement de la queue.
- `abysse_aspiration_debut.wav` : début de l'aspiration.
- `abysse_aspiration_loop.wav` : aspiration continue.
- `abysse_aspiration_fin.wav` : arrêt du souffle.
- `abysse_energie_bleue.wav` : charge bleue récupérée.
- `abysse_regeneration.wav` : énergie absorbée qui soigne le boss.
- `abysse_recrache.wav` : expulsion des éléments avalés.
- `abysse_defaite.wav` : effondrement du squelette.

Ne pas produire les anciens lasers pour l'instant : cette phase a été retirée.

### Enfer — Guêpes

- `guepe_vol_loop.wav` : bourdonnement local, discret, lié à la présence de la guêpe.
- `guepe_dash.wav` : accélération brutale.
- `guepe_venin.wav` : projectile de venin.
- `guepe_aterrissage.wav` : arrivée au sol.
- `guepe_invocation.wav` : apparition des petites guêpes.
- `guepe_defaite.wav` : fin du combat.

### Renaissance

- Boss final : attendre son apparence et ses attaques avant de produire ses sons.
- `retrouvailles.wav` : son doux au rapprochement des deux araignées.
- `famille_apparition.wav` : révélation des bébés après le fondu noir.

## Priorité 3 — créatures, dangers et interactions

Ces sons doivent être ponctuels et limités à proximité du joueur, pour éviter que toutes les créatures jouent en même temps.

- Araignée : petits pas secs, petits pas sur terre, déplacement aquatique — 3 à 5 variations par famille, facultatifs.
- Serpent : sifflement bref et mouvement d'attaque.
- Scie : rotation courte ou boucle locale, choc métallique.
- Piège : fermeture et capture.
- Larve : déplacement / bond court.
- Petite guêpe : vol local et attaque.
- Oiseau / mouette : battement d'ailes, cri bref, plongée.
- Taupe : creusement, sortie du sol, entrée dans un tunnel.
- Ver : sortie de terre et passage souterrain.
- Poisson : accélération dans l'eau, morsure.
- Crabe : course sur le sol, changement brusque de direction / pincement si utilisé.
- Méduse : pulsation lumineuse ou décharge, très courte.
- Poisson-lanterne : allumage / attaque lumineuse.
- Créatures de Renaissance : buisson qui s'agite, pas d'arbre, rencontre de l'araignée blanche.
- Dangers : déclenchement de piques, éruption de lave, projection de magma, chute de roche, foudre, trou qui s'ouvre.
- Interactions : entrée / sortie de tunnel, œuf ramassé ou cassé, capture / libération d'un porteur de larme.

## Concepteur de niveaux — facultatif, après le jeu

- `editeur_placer.wav` : poser un élément.
- `editeur_supprimer.wav` : enlever un élément.
- `editeur_annuler.wav` et `editeur_retablir.wav` : annuler / refaire.
- `editeur_sauvegarder.wav` : sauvegarde réussie.
- `editeur_tester.wav` : démarrer un test.
- `editeur_valide.wav` : carte validée.
- `editeur_erreur.wav` : placement / carte invalide.

Conserver les sons go, back et selection existants pour les actions communes ; inutile de refaire chaque clic.

## Musiques à composer, si tu veux sonoriser les parties

La musique de menu existe déjà. Les pistes suivantes sont proposées, pas encore raccordées :

- Une musique de jeu pour Paradis, Ciel, Terre, Océan, Abysse et Enfer, chacune bouclable.
- Une musique de boss commune pour commencer, puis éventuellement une variante par boss.
- Une musique de Sanctuaire, si souhaitée.
- Une musique de retrouvailles pour Renaissance.
- Une musique de crédits.
- Éventuellement une courte variante de victoire par biome ; un seul jingle commun suffit au départ.

Pas de boucle d'ambiance générale vent / eau / grondement à recréer pour le moment : tu as demandé de retirer le son d'ambiance.

## Livraison des fichiers

Bruitages : WAV, idéalement 48 kHz / 24 bits, mono pour les sons ponctuels. Musiques : WAV maître et export OGG, stéréo. Un fichier par événement, pas une longue piste qui regroupe plusieurs sons. Éviter les silences inutiles au début et la saturation. Pour les boucles, fournir un raccord propre et indiquer « loop » dans le nom. Fournir 2 ou 3 variations pour les sons très répétés. Les durées sont des repères, pas des contraintes strictes.

Ordre conseillé : mort → victoire → sons des six boss → dangers / ennemis → musique de partie → confort du concepteur.
