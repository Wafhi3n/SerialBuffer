# Serial Buffer : la tournée des buffs en extérieur

> État : **validée par le user le 2026-10-04 (D1 à D29), faisabilité prouvée par la sonde**
> (relevés R1 à R5). **Étendue le 2026-10-05 (D30 à D33)** : le groupe et le raid passent devant,
> la liste du groupe vit aussi en instance, un rouage sur le tableau ouvre une grille buffs × classes.
> · Rédigée le 2026-10-04 · Idée du user le 2026-10-04, périmètre tranché par lui le même jour
> (cf. Décisions).
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

En instance (donjon, raid), le tableau ne liste que ton groupe ou ton raid (D31) : les inconnus
sont une affaire d'extérieur, le groupe se buffe partout.

Les joueurs y sont rangés **dans l'ordre où ils sont entrés dans la liste** : le premier entré est en
tête (FIFO). **Les membres de ton groupe ou de ton raid passent devant**, dans une partie à eux en
haut du tableau (D30) ; les autres suivent. Un clic sur une ligne lance le buff sur ce joueur. Une touche « buff suivant » lance le
buff sur le premier de la liste qui est à portée, sans viser personne. Un joueur buffé **sort de la
liste tout de suite** : on enchaîne. Quand elle est vide, la tournée est finie.

Tous les buffs que ta classe sait poser sur un autre joueur sont cochés d'office ; tu décoches ce
que tu ne veux pas, **classe par classe**, dans une grille des options (une ligne par buff, une
colonne par classe de la cible, comme un tableur ; D33), qu'un rouage du tableau ouvre (D32). Le
paladin pose **la première bénédiction de sa liste de priorité qu'il connaît et qui est cochée pour
la classe de la cible** (Rois > Sagesse > Puissance par défaut), réglable dans les options du jeu
(Options > AddOns). **Un buff de mana ne va jamais à une classe sans mana** : pas de Sagesse ni
d'Intelligence des Arcanes pour un guerrier ou un voleur.

Chaque buff part **d'un clic ou d'une touche du joueur**. L'addon prépare la file, le joueur appuie.

Chaque ligne nomme le joueur et le buff qu'elle va lancer. Il n'y a **qu'une ligne par joueur**,
même s'il lui manque plusieurs buffs : elle propose le prochain qui manque.

## Ce qu'on NE fait PAS

- **Lancer un sort sans clic ni touche.** Le jeu l'interdit (`CastSpellByName` est protégé sur
  Forever), et ce n'est pas l'esprit de l'addon.
- **Les inconnus en instance** (donjon, raid, champ de bataille) : les plaques amies y sont
  interdites sur l'interface moderne (H2) et les noms peuvent y devenir secrets. En instance, la
  liste ne montre **que ton groupe ou ton raid** (D31).
- **Recalculer pendant ton combat** : le jeu interdit de changer les boutons sécurisés en combat. Le
  tableau reste affiché, figé ; seules les lignes du groupe restent cliquables (D36).
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

- **Liste vide** : quatre causes, quatre messages distincts. Les plaques amies sont coupées ;
  personne n'est autour ; tout le monde est buffé (« Tournée finie ») ; des joueurs sont illisibles
  (nom ou buffs cachés par le jeu, surtout en instance : D31), comptés dans le pied.
- **Entrée en combat** (D36) : le tableau reste affiché, figé tel qu'au pull, et se recalcule à la
  sortie :
  - les lignes du groupe (et la tienne) restent cliquables, par le jeton de groupe, sans toucher à
    ta cible ; celles des inconnus s'éteignent et ne lancent rien ;
  - une ligne buffée en combat se grise, et ne sort du tableau qu'à la fin du combat ;
  - la touche « buff suivant » ne fait rien en combat ;
  - si le groupe change pendant le combat, les lignes du groupe affichent « groupe changé » : un
    clic peut alors toucher un autre membre (exception de D36).

  Le figé, le gris et la touche inerte découlent des règles du jeu sur les boutons sécurisés, pas
  d'un choix du user.
- **Instance** (D31) : la liste ne montre que ton groupe ou ton raid, sans les plaques. Un membre
  dont le nom ou les buffs sont illisibles (verrou `Map` : les noms deviennent secrets en donjon)
  n'entre pas, et le pied du tableau compte ces joueurs illisibles, pour qu'une liste vide ne passe
  pas pour une tournée finie.
