# Serial Buffer : la tournée des buffs en extérieur

> État : **validée par le user le 2026-10-04 (D1 à D23), faisabilité prouvée par la sonde**
> (relevés R1 à R5). Q11 et Q13 restent ouvertes. · Rédigée le 2026-10-04 · Idée du user le 2026-10-04,
> périmètre tranché par lui le même jour (cf. Décisions).
> **Le mécanisme retenu** : on **voit** les joueurs par leurs plaques (portée et buffs se lisent
> sur le jeton), on les **buffe** par un bouton macro à leur nom complet (`/targetexact Prénom
> Nom`). Le jeu refuse de lancer un sort sur un jeton de plaque (H1 fausse, H8 tient).
> Cible : WoW: Forever / Camelot (16001) · Addon : **Serial Buffer** (`SerialBuffer`, `/sbuff`),
> créé le 2026-10-04 (squelette `c886176`), déclaré **inactif** dans `addons.json` tant que c'est
> un squelette.
> Rédigée d'abord dans l'outillage (branche `docs/spec-serial-buffer`, `d62b315`, non fusionnée),
> puis déménagée ici. C'est **cette** copie qui fait foi.

## Le problème

Sur Forever, un buff dure une heure. Un mage, un prêtre, un druide ou un paladin qui veut en faire
profiter les joueurs qu'il croise doit les cibler un par un, vérifier dans l'infobulle s'ils ont déjà
le buff, lancer le sort, puis chercher le suivant. Dans une ville ou un camp de quête, on ne sait plus
qui on a déjà fait. Personne ne fait donc la tournée, et la plupart des joueurs passent sans buff.

## Ce qu'on veut

Hors combat, en extérieur, **un tableau sur le côté de l'écran** liste les joueurs amis autour de toi
**à qui il manque un de tes buffs** :
- ceux qui sont **à portée de sort** ;
- **les membres de ton groupe ou de ton raid, même hors de portée**, marqués comme tels.

Les joueurs y sont rangés **dans l'ordre où ils sont entrés dans la liste** : le premier entré est en
tête (FIFO). Un clic sur une ligne lance le buff sur ce joueur. Une touche « buff suivant » lance le
buff sur le premier de la liste qui est à portée, sans viser personne. Un joueur buffé **sort de la
liste tout de suite** : on enchaîne. Quand elle est vide, la tournée est finie.

Tous les buffs que ta classe sait poser sur un autre joueur sont cochés d'office ; tu décoches ce
que tu ne veux pas. Le paladin pose **la première bénédiction de sa liste de priorité qu'il connaît**
(Rois > Sagesse > Puissance par défaut), réglable dans les options du jeu (Options > AddOns). **Un buff de
mana ne va jamais à une classe sans mana** : pas de Sagesse ni d'Intelligence des Arcanes pour un
guerrier ou un voleur.

Chaque buff part **d'un clic ou d'une touche du joueur**. L'addon prépare la file, le joueur appuie.

Chaque ligne nomme le joueur et le buff qu'elle va lancer. Il n'y a **qu'une ligne par joueur**,
même s'il lui manque plusieurs buffs : elle propose le prochain qui manque.

## Ce qu'on NE fait PAS

- **Lancer un sort sans clic ni touche.** Le jeu l'interdit (`CastSpellByName` est protégé sur
  Forever), et ce n'est pas l'esprit de l'addon.
- **Instances** (donjon, raid, champ de bataille) : les plaques amies y sont interdites sur
  l'interface moderne (H2) et les noms y deviennent secrets. La liste s'y efface derrière un message.
- **Recalculer pendant ton combat** : le jeu interdit de changer les boutons sécurisés en combat. Le
  tableau se masque, ou reste affiché figé avec l'option (D12).
- **Version de groupe des buffs** (Illumination des Arcanes, Prière de robustesse, Don du fauve) en
  v1 : elle coûte des composants et ne touche que ton groupe. Les membres de ton groupe reçoivent la
  version simple, comme tout le monde.
