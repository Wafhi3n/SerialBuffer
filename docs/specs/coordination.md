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

## Palier 1 : annoncer et afficher (2026-10-05) — vu en jeu à 13:08 (registre)

*Choix de l'agent pour le palier 1, le user ayant dit « tu peux commencer » ; à revoir s'il le
souhaite.* Rien de ce palier ne change ce que ton tableau propose : il annonce et il montre.

- **Ce qui s'annonce** : ta ligne « Groupe / raid » telle qu'elle s'appliquera, classe par classe :
  ton choix unique s'il est rempli et appris, sinon ce que ta colonne donnera (paladin : la
  première bénédiction connue ; prêtre, mage, druide : tous leurs buffs connus de la colonne).
- **Quand** : en entrant dans un groupe, à la connexion ou au `/reload` si tu es groupé (une
  demande « R », à laquelle les autres répondent par leur annonce), et quand tu changes ta grille.
  Chaque annonce est **regroupée** : plusieurs clics dans la grille en deux secondes font un seul
  message ; la réponse à une demande attend une à trois secondes au hasard, pour que tout un raid ne
  réponde pas d'un bloc.
- **Où** : `RAID` en raid, `PARTY` en groupe (R1 ter) ; jamais seul, jamais hors du groupe. Pendant
  un verrou de messagerie (`C_ChatInfo.InChatMessagingLockdown`, combat de boss), l'envoi attend.
- **Ce qui se reçoit** : seulement d'un membre de ton groupe (nom complet de l'expéditeur comparé à
  `GetUnitName(unité, true)` des membres), jamais de toi-même ; un message mal formé ou d'une autre
  version est ignoré sans erreur. Rien n'est sauvegardé ; un membre qui quitte le groupe disparaît.
- **Où ça se voit (C3)** : dans les options, sous la grille, une partie « Groupe / raid » : ta ligne
  (modifiable, comme avant) puis une ligne par autre Serial Buffer du groupe, son nom et ses icônes
  dans les colonnes des classes (lecture seule), jusqu'à huit lignes.

## Palier 2 : le premier arrivé garde, les paladins en surplus comblent (C4, 2026-10-05)

*Choix de l'agent pour appliquer C4, le user ayant dit « on continue le dev » ; à revoir s'il le
souhaite.* Seuls les **paladins** sont concernés (C2 : ce sont eux qui se partagent des buffs
uniques) ; les prêtres, mages et druides posent tout, comme avant.

- **« Premier annoncé » = le plus ancien dans le groupe** : chaque paladin annonce l'heure du
  serveur (`GetServerTime`) à laquelle il est entré dans le groupe. Le plus ancien passe devant ; à
  égalité, l'ordre alphabétique des noms complets. Tous les clients ont les mêmes chiffres, donc
  tranchent pareil. Un `/reload` ne te fait pas perdre ta place (l'heure est gardée tant que tu
  restes groupé).
- **La répartition, classe par classe** : chacun prend, dans **ses propres** préférences pour le
  groupe (son choix unique, puis sa colonne : D35, D37), la première bénédiction connue qu'aucun
  paladin plus ancien n'a annoncée pour cette classe. C'est ce qu'il annonce, et ce que son tableau
  propose aux membres du groupe de cette classe. Un paladin dont toutes les préférences sont prises
  ne propose rien à cette classe : on ne sort jamais de ce que le joueur a choisi dans sa grille
  (Salut sur un guerrier, par exemple, n'arrive que s'il l'a mis dans sa colonne).
- Le plus ancien ne bouge jamais pour un plus récent ; un plus récent se réajuste dès qu'une annonce
  d'un plus ancien change (regroupé, comme toute annonce).
- Un client du palier 1 n'annonce pas son heure d'arrivée : il compte comme le plus ancien (il ne
  sait pas se réajuster, les autres le contournent).
- **Les inconnus** dehors ne sont pas touchés : la répartition ne vaut que pour les membres du groupe.
- Les refus restent en place : trop bas (D24, D38) ou bénédiction d'un autre déjà là (D27), la ligne
  passe à la préférence suivante qu'aucun plus ancien n'a prise.
- `/sbuff groupe` montre aussi ta propre répartition.

## Palier 3 : laisser un autre régler ta ligne (C1, 2026-10-05)

*Choix de l'agent pour appliquer C1, le user ayant dit « vas-y » ; à revoir s'il le souhaite.*

- **L'option, à trois positions**, dans les options sous « Groupe / raid : qui pose quoi » : « qui
  peut régler ta ligne à ta place » : **personne** (par défaut), **le chef** (le chef du groupe ou
  du raid et ses assistants), **n'importe qui** du groupe. Trois cases qui s'excluent (aucun menu
  déroulant, ils font planter Forever).
- **Chaque annonce dit cette option** : les autres savent s'ils ont le droit de régler ta ligne.
- **Régler la ligne d'un autre** : dans la partie « qui pose quoi », les cases de la ligne d'un
  joueur qui te le permet deviennent cliquables (clic, molette), comme ta ligne « Toi » : vide, puis
  les buffs de SA classe, sans ceux qu'interdit D23. Ta modification part vers lui, regroupée (une
  seconde après ton dernier clic sur la même case), et ne change que cette case de sa ligne
  « Groupe / raid » (son choix unique pour cette classe). Les cases des autres restent en lecture
  seule.