- **Toi, dans un groupe** : tu es dans la partie du groupe (D30). Seul, tu restes dans la liste à ta
  place d'arrivée, comme avant (D8).
- **Joueur déjà buffé par quelqu'un d'autre**, ou avec un rang plus fort : il a le buff, il n'entre
  pas dans la liste.
- **Il reste moins de 10 minutes au buff d'un joueur** (D11) : il rentre dans la liste, en fin de
  file. Même chose quand le buff a expiré.
- **Un inconnu sort de portée puis revient** : il sort de la liste, puis y rentre en fin de file.
- **Un membre du groupe hors de portée** : il reste dans la liste, marqué « hors de portée », dans
  une partie à lui tout en bas (D25, D30). La touche « buff suivant » le saute. Un clic sur sa ligne laisse le jeu dire qu'il est
  trop loin.
- **Un membre du groupe que le client ne voit pas** (autre carte, déconnecté) : on ne peut pas lire
  ses buffs (`GetUnitAuraBySpellID` rend `nil` pour une unité invisible), donc on ne sait pas s'il
  lui en manque un. Il est donc absent de la liste (D18).
- **Joueur en combat** : absent de la liste (D16). Il y entre, en fin de file, à la fin de son
  combat.
- **Joueur mort ou fantôme, PNJ, joueur de l'autre faction** : jamais dans la liste.
- **Joueur marqué PvP** : absent par défaut (D5).
- **Le sort échoue** (hors de vue, hors de portée, cible invalide) : le joueur reste dans la liste
  mais repasse en fin de file, pour ne pas bloquer la touche « buff suivant ». Le jeu affiche sa
  propre erreur, comme d'habitude. Un « sort pas prêt » (clic martelé pendant le temps de recharge
  global) ne fait rien. **Cible trop basse** : D24.
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

Toutes prises par le user : D1 à D29 le 2026-10-04, D30 à D33 le 2026-10-05.

- **D1 : le nom est « Serial Buffer ».** « Buffomatic » a été écarté parce qu'il est trop proche de
  Buffomat Classic, qui existe déjà sur CurseForge.
- **D2 : une liste hors combat, un clic par buff, et le joueur buffé sort de la liste.**
- **D3 : le terrain, c'est l'extérieur.** Le but est de buffer tout le monde dehors. Pour les
  inconnus seulement depuis D31 (2026-10-05) : le groupe et le raid se buffent aussi en instance.
- **D4 : toutes les classes qui ont des buffs entrent dès la v1.** Selon le user, tous les buffs
  durent 1 h sur Forever. L'addon n'en dépend pas : il lit sur l'aura **le temps qui reste**, et ne
  code aucune durée.
- **D5 : les joueurs marqués PvP sont cachés par défaut**, et une option les affiche (marqués). Les
  buffer te met PvP.
- **D6 : l'addon propose d'activer les plaques amies** (en mode « noms seuls ») à la première
  ouverture. Si tu refuses, la question ne revient pas, et une liste vide dit pourquoi.
- **D7 : une ligne par joueur**, qui propose le prochain buff qui lui manque.
- **D8 : l'ordre est FIFO.** Le premier joueur entré dans la liste est en tête. ~~Ni toi ni ton
  groupe ne passez devant~~ : le groupe passe devant depuis D30 (2026-10-05). Le FIFO tient à
  l'intérieur de chaque partie du tableau.
- **D9 : un joueur hors de portée n'est pas dans la liste, sauf s'il est de ton groupe ou de ton
  raid.**
- **D10 : la liste est un tableau sur le côté de l'écran.**
- **D11 : à 10 minutes de l'expiration, un joueur peut revenir dans la liste.**
- ~~D12 : pendant ton combat, le tableau est désactivé, sauf avec une option qui le garde affiché,
  figé~~ : remplacée par D36 le 2026-10-05 (affiché, figé, toujours).
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
- ~~D21 : avec l'option « garder en combat », les lignes des inconnus restent cliquables~~ :
  remplacée par D36 le 2026-10-05 (en combat, seules les lignes du groupe sont cliquables).
