# API Silken Hell

Worker et base exclusivement dédiés à Silken Hell. Aucun binding, migration ou route de GET OUT n'est utilisé.

## Routes

- `GET /health` : état et nom du service.
- `GET /v1/location` : code pays fourni par `request.cf.country` ; `ZZ` si inconnu.
- `GET /v1/leaderboard?world=1&scope=global` : 10 meilleurs joueurs, un résultat par identité, avec chrono, morts et skin.
- `GET /v1/leaderboard?world=1&scope=country` : même vue, filtrée par le pays détecté côté serveur.
- `POST /v1/runs` : `{name,world,skin}` crée une partie et fige son pays et son skin. Mondes jouables : 1, 2, 4, 5, 6.
- `POST /v1/runs/:id/checkpoint` : `{level,elapsedMs,deaths}` valide chaque niveau. Le dixième écrit le score.

Les POST demandent `Authorization: Bearer <64 caractères hexadécimaux aléatoires>`. Le serveur ne conserve que le SHA-256 de cette identité. Aucun secret Cloudflare n'est embarqué dans le jeu. Un pseudo n'est pas un compte authentifié.

Les contrôles empêchent notamment les niveaux sautés, les scores incomplets, les compteurs incohérents et les doubles soumissions. Ils ne prouvent pas l'intégrité d'un client modifié. Le déblocage des mondes est sauvegardé côté jeu pour conserver la progression hors ligne.

## Déployer

```
npm test
npx wrangler d1 migrations apply silken-hell-scores --remote
npx wrangler deploy
```

Le fichier `wrangler.jsonc` nomme explicitement la base dédiée. Ne jamais substituer une base de GET OUT. Un cron supprime les métadonnées des parties de plus de deux jours, sans supprimer les scores.

## Tests

`npm test` utilise `node:sqlite` de Node 24 et n'accède à aucune ressource distante. Les tests couvrent les pays, les mondes, l'authentification anonyme, la progression, l'idempotence, les temps impossibles, les charges trop grandes et la limitation de débit.

## Workshop

- `GET /v1/workshop?page=1` : huit cartes par page, triées par étoiles décroissantes ; état de l’étoile de l’installation si authentifiée.
- `GET /v1/workshop/:id` : carte et disposition complète.
- `POST /v1/workshop` : `{title,author,layout,id?}` publie une carte ou met à jour une publication appartenant à la même identité.
- `POST /v1/workshop/:id/star` : `{starred:true|false}` ajoute/retire l’unique étoile de cette installation.

Migration additive `0004_workshop.sql`. Cartes limitées à 1 000 objets et 128 Kio, format de données validé côté serveur/client, aucun code téléchargé. Créations limitées à 20/heure et 100 par identité ; limite IP commune conservée. Les identités restent anonymes par installation.