- **Chez lui** : la modification ne s'applique que si l'expéditeur est de son groupe et que son
  option le permet à ce moment-là ; sinon elle est ignorée (et comptée). Appliquée, sa grille change
  comme s'il avait cliqué lui-même (même contrôle des ids, D23 compris), il voit dans son chat
  « <Nom> a réglé ta ligne Groupe / raid », et il se réannonce : tout le groupe voit le nouveau
  réglage, répartition du palier 2 comprise.
- Ça vaut pour toutes les classes qui ont des buffs : un chef peut ainsi assigner un buff unique à
  un prêtre pour une classe (C2). Par défaut, personne n'a de choix unique : chacun pose tout.
- Rien ne se lance tout seul (D2) : régler la ligne de quelqu'un change ce que SON tableau propose,
  c'est toujours lui qui clique.

## Contrat

**Message d'addon, préfixe `SBUF`, version 1.** Champs séparés par `|`, en ASCII :

- `1|R` : « annoncez-vous ». Celui qui le reçoit répond par son annonce.
- `1|A|<classe du lanceur>|<e1>|…|<e9>` : l'annonce. Les neuf entrées suivent l'ordre des colonnes
  de la grille (`WARRIOR PALADIN PRIEST SHAMAN DRUID ROGUE MAGE WARLOCK HUNTER`, `Buffs.CLASSES`) ;
  chacune est `0` (rien) ou des ids de sort de rang 1 séparés par `+` (`20217`, `1243+976`).

Un client lit les versions qu'il connaît et ignore le reste ; un champ en trop est ignoré. Changer
le sens d'un champ demande une version 2, jamais une retouche de la version 1.

**Ajout du palier 2, compatible avec la version 1** (un client du palier 1 ignore le champ en trop) :
un 13e champ, facultatif, après les neuf entrées : l'heure du serveur, en secondes entières, à
laquelle le lanceur est entré dans le groupe (`…|<e9>|1759662000`). Absent, mal formé : le lanceur
compte comme le plus ancien.

**SavedVariables** : `coordSince`, cette même heure, gardée tant que tu restes groupé (pour qu'un
`/reload` ne te fasse pas perdre ta place) et effacée hors groupe. Aucune donnée d'un autre joueur.

**Ajouts du palier 3, compatibles avec la version 1** :
- un 14e champ facultatif dans l'annonce, après l'heure d'arrivée : qui peut régler la ligne du
  lanceur, `N` (personne), `L` (le chef et ses assistants) ou `A` (n'importe qui). Absent ou autre :
  `N`. Un client qui n'a pas d'heure d'arrivée à donner écrit `0` en 13e champ.
- une nouvelle sorte de message, ignorée par un client des paliers 1 et 2 (« sorte inconnue ») :
  `1|S|<nom complet de la cible>|<classe>|<id>` : « règle le choix unique de cette classe dans ta
  ligne Groupe / raid » ; `<classe>` est l'un des neuf jetons de `WIRE_CLASSES`, `<id>` un id de
  sort de rang 1, ou `0` pour vider la case.
- **SavedVariables** : `coordWho` (`none`, `leader` ou `anyone` ; `none` par défaut).

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
