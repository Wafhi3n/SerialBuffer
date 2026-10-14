# Serial Buffer : le buff à la demande (clic droit sur une ligne)

> Statut : brouillon · Décidé le 2026-10-14 par le user (A1 à A3) ; A4 à A9 proposées, à valider.
> Spec mère : `serial-buffer.md` (D1-D49). Coordination : `coordination.md`.

## Le problème

Un joueur demande un buff précis : « Might please », « can I get Wisdom? », « Thorns? ». Le tableau
ne propose que ce que la grille a décidé (D22 : Rois > Sagesse > Puissance pour un paladin ; D44 :
Épines aux tanks seulement). Pour répondre à la demande, il faut aujourd'hui sortir de l'addon :
cibler le joueur à la main, chercher le sort dans la barre, le lancer. Puis, pour un paladin, au tour
suivant, la ligne repropose Rois au même joueur, et un clic machinal écrase la Puissance qu'il voulait
(un paladin n'a qu'une bénédiction à lui par cible).

## Ce qu'on veut

- **Clic droit sur une ligne : les icônes des buffs de ta classe se déroulent à côté d'elle.** Un clic
  sur une icône buffe ce joueur tout de suite, avec ce buff-là.
- Le choix est **retenu pour ce joueur jusqu'à ta déconnexion** : aux tours suivants, sa ligne propose
  le buff demandé à la place de celui de la grille, et le clic gauche comme la touche « buff suivant »
  le posent.
- La rangée montre **tous les buffs que tu sais lancer**, même décochés dans la grille, même déjà sur
  lui (pour rafraîchir). Ceux qu'il porte déjà sont marqués.
- Le clic gauche ne change pas : il lance le buff proposé par la ligne (D2, D25 : on peut toujours
  marteler la première ligne).

## Ce qu'on NE fait PAS

- **Pas de lancement depuis un menu.** Un menu du jeu n'est pas sécurisé et ne peut pas lancer un sort
  (source Forever, `SecureTemplates.lua`, `SECURE_ACTIONS.menu` : il exécute une fonction, pas un
  sort). D'où la rangée de boutons sécurisés (A1).
- **Rien en combat.** Le tableau y est figé (D36) : pas d'attribut sécurisé posé, pas de cadre
  sécurisé affiché. Le clic droit d'une ligne n'y fait rien.
- **Rien de sauvegardé.** La demande vit en mémoire de session, par GUID, comme le refus « trop bas »
  de D24. Le Contrat interdit nom et GUID dans la base. Conséquence : un `/reload` l'oublie aussi.
- **Pas de lecture du chat.** L'addon ne devine pas une demande dans un chuchotement ou un /say : c'est
  le joueur qui la lit et fait le clic droit.
- **Pas d'annonce aux autres buffeurs.** La coordination (`coordination.md`) annonce une répartition
  par classe ; une demande ne vise qu'un joueur, elle reste locale.

## Cas particuliers

- **La rangée ouverte au moment du pull** : elle se ferme d'elle-même. Un cadre sécurisé ne se cache
  pas depuis le code en combat ; il faut un pilote d'état sécurisé (`[combat] hide`), comme celui de
  la touche « buff suivant ».
- **La ligne quitte le tableau pendant que sa rangée est ouverte** (buffé par un autre, sorti de
  portée, rendu suivant) : la rangée se ferme. Elle ne doit jamais rester ouverte sur un autre joueur
  que celui qu'elle affiche.
- **Fermer sans choisir** : Échap, un clic ailleurs, un second clic droit sur la même ligne.
- **Le bord de l'écran** : la rangée s'ouvre du côté où elle tient (le tableau est souvent collé à
  droite).
- **Un buff trop haut pour la cible** (D24, D38) : le clic part, le jeu refuse, le refus s'apprend
  comme aujourd'hui. La demande tombe alors pour ce rang ; l'icône reste dans la rangée.
- **Le joueur demandé n'est plus vu** (parti, hors de portée) : la demande reste en mémoire et
  resservira s'il revient avant ta déconnexion.
- **Un paladin qui reçoit une bénédiction demandée par un AUTRE paladin** (D27) : la demande est la
  tienne, c'est ta bénédiction qui compte, comme pour la grille.
- **Ta propre ligne** : le clic droit marche aussi sur toi.
- **Le groupe en instance** (D31) : la rangée vise par le jeton du groupe, comme le clic gauche.

## Décisions

- **A1 (user, 2026-10-14) : une rangée d'icônes, pas un menu.** Un clic sur une icône lance le sort
  tout de suite. Écarté : le menu natif, qui change le buff de la ligne et demande un 2e clic.
- **A2 (user, 2026-10-14) : la demande est retenue jusqu'à la déconnexion.** Écarté : « une fois
  seulement », qui laisse un paladin écraser la demande au tour suivant.
