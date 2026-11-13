-- SerialBuffer_Locale_koKR.lua — overlay CORÉEN (koKR). Clé FR → texte coréen. Bêta (D56).
--
-- TRANSLATORS (Korean players): corrections are welcome as a pull request on
-- https://github.com/Wafhi3n/SerialBuffer (edit this file on GitHub, then "Propose changes").
--   * Change ONLY the Korean text on the right of "=". The key on the left is the French original:
--     leave it exactly as it is, or that line stops working.
--   * The "-- en:" comment at the end of each line is the English text, to help you translate.
--   * Keep every %s and %d, in the same order: the addon puts a name, a number or a spell there.
--   * Don't add or remove lines. A key missing here falls back to English in the game.
-- Terms copied from the game client's own Korean strings (GlobalStrings koKR, build 1.60.1.70938):
--   방어 전담 (Tank role / main tank), 파티, 공격대, 파티장, 부공격대장, 설정, 단축키 설정,
--   사정 거리, 재료, 전투 중에는 할 수 없습니다, 전체, 예 / 아니요, 닫기; class and spell names
--   (전사, 도적, 축복) come from the client too. Everything else is the maintainer's wording and is the
--   first place to look. "버프" is the players' word: the client itself says 강화 지속효과.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

if (GetLocale and GetLocale() or "enUS") ~= "koKR" then return end

