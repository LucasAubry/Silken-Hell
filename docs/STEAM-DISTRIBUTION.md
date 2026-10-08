# Paquets autonomes Silken Hell

Les paquets générés sont dans `dist/steam/content/` et leurs archives de transfert
dans `dist/steam/`. Le joueur n’installe pas LÖVE, Python ou curl.

| Système | Contenu / exécutable Steam | Moteur et réseau |
| --- | --- | --- |
| Windows x64 | `windows/SilkenHell.exe` | LÖVE 11.5 fusionné, DLL et curl inclus |
| macOS Intel + Apple Silicon | `macos/Silken Hell.app` | LÖVE universel inclus ; curl natif de macOS |
| Linux x64 | `linux/SilkenHell.sh` | LÖVE AppImage extrait (sans FUSE), curl statique et certificats inclus |

Le rendu nécessite les pilotes graphiques compatibles LÖVE. Le paquet Linux est
testé sur Ubuntu 22.04 ; ce test ne constitue pas une certification Steam Deck.
Les sauvegardes et projets restent dans le dossier utilisateur, jamais dans
l’installation Steam. Le paquet contient l’éditeur, accessible depuis le jeu.

## Construire et vérifier

1. `python3 tools/package.py`
2. `python3 tools/build_desktop.py --platform windows` (possible depuis Mac).
3. `python3 tools/build_desktop.py --platform macos` (sur Mac).
4. `python3 tools/build_desktop.py --platform linux` (sur Linux avec Docker pour
   compiler curl statique). Les trois builds sont aussi automatisés dans GitHub.
5. `python3 tools/test_desktop.py --standalone windows|macos|linux` sur le système
   correspondant : lancement réel du paquet, sauvegardes, éditeur, combat, réseau.

Les téléchargements sont limités aux versions/empreintes consignées dans
`tools/desktop_dependencies.json`. Un changement de certificat CA ou de version
nécessite une mise à jour explicite de ce fichier. Les licences des composants
accompagnent les paquets. `build-manifest.json` contient les empreintes livrées.

La signature Mac locale est **ad-hoc** : pour la distribution publique, construire
avec `MACOS_SIGN_IDENTITY="Developer ID Application: …"`, puis notariser avec le
compte Apple du studio et agrafer le ticket avant l’envoi Steam. Aucun compte ni
certificat Apple n’a été inventé ou utilisé. Ne pas confondre lancement local
validé et validation Gatekeeper d’un téléchargement public.

## Configurer Steam plus tard

Aucun identifiant Steam n’est encore renseigné. Aucun envoi ni publication
Steam n’est effectué par ces scripts.

- `python3 tools/steam_config.py --templates` génère des modèles non exécutables
  `.vdf.template` dans `dist/steam/scripts`.
- Copier `steam/config.example.json` vers `steam/config.local.json`, puis remplir
  l’App ID et les trois Depot IDs réels.
- Dans Steamworks, associer chaque dépôt à son OS et au package vendu. Renseigner
  les trois options de lancement de `steam/launch-options.json`, sans argument.
  Sur Mac, sélectionner le bundle `.app` pour conserver le choix natif de
  l’architecture. Langues : toutes, pour chaque dépôt.
- `python3 tools/steam_config.py` produit les VDF avec `Preview 1`.
- Quand le contenu est validé, `python3 tools/steam_config.py --upload` produit
  les VDF d’envoi. Cela n’exécute toujours pas SteamCMD.
- Plus tard, sur une machine authentifiée :
  `steamcmd +login COMPTE_BUILD +run_app_build CHEMIN_ABSOLU/app_build.vdf +quit`.
  Le mot de passe et Steam Guard se saisissent dans SteamCMD ; aucun secret ne
  doit être ajouté au dépôt Git.
- Aucun script ne comporte `SetLive`. Activer d’abord une branche privée Steam
  et tester téléchargement, démarrage, sauvegarde et éditeur depuis le client.
  La mise en vente/branche publique est une étape distincte.

Les succès, classements et cartes fonctionnent actuellement via le système du
jeu et son API. Le SDK Steamworks, Steam Cloud et le Workshop natif ne sont pas
intégrés par ce travail d’empaquetage ; voir `STEAM-WORKSHOP.md`.

Références : [SteamPipe](https://partner.steamgames.com/doc/sdk/uploading),
[distribution LÖVE](https://love2d.org/wiki/Game_Distribution),
[curl Windows officiel](https://curl.se/windows/).
