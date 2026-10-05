# Serial Buffer : la coordination entre buffeurs du groupe

> État : **brouillon**, idée du user le 2026-10-05 (après la v0.2.0). Rien n'est décidé au-delà de
> ses mots, cités ci-dessous ; les questions ouvertes attendent ses réponses. Aucune ligne de code.
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

Dit autrement, à confirmer :
1. Chaque membre du groupe qui a Serial Buffer annonce aux autres sa grille pour le groupe (ce
   qu'il compte poser, sur quelle classe).
2. Dans les options, on voit la grille des autres buffeurs du groupe à côté de la sienne.
3. Une option (désactivée par défaut) laisse un autre joueur du groupe régler ta ligne « Groupe /
   raid » à ta place ; ses choix arrivent par le réseau et s'appliquent chez toi.
4. Chaque buff part toujours d'un clic ou d'une touche de **toi** (D2) : la coordination change ce
   que ta liste propose, jamais qui appuie.

## Ce qu'on NE fait PAS (proposé, à valider)

- **Lancer un sort à la place de quelqu'un** : impossible (D2) et hors sujet.
- **Parler aux joueurs qui n'ont pas l'addon** : aucun chuchotement, aucun message dans le chat
  (« pas de spam des joueurs », règle de l'écosystème).
- **Communiquer hors du groupe** : seuls ton groupe ou ton raid reçoivent les messages ; rien avec
  les inconnus d'Ironforge.
- **Laisser n'importe qui décider par défaut** : sans l'option, personne ne change tes buffs.
- **Parler le protocole d'un autre addon** (PallyPower et cie) : pas en première version (Q5).

## Ce qui n'est pas prouvé

- **H1 : un message d'addon en `PARTY`, `RAID` ou `INSTANCE_CHAT` arrive sur Forever.** Jamais
  mesuré : le skill public `wow-forever-api` (`chat-channels-and-communities.md`) ne couvre que le
  canal perso (livré), les canaux du jeu et les communautés (avalés en silence), `SAY` / `YELL`
  (refusés hors instance) et le chuchotement (livré). À éprouver d'abord, à deux comptes groupés,
  dehors puis en donjon.
- **H2 : en combat de BOSS, les envois d'addon sont bloqués** (verrou `Chat`, mesuré le 2026-09-30
  pour `SendChatMessage` sur un canal, `secret-values-and-lockdowns.md`). La coordination doit donc
  se faire hors combat de boss ; à vérifier pour `SendAddonMessage` en groupe.

## Cas particuliers (à trancher)

- Deux paladins choisissent la même bénédiction pour la même classe : qui cède ? (Q4)
- Le joueur qui décide pour toi quitte le groupe, ou se déconnecte : tes choix reviennent-ils à ta
  grille ?
- Deux joueurs veulent décider pour toi en même temps.
- Versions différentes de l'addon dans le groupe : un message inconnu est ignoré, jamais une erreur.
- Un message reçu en combat (le tableau est figé, D36) : il s'applique à la sortie du combat.
- Un raid de 40 : les messages doivent rester rares et groupés (un message par changement, pas un
  par seconde).
- Rien de ce qui arrive par le réseau n'est sauvegardé (règle « aucune donnée de joueur ») ; à la
  reconnexion, chacun se réannonce.

## Questions ouvertes (au user)

- **Q1 : qui peut décider pour toi**, quand l'option est active ? N'importe quel membre du groupe,
  le chef de groupe ou de raid (et ses assistants), ou un joueur que tu désignes par son nom ?
- **Q2 : qu'est-ce qui se coordonne ?** Seulement les bénédictions des paladins, ou aussi les buffs
  des prêtres, mages et druides (deux prêtres qui se partagent le raid) ?
- **Q3 : où voit-on les autres ?** Dans la grille des options (une ligne par buffeur), dans le
  tableau (« Rois : Paladin2 »), ou les deux ?
- **Q4 : conflit** : deux paladins sur la même bénédiction pour la même classe. Le premier annoncé
  garde, l'autre passe à son choix suivant ? Ou on laisse faire et on l'affiche seulement ?
- **Q5 : PallyPower** : faut-il un jour lire ses messages, pour coordonner avec des paladins qui ne
  l'ont pas, ou rester entre utilisateurs de Serial Buffer ?

## Critères d'acceptation (provisoires)

1. [humain] Deux comptes groupés, deux paladins : chacun voit dans ses options la grille de l'autre.
   Témoin connu-bon : la grille de l'autre, ouverte sur son écran.
2. [humain] Le paladin 2 active l'option ; le paladin 1 lui règle « Sagesse aux mages » ; le tableau
   du paladin 2 propose Sagesse à Gnomi. Sans l'option, rien ne change chez le paladin 2.
3. [test] Un message mal formé, d'une autre version ou d'un joueur hors du groupe est ignoré sans
   erreur, et ne change rien.
4. [humain] Une séance en donjon avec coordination ne laisse ni erreur Lua ni `ADDON_ACTION_BLOCKED`,
   y compris pendant un combat de boss.

## Contrat (à définir)

Le format des messages : préfixe d'addon dédié, numéro de version, une ligne par changement. À figer
avant le premier envoi, puisque des clients déjà déployés le liront.

## Renvois

- `serial-buffer.md` : D2 (un clic par buff), D22, D27, D34 à D36.
- Skill public `wow-forever-api` : `chat-channels-and-communities.md` (routes d'envoi mesurées),
  `secret-values-and-lockdowns.md` (verrou `Chat` en combat de boss).
- Mémoire de l'écosystème : CraftLink (transport d'addon de Crafting Order) a déjà payé les pièges
  des envois sur Forever ; règle « pas de spam des joueurs ».
