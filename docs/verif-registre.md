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

- 2026-10-04 18:16 - jusqu'a b497d03 - feat/palier-b-clic@b497d03 (deploye 18:06) - GO palier (b), rapporte - Redemption (paladin, compte n. 4), Ironforge, hors combat. Rapporte par le user apres une passe complete : « ca fonctionne correctement » (le clic sur une ligne buffe ce joueur, la liste se vide, la premiere ligne reste en place, la cible trop basse n'y reste plus). Lu dans SerialBufferDB apres son /reload de 18:16 : position du tableau convertie en TOPLEFT/BOTTOMLEFT (ancrage par le haut, D25) ; seenErrors = ERR_SPELL_FAILED_S « Target is too low level » et ERR_SPELL_COOLDOWN « Spell is not ready yet. » (le refus pour niveau est donc arrive et a ete traite par son TEXTE, D24). BugGrabber : aucune erreur de SerialBuffer. NON observe : la touche « buff suivant » (raccourci CLICK), le combat (tableau masque, touche inerte), le PvP, l'instance, /sbuff options, le pretre et le druide.

- 2026-10-04 18:21 - jusqu'a b497d03 - feat/palier-b-clic@b497d03 ou @3a3e57c (deploye 18:17 ; le /reload qui l'aurait charge n'est pas connu, le raccourci est le meme dans les deux) - GO touche « buff suivant », rapporte - Redemption (paladin), Ironforge. Rapporte par le user : « oui elle fonctionne » — le raccourci « Next buff » (section Serial Buffer du menu des raccourcis, Bindings.xml : CLICK SerialBufferNextButton:LeftButton, runOnUp) assigne a une touche buffe le premier de la file a chaque appui. Premier raccourci CLICK d'un de nos addons eprouve sur Forever. NON observe : la touche en combat (doit ne rien faire), la touche quand le tableau est cache par /sbuff.