local T = {
    ["version %s. Tape /%s aide pour l'aide."] = "버전 %s. /%s help 로 도움말을 볼 수 있습니다.", -- en: version %s. Type /%s help for help.
    ["version %s"] = "버전 %s", -- en: version %s
    ["Commandes :"] = "명령어:", -- en: Commands:
    ["affiche la version"] = "버전 표시", -- en: shows the version
    ["affiche ou cache le tableau"] = "창 표시/숨기기", -- en: shows or hides the panel
    ["montre ou cache les joueurs PvP"] = "PvP 활성화 플레이어 표시/숨기기", -- en: shows or hides PvP-flagged players
    ["Joueurs PvP affichés."] = "PvP 활성화 플레이어를 표시합니다.", -- en: PvP-flagged players shown.
    ["Joueurs PvP cachés, sauf quand tu es marqué toi-même."] = "PvP 활성화 플레이어를 숨깁니다. 단, 내가 PvP 활성화 상태일 때는 표시합니다.", -- en: PvP-flagged players hidden, except while you're flagged yourself.
    ["Pas pendant un combat."] = "전투 중에는 할 수 없습니다.", -- en: Not during combat.
    ["PvP"] = "PvP", -- en: PvP
    ["En instance : seul ton groupe est listé."] = "인스턴스: 파티원만 표시됩니다.", -- en: In an instance: only your group is listed.
    ["Ta classe n'a pas de buff à poser sur les autres."] = "내 직업에는 다른 사람에게 걸 버프가 없습니다.", -- en: Your class has no buff to cast on others.
    ["Plaques des joueurs amis coupées : l'addon ne voit pas les joueurs autour de toi."] = "아군 플레이어 이름표가 꺼져 있어 애드온이 주변 플레이어를 볼 수 없습니다.", -- en: Friendly player nameplates are off: the addon can't see the players around you.
    ["Pour les voir : %s > %s > %s."] = "켜는 방법: %s > %s > %s.", -- en: To see them: %s > %s > %s.
    ["+%d autres"] = "+%d명 더", -- en: +%d more
    ["Personne à buffer autour de toi."] = "주변에 버프가 필요한 사람이 없습니다.", -- en: Nobody around you needs a buff.
    ["Tournée finie !"] = "모두 완료!", -- en: Round done!
    ["%d à buffer"] = "버프 대상 %d명", -- en: %d to buff
    ["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."] = "내 버프를 하나도 인식하지 못했습니다 (ID: %s). 애드온 제작자에게 알려 주세요.", -- en: None of your buffs was recognized (ids: %s). Please tell the addon author.
    ["non appris"] = "배우지 않음", -- en: not learned
    ["Une bénédiction par classe : le 1er choix, sinon le suivant"] = "직업마다 축복 하나: 1순위, 없으면 다음 순위", -- en: One blessing per class: the 1st choice, otherwise the next
    ["Tes buffs par classe, dans l'ordre"] = "직업별 내 버프 (순서대로)", -- en: Your buffs per class, in order
    ["Toutes"] = "전체", -- en: All
    ["Choix %d"] = "%d순위", -- en: Choice %d
    ["Buff %d"] = "버프 %d", -- en: Buff %d
    ["Vide"] = "비어 있음", -- en: Empty
    ["Vide : la grille du dessus s'applique."] = "비어 있음: 위의 표가 적용됩니다.", -- en: Empty: the grid above applies.
    ["Clic ou molette : buff suivant. Clic droit : précédent."] = "클릭 또는 마우스 휠: 다음 버프. 오른쪽 클릭: 이전 버프.", -- en: Click or mouse wheel: next buff. Right-click: previous.
    ["Remplir : recopie la case « Toutes » sur toutes les classes"] = "채우기: \"전체\" 칸을 모든 직업에 복사", -- en: Fill: copies the "All" box to every class
    ["Remettre cette classe par défaut"] = "이 직업 기본값 복원", -- en: Reset this class to default
    ["Tout par défaut"] = "모두 기본값 복원", -- en: Reset all
    ["buffé"] = "버프 완료", -- en: buffed
    ["groupe changé"] = "파티 변경됨", -- en: group changed
    ["expiré"] = "만료됨", -- en: expired
    ["Groupe / raid : qui pose quoi"] = "파티 / 공격대: 누가 무엇을 거는가", -- en: Group / raid: who casts what
    ["Toi"] = "나", -- en: You
    ["Toi, après répartition"] = "나 (분배 후)", -- en: You, after the split
    ["Qui peut régler ta ligne Groupe / raid :"] = "내 파티 / 공격대 줄을 설정할 수 있는 사람:", -- en: Who can set your Group / raid row:
    ["personne"] = "없음", -- en: nobody
    [" (réglable)"] = " (설정 가능)", -- en: " (you can set it)"
    ["Choix unique pour cette classe."] = "이 직업에는 하나만 선택합니다.", -- en: Single choice for this class.
    ["Pas de choix unique : sa grille s'applique."] = "단일 선택 없음: 해당 직업의 표가 적용됩니다.", -- en: No single choice: their grid applies.
    ["%s à tous"] = "%s: 모두에게", -- en: %s for everyone
    ["Coché : %s va à tous ceux qui ne l'ont pas. Décoché : aux tanks de ton groupe seulement (rôle Tank, ou main tank du raid)."] =
        "선택: %s 버프가 없는 모든 사람에게 겁니다. 해제: 내 파티의 방어 전담에게만 겁니다 (방어 전담 역할, 또는 공격대에서 방어 전담으로 지정된 사람).", -- en: Ticked: %s goes to everyone who doesn't have it. Unticked: only the tanks of your group (Tank role, or raid main tank).
    ["Buffs courts"] = "짧은 버프", -- en: Short buffs
    ["Un buff de 10 min est reproposé quand il lui reste moins de %d min. Clic, clic droit ou molette : changer."] =
        "10분 버프는 남은 시간이 %d분 미만이면 다시 제안됩니다. 클릭, 오른쪽 클릭 또는 마우스 휠: 변경.", -- en: A 10-minute buff is offered again once it has less than %d min left. Click, right-click or mouse wheel: change.
    ["courts : sous %d min"] = "짧은 버프: %d분 미만", -- en: short: under %d min
    ["Buffs courts (10 min) : rafraîchir s'il leur reste moins de %d min"] = "짧은 버프 (10분): 남은 시간이 %d분 미만이면 갱신", -- en: Short buffs (10 min): refresh when less than %d min left
    ["À tous :"] = "모두에게:", -- en: For everyone:
    ["Composant manquant : ce buff n'est pas proposé tant que tu n'en as pas."] =
        "재료 부족: 재료가 생길 때까지 이 버프는 제안되지 않습니다.", -- en: Missing reagent: this buff isn't offered until you have some.
    ["Coché : %s va à tous ceux qui ne l'ont pas. Décoché : à toi et à ton groupe seulement."] =
        "선택: %s 버프가 없는 모든 사람에게 겁니다. 해제: 나와 내 파티에게만 겁니다.", -- en: Ticked: %s goes to everyone who doesn't have it. Unticked: only you and your group.
    ["Un buff court (10 min) ne va qu'à toi et à ton groupe (un buff de tank : aux tanks), sauf si tu coches « à tous » sous le titre du tableau."] =
        "짧은 버프 (10분)는 나와 내 파티에게만 겁니다 (방어 전담용 버프는 방어 전담에게). 창 제목 아래의 \"모두에게\"를 선택하면 모두에게 겁니다.", -- en: A short buff (10 min) only goes to you and your group (a tank buff: to the tanks), unless you tick "for everyone" under the panel title.
    ["Buffs sans restriction : il les pose à qui ne les a pas."] = "제한 없는 버프: 버프가 없는 사람 누구에게나 겁니다.", -- en: Unrestricted buffs: they cast them on whoever lacks them.
    ["Tes buffs vont à tous ceux qui ne les ont pas : rien à régler. Un buff de mana n'est jamais proposé aux guerriers ni aux voleurs."] =
        "내 버프는 없는 모든 사람에게 겁니다. 설정할 것이 없습니다. 마나 버프는 전사와 도적에게는 제안되지 않습니다.", -- en: Your buffs go to everyone who doesn't have them: nothing to set. A mana buff is never offered to warriors or rogues.
    ["Toi : chef ou assistant = %s, ton option = %s"] = "나: 파티장 또는 부공격대장 = %s, 내 설정 = %s", -- en: You: leader or assistant = %s, your option = %s
    ["oui"] = "예", -- en: yes
    ["non"] = "아니요", -- en: no
    ["le chef et ses assistants"] = "파티장과 부공격대장", -- en: the leader and assistants
    ["n'importe qui du groupe"] = "파티의 누구나", -- en: anyone in the group
    ["%s a réglé ta ligne Groupe / raid."] = "%s님이 내 파티 / 공격대 줄을 설정했습니다.", -- en: %s set your Group / raid row.
    ["Clic ou molette : régler sa ligne (il te le permet)."] = "클릭 또는 마우스 휠: 이 사람의 줄 설정 (허용됨).", -- en: Click or mouse wheel: set their row (they allow you to).
    [" (avant toi)"] = " (나보다 먼저)", -- en: " (before you)"
    [" (après toi)"] = " (나보다 나중)", -- en: " (after you)"
    ["Aucun autre Serial Buffer dans ton groupe."] = "파티에 다른 Serial Buffer 사용자가 없습니다.", -- en: No other Serial Buffer in your group.
    ["Pas de groupe."] = "파티에 속해 있지 않습니다.", -- en: Not in a group.
    ["Serial Buffer dans ton groupe :"] = "파티의 Serial Buffer 사용자:", -- en: Serial Buffer in your group:
    ["liste les Serial Buffer de ton groupe"] = "파티의 Serial Buffer 사용자 목록", -- en: lists the Serial Buffers in your group
    ["%d min"] = "%d분", -- en: %d min
    ["%d s"] = "%d초", -- en: %d s
    ["Groupe / raid : un choix unique pour les membres de ton groupe ou raid ; vide, la grille du dessus s'applique. Un buff de mana n'est jamais proposé aux guerriers ni aux voleurs."] =
        "파티 / 공격대: 파티원 또는 공격대원에게 적용할 단일 선택. 비어 있으면 위의 표가 적용됩니다. 마나 버프는 전사와 도적에게는 제안되지 않습니다.", -- en: Group / raid: a single choice for the members of your group or raid; empty, the grid above applies. A mana buff is never offered to warriors or rogues.
    ["Options : quels buffs sur quelles classes"] = "설정: 어떤 직업에 어떤 버프를", -- en: Options: which buffs on which classes
    ["%d illisible(s) : le jeu cache leur nom ou leurs buffs."] = "%d명 확인 불가: 게임이 이름이나 버프를 숨깁니다.", -- en: %d unreadable: the game hides their name or their buffs.
    ["Buffs cachés par le jeu : la liste suit tes propres sorts."] = "게임이 버프를 숨깁니다: 목록이 내가 시전한 주문을 따릅니다.", -- en: Buffs hidden by the game: the list follows your own casts.
    ["Mode à l'aveugle forcé : la liste suit tes propres sorts (cette séance)."] = "블라인드 모드 강제: 목록이 내가 시전한 주문을 따릅니다 (이번 접속 동안).", -- en: Blind mode forced: the list follows your own casts (this session).
    ["Mode à l'aveugle automatique : seulement quand le jeu cache les buffs."] = "블라인드 모드 자동: 게임이 버프를 숨길 때만.", -- en: Blind mode automatic: only when the game hides buffs.
    ["suit tes propres sorts au lieu des buffs lus (cette séance)"] = "버프를 읽는 대신 내가 시전한 주문을 따름 (이번 접속 동안)", -- en: follow your own casts instead of reading buffs (this session)
    ["Raid"] = "공격대", -- en: Raid
    ["Groupe"] = "파티", -- en: Group
    ["Autour de toi"] = "주변", -- en: Around you
    ["Hors de portée"] = "사정 거리 밖", -- en: Out of range
    ["Montrer les joueurs marqués PvP"] = "PvP 활성화 플레이어 표시", -- en: Show PvP-flagged players
    ["Options indisponibles sur ce client."] = "이 클라이언트에서는 설정을 사용할 수 없습니다.", -- en: Options are unavailable on this client.
    ["ouvre les options"] = "설정 열기", -- en: opens the options
    ["Buff suivant"] = "다음 버프", -- en: Next buff
    ["Rafraîchir un buff s'il lui reste moins de %d min"] = "남은 시간이 %d분 미만인 버프 갱신", -- en: Refresh a buff with less than %d min left
    ["Groupe seul"] = "파티만", -- en: Group only
    ["Coché : seuls toi et ton groupe ou ton raid sont listés ; les joueurs autour de toi sont ignorés."] = "선택: 나와 내 파티 또는 공격대만 표시합니다. 주변 플레이어는 무시합니다.", -- en: Checked: only you and your group or raid are listed; players around you are ignored.
    ["Groupe seul : ignorer les joueurs autour de toi"] = "파티만: 주변 플레이어 무시", -- en: Group only: ignore players around you
    ["Personne à buffer dans ton groupe."] = "파티에 버프가 필요한 사람이 없습니다.", -- en: Nobody in your group needs a buff.
    ["Joueurs autour ignorés : seuls toi et ton groupe sont listés."] = "주변 플레이어 무시: 나와 내 파티만 표시합니다.", -- en: Players around you ignored: only you and your group are listed.
    ["Joueurs autour listés."] = "주변 플레이어를 표시합니다.", -- en: Players around you are listed.
    ["montre ou ignore les joueurs autour de toi (groupe seul)"] = "주변 플레이어 표시/무시 (파티만)", -- en: shows or ignores players around you (group only)
    ["Touche « buff suivant » : %s"] = "\"다음 버프\" 단축키: %s", -- en: "Next buff" key: %s
    ["Aucune touche pour « buff suivant »."] = "\"다음 버프\"에 지정된 단축키가 없습니다.", -- en: No key bound to "Next buff".
    ["Clic : la page Raccourcis du jeu, section Serial Buffer."] = "클릭: 게임의 단축키 설정, Serial Buffer 항목.", -- en: Click: the game's Keybindings page, Serial Buffer section.
    ["touche ?"] = "단축키?", -- en: key?
    -- Short mouse codes in the panel header (wheel up / wheel down / mouse button N): keep them short.
    ["MH"] = "휠위", -- en: WU
    ["MB"] = "휠아래", -- en: WD
    ["S%d"] = "M%d", -- en: M%d
    ["Page des raccourcis indisponible : Échap > Options > Raccourcis > Serial Buffer."] = "단축키 설정을 열 수 없습니다: ESC > 설정 > 단축키 설정 > Serial Buffer.", -- en: Keybindings page unavailable: Esc > Options > Keybindings > Serial Buffer.
    ["ta touche « buff suivant », et la page des raccourcis pour la changer"] = "\"다음 버프\" 단축키, 그리고 이를 바꿀 단축키 설정 화면", -- en: your "Next buff" key, and the Keybindings page to change it
    ["Signaler un bug ou proposer une idée"] = "버그 신고 또는 아이디어 제안", -- en: Report a bug or suggest an idea
    ["Bug"] = "버그", -- en: Bug
    ["Idée"] = "아이디어", -- en: Idea
    ["Sans compte GitHub"] = "GitHub 계정 없음", -- en: No GitHub account
    ["Lien copié : colle-le (Ctrl+V) dans ton navigateur."] = "링크 복사됨: 브라우저에 붙여넣으세요 (Ctrl+V).", -- en: Link copied: paste it (Ctrl+V) into your browser.
    ["Fermer"] = "닫기", -- en: Close
    ["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."] = "이 링크를 복사(Ctrl+C)해서 브라우저에서 여세요. 버전이 미리 입력된 양식이 열립니다.", -- en: Copy this link (Ctrl+C) and open it in your browser: the form comes up with the version already filled in.
    ["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."] = "GitHub 계정이 없나요? 이 링크를 복사(Ctrl+C)해서 CurseForge 페이지에 댓글을 남겨 주세요.", -- en: No GitHub account? Copy this link (Ctrl+C) and leave a comment on the CurseForge page.
    ["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."] = "버그나 애드온 아이디어가 있나요? 아래에서 고르면 미리 입력된 양식 링크를 알려 드립니다.", -- en: A bug, or an idea for the addon? Pick below: the addon gives you the link to the form, already filled in.
    ["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"] = "버그 신고 또는 아이디어 제안 (GitHub 이슈 링크)", -- en: report a bug or suggest an idea (link to a GitHub issue)
    ["Afficher le tableau (/sbuff)"] = "창 표시 (/sbuff)", -- en: Show the panel (/sbuff)
    ["Tableau caché. /sbuff, ou la case « Afficher le tableau » des options, le réaffiche."] = "창을 숨겼습니다. /sbuff 또는 설정의 \"창 표시\" 칸으로 다시 표시할 수 있습니다.", -- en: Panel hidden. /sbuff, or the "Show the panel" box in the options, brings it back.
    ["(/sbuff %s %s pour changer)"] = "(변경: /sbuff %s %s)", -- en: (/sbuff %s %s to change it)
    ["Lignes du tableau, au plus"] = "창에 표시할 최대 줄 수", -- en: Max rows in the panel
    ["Réduire le tableau à sa barre de titre"] = "창을 제목 표시줄로 접기", -- en: Collapse the panel to its title bar
    ["Déplier le tableau"] = "창 펼치기", -- en: Expand the panel
    ["Réduit, la touche « buff suivant » buffe toujours le premier de la liste."] = "접혀 있어도 \"다음 버프\" 단축키는 목록의 첫 번째 사람에게 버프를 겁니다.", -- en: Collapsed, the "Next buff" key still buffs the top of the list.
}
for k, v in pairs(T) do NS.L[k] = v end