- **D22 : le paladin suit un ordre de PRIORITÉ, Rois > Sagesse > Puissance par défaut**
  (*depuis D34, le 2026-10-05 : un ordre par classe de la cible, dans la grille ; le défaut reste
  celui-ci*), réglable dans
  les options du jeu (Options > AddOns > Serial Buffer). Chaque cible reçoit la première bénédiction
  de la liste que le paladin connaît, qui est cochée et qui lui sert (D23). Une bénédiction que tu ne
  connais pas encore (Rois est un talent) cède simplement sa place à la suivante. Salut n'est pas dans
  la liste. Cela règle Q12.
- **D24 : une cible trop basse pour un buff sort de la liste POUR CE BUFF**, jusqu'à ce qu'elle monte
  de niveau (retour du user en jeu, 2026-10-04 : « malgré l'erreur target too low elle reste dans la
  liste »). Un paladin passe à la bénédiction suivante de sa priorité ; un prêtre au buff suivant ;
  si tout est refusé, le joueur sort de la liste. Cela règle Q11. L'erreur se reconnaît par son nom
  (`GetGameMessageInfo`, quelle que soit la langue), sinon par son texte.
- **D25 : la première ligne ne bouge pas** (retour du user : « pour qu'on puisse spammer le clic sur
  la première ligne et buffer tout le monde »). Le tableau s'accroche par son coin haut, et le bas
  remonte quand la liste raccourcit. *Conséquence dérivée, non décidée par le user* : les membres du
  groupe hors de portée passent en bas de l'AFFICHAGE, sous les joueurs à portée, pour que la
  première ligne soit toujours quelqu'un qu'on peut buffer. L'ordre FIFO tient à l'intérieur de
  chaque partie.
- **D26 : « un sort plus puissant est actif » écarte le joueur pour CE buff, 20 minutes** (retour
  du user en jeu, 2026-10-04 : l'erreur « empêche le nôtre de se mettre et n'enlève pas la personne
  de la liste »). Il passe au buff suivant, ou sort de la liste. L'erreur se reconnaît par son texte
  (`SPELL_FAILED_AURA_BOUNCED`). *Le délai de 20 min est un choix de code* : on ne sait pas quand le
  sort plus puissant expire.
- **D27 : paladin, la bénédiction voulue déjà posée par un AUTRE paladin avec plus de 30 minutes
  restantes fait passer à la suivante** (décision du user, 2026-10-04 : « le mage a déjà Rois, l'addon
  doit nous faire mettre Sagesse » ; « plus d'une demi-heure » est son exemple de seuil). Un paladin
  ne garde qu'une bénédiction à lui par joueur, d'où trois cas :
  - celle d'un autre, plus de 30 min : la suivante de la priorité ;
  - celle d'un autre, 30 min ou moins : on la refait, pour la rafraîchir (confirmé par le user le
    2026-10-04) ;
  - la sienne, ou un lanceur illisible : le joueur est servi, sauf si elle expire (D11).
  Le lanceur se lit comme le fait Blizzard (`sourceUnit` comparé à `"player"`). Ce n'est **pas
  encore mesuré** sur Forever pour un buff posé par un autre joueur.