- **Buffs sur soi seul** (armures, Feu intérieur…) : ce n'est pas une tournée.
- **Sorts qui changent les dégâts ou les soins reçus** (Amplifier la magie, Atténuer la magie) : on ne
  les impose pas à un inconnu.
- **Coordination entre buffeurs** (qui buffe qui, répartition des bénédictions entre paladins) :
  aucun message réseau en v1.
- **Aucun message aux joueurs buffés** (chuchotement, /dire) : c'est du spam.
- **Rien du voisinage n'est sauvegardé** : ni nom, ni GUID. La liste vit le temps de la session.
- **Classes sans buff long à poser sur un inconnu** (chaman, chasseur, démoniste, guerrier,
  voleur) : rien en v1.

## Ce qui n'est pas encore prouvé

La liste repose sur des faits que personne n'a encore mesurés sur Forever. La source Blizzard citée
est celle du build 70205, lue le 2026-10-04.

- **H1 : un bouton sécurisé lance un sort sur un joueur désigné par sa plaque** (jeton
  `nameplateN`). Côté Lua, `SECURE_ACTIONS.spell` (`SecureTemplates.lua`) transmet l'unité telle
  quelle à `CastSpellByID` / `CastSpellByName`. **FAUSSE (R3)** : le jeu ignore ce sort en silence.
  Le repli H8, le ciblage par le nom, **tient (R4)**, et les inconnus restent donc dans le
  périmètre.
- **H2 : dehors, la plaque d'un joueur ami arrive comme une plaque normale** (`NAME_PLATE_UNIT_ADDED`),
  pas comme une plaque interdite (`FORBIDDEN_NAME_PLATE_UNIT_ADDED`). En instance, elle est interdite
  sur l'interface moderne (vu sur TBC 2.5.6 en juillet 2026).
  **Mesuré sur Forever : interdite en instance (R1), normale dehors (R3).**
- **H3 : on sait si un joueur est à portée du sort** : `C_Spell.IsSpellInRange(sort, jeton)` est
  documentée, sans `HasRestrictions` (le marqueur d'une fonction protégée). **Mesuré (R1) : elle
  répond oui ou non sur un jeton de plaque, même interdite.**
- **H4 : on sait si un inconnu a déjà le buff**, quel que soit le joueur qui l'a posé et son rang :
  `C_UnitAuras.GetUnitAuraBySpellID` ou `GetAuraDataBySpellName`, documentées sans
  `HasRestrictions`. Trois réserves :
  - leur résultat peut devenir secret sous restriction (`SecretWhenUnitAuraRestricted`), d'où le
    combat et les instances exclus ;
  - leur argument d'unité est typé `UnitTokenRestrictedForAddOns`, un type que la doc ne définit
    nulle part. **Mesuré (R1) : un jeton de plaque, même interdite, est accepté hors combat**, et
    les deux lectures rendent l'aura et le temps qui reste ;
  - un sort à rangs porte un id par rang. **Mesuré (R1) : Forever garde les rangs.** Le nom
    « Blessing of Might » se résout en 19834 (rang 2), alors que le rang 1 est 19740. La lecture
    **par nom** est donc la bonne, puisqu'elle ne dépend pas du rang.
- **H5 : les plaques amies s'affichent au moins aussi loin que portent les buffs.** Sinon la liste
  rate des joueurs à portée. Aucune CVar de distance n'apparaît dans la source Camelot.
  **Tient à Ironforge (R3, R4)** : chaque relevé compte de 1 à 3 joueurs « hors portée », donc les
  plaques voient plus loin que Bénédiction de puissance.
- **H6 : un buff de haut rang sur un joueur de bas niveau** est soit refusé, soit lancé à un rang
  inférieur par le jeu. **Mesuré en partie (R5)** : Puissance (rang 2) passe sur un niveau 2, et
  Sagesse (rang 1, le seul connu) est refusée sur un niveau 2. Cela colle avec la règle de vanilla
  (cible ≥ niveau du sort − 10), mais **cette règle reste une hypothèse**. On ne sait pas non plus
  si le jeu abaisse le rang quand un rang plus bas est connu. Le test qui tranche : Puissance sur
  un niveau 1, puis lire le `spellId` de l'aura (19740 = rang abaissé ; refus = pas d'abaissement).
