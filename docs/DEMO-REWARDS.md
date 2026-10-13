# Récompenses de la démo Steam

Royale (5) et Pétrole (26) sont réservés au compte ayant joué à la démo.
Soie (1) et Perle (2) restent les seuls skins de départ. Les outils de développement
peuvent toujours tout débloquer localement.

Lucas a confirmé que la démo sera une application Steam séparée et qu'aucun des
App ID n'est encore disponible. Le projet ne possède pas de liaison Steamworks :
**la reconnaissance automatique des comptes n'est donc pas encore branchée**.

Le point d'intégration prévu est `src/demo_progress.lua` :

1. Après authentification Steamworks, appeler `bindAccount(steamId)` avec
   l'identifiant réel sous forme de chaîne ; appeler `bindAccount(nil)` à la
   déconnexion. Ne pas utiliser le pseudo ni l'identité des classements HTTP.
2. La version démo se lance avec `--demo` (ou `SILKEN_DEMO=1`). Le lancement effectif
   d'une partie mémorise le compte dans `demo-entitlements.json` ; prévisualisations,
   replays et cartes de l'éditeur ne créent pas ce droit.
3. Quand les deux App ID seront connus, raccorder la liaison Steamworks et le
   transfert de ce fichier entre les sauvegardes des deux applications. La version
   complète doit lire la sauvegarde du compte authentifié avant d'afficher les skins.

Les comptes sont distingués et aucun skin n'est attribué uniquement parce qu'une
ancienne sauvegarde existe sur la machine. Les contrôles de développement et une
réinitialisation de progression ne suppriment pas le droit acquis par la démo.