- **D28 : hors paladin, un joueur dont le buff a encore plus de 45 minutes n'apparaît pas**
  (demande du user, 2026-10-04 : « idem pour les sorts des autres classes, si un sort a plus de
  45-50 min il n'apparaît pas, sauf config dans les options »). En dessous du seuil, il revient
  dans la liste pour être rafraîchi, quel que soit le lanceur du buff. Le seuil se règle dans les
  options (− / +, par pas de 5 min, de 10 à 55) ; 45 par défaut, le bas de la fourchette du user.
  Remplace D11 pour le prêtre, le mage et le druide ; le paladin garde D11 (10 min) et D27.
- **D29 : un joueur à qui il manque plusieurs buffs garde sa place en tête** jusqu'à les avoir tous :
  le clic suivant sur la première ligne lui donne le buff d'après. Le user n'avait pas de
  préférence (2026-10-04) ; l'agent a gardé ce comportement, déjà codé : un joueur qui s'en va ne
  repart pas à moitié buffé. L'autre voie (fin de file après chaque buff, donc des tours) reste
  possible si le user la demande.
- **D23 : un buff de mana ne va jamais à une classe sans mana.** Bénédiction de sagesse,
  Intelligence des Arcanes et **Esprit divin** (ajouté par le user le même jour) sautent les
  guerriers et les voleurs : un paladin sans Rois donne Puissance au guerrier, un mage ne liste pas
  les guerriers ni les voleurs, et un prêtre ne leur propose que Robustesse et Protection contre
  l'Ombre. Rappel du user : seul le **paladin** ne pose qu'une bénédiction par joueur ; un prêtre, un
  mage ou un druide posent tous leurs buffs, l'un après l'autre (D7).
- **D30 : les membres du groupe ou du raid à buffer passent devant**, dans une partie à eux en haut
  du tableau, distinguée des autres (demande du user, 2026-10-05 : « il faut qu'au-dessus de la
  liste on distingue les membres du groupe/raid qui doivent être buff en priorité »). Remplace « ni
  ton groupe ne passe devant » de D8. Le FIFO tient dans chaque partie, et la touche « buff
  suivant » sert donc le groupe d'abord. *Conséquences dérivées, non décidées par le user* :
  - trois parties, chacune sous un titre : **Raid** (ou **Groupe**), **Autour de toi**, puis **Hors
    de portée** (les membres du groupe trop loin), tout en bas pour que la première ligne reste
    quelqu'un qu'on peut buffer (D25) ;
  - les titres n'apparaissent que si tu es groupé : seul, le tableau garde son allure d'avant ;
  - toi, groupé, tu es dans la partie du groupe ; seul, tu restes à ta place d'arrivée (D8).
- **D31 : l'addon traite le groupe et le raid autrement que les inconnus** : en instance (donjon,
  raid), la liste montre ton groupe ou ton raid, au lieu de se mettre en pause. Les inconnus restent
  une affaire d'extérieur (plaques interdites en instance). *Interprétation de l'agent* de la réponse
  du user (2026-10-05) à « en instance, pause ou groupe seul ? » : « l'addon doit se comporter
  différemment avec les membres de groupe/raid qu'avec les randoms ». **Jamais mesuré** : la lecture
  des noms et des buffs sur `raidN` / `partyN` en instance (le verrou `Map` rend des noms secrets en
  donjon), et `/targetexact` en instance. Un nom ou un buff illisible écarte le joueur (règle de
  sûreté) et le pied du tableau compte les illisibles.
- **D32 : un rouage sur le tableau ouvre les options** (demande du user, 2026-10-05). Pas en combat :
  le panneau d'options du jeu ne s'ouvre pas pendant un combat.
- **D33 : une grille buffs × classes dans les options, « comme un tableur »** (demande du user,
  2026-10-05 : « pouvoir choisir quel buff on met sur quelle classe »). Une ligne par buff, une
  colonne par classe de la cible ; une case cochée = ce buff se pose sur cette classe.
  - **Paladin** : les six bénédictions (Rois, Sagesse, Puissance, Salut, Lumière, Sanctuaire ; choix
    du user le 2026-10-05). Salut, Lumière et Sanctuaire sont **décochées partout par défaut**
    (proposé par l'agent dans la question, retenu). Chaque cible reçoit la première bénédiction de
    la priorité (D22) qui est connue, cochée pour sa classe, et qu'elle peut recevoir (D23, D24,
    D27). « Une bénédiction par classe » s'obtient en ne cochant qu'elle dans la colonne. L'ordre se
    règle toujours avec Monter / Descendre, sur la ligne de la grille.
  - **Les cases de D23** (buff de mana × guerrier, voleur) sont **grisées, jamais cochables** :
    D23 dit « jamais ».
  - *Conséquence dérivée* : la case à cocher globale d'un buff (D14) disparaît au profit de la
    grille. Un buff décoché avant la grille l'est pour toutes les classes après la mise à jour (la
    base passe à `schemaVer` 2).

  **La forme de D33 (cases à cocher, priorité globale à flèches) est remplacée par D34 le jour
  même**, après la capture du user. Restent de D33 : une colonne par classe, les six bénédictions,
  Salut, Lumière et Sanctuaire absentes par défaut, D23 jamais.