- **H7 : buffer un joueur en combat te met en combat**, ce qui figerait la liste. C'est le
  comportement connu du jeu, **pas mesuré** sur Forever. D16 exclut de toute façon les joueurs en
  combat.

### Relevés de la sonde

- **R1, 2026-10-04 16:31 et 16:32**, build 70205. Personnage : Rédemption (paladin), compte n° 4.
  Lieu : **en donjon, hors combat**, avec 4 joueurs amis (probablement le groupe). Ce que dit le
  journal de `DevMacroDB` :
  - les 4 plaques sont **INTERDITES** (`GetNamePlateForUnit` rend `nil`), et l'événement
    `FORBIDDEN_NAME_PLATE_UNIT_ADDED` est arrivé 9 fois pour des joueurs amis ;
  - les **noms se lisent en clair** sur ces jetons ;
  - `IsSpellInRange` rend « oui » ;
  - `GetAuraDataBySpellName` et `GetUnitAuraBySpellID` rendent l'aura sans erreur, y compris pour
    un joueur en combat ;
  - Bénédiction de puissance (19834) : **il reste 51 min**, sur un buff qui dure 5 minutes en
    vanilla. Cela corrobore D4 (1 h sur Forever).

  H1 n'a pas été éprouvée : la sonde ne vise pas une plaque interdite d'elle-même.
- **R2, 2026-10-04 16:35 et 16:36**, même lieu, même personnage. Mêmes résultats que R1. Entre
  deux relevés pris à 32 s d'écart, Gecko passe de `nameplate3` à `nameplate2` : les jetons
  changent de joueur en quelques secondes, d'où la règle « une ligne suit son joueur, jamais un
  jeton » (critère 11). Aucun bouton n'a été visé, donc H1 n'est toujours pas éprouvée.
- **R3, 2026-10-04 de 16:42 à 16:50, Ironforge**, dehors, hors combat, même personnage.
  - **Journal à 16:42** :
    - 19 joueurs amis, **aucune plaque interdite** : H2 vaut dehors ;
    - portée et auras lues sur tous ;
    - le bouton vise Polymorphme (`nameplate1`) ; quatorze clics entre 1 et 4 s après, et **aucun
      envoi de sort, aucun message d'erreur, aucun blocage d'addon**.
  - **Rapporté par le user**, avec le journal de ces gestes pas encore relu :
    - (3) `/cast [@nameplate3] Blessing of Might`, tapé à la main : **rien** ;
    - (4) le même bouton sur `target` : **buffe** ;
    - (5) le même bouton sur `player` : **buffe** ;
    - (6) le bouton qui lance par id (19834) sur `player` : rien. Le user venait de recevoir ce
      buff à l'étape 5, donc l'erreur « déjà actif » peut l'expliquer : ce n'est **pas un fait**
      tant que le journal n'est pas lu.
  - **Verdict : H1 est fausse.** Le jeu ignore en silence un sort lancé sur un jeton de plaque, que
    ce soit par le bouton ou par une macro tapée, alors que le même bouton marche sur `target` et
    sur `player`. **Doute levé dans le journal de 16:51 à 16:52** : plus de quarante clics sur le
    bouton visant `nameplate1`, puis `nameplate2`, avec `l'unité existe : true` à chaque clic, et
    aucun envoi de sort. Le jeton existait bien.
- **H8, le chemin de repli (TIENT, R4)** : un bouton de type `macro` qui cible par le **nom** et
  non par la plaque. `SECURE_ACTIONS.macro` passe par `C_Macro.RunMacroText`, et `/targetexact`
  existe (`SlashCommands.lua`, `TargetUnit(nom, true)`). Une ligne est donc liée au **nom complet**
  du joueur : le risque du jeton qui change de joueur ne touche plus que la lecture, jamais le
  lancer.
