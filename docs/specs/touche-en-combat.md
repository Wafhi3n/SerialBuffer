# Serial Buffer : la touche « buff suivant » en combat

> État : **codée sur `feat/sb-touche-combat` (2026-10-16), pas vue en jeu**, idée du user le
> 2026-10-16 au sortir de son premier champ de bataille (« est-il possible d'activer le raccourci
> pour buffer les gens en combat en mode aveugle pendant le BG ? » puis « de toute façon on va devoir
> tester des trucs pour le rendre confortable en BG » ; il préfère tester en champ de bataille
> qu'avec deux comptes en monde ouvert). T-Q2 est tranchée par le jeu ; T-Q1 et T-Q3 sont codées
> selon les propositions, **à confirmer par le user**. T-H1 se prouve en jeu, au premier appui.
> Spec mère : `serial-buffer.md`, dont elle assouplit D36 (« la touche « buff suivant » ne fait
> rien en combat »).

## Le problème

En champ de bataille, on est presque tout le temps en combat. Les alliés meurent souvent, reviennent
du cimetière sans buff, et le joueur n'a ni le temps ni l'envie de viser des lignes à la souris
pendant une bagarre. Hors combat, la touche « buff suivant » (spec mère, « Ce qu'on veut » ; D41) le
fait en un appui. En
combat, elle ne fait plus rien (D36), parce qu'un addon ne peut pas changer la macro d'un bouton
sécurisé pendant un combat : elle viserait sans fin le même joueur. Le seul geste qui reste est le
clic sur la ligne d'un membre du groupe. En champ de bataille, tous les alliés sont dans le raid,
donc ces lignes restent cliquables (D36), mais à la souris.

Mesuré le 2026-10-16 (registre, capture de COCProbe) : pendant tout le match, le jeu cache les
auras des alliés, et Serial Buffer est en mode à l'aveugle (D52) du début à la fin.

## Ce qu'on veut

En combat, la touche « buff suivant » **descend la liste telle qu'elle était au début du combat**.
Un appui lance le buff de la ligne suivante encore active : un membre du groupe ou du raid, ou
toi. Hors combat, rien ne change.
- Une ligne buffée par la touche se grise, comme après un clic sur une ligne en combat (D36).
- En mode à l'aveugle, le sort réussi compte comme un clic réussi (D52, `Queue.cast`) : l'allié ne
  revient pas dans la liste à la sortie du combat, sauf s'il meurt entre-temps.
- Les lignes d'inconnus, éteintes en combat (D36), sont sautées.
- **Une ligne grisée « buffé » ne se reclique plus en combat** (le user, 2026-10-16, premier essai :
  « ça a écrit buffé mais je peux quand même recliquer dessus », et le buff repartait). Le bouton
  protégé ne se désactive pas en combat ; un cadre non protégé posé dessus, qui prend la souris,
  s'affiche quand la ligne se grise et avale le clic. Il ne vient qu'après un sort **réussi** : une
  ligne dont le clic a raté (portée, recharge globale) reste cliquable.

## Ce qu'on ne fait pas

- **Recalculer la liste en combat.** Elle reste figée (D36). Un allié mort et revenu en plein
  combat n'y rentre pas avant la sortie du combat : le jeu interdit de toucher aux boutons.
- **Lire les auras pour savoir si un buff a porté.** En champ de bataille, elles sont cachées.
- **Viser un inconnu en combat.** Pas de jeton de groupe, donc il faudrait changer ta cible
  (`/targetexact`), ce que D36 refuse.
- **Une deuxième touche** (« buff précédent », « recommencer la liste ») : pas avant d'avoir vu la
  première tourner en champ de bataille.

## Le mécanisme pressenti (hypothèse T-H1, à prouver sur le client)

Un addon ne peut pas changer l'attribut d'un bouton sécurisé en combat, mais un **bout de code
restreint** attaché au bouton (`SecureHandlerWrapScript`, exécuté dans l'environnement protégé du
jeu) le peut. Avant le combat, Serial Buffer y dépose la liste figée (jeton de groupe + nom du sort
de chaque ligne active). À chaque appui en combat, ce code réécrit la macro du bouton
(`/cast [@raidN,help,nodead] <sort>`) pour la ligne suivante.

C'est du savoir **Retail**, jamais mesuré sur Forever. Trois inconnues :
- **H1** : le code restreint peut-il réécrire `macrotext` en combat, et le sort part-il sur le
  nouveau jeton ?
- **H2** : ce code est aveugle. Il ne sait pas si le sort a porté (hors de portée, recharge globale,
  mana, ligne de vue, mort). Peut-il au moins lire l'heure (`GetTime`), ou un attribut posé en combat
  par le code normal sur un cadre non protégé (le signal « sort réussi ») ?
- **H3** : la touche est liée en `runOnUp` (Bindings.xml) : le bouton reçoit l'appui ET le relâché.
  Le code doit avancer **une fois** par appui, quel que soit `ActionButtonUseKeyDown`.

**Lu dans la source de Blizzard le 2026-10-16** (clone Gethe `forever`,
`Blizzard_RestrictedAddOnEnvironment` et `SecureTemplates.lua`), pas mesuré :
- H2 : **non, sur les deux points.** `GetTime` n'est pas dans la liste des fonctions de
  l'environnement restreint (`RestrictedEnvironment.lua`) ; une poignée sur un cadre non protégé
  lève « Invalid frame handle » en combat (`GetHandleFrame`, `RestrictedFrames.lua`). Le code
  restreint ne peut donc pas savoir si le sort a porté.
- H3 : le code enveloppant reçoit `self, button, down` (`Wrapped_Click`) et peut annuler le clic en
  rendant `false`. Le bouton lance sur l'appui ou le relâché selon son attribut `useOnKeyDown`, à
  défaut le CVar (`SecureActionButton_ShouldUseOnKeyDown`) : on pose l'attribut d'après le CVar,
  hors combat, et le code n'avance que sur le clic qui lance.
- H1 reste à voir en jeu : la source le permet (`HANDLE:SetAttribute` sur un cadre protégé), seul
  le client dira si le sort part sur le nouveau jeton.

## Questions à trancher par le user

- **T-Q1 : seulement en champ de bataille, ou dans tout combat en groupe ?** Le mécanisme est le
  même partout (lignes du groupe seulement). Proposition : partout. Un donjon ou un raid y gagnent
  aussi, et le tester hors champ de bataille est plus simple.
- **T-Q2 : un appui qui ne lance rien** (recharge globale, hors de portée…). Selon H2 :
  - (a) on passe quand même au suivant : le plus simple, mais un appui trop rapide saute quelqu'un,
    qui reste dans la liste et revient à la sortie du combat (en aveugle, il n'a pas de sort réussi) ;
  - (b) on ne passe au suivant que si le précédent a réussi : il faut que H2 dise oui (signal de
    réussite lisible par le code restreint) ;
  - (c) on ne passe pas au suivant pendant 1,5 s après un appui : demande `GetTime` (H2), et ne
    règle ni la portée ni la ligne de vue.

  Proposition : (b) si H2 le permet, sinon (a). Un saut n'est pas grave : la ligne revient à la
  sortie du combat.

  **Tranché par le jeu le 2026-10-16 : (a).** H2 dit non (source). Un sort hors de portée ne part
  pas du tout et ne déclenche pas de recharge globale (à voir en jeu) : on réappuie et la touche
  passe au suivant. Seul un appui pendant la recharge globale fait sauter quelqu'un.
- **T-Q3 : au bout de la liste.** La touche ne fait plus rien (proposition) ou repart du début. Si
  elle repart du début, elle rebuffe des gens déjà buffés.

## Cas limites

- **Le groupe change en plein combat** : les jetons peuvent désigner un autre joueur. C'est la même
  exception que pour les clics de ligne (D36, « groupe changé »), et la même réponse.
- **Allié mort** : la macro `[@raidN,help,nodead]` ne lance rien. On le saute (T-Q2 ne s'applique
  pas : c'est voulu).
- **Tableau caché ou limité** (D51) : la touche vise ce que la file proposait au début du combat,
  pas seulement les lignes affichées (à trancher avec T-Q1 : proposition, la file entière, jusqu'à
  16 lignes de boutons).
- **`/reload` en plein combat** : les boutons attendent la fin du combat (D36). La touche ne fait
  rien jusque-là.
- **Plusieurs buffs pour un même joueur** (grille par classe) : chaque ligne porte son sort, la macro
  de l'appui prend celui de la ligne.

## Critères d'acceptation

1. [test] La liste déposée au début du combat contient, dans l'ordre de la file, les seules lignes
   qui lancent encore en combat (toi et ton groupe), avec leur jeton et leur sort.
   → `tests/test_serialbuffer_touche_combat.lua`
2. [test] Après un appui suivi d'un sort réussi, la ligne visée se grise et, en aveugle, `Queue.cast`
   la retient : à la sortie du combat, elle ne revient pas.
3. [agent] Aucun `SetAttribute` sur un bouton sécurisé depuis le code normal en combat, et le code
   restreint n'appelle que ce que l'environnement protégé autorise. → `api-gotcha-reviewer`
4. [humain] En monde ouvert, deux comptes groupés, un monstre : en combat, trois appuis espacés
   buffent toi, puis l'autre compte, puis plus rien (bout de liste, si T-Q3 = s'arrêter). Témoin
   connu : avant le changement, la touche ne fait rien en combat (relevé du 2026-10-11 23:10).
   Observateur : le user, en jeu.
5. [humain] En champ de bataille, en combat : des appuis espacés buffent des alliés différents, leurs
   lignes se grisent, et à la sortie du combat aucun d'eux ne revient (sauf un mort). Témoin connu :
   un clic de ligne en combat, qui fait déjà ça (D36).
6. [humain] BugSack après le combat : aucune erreur de SerialBuffer, aucun `ADDON_ACTION_BLOCKED`.

## Contrat

Aucun : ni message réseau, ni donnée sauvegardée.

## Liens

- `serial-buffer.md` : « Ce qu'on veut » (la touche), D36 (combat figé), D41 (la touche dans l'en-tête), D51 (le
  curseur des lignes), D52 (mode à l'aveugle).
- Skill public `wow-addon-dev:wow-forever-api`, `taint-and-protected-frames.md` et
  `secret-values-and-lockdowns.md` (section « In a battleground match », 2026-10-16).
- `docs/verif-registre.md`, relevé du 2026-10-16 17:50 (D52 en champ de bataille).

## Plan (2026-10-16, meurt quand c'est fait)

La bêta ferme le **2026-10-19**, et le client revient au lancement, le 2026-11-04.
1. ~~Sonde T-H1 à T-H3 en monde ouvert~~ : remplacée le même jour par la lecture de la source (H2,
   H3) et par le code lui-même (H1), que le user préfère éprouver directement en champ de bataille.
2. FAIT : le code et le test (`feat/sb-touche-combat`, SB et outillage), au banc. T-Q1 = partout,
   T-Q3 = s'arrêter, à confirmer par le user.
3. Avant de s'inscrire : seul, un monstre en monde ouvert, en combat, la touche te buffe toi
   (critère 4 réduit à un compte), BugSack propre.
4. Les critères 5 et 6 au champ de bataille suivant.
