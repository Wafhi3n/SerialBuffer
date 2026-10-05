# Serial Buffer : la coordination entre buffeurs du groupe

> État : **brouillon, questions tranchées le 2026-10-05 (C1 à C5)**, idée du user le même jour
> (après la v0.2.0). Aucune ligne de code ; H1 (le message d'addon dans le groupe) à prouver d'abord.
> Spec mère : `serial-buffer.md` (D1 à D39), dont elle lève l'exclusion « Coordination entre
> buffeurs : aucun message réseau en v1 ».

## Le problème

Dans un groupe ou un raid à deux paladins (ou deux prêtres), chacun buffe de son côté. L'addon
devine ce que fait l'autre en lisant les buffs déjà posés (D27 : la bénédiction d'un autre paladin
fait passer à la suivante), mais seulement **après coup** : les deux peuvent viser la même classe
avec la même bénédiction, l'un écrase l'autre ou se fait refuser, et personne ne sait qui doit poser
quoi. Mesuré en donjon le 2026-10-05 : ce repli après coup a joué 395 fois en une séance.

Dans un raid, c'est d'habitude le chef ou un paladin qui répartit les bénédictions (« toi Rois aux
guerriers, moi Sagesse aux mages ») ; aujourd'hui, Serial Buffer ne sait rien de cette répartition.

## Ce qu'on veut

Les mots du user (2026-10-05) :
- « tous les membres du groupe qui ont l'addon communiquent entre eux pour faire en sorte de ne pas
  s'empiéter » ;
- « le paladin 1 voit quelle bénédiction le paladin 2 pose » ;
- « on peut rajouter un toggle pour faire en sorte qu'un autre joueur puisse décider de la
  bénédiction / du buff que l'on pose ».

Dit autrement, avec les décisions C1 à C5 :
1. Chaque membre du groupe qui a Serial Buffer annonce aux autres ce qu'il compte poser au groupe,
   sur quelle classe : sa ligne « Groupe / raid ».
2. Dans les options, **sous la grille**, une partie « Groupe / raid » montre une ligne par buffeur
   du groupe : la tienne (ta ligne « Groupe / raid », déplacée là) et celle des autres (C3).
3. Une option à trois positions dit **qui peut régler ta ligne à ta place** : personne, le chef
   (chef de groupe ou de raid et ses assistants), ou n'importe qui du groupe (C1). Ses choix
   arrivent par le réseau et s'appliquent chez toi.
4. Deux paladins sur la même bénédiction pour la même classe : le premier annoncé la garde ; les
   paladins en trop comblent les bénédictions qui manquent (C4).
5. Chaque buff part toujours d'un clic ou d'une touche de **toi** (D2) : la coordination change ce
   que ta liste propose, jamais qui appuie.

## Ce qu'on NE fait PAS (proposé, à valider)

- **Lancer un sort à la place de quelqu'un** : impossible (D2) et hors sujet.
- **Parler aux joueurs qui n'ont pas l'addon** : aucun chuchotement, aucun message dans le chat
  (« pas de spam des joueurs », règle de l'écosystème).
- **Communiquer hors du groupe** : seuls ton groupe ou ton raid reçoivent les messages ; rien avec
  les inconnus d'Ironforge.
- **Laisser quelqu'un décider par défaut** : l'option est sur « personne » tant que tu ne la
  changes pas (conséquence dérivée de C1, à confirmer).
- **Parler le protocole d'un autre addon** (PallyPower et cie) : on reste entre utilisateurs de
  Serial Buffer (C5).

## Ce qui n'est pas prouvé

- **H1 : un message d'addon en `PARTY`, `RAID` ou `INSTANCE_CHAT` arrive sur Forever.** Le skill
  public `wow-forever-api` (`chat-channels-and-communities.md`) ne couvrait que le canal perso
  (livré), les canaux du jeu et les communautés (avalés en silence), `SAY` / `YELL` (refusés hors
  instance) et le chuchotement (livré). **`PARTY` et `RAID` TIENNENT dehors (relevés R1 à R1 ter)** ;
  restent le donjon, `INSTANCE_CHAT` et le combat de boss.
  - **R1, 2026-10-05 vers 13:00, Hurlevent (canaux), dehors, hors combat**, Gnomi Short et
    Rédemption groupées, sans addon, par deux `/run` : chez Gnomi,
    `C_ChatInfo.SendAddonMessage("SBUF", "bonjour", "PARTY")` a rendu **0** (accepté) ; chez
    Rédemption, `CHAT_MSG_ADDON` est arrivé avec `bonjour`, `PARTY` et l'expéditeur **« Gnomi
    Short »** (le nom complet, avec l'espace : le même que `GetUnitName(unité, true)`, de quoi
    relier un message à un membre du groupe). Captures du user.
  - **R1 bis, quelques minutes après** : le groupe converti en raid (« Party converted to Raid »),
    la même ligne, toujours en `PARTY`, arrive encore deux fois chez Rédemption. En raid, `PARTY`
    vise le sous-groupe (les deux étaient dans le groupe 1). Le canal écrit dans le message est
    celui que l'envoi demande, pas le type du groupe.
  - **R1 ter, juste après** : Gnomi déplacée dans le groupe 2 du raid, Rédemption dans le groupe 1.
    Rapporté : « plus de message » (la ligne envoyée n'est pas dite ; avec `PARTY`, c'est attendu,
    le sous-groupe ne contient plus Rédemption). Puis `SendAddonMessage("SBUF", "bonjour", "RAID")`
    depuis Gnomi : reçu deux fois chez Rédemption, « bonjour RAID Gnomi Short ». **`RAID` traverse
    les sous-groupes.** D'où la règle du palier 1 : `RAID` en raid, `PARTY` en groupe.
    `INSTANCE_CHAT` (groupe formé par la recherche de groupe) n'est pas mesuré.
- **H2 : en combat de BOSS, les envois d'addon sont bloqués** (verrou `Chat`, mesuré le 2026-09-30
  pour `SendChatMessage` sur un canal, `secret-values-and-lockdowns.md`). La coordination doit donc
  se faire hors combat de boss ; à vérifier pour `SendAddonMessage` en groupe.