- **R4, 2026-10-04 de 16:57 à 17:00, Ironforge : H8 TIENT.**
  - **1er essai (16:57)** : `/targetexact Indy-Olsen` ne cible personne, et le sort part sur la
    cible d'avant, un sanglier (« Out of range »). Sur Forever, la 2e valeur de `UnitName` est un
    **nom de famille**, pas un royaume (déjà relevé par COC le 2026-09-27). Le nom à cibler est
    donc « Prénom Nom », avec une espace : c'est ce que rend `GetUnitName(unité, true)`.
  - **Corrigé (17:00)**, avec le texte de macro `/cleartarget`, `/targetexact Prénom Nom`,
    `/cast [@target,exists,help,nodead] <sort>`, `/targetlasttarget` :
    - **trois inconnus buffés d'un clic chacun** : Gerald Weatherlight, Monkeymagic Tripitaka,
      Moxxie Fizzlebang ;
    - chaque fois, envoi vers le bon nom complet, sort réussi, aura relue sur le joueur ;
    - **il restait 59 min 58 s** au buff juste après le lancer : Bénédiction de puissance dure
      **1 h** sur Forever (D4 confirmée pour ce sort).
  - **La cible n'est PAS rendue de façon fiable.** Avant le premier clic, tu n'avais pas de
    cible. Après le 1er clic : toujours pas de cible. Après les clics suivants : ta cible devient
    un joueur buffé plus tôt (Gerald), parce que `/targetlasttarget` reprend la cible
    précédente. Le user a tranché : D20.
- **R5, 2026-10-04 de 17:03 à 17:05, Ironforge** (H6).
  - **Journal** : Puissance (19834, rang 2) sur Gnomi Short, **niveau 2**, par le bouton macro :
    sort réussi, aura relue (59 min 58 s).
  - **Rapporté par le user**, lancé à la main, sans texte d'erreur relevé : Sagesse (19742, rang 1)
    est **refusée** sur une cible de niveau 2.

## Cas particuliers

- **Liste vide** : trois causes, trois messages distincts. Les plaques amies sont coupées ;
  personne n'est autour ; tout le monde est buffé (« Tournée finie »).
- **Entrée en combat** (D12) : par défaut, le tableau se masque, puis revient recalculé à la sortie.
  Avec l'option, il reste affiché, figé tel qu'avant le combat :
  - **toutes les lignes restent cliquables, inconnus compris** (D21). Le bouton cible par le nom,
    qui ne change pas de joueur. Un inconnu parti entre-temps ne reçoit rien : la macro ne lance
    que si le nom a bien été ciblé ;
  - une ligne buffée en combat se grise, et ne sort du tableau qu'à la fin du combat ;
  - la touche « buff suivant » ne fait rien en combat ;
  - **conséquence de la macro** : elle commence par vider ta cible, donc un clic en plein combat te
    fait perdre l'ennemi que tu visais.

  Le gris, la touche et la perte de cible découlent des règles du jeu sur les boutons sécurisés,
  pas d'un choix du user.
- **Instance** : un message remplace la liste ; aucun calcul.
- **Joueur déjà buffé par quelqu'un d'autre**, ou avec un rang plus fort : il a le buff, il n'entre
  pas dans la liste.
- **Il reste moins de 10 minutes au buff d'un joueur** (D11) : il rentre dans la liste, en fin de
  file. Même chose quand le buff a expiré.
- **Un inconnu sort de portée puis revient** : il sort de la liste, puis y rentre en fin de file.
- **Un membre du groupe hors de portée** : il reste dans la liste, à sa place, marqué « hors de
  portée ». La touche « buff suivant » le saute. Un clic sur sa ligne laisse le jeu dire qu'il est
  trop loin.