- **A3 (user, 2026-10-14) : la rangée propose tous les buffs de ta classe**, cochés ou non, portés ou
  non ; ceux qu'il a déjà sont marqués. Écarté : « seulement ceux qui manquent », qui interdit de
  rafraîchir.
- **A4 (proposé) : le clic droit d'une ligne ne lance plus de buff.** Aujourd'hui il fait comme le
  clic gauche (D44 l'a rétabli) ; il ouvre désormais la rangée.
- **A5 (proposé) : ce que la demande change, selon le buff.**
  - Une bénédiction de paladin **remplace** celle que la grille donne à ce joueur.
  - Un autre buff **s'ajoute** à ceux de la grille et passe devant eux. Exemple : Épines pour un
    joueur qui n'est pas tank (D44), ou Respiration aquatique (D47 sans « à tous »).
- **A6 (proposé) : une demande passe outre les règles de la grille pour ce joueur**, y compris D23
  (pas de buff de mana à une classe sans mana) et D44 : le joueur l'a demandé. Les règles du jeu
  restent : niveau trop bas, composant manquant (D48), portée.
- **A7 (proposé) : l'icône de la ligne montre la demande**, avec une marque discrète (un liseré), pour
  qu'on voie que la ligne ne suit plus la grille.
- **A8 (proposé) : annuler une demande**, c'est un clic droit, puis la dernière icône de la rangée
  (« selon la grille »), qui n'apparaît que si une demande est en cours.
- **A9 (proposé) : rien dans le chat** (skill `chat-output`) : ni à l'ouverture, ni au choix, ni à
  l'annulation. L'icône de la ligne suffit.

## Questions ouvertes (au user)

- **Q1 : une demande pour un joueur hors de ton groupe**, inconnu croisé en ville, est-elle utile
  jusqu'à la déconnexion, ou seulement le temps de la tournée ?
- **Q2 : A6, passer outre D23** : une Sagesse sur un guerrier qui la demande, d'accord ? (Le jeu la
  pose sans rien dire, elle ne lui sert à rien.)

## Critères d'acceptation

1. [test] Une demande pour un GUID fait proposer le buff demandé à la place de celui de la grille
   (bénédiction), ou avant eux (autre buff) ; sans demande, la file ne change pas.
   → `tests/test_serialbuffer_demande.lua`
2. [test] Une demande annulée rend la proposition de la grille ; le refus « trop bas » appris retire
   la demande pour ce rang.
3. [test] La base sauvegardée ne contient ni nom ni GUID après une demande (Contrat).
4. [agent] Aucun attribut sécurisé posé, aucun cadre sécurisé montré, caché ou déplacé en combat ; la
   rangée se ferme au pull par un pilote d'état. → `api-gotcha-reviewer`
5. [check] Les infobulles et la marque « selon la grille » sont traduites dans les trois overlays.
6. [humain] Paladin hors combat, à côté de B (guerrier) : clic droit sur la ligne de B, la rangée
   montre toutes les bénédictions ; un clic sur Puissance la pose sur B. B a sa bénédiction de
   Puissance dans sa barre de buffs. Témoin connu-bon : la bénédiction lancée à la main depuis la
   barre d'action sur B.
7. [humain] Au tour suivant (B revient dans la liste après D27/D28), sa ligne propose Puissance, pas
   Rois ; un clic gauche pose Puissance. Après une déconnexion, sa ligne repropose Rois.
8. [humain] Rangée ouverte, on engage un combat : la rangée disparaît, aucune erreur Lua, aucune ligne
   « action bloquée » dans le chat. Témoin connu-bon : la touche « buff suivant », inerte en combat
   depuis D36.
9. [humain] Le clic gauche sur la première ligne, martelé, vide toujours la file (D25) ; le clic droit
   ne lance plus rien.

## Contrat

- **SavedVariables : inchangées.** La demande vit en mémoire de session, clé = GUID.
- **Le clic droit d'une ligne change de sens** : il ouvre la rangée et ne lance plus de buff (A4).
  C'est un geste que les joueurs ont déjà ; la Nouveauté de la version doit le dire.

## Renvois

- Spec mère `serial-buffer.md` : D2, D22-D29 (file et priorités), D31 (instance), D36 (combat), D38
  (refus appris), D44, D47, D48.
- Source Forever : `Blizzard_FrameXML/SecureTemplates.lua` (`SECURE_ACTIONS.menu`, `PerformAction`,
  `SecureUnitButton_OnLoad` qui pose `*type2 = "menu"`).
- Skill `wow-addon-dev:wow-forever-api`, référence `taint-and-protected-frames`.
- Skill `wow-addon-dev:chat-output` (A9). Skill `human-verification` (critères 6 à 9).