## Cas particuliers (à trancher)

- Deux paladins choisissent la même bénédiction pour la même classe : le premier annoncé la garde,
  l'autre comble ce qui manque (C4). Reste à dire ce que « premier » veut dire quand deux annonces
  se croisent (proposition : l'ordre d'annonce vu par le chef, sinon l'ordre alphabétique des noms,
  pour que tous les clients tranchent pareil).
- Le joueur qui décide pour toi quitte le groupe, ou se déconnecte : tes choix reviennent-ils à ta
  grille ?
- Deux joueurs veulent décider pour toi en même temps.
- Versions différentes de l'addon dans le groupe : un message inconnu est ignoré, jamais une erreur.
- Un message reçu en combat (le tableau est figé, D36) : il s'applique à la sortie du combat.
- Un raid de 40 : les messages doivent rester rares et groupés (un message par changement, pas un
  par seconde).
- Rien de ce qui arrive par le réseau n'est sauvegardé (règle « aucune donnée de joueur ») ; à la
  reconnexion, chacun se réannonce.

## Décisions

Toutes prises par le user le 2026-10-05, en réponse aux questions Q1 à Q5 du brouillon.

- **C1 : qui peut régler ta ligne à ta place, une option à trois positions** : « ceux qui ont la
  promote / raid leader » (le chef de groupe ou de raid et ses assistants), « n'importe qui », ou
  « personne ». *Conséquence dérivée : « personne » par défaut.*
- **C2 : la coordination vise d'abord les classes qui ont plusieurs buffs UNIQUES à se partager**,
  c'est-à-dire les paladins (une bénédiction par paladin et par cible). Elle reste ouverte aux
  prêtres, mages et druides « au cas où le raid lead veut assigner une personne à un buff » ; mais
  **par défaut, chacun de ceux-là pose tout**, comme aujourd'hui (D7).
- **C3 : ce que posent les autres se voit dans les options, sous la grille** ; ta propre ligne
  « Groupe / raid » descend dans cette partie, avec celles des autres buffeurs du groupe.
- **C4 : le premier annoncé garde sa bénédiction ; s'il y a trop de paladins, ceux en surplus
  comblent les bénédictions manquantes** (« les paladins en surplus font le remplissage des buffs
  manquants »).
- **C5 : on reste entre utilisateurs de Serial Buffer** pour le moment : pas de lecture des messages
  de PallyPower ou d'un autre addon.

## Critères d'acceptation (provisoires)

1. [humain] Deux comptes groupés, deux paladins : chacun voit dans ses options la grille de l'autre.
   Témoin connu-bon : la grille de l'autre, ouverte sur son écran.
2. [humain] (C1) Le paladin 2 règle l'option sur « le chef » ; le paladin 1, chef du groupe, lui
   règle « Sagesse aux mages » ; le tableau du paladin 2 propose Sagesse à Gnomi. Sur « personne »,
   rien ne change chez le paladin 2 ; un membre sans promotion n'a d'effet que sur « n'importe qui ».
3. [humain] (C4) Trois paladins, deux classes à servir : les deux premiers annoncés gardent leurs
   bénédictions, le troisième se voit proposer celles qui manquent.
4. [test] Un message mal formé, d'une autre version ou d'un joueur hors du groupe est ignoré sans
   erreur, et ne change rien.
5. [humain] Une séance en donjon avec coordination ne laisse ni erreur Lua ni `ADDON_ACTION_BLOCKED`,
   y compris pendant un combat de boss.

## Contrat (à définir)

Le format des messages : préfixe d'addon dédié, numéro de version, une ligne par changement. À figer
avant le premier envoi, puisque des clients déjà déployés le liront.

## Plan (2026-10-05, volatile)

0. ~~**La sonde H1**~~ : `PARTY` dehors, prouvé (R1). La même sonde en donjon et en `RAID` peut se
   faire pendant le palier 1, elle ne le bloque pas.
1. Annoncer sa ligne « Groupe / raid » et voir celle des autres sous la grille (C3).
2. Le premier annoncé garde, les paladins en surplus comblent (C4).
3. L'option à trois positions et le réglage à distance (C1).
4. L'assignation par le chef pour les prêtres, mages et druides (C2).

## Renvois

- `serial-buffer.md` : D2 (un clic par buff), D22, D27, D34 à D36.
- Skill public `wow-forever-api` : `chat-channels-and-communities.md` (routes d'envoi mesurées),
  `secret-values-and-lockdowns.md` (verrou `Chat` en combat de boss).
- Mémoire de l'écosystème : CraftLink (transport d'addon de Crafting Order) a déjà payé les pièges
  des envois sur Forever ; règle « pas de spam des joueurs ».