- **Un membre du groupe que le client ne voit pas** (autre carte, déconnecté) : on ne peut pas lire
  ses buffs (`GetUnitAuraBySpellID` rend `nil` pour une unité invisible), donc on ne sait pas s'il
  lui en manque un. Il est donc absent de la liste (D18).
- **Joueur en combat** : absent de la liste (D16). Il y entre, en fin de file, à la fin de son
  combat.
- **Joueur mort ou fantôme, PNJ, joueur de l'autre faction** : jamais dans la liste.
- **Joueur marqué PvP** : absent par défaut (D5).
- **Le sort échoue** (ligne de vue, mana, interruption) : le joueur reste dans la liste mais repasse
  en fin de file, pour ne pas bloquer la touche « buff suivant ». Le jeu affiche sa propre erreur,
  comme d'habitude. **Cible trop basse (H6)** : avec cette règle, le joueur tournerait dans la file
  sans fin. Voir Q11.
- **Une plaque disparaît et son jeton passe à un autre joueur** : une ligne suit **son joueur**,
  jamais un jeton. La plaque ne sert qu'à lire ; le lancer passe par le nom complet (H8). Un clic ne
  doit jamais buffer quelqu'un d'autre que le nom affiché.
- **Le nom ciblé n'existe plus** (joueur parti, déconnecté) : `/targetexact` ne cible personne, et
  **rien ne part**. La macro ne lance que sur une cible existante, amie et vivante. Relevé le
  2026-10-04 à 16:57, avant cette garde : le sort partait sur la cible d'avant.
- **Deux prêtres dans la zone** : si l'autre a posé Robustesse, le joueur n'entre pas dans ta liste.
- **Un nom ou un GUID secret** (ne devrait pas arriver dehors) : l'unité est ignorée, sans erreur.
- **Toi-même** : tu entres dans la liste si le buff te manque.

## Décisions

Toutes prises par le user le 2026-10-04.

- **D1 : le nom est « Serial Buffer ».** « Buffomatic » a été écarté parce qu'il est trop proche de
  Buffomat Classic, qui existe déjà sur CurseForge.
- **D2 : une liste hors combat, un clic par buff, et le joueur buffé sort de la liste.**
- **D3 : le terrain, c'est l'extérieur.** Le but est de buffer tout le monde dehors.
- **D4 : toutes les classes qui ont des buffs entrent dès la v1.** Selon le user, tous les buffs
  durent 1 h sur Forever. L'addon n'en dépend pas : il lit sur l'aura **le temps qui reste**, et ne
  code aucune durée.
- **D5 : les joueurs marqués PvP sont cachés par défaut**, et une option les affiche (marqués). Les
  buffer te met PvP.
- **D6 : l'addon propose d'activer les plaques amies** (en mode « noms seuls ») à la première
  ouverture. Si tu refuses, la question ne revient pas, et une liste vide dit pourquoi.
- **D7 : une ligne par joueur**, qui propose le prochain buff qui lui manque.
- **D8 : l'ordre est FIFO.** Le premier joueur entré dans la liste est en tête. Ni toi ni ton
  groupe ne passez devant.
- **D9 : un joueur hors de portée n'est pas dans la liste, sauf s'il est de ton groupe ou de ton
  raid.**
- **D10 : la liste est un tableau sur le côté de l'écran.**
- **D11 : à 10 minutes de l'expiration, un joueur peut revenir dans la liste.**
- **D12 : pendant ton combat, le tableau est désactivé**, sauf avec une option qui le garde
  affiché, figé (cf. Cas particuliers).
- **D13 : une ligne buffée sort tout de suite**, même si la souris est sur le tableau. « On est un
  serial buffer, on enchaîne. »
- **D14 : tous les buffs de la classe sont cochés par défaut.** Les sorts écartés plus haut
  (Amplifier, Atténuer la magie) n'en font pas partie.
- ~~D15 : le paladin pose une bénédiction par classe de la cible~~ : remplacée par D22.
- **D16 : un joueur en combat n'entre pas dans la liste** (il s'agit des joueurs de la liste, pas
  de toi). Le buffer te mettrait en combat et figerait le tableau (H7).