- **D34 : chaque case de la grille est une ICÔNE qu'on change au clic ou à la molette**, de « vide »
  à chacun des buffs disponibles (demande du user, 2026-10-05, sur sa capture : « pour simplifier
  chaque case est une icône qu'on change au clic ou à la molette, on va de vide à tous les buffs
  dispo »). Choix du user sur maquette, le même jour : **plusieurs choix par classe**, une ligne par
  rang (1er choix, 2e, 3e) :
  - **paladin** : chaque classe reçoit le 1er choix de SA colonne ; s'il ne passe pas (pas appris,
    trop bas D24, déjà posé par un autre paladin D27), le 2e, puis le 3e. **Remplace la priorité
    globale de D22** (une liste réglée par flèches) : la priorité est maintenant par classe ;
  - **prêtre, mage, druide** : la colonne donne les buffs à poser sur cette classe, dans l'ordre
    (D7) ; une case vide = un buff de moins ;
  - une première colonne **« Toutes »** : on y choisit une icône, puis le bouton **Remplir** de la
    ligne la recopie sur toutes les classes ;
  - un bouton **↺ sous chaque classe** remet sa colonne par défaut (« un bouton pour remettre les
    choix pour la classe par défaut »), et **« Tout par défaut »** remet toutes les colonnes de ta
    classe.

  *Conséquences dérivées, non décidées par le user :*
  - trois rangs pour le paladin, comme sur la maquette ; pour les autres, autant de rangs que de
    buffs (prêtre 3, druide 2, mage 1) ;
  - clic gauche et molette vers le bas : buff suivant ; clic droit et molette vers le haut : buff
    précédent ;
  - une case ne propose que vide, puis les buffs qui ne sont ni interdits à la classe (D23) ni déjà
    pris à un autre rang de la même colonne ;
  - Remplir **laisse telle quelle** une case où le buff est interdit (Sagesse sur un guerrier) et,
    si le buff est déjà à un autre rang de la colonne, **échange** les deux cases ;
  - la colonne « Toutes » n'est qu'un modèle de la séance (non sauvegardé), qui part du défaut ;
  - un buff que le client ne sait pas nommer n'apparaît pas dans la grille (Sanctuaire, id 20911,
    relevé du 2026-10-05 09:55) ;
  - le réglage est rangé **par classe du lanceur** : la base est commune au compte, un paladin et un
    prêtre du même compte ont chacun leur grille ;
  - la base passe à `schemaVer` 3 : les réglages d'avant (cases décochées de la v0.1.0, priorité
    du paladin, grille D33) deviennent les colonnes équivalentes.
- **D35 : une ligne « Groupe / raid » à part, un CHOIX UNIQUE par classe, « au cas où »** (demande
  du user, 2026-10-05 : « on pourrait rajouter une table spéciale pour le groupe/raid avec un choix
  unique du coup ? au cas où »). Pour un membre de ton groupe ou de ton raid (toi compris quand tu
  es groupé), la case de sa classe donne LE buff à poser, sans repli. C'est l'usage d'un raid où les
  paladins se partagent les bénédictions. *Conséquences dérivées, non décidées par le user :*
  - la ligne est **vide par défaut**, et une case vide laisse la grille du dessus s'appliquer : « au
    cas où », elle ne change rien tant qu'on ne la remplit pas ;
  - même interaction que la grille (clic, molette), sa propre case « Toutes » et son Remplir ; ↺
    remet aussi cette case ; D23 tient (pas de Sagesse proposée aux guerriers) ;
  - un choix pas encore appris laisse la grille du dessus s'appliquer ;
  - ~~paladin : le choix unique déjà posé par un autre paladin depuis plus de 30 minutes vaut
    « servi » ; trop bas (D24) : le joueur sort de la liste~~ : remplacé par D37 le 2026-10-05 (repli
    sur la colonne).
