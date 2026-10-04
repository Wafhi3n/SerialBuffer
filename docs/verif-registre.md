# Registre de verification en jeu - SerialBuffer

Meme role que celui de Crafting Order - Classic : dire jusqu'ou l'addon a ete **vu fonctionner**
dans le client, puisque aucune porte automatique ne sait le dire. `scripts/untested.ps1 -Addon
SerialBuffer` fait l'union de tous les releves ci-dessous et liste ce qu'aucun n'avait dans le client.

Format d'un releve (le plus recent EN TETE) :

```
- AAAA-MM-JJ HH:MM - jusqu'a <sha> - <build> - <verdict> - <ce qui a ete observe>
```

Le `<sha>` est le dernier commit reellement present dans le client pendant la seance. On n'ecrit
un releve qu'APRES avoir observe, et on dit ce qui n'a PAS ete observe. Plusieurs sessions peuvent
ecrire ici en parallele : l'heure plutot qu'un numero du jour, et le fichier fusionne en
`merge=union` (`.gitattributes`) sans conflit.

**Un rebase perime le sha d'un releve** : apres le rebase d'une branche deja couverte, avancer son
sha (`git log --oneline` sur la nouvelle branche donne l'equivalent, le message est identique).

## Releves

- 2026-10-04 17:50 - jusqu'a c24d335 - feat/palier-a-tableau@c24d335 (deploye 17:44, charge au /reload de 17:46) - GO partiel palier (a) - Gnomi Short (mage niv. 2, compte n. 1), Ironforge, hors combat. Rapporte par le user, capture du chat a l'appui : « Serial Buffer loaded » SANS l'alerte « None of your buffs was recognized » -> Intelligence des Arcanes (id 1459, rang 1 de vanilla) est reconnue sur Forever. Le tableau listait les joueurs autour sans le buff ; le user les a buffes un par un A LA MAIN : chaque buffe sortait de la liste, jusqu'a la vider, et sa propre ligne aussi. BugGrabber : aucune erreur de SerialBuffer. NON observe : l'ordre FIFO, l'absence des guerriers et voleurs (D23), le membre du groupe hors de portee, le PvP (/sbuff pvp), le combat (pilote d'etat), l'instance, les options (/sbuff options), /sbuff cacher-afficher, le paladin (priorite D22), le pretre et le druide.