- **D17 : la commande est `/sbuff`.**
- **D18 : un membre du groupe que le client ne voit pas** (autre carte, déconnecté) **est absent de
  la liste** : on ne peut pas savoir s'il lui manque un buff.
- ~~D19 : la table du paladin par classe de cible~~ : remplacée par D22 et D23 le 2026-10-04.
- **D20 : après un buff, on passe au suivant de la file (FIFO)**, comme une pile. Rendre la cible
  que tu avais avant n'est pas un objectif. *Conséquence dérivée, non décidée par le user* : la
  macro n'a plus besoin de `/targetlasttarget`, qui ne rendait de toute façon pas la bonne cible
  (R4). Le dernier joueur buffé reste ciblé.
- **D21 : avec l'option « garder en combat », les lignes des inconnus restent cliquables**,
  comme celles du groupe. Cela remplace la conséquence tirée pour D12 avant H8 (lignes d'inconnus
  inactives en combat).
- **D22 : le paladin suit un ordre de PRIORITÉ, Rois > Sagesse > Puissance par défaut**, réglable dans
  les options du jeu (Options > AddOns > Serial Buffer). Chaque cible reçoit la première bénédiction
  de la liste que le paladin connaît, qui est cochée et qui lui sert (D23). Une bénédiction que tu ne
  connais pas encore (Rois est un talent) cède simplement sa place à la suivante. Salut n'est pas dans
  la liste. Cela règle Q12.
- **D23 : un buff de mana ne va jamais à une classe sans mana.** Bénédiction de sagesse,
  Intelligence des Arcanes et **Esprit divin** (ajouté par le user le même jour) sautent les
  guerriers et les voleurs : un paladin sans Rois donne Puissance au guerrier, un mage ne liste pas
  les guerriers ni les voleurs, et un prêtre ne leur propose que Robustesse et Protection contre
  l'Ombre. Rappel du user : seul le **paladin** ne pose qu'une bénédiction par joueur ; un prêtre, un
  mage ou un druide posent tous leurs buffs, l'un après l'autre (D7).

## Questions ouvertes (au user)

Q1 à Q10 sont tranchées (D8 à D19) et D20, D21 ajoutées, toutes le 2026-10-04.

- **Q11 : un joueur trop bas pour ton buff** (H6, R5 : Sagesse refusée sur un niveau 2). Avec la
  règle « le sort échoue → fin de file », il tournerait sans fin. Deux pistes :
  - **(a)** après un refus pour niveau, il sort de la liste pour ce buff, jusqu'à ce qu'il monte
    de niveau ;
  - **(b)** l'addon lance un rang plus bas que tu connais, s'il en existe un ; sinon, (a).

  La réponse dépend aussi de H6 : si le jeu abaisse déjà le rang tout seul, (b) n'a pas d'objet.
- ~~Q12 : une bénédiction de la table que tu ne connais pas~~ : réglée par D22, la suivante de la
  priorité prend sa place.
- **Q13 : un joueur à qui il manque deux buffs.** Après le premier, il garde sa place en tête (le
  comportement codé au palier (a)) ou repasse en fin de file ? « On passe à la suivante » (D20)
  peut se lire des deux façons.

## Critères d'acceptation

### La sonde, avant toute ligne de l'addon

- **S1** [humain] (H1) En ville, plaques amies activées, un clic sur le bouton de la sonde lance le
  buff sur le joueur de la première plaque amie listée, et **c'est ce joueur-là** qui le reçoit.
  Témoin connu-bon : le même sort lancé par `/cast [@target]` sur ce joueur ciblé. Observateur : le
  user, en jeu.
- **S2** [humain] (H2 à H5) La sonde affiche, pour chaque plaque amie : le nom, la portée
  (oui / non / rien), le buff présent ou non (ou l'erreur que rend la lecture d'aura sur ce jeton),
  et le type d'événement reçu (normal ou interdit).
  Témoin connu-bon : un joueur ciblé à côté de toi, observé avec puis sans le buff.