- **D36 : en combat, le tableau reste affiché, figé, « comme PallyPower »** (user, 2026-10-05 : « en
  combat on doit juste voir le tableau pour rebuff, c'est tout » ; « on a juste les noms des joueurs
  à rebuff et on peut cliquer dessus pour cast, quitte à rafraîchir après le combat »). Remplace D12
  (tableau masqué par défaut) et D21 (lignes d'inconnus cliquables avec l'option) ; l'option
  « garder en combat » disparaît.
  - les lignes de ton groupe ou raid, et la tienne, restent cliquables : le sort part sur leur
    **jeton de groupe** (`/cast [@raid3,help,nodead] <sort>`), sans toucher à ta cible ;
  - les lignes d'inconnus deviennent inertes (`/stopmacro [combat]`) et s'éteignent : en combat, la
    macro par le nom te ferait perdre ta cible ;
  - une ligne se grise quand notre sort sur ce joueur a réussi ; rien ne bouge, rien ne sort,
    personne n'entre avant la fin du combat, où le tableau se recalcule ;
  - la touche « buff suivant » ne fait rien en combat (elle viserait toujours le même joueur).

  *Conséquences dérivées, non décidées par le user :*
  - hors combat aussi, un clic sur une ligne du groupe ne change plus ta cible (même macro) ;
  - **exception assumée, comme PallyPower** : le code sécurisé du jeu ne connaît ni `UnitName` ni
    `UnitGUID` (`RestrictedEnvironment.lua`, build 70205), donc rien ne vérifie au clic que `raid3`
    est toujours le joueur affiché. Si le groupe change pendant le combat, les numéros se décalent
    et un clic peut buffer un autre membre que le nom écrit. Les lignes du groupe le disent alors
    (« groupe changé ») jusqu'à la fin du combat. Hors combat, le tableau se recalcule à chaque
    changement du groupe ;
  - pendant le combat, rien n'est relu (ni auras ni portée) : la file garde l'ordre d'avant le pull.
  - **Relevé R6, rapporté par le user le 2026-10-05** : `/cast [@Prénom Nom] Blessing of Might`, tapé,
    « ne fonctionne pas avec le nom d'un gars devant moi ». On ne sait pas s'il était du groupe
    (`[@nom]` ne vise qu'un membre du groupe) : ce n'est pas un fait mesuré, seulement la raison de
    passer par le jeton. **Jamais mesuré** : un jeton `partyN` / `raidN` dans une condition de macro
    sur Forever (les plaques échouent, `target` et `player` marchent).
- **D37 : le choix unique de la ligne « Groupe / raid » se replie sur la colonne de la classe quand
  il ne passe pas** (user, 2026-10-05, après Gnomi, mage niveau 2, groupée avec Rédemption : Rois
  est son choix unique, le jeu le refuse « Target is too low level », et elle n'avait plus rien).
  Le choix unique d'abord ; s'il est trop bas (D24, D38), pas appris, ou déjà posé par un autre
  paladin (D27), les choix de la colonne, dans l'ordre. Gnomi : Rois refusé → Sagesse refusée →
  Puissance. Pour un prêtre, un mage ou un druide, un choix unique présent sur le joueur vaut
  « servi » : la colonne ne sert que si le choix ne peut pas passer. Remplace « sans repli » de D35.
- **D38 : l'addon APPREND les refus « trop bas » et les garde** (user, 2026-10-05, « apprendre des
  refus »). Après « Target is too low level » sur un joueur de niveau N, il retient « ce rang de ce
  sort est refusé jusqu'au niveau N » dans ses réglages (`tooLow`, rang du sort → niveau ; aucune
  donnée de joueur) : le refus survit au `/reload`, et ce buff n'est plus proposé à personne de ce
  niveau ou moins, on passe directement au suivant. *Conséquences dérivées, non décidées par le
  user :*
  - la clé est le rang que le jeu lance (`C_Spell.GetSpellInfo(nom).spellID`, le plus haut connu) :
    un nouveau rang appris repart de zéro, puisque son niveau requis est plus haut ;
  - un buff réussi sur un niveau N que l'addon croyait refusé corrige le seuil (N − 1) ;
  - aucun niveau codé en dur : le vrai seuil s'apprend un refus à la fois. Un joueur qui monte d'un
    niveau sous le seuil coûte un clic de plus (Rois, sans doute refusé jusqu'au niveau 9 selon la
    règle de vanilla « niveau du sort − 10 », jamais mesurée sur Forever) ;
  - le refus « trop bas » d'un joueur précis pendant la séance (D24) reste, en plus.

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
- ~~Q11 : un joueur trop bas pour ton buff~~ : réglée par D24.
- ~~Q13 : un joueur à qui il manque deux buffs~~ : réglée par D29.

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
4. [humain] (D36) À l'entrée en combat, le tableau reste affiché, figé ; les lignes d'inconnus
   s'éteignent, et un clic dessus ne lance rien. À la sortie, il se recalcule. Une séance qui mêle
   tournée et combats ne laisse ni `ADDON_ACTION_BLOCKED` ni erreur Lua (BugGrabber, `taint.log`).