- **S3** [humain] (H6, H7) Un buff lancé sur un joueur de bas niveau, puis sur un joueur en combat :
  on note ce que fait le jeu.

### L'addon

1. [humain] Dehors, hors combat, plaques amies activées : le tableau sur le côté montre les joueurs
   amis à portée à qui il manque un buff coché, **et eux seuls**, dans leur ordre d'arrivée. Témoin
   connu-bon : les joueurs autour, comptés à l'œil, avec leurs buffs lus dans l'infobulle.
2. [humain] Un clic sur une ligne : le joueur nommé reçoit le buff, puis sa ligne sort aussitôt de
   la liste.
3. [humain] La touche « buff suivant », assignée dans le menu des raccourcis, buffe le premier de la
   liste qui est à portée.
4. [humain] Sans l'option, le tableau se masque à l'entrée en combat, et un clic à l'endroit où il
   était ne lance rien. À la sortie, il revient recalculé. Une séance qui mêle tournée et combats ne
   laisse ni `ADDON_ACTION_BLOCKED` ni erreur Lua (BugGrabber, `taint.log`).
5. [humain] Un joueur marqué PvP est absent par défaut. Avec l'option, il apparaît, marqué.
6. [humain] Plaques amies coupées : à la première ouverture, l'addon propose de les activer. Sur
   « oui », les plaques amies passent en noms seuls. Sur « non », la question ne revient pas, et la
   liste dit pourquoi elle est vide.
7. [humain] En donjon, un message remplace la liste, sans erreur.
8. [humain] À un joueur il manque deux buffs cochés : il n'a qu'une ligne, qui propose l'un puis
   l'autre, et il sort de la liste quand il a les deux.
9. [test] La liste se construit à partir d'unités simulées (ami, ennemi, PNJ, mort, PvP, en combat,
   déjà buffé, buff à moins de 10 minutes, hors portée, membre du groupe hors portée, toi-même) et
   contient exactement les bonnes, en ordre FIFO. Un joueur qui sort puis revient, ou dont le sort
   a échoué, repasse en fin de file.
   → `tests/test_serialbuffer_list.lua`, qui arrive en même temps que l'addon et jamais avant
   (`CLAUDE.md`).
10. [test] Une unité dont le nom ou le GUID est secret est ignorée, sans erreur et sans servir de clé
    de table.
11. [test] Une ligne suit son joueur : quand un jeton de plaque change de joueur, aucune ligne ne vise
    quelqu'un d'autre que le joueur qu'elle nomme.
12. [porte] Lua 5.1, tailles, locales complètes : `.\deploy.ps1 -Check`.
13. [agent] `api-gotcha-reviewer` : aucun appel à `CastSpellByName`, aucun attribut sécurisé changé
    en combat, toutes les lectures d'aura gardées.
14. [humain] Un membre du groupe loin de toi, mais sur la même carte, reste dans le tableau, marqué
    « hors de portée ». La touche « buff suivant » le saute. Témoin connu-bon : le même joueur,
    buffé normalement une fois revenu à portée.
15. [humain] Avec l'option « garder en combat » : en combat, le tableau reste affiché ; une ligne,
    d'inconnu ou du groupe, buffe ce joueur, puis se grise ; à la sortie du combat, le tableau se
    recalcule. Même absence d'erreur qu'au critère 4.
18. [humain] Un clic sur la ligne d'un joueur parti, ou qui a changé de nom : **rien ne part**, et
    aucun autre joueur n'est buffé. Témoin connu-bon : le relevé R4, avant la garde, où le sort
    partait sur la cible d'avant.
16. [humain] Un paladin sans Rois voit, dans le tableau, Puissance pour un guerrier et Sagesse pour
    un mage ; avec Rois, Rois pour les deux. Dans Options > AddOns > Serial Buffer, il fait
    descendre Rois : le tableau propose aussitôt la bénédiction suivante, et l'ordre survit à un
    `/reload`. Témoin connu-bon : la bénédiction lancée à la main.