5. [humain] Un joueur marqué PvP est absent par défaut. Avec l'option, il apparaît, marqué.
6. [humain] Plaques amies coupées : à la première ouverture, l'addon propose de les activer. Sur
   « oui », les plaques amies passent en noms seuls. Sur « non », la question ne revient pas, et la
   liste dit pourquoi elle est vide.
7. ~~[humain] En donjon, un message remplace la liste, sans erreur.~~ Remplacé par le critère 21
   (D31, 2026-10-05) : en donjon, la liste montre le groupe.
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
15. [humain] (D36) En combat, groupé : un clic sur la ligne d'un membre du groupe le buffe sans
    changer ta cible (l'ennemi visé reste ciblé), puis la ligne se grise ; à la sortie du combat, le
    tableau se recalcule. Même absence d'erreur qu'au critère 4. Témoin connu-bon : le même membre
    buffé hors combat.
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
19. [test] (D30) Les membres du groupe à portée passent devant les inconnus, les membres hors de
    portée restent tout en bas, et le FIFO tient dans chaque partie. Toi, non groupé, tu gardes ta
    place d'arrivée.
20. [humain] (D30) En groupe ou en raid, dehors : le tableau montre la partie « Groupe » (ou
    « Raid ») en haut, puis « Autour de toi », puis « Hors de portée ». Un clic répété sur la
    première ligne buffe d'abord tout le groupe à portée, puis les inconnus. Seul, aucun titre.
    Témoin connu-bon : le même tableau seul, avant de grouper.
21. [humain] (D31) En donjon, groupé : la liste montre les membres du groupe à qui il manque un
    buff, et un clic buffe le nommé. Si elle est vide alors qu'un membre n'a pas le buff, le pied
    compte des illisibles. Témoin connu-bon : le même membre, buffé à la main.
22. [humain] (D32) Un clic sur le rouage, hors combat, ouvre Options > AddOns > Serial Buffer ; en
    combat, un message dit « pas pendant un combat ».
23. [humain] (D34) Dans la grille, passer le 1er choix de la colonne Guerrier de Rois à Puissance
    (clic ou molette) : le tableau propose aussitôt Puissance aux guerriers, et Rois aux autres
    classes. La molette sur une case change la case sans faire défiler le panneau. Dans la colonne
    Guerrier, Sagesse n'est jamais proposée. Choisir Salut dans « Toutes » puis Remplir : Salut en
    1er choix partout. ↺ sous Guerrier remet sa colonne. Le réglage survit à un `/reload`.
24. [test] (D34) Le défaut de chaque colonne ; le cycle d'une case (vide → buffs → vide), qui saute
    les buffs interdits (D23) et ceux déjà pris dans la colonne ; Remplir, qui laisse une case
    interdite et échange un doublon ; ↺ et « Tout par défaut » ; une case vide ne propose rien ;
    seul le paladin pose UNE bénédiction ; la grille d'un paladin ne change pas ce que propose un
    prêtre du même compte ; la migration vers `schemaVer` 3 depuis la v0.1.0 (`off`, `priority`) et
    depuis D33 (`classBuffs`), une seule fois.
25. [test] (D35) Vide, la ligne « Groupe / raid » ne change rien ; remplie, un membre du groupe de
    cette classe ne se voit proposer que ce buff, et un inconnu de la même classe garde la grille ;
    un choix pas appris laisse la grille s'appliquer ; D23 tient.
26. [humain] (D35) Groupé, choisir Puissance dans la case Guerrier de la ligne « Groupe / raid » :
    le guerrier du groupe se voit proposer Puissance, un guerrier inconnu dehors garde Rois.
27. [test] (D37, D38) Un choix unique trop bas (appris) passe à la colonne ; un choix unique présent
    sur un mage du groupe vaut « servi » pour un mage lanceur ; un seuil appris écarte le buff
    jusqu'à ce niveau compris et pas au-dessus ; un refus ne fait que monter le seuil ; un succès
    au-dessous du seuil le corrige ; la clé est le rang lancé.
28. [humain] (D37, D38) Paladin groupé avec Gnomi (niveau 2), Rois en choix unique des mages : un
    clic sur Gnomi → « too low level » → la ligne passe à Sagesse, refusée → Puissance, qui passe.
    Après un `/reload`, Gnomi se voit proposer Puissance d'emblée. `SerialBufferDB.tooLow` porte les
    rangs de Rois et de Sagesse à 2. Témoin connu-bon : la v0.2.0-beta, où Gnomi n'avait plus rien.

## Contrat

- **SavedVariables : des réglages seulement.** Ce sont les colonnes de la grille (`orders`, classe
  du lanceur → classe de la cible → ids de sort par rang, 0 = case vide ; seules les colonnes qui
  s'écartent du défaut ; des jetons de classe et des ids, aucune donnée de joueur ; elles remplacent
  `off`, `priority` et `classBuffs`, migrés par `schemaVer` 3), la ligne « Groupe / raid »
  (`groupPick`, classe du lanceur → classe de la cible → id ; D35), les refus « trop bas » appris
  (`tooLow`, rang de sort → niveau ; D38), l'option PvP, la réponse à la
  proposition des plaques et la position du tableau (son coin haut gauche). Pour le diagnostic, `seenErrors` : le
  nom et le texte des erreurs du jeu vues juste après un de nos clics. **Aucun nom de joueur, aucun
  GUID** : un secret sauvegardé empoisonne la base. Le refus « trop bas » (D24) vit en mémoire de
  session, jamais sauvegardé.
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
4. **Fusion du 2026-10-04 (accord du user)** : les paliers (a) et (b) et l'icône sont dans `main`
   (`5df56f7`) ; les tests `test_serialbuffer_list.lua` et `test_serialbuffer_cast.lua` et
   SerialBuffer **actif** dans `master` de l'outillage (`0e78231`) ; adresse CurseForge déclarée.
   Dépôt GitHub `Wafhi3n/SerialBuffer` créé par le user, avec le webhook CurseForge
   (`serial-buffer`, page en préparation). Rien de poussé à cette date.
5. **Les paliers**, chacun testé au banc :
   - (a) la liste seule, sans clic (critères 1, 5, 7, 14). **Codé le 2026-10-04** (SerialBuffer
     `2b40b0b`, branche `feat/palier-a-tableau`), déployé au jeu (`feat/palier-a-tableau@2b40b0b`),
     **pas encore vu en jeu**. Test headless des critères 9, 10, 11 et 17 :
     `tests/test_serialbuffer_list.lua`, sur la branche d'outillage `feat/serialbuffer-palier-a`
     (`bb2257e`), à fusionner le même jour que ce palier sur `main`. Hors plan : le catalogue
     non paladin (mage, prêtre, druide) n'a jamais été vu sur Forever ;
   - (b) le clic et la touche (critères 2, 3, 8, 16, 18). **Codé le 2026-10-04** (SerialBuffer
     `72bb352`, branche `feat/palier-b-clic`, posée sur le palier a), déployé
     (`feat/palier-b-clic@72bb352`), **pas encore vu en jeu**. Test headless :
     `tests/test_serialbuffer_cast.lua`, branche d'outillage `feat/serialbuffer-palier-b` (`7c188eb`).
     Jamais mesuré sur Forever : un raccourci `CLICK <bouton>:LeftButton` déclaré dans
     `Bindings.xml` (Blizzard n'en déclare aucun) ; repli si la touche ne marche pas, une macro du
     joueur `/click SerialBufferNextButton`. Choix de code, pas une décision du user : seules les
     erreurs qui tiennent à la cible (hors de vue, hors de portée, trop bas, cible invalide)
     renvoient en fin de file, pour qu'une touche martelée pendant le temps de recharge global ne
     fasse pas tourner la file. **Revu après le 1er essai du user (Rédemption, 18:00)** : D24 et D25,
     `b497d03`, déployé, pas encore revu en jeu. Le relevé de cet essai reste à écrire : le clic
     a-t-il buffé ? ;
   - (c) le combat (critères 4 et 15) ;
   - (d) la proposition des plaques et les options (critère 6) ;
   - (e) le groupe devant, le groupe en instance, le rouage et la grille (D30 à D33, critères 19 à
     24). Codé le 2026-10-05 sur `feat/groupe-et-grille` (SerialBuffer et outillage, même nom).