17. [test] La priorité du paladin et D23 : sans Rois, Puissance au guerrier et Sagesse au mage ; avec
    Rois, Rois pour tous ; un ordre réglé l'emporte ; une bénédiction décochée cède sa place ; un
    mage ne propose rien aux guerriers ni aux voleurs.

## Contrat

- **SavedVariables : des réglages seulement.** Ce sont les buffs cochés par classe (`off`), l'ordre
  des bénédictions du paladin (`priority`), l'option PvP, l'option « garder en combat », la réponse à la proposition
  des plaques et la position du tableau. **Aucun nom de joueur, aucun GUID** : un secret sauvegardé
  empoisonne la base.
- **Raccourci clavier** « Serial Buffer : buff suivant », dans le menu des raccourcis du jeu.
- **Commande** : `/sbuff` (D17).

## Renvois

- Skill `wow-addon-dev:wow-forever-api`, références `taint-and-protected-frames` (bouton sécurisé,
  combat), `secret-values-and-lockdowns` (lecture d'aura qui lève une erreur, verrou d'instance),
  `missing-apis-and-guards` (`CastSpellByName` protégé).
- Skill `wow-classic-addon-dev` : les conventions, les portes, le banc.
- Skill `new-addon` : la création (`scripts\new_addon.ps1`).
- Skill `human-verification` : la sonde et les critères `[humain]`.
- COC, `CraftingOrderClassic_Compat.lua` (`A.PlayerName`) : sur Forever, la 2e valeur de
  `UnitName` est le nom de famille, et le nom complet est « Prénom Nom » (relevé du 2026-09-27).
- Source Forever 70205 : `Blizzard_FrameXML/SecureTemplates.lua` (`SECURE_ACTIONS.spell` et
  `.macro`), `Blizzard_ChatFrameBase/Shared/SlashCommands.lua` (`/targetexact`),
  `Blizzard_NamePlates/Camelot/Blizzard_NamePlateConstants.lua` (CVars des plaques amies),
  `Blizzard_APIDocumentationGenerated/SpellDocumentation.lua` (`IsSpellInRange`) et
  `UnitAuraDocumentation.lua` (`GetUnitAuraBySpellID`).

## Plan (2026-10-04, volatile)

1. ~~La sonde~~ : faite le 2026-10-04 (relevés R1 à R5). Elle vit dans
   `DevMacro/DevMacro_SBProbe.lua` (`/sbprobe`, `/sbprobe macro [n]` ; dépôt local DevMacro,
   `697b70c`). Ses sorties vont dans `DevMacroDB.log`. Restent H6 (niveau 1) et H7 (joueur en
   combat), qui ne bloquent pas. Les faits généraux vont dans le skill public `wow-forever-api`.
2. ~~Le user tranche les questions ouvertes~~ : fait le 2026-10-04 (D1 à D19).
3. ~~Création~~ : faite le 2026-10-04. Déclaration dans l'outillage (`a6993af` sur `master`,
   inactif), squelette créé (`c886176`), spec déménagée ici.
4. **Les paliers**, chacun testé au banc :
   - (a) la liste seule, sans clic (critères 1, 5, 7, 14). **Codé le 2026-10-04** (SerialBuffer
     `2b40b0b`, branche `feat/palier-a-tableau`), déployé au jeu (`feat/palier-a-tableau@2b40b0b`),
     **pas encore vu en jeu**. Test headless des critères 9, 10, 11 et 17 :
     `tests/test_serialbuffer_list.lua`, sur la branche d'outillage `feat/serialbuffer-palier-a`
     (`bb2257e`), à fusionner le même jour que ce palier sur `main`. Hors plan : le catalogue
     non paladin (mage, prêtre, druide) n'a jamais été vu sur Forever ;
   - (b) le clic et la touche (critères 2, 3, 8, 16) ;
   - (c) le combat (critères 4 et 15) ;
   - (d) la proposition des plaques et les options (critère 6).
