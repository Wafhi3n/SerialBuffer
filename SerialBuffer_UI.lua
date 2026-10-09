-- SerialBuffer_UI.lua — LE TABLEAU SUR LE CÔTÉ (D10) : une ligne par joueur à buffer, en ordre FIFO.
--
-- Palier (b) : chaque ligne est un bouton SÉCURISÉ de type macro ; un clic buffe ce joueur par son nom
-- complet (SerialBuffer_Cast.lua). Un bouton caché, « SerialBufferNextButton », porte la touche
-- « buff suivant » (Bindings.xml) : il vise le premier de la file à portée.
-- Trois cadres :
--   - le PILOTE, enfant de UIParent : il porte le panneau (D36 : le tableau reste affiché en combat ;
--     avant, un pilote d'état le masquait, D12) ;
--   - le PANNEAU, enfant du pilote : /sbuff l'affiche ou le cache, hors combat seulement ;
--   - la TOUCHE, hors du panneau : un pilote d'attribut lui retire son action en combat.
-- Un attribut sécurisé ne se pose JAMAIS en combat : Render ne fait rien tant qu'il dure. En combat
-- (D36), le tableau est FIGÉ : on ne touche qu'aux régions enfants d'une ligne (couleur du nom, icône
-- désaturée, texte de la note), jamais au bouton lui-même (Show, Hide, SetPoint, SetAlpha).
-- Le tableau ne lit QUE ce que SerialBuffer_Run.lua lui passe (rows, état) : jamais le client.
-- D30 : groupé, les lignes se rangent sous trois titres (Raid ou Groupe, Autour de toi, Hors de
-- portée) ; les lignes se replacent donc à chaque rendu, hors combat. Groupé, un titre précède
-- toujours la première ligne : elle ne bouge pas (D25). D32 : un rouage ouvre les options.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local UI = { rows = {}, heads = {} }
NS.UI = UI

local WIDTH, ROW_H, HEAD_H, MAX_ROWS, PAD, TOP = 300, 18, 16, 16, 8, 20   -- 300 : place pour le temps restant
-- Le rouage (D32) : le premier de ces atlas que le client connaît (une mention dans la source
-- Blizzard ne prouve pas qu'il existe sur Forever), sinon une texture de fichier.
local GEAR_ATLASES = { "questlog-icon-setting", "OptionsIcon-Brown", "GM-icon-settings" }
local GEAR_FILE = "Interface\\Buttons\\UI-OptionsButton"
local BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 14, insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local function classColor(class)
    local c = class and C_ClassColor and C_ClassColor.GetClassColor and C_ClassColor.GetClassColor(class)
    if not c and class and RAID_CLASS_COLORS then c = RAID_CLASS_COLORS[class] end
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- Le panneau s'accroche par son COIN HAUT GAUCHE : quand la liste raccourcit, c'est le bas qui
-- remonte, la première ligne ne bouge pas, et un clic répété dessus vide la file. Une ancienne
-- position (centre) se convertit au premier passage. Rend false si l'écran n'est pas encore mesuré.
local function anchorTop(panel)
    local left, top = panel:GetLeft(), panel:GetTop()
    if not (left and top) then return false end
    panel:ClearAllPoints()
    panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left, top)
    NS.db.pos = { point = "TOPLEFT", relPoint = "BOTTOMLEFT", x = left, y = top }
    panel.anchored = true
    return true
end

-- Les deux sens du clic : l'action part sur l'enfoncé ou le relâché selon le réglage du joueur
-- (ActionButtonUseKeyDown), une seule fois. C'est ce que la sonde a validé.
local function secureMacroButton(name, parent)
    local b = CreateFrame("Button", name, parent, "SecureActionButtonTemplate")
    b:RegisterForClicks("AnyUp", "AnyDown")
    b:SetAttribute("type", "macro")
    b:HookScript("OnClick", function(self) NS.Cast:NoteClick(self, GetTime()) end)
    return b
end

-- Pose le texte de macro s'il a changé, et retient qui il vise (pour un sort raté). Jamais en combat
-- (l'appelant le garantit).
local function setMacro(b, text, r)
    if b.macro ~= text then
        b:SetAttribute("macrotext", text)
        b.macro = text
    end
    b.guid = r and r.guid
    b.buffName = r and r.buff and r.buff.name
    b.level = r and r.level
end

local function buildRow(panel)
    local row = secureMacroButton(nil, panel)
    row:SetSize(WIDTH - 2 * PAD, ROW_H)
    local hl = row:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    -- Au bord droit, l'ICÔNE du buff, qui tient lieu de son nom (le user, 2026-10-09 : plus de nom
    -- de sort à traduire ni à tronquer) ; toujours au bord, les icônes de toutes les lignes forment
    -- une colonne (le temps restant devant elle la décalait, vu sur capture le même jour). Devant
    -- l'icône, la note (PvP, temps restant) ; le nom du joueur prend la place qui reste et se tronque.
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_H - 2, ROW_H - 2)
    row.icon:SetPoint("RIGHT")
    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.note:SetPoint("RIGHT", row.icon, "LEFT", -4, 0)
    row.note:SetJustifyH("RIGHT")
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT")
    row.name:SetPoint("RIGHT", row.note, "LEFT", -6, 0)
    row.name:SetJustifyH("LEFT")
    row.name:SetWordWrap(false)
    row.noteRGB = { row.note:GetTextColor() }
    row:Hide()
    return row
end

local function gearAtlas()
    for _, a in ipairs(GEAR_ATLASES) do
        local ok, info = pcall(C_Texture.GetAtlasInfo, a)
        if ok and info then return a end
    end
    return nil
end

-- D32 : le rouage. Un bouton ordinaire (pas sécurisé) : Options:Open refuse lui-même en combat.
local function gearButton(panel)
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(16, 16)
    b:SetPoint("TOPRIGHT", -PAD + 2, -PAD + 1)
    local atlas = C_Texture and gearAtlas()
    for _, layer in ipairs({ "ARTWORK", "HIGHLIGHT" }) do
        local t = b:CreateTexture(nil, layer)
        t:SetAllPoints()
        if atlas then t:SetAtlas(atlas) else t:SetTexture(GEAR_FILE) end
        if layer == "HIGHLIGHT" then t:SetBlendMode("ADD"); t:SetAlpha(0.4) end
    end
    b:SetScript("OnClick", function() NS.Options:Open() end)
    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(L["Options : quels buffs sur quelles classes"])
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

function UI:Build()
    if self.panel then return end
    local driver = CreateFrame("Frame", "SerialBufferDriver", UIParent)
    driver:SetAllPoints(UIParent)
    local panel = CreateFrame("Frame", "SerialBufferPanel", driver, "BackdropTemplate")
    panel:SetSize(WIDTH, 60)
    panel:SetBackdrop(BACKDROP)
    panel:SetBackdropColor(0, 0, 0, 0.8)
    local p = NS.db.pos
    if p then panel:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else panel:SetPoint("TOPRIGHT", UIParent, "RIGHT", -40, 200) end
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    -- Le panneau porte des boutons sécurisés, donc le jeu le protège : en combat (il reste affiché,
    -- D36), StartMoving, StopMovingOrSizing, ClearAllPoints et SetPoint sont bloqués (taint.log du
    -- 2026-10-06 ; StartMoving branché tel quel s'y nomme « UNKNOWN() »). Pas de glisser en combat ;
    -- un glisser commencé juste avant le pull se termine à la sortie du combat (UI:CombatEnd).
    panel:SetScript("OnDragStart", function(f)
        if InCombatLockdown() then return end
        f.dragging = true
        f:StartMoving()
    end)
    panel:SetScript("OnDragStop", function(f)
        if not f.dragging or InCombatLockdown() then return end
        f.dragging = false
        f:StopMovingOrSizing()
        anchorTop(f)
    end)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", PAD, -PAD)
    panel.title:SetText("Serial Buffer")
    panel.gear = gearButton(panel)
    panel.count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.count:SetPoint("RIGHT", panel.gear, "LEFT", -4, 0)
    NS.Header:Build(panel)   -- D40, D41 : la case « Groupe seul » et la touche « buff suivant »
    panel.msg =panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.msg:SetWidth(WIDTH - 2 * PAD)
    panel.msg:SetJustifyH("LEFT")
    for i = 1, MAX_ROWS do self.rows[i] = buildRow(panel) end
    for i = 1, #NS.Queue.SECTIONS do
        local head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        head:SetJustifyH("LEFT")
        head:Hide()
        self.heads[i] = head
    end
    self.driver, self.panel = driver, panel
    if NS.Report then NS.Report:AttachHeaderButton(panel) end   -- le scarabée, à gauche du rouage
    self:BuildNext()
    panel:SetShown(NS.db.shown)
end

-- La touche « buff suivant ». Caché : seul son raccourci le clique. En combat, le pilote d'attribut
-- lui retire son type, et la touche ne fait rien (D36 : elle viserait toujours le même joueur).
function UI:BuildNext()
    local b = secureMacroButton(NS.Cast.NEXT_BUTTON, UIParent)
    b:Hide()
    RegisterAttributeDriver(b, "type", "[combat] nil; macro")
    self.next = b
end

function UI:IsVisible()
    return self.panel ~= nil and self.panel:IsVisible()
end

-- Afficher ou cacher : /sbuff (Toggle) et la case « Afficher le tableau » des options. Jamais en
-- combat (ancêtre de boutons sécurisés) : rend false si refusé. Caché, le tableau ne se recalcule
-- plus : la touche « buff suivant » est vidée, pour ne pas viser une file périmée. Une ligne de chat
-- dit comment le retrouver : caché par /sbuff, il ne se devinait plus (le user, 2026-10-09).
function UI:SetVisible(on)
    if not self.panel then return false end
    if InCombatLockdown() then NS:Print(L["Pas pendant un combat."]) return false end
    NS.db.shown = on and true or false
    self.panel:SetShown(NS.db.shown)
    if not NS.db.shown then
        setMacro(self.next, nil, nil)
        NS:Print(L["Tableau caché. /sbuff, ou la case « Afficher le tableau » des options, le réaffiche."])
    end
    -- La case des options suit /sbuff ; hors combat seulement (cf. Header:SetGroupOnly).
    if NS.Options.built then NS.Options:Refresh() end
    return true
end

function UI:Toggle()
    if not self.panel then return end
    self:SetVisible(not self.panel:IsShown())
end

-- Hors combat seulement (Render). Remet aussi ce que le combat a changé (D36 : gris, note).
-- D39 : « 8 min », « 40 s », ou « expiré » à zéro. Arrondi vers le HAUT, comme la barre de buffs du
-- jeu (6 min 30 s s'y lit « 7 m » : vu le 2026-10-05, la ligne disait « 6 min » à côté).
local function leftText(sec)
    if sec <= 0 then return L["expiré"] end
    if sec > 60 then return string.format(L["%d min"], math.ceil(sec / 60)) end
    return string.format(L["%d s"], math.ceil(sec))
end

-- La note : PvP, hors de portée, puis le temps restant s'il y en a un (D39). Le buff, c'est l'icône.
local function setNote(row, sec)
    local text = row.baseNote
    if sec then text = (text ~= "" and text .. " · " or "") .. leftText(sec) end
    row.note:SetText(text)
end

-- Hors combat seulement (Render). Remet aussi ce que le combat a changé (D36 : gris, note).
local function fillRow(row, r)
    setMacro(row, NS.Cast.MacroFor(r), r)
    row.combatOK, row.isSelf = NS.Cast.CombatClickable(r), r.self
    row.expiresAt, row.done, row.stale = r.expiresAt, false, false
    row.icon:SetTexture(r.buff.icon)
    row.icon:SetDesaturated(false)
    row.name:SetText(r.name)
    row.name:SetTextColor(classColor(r.class))
    row.baseNote = r.pvp and L["PvP"] or ""
    setNote(row, r.left)
    row.note:SetTextColor(unpack(row.noteRGB))
    -- Hors de portée : la ligne se grise et s'estompe, sans texte, comme les cadres de groupe du jeu
    -- (le user, 2026-10-09). Sa section « Hors de portée » le dit déjà.
    if r.outOfRange then
        row.name:SetTextColor(0.5, 0.5, 0.5)
        row.icon:SetDesaturated(true)
    end
    row:SetAlpha(r.outOfRange and 0.5 or 1)
    row:Show()
end

-- D39 : en combat, le temps restant des lignes cliquables descend (depuis l'heure de fin relevée
-- avant le pull : rien n'est relu) ; à zéro, « expiré » en orange. Régions enfants seulement.
function UI:CombatTick(now)
    for _, row in ipairs(self.rows) do
        if row:IsShown() and row.combatOK and not row.done and not row.stale and row.expiresAt then
            local sec = NS.Queue.Remaining(row, now)
            setNote(row, sec)
            if sec <= 0 then row.note:SetTextColor(1, 0.6, 0.2) end
        end
    end
end

-- D36 : une ligne éteinte ou faite, en combat. Régions enfants seulement : le bouton est protégé.
local function dim(row, note, r, g, b)
    row.name:SetTextColor(0.45, 0.45, 0.45)
    row.icon:SetDesaturated(true)
    if note then
        row.note:SetText(note)
        row.note:SetTextColor(r or 0.5, g or 0.5, b or 0.5)
    end
end

-- Au pull : les lignes d'inconnus s'éteignent (elles ne lancent plus rien : /stopmacro [combat]).
function UI:CombatStart()
    for _, row in ipairs(self.rows) do
        if row:IsShown() and not row.combatOK then dim(row, nil) end
    end
    self:FinishDrag()   -- un glisser en cours au pull : posé tout de suite si le jeu le permet encore
end

-- Termine un glisser resté en cours (pull pendant le glisser) : hors verrou seulement, sinon à la
-- sortie du combat (SerialBuffer_Run.lua, PLAYER_REGEN_ENABLED).
function UI:FinishDrag()
    local p = self.panel
    if not (p and p.dragging) or InCombatLockdown() then return end
    p.dragging = false
    p:StopMovingOrSizing()
    anchorTop(p)
end

-- Notre sort sur ce joueur a réussi pendant le combat : sa ligne se grise, sans sortir du tableau.
function UI:MarkDone(guid)
    for _, row in ipairs(self.rows) do
        if row:IsShown() and row.guid == guid then
            row.done = true                                  -- D39 : plus de décompte
            dim(row, L["buffé"], 0.4, 0.8, 0.4)
        end
    end
end

-- Le groupe a changé pendant le combat : un jeton peut désigner un autre joueur (exception de D36).
function UI:MarkStale()
    for _, row in ipairs(self.rows) do
        if row:IsShown() and row.combatOK and not row.isSelf then
            row.stale = true                                 -- D39 : le décompte ne l'écrase pas
            row.note:SetText(L["groupe changé"])
            row.note:SetTextColor(1, 0.4, 0.3)
        end
    end
end

-- Clés écrites en toutes lettres : la porte de localisation ne voit pas un L[variable].
local function stateMessage(state)
    if state == "instance" then return L["En instance : seul ton groupe est listé."] end
    if state == "nobuffs" then return L["Ta classe n'a pas de buff à poser sur les autres."] end
    if state == "noplates" then return L["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."] end
    return nil
end

local function sectionTitle(section, kind)
    if section == "group" then return kind == "raid" and L["Raid"] or L["Groupe"] end
    if section == "around" then return L["Autour de toi"] end
    return L["Hors de portée"]
end

-- Le message du pied : l'état, le reste de la liste, les illisibles (D31), sinon pourquoi la liste est
-- vide (spec, « Liste vide »). Une ligne par message.
local function footer(rows, info)
    local lines = {}
    local m = stateMessage(info.state)
    if m then lines[#lines + 1] = m end
    if info.state ~= "nobuffs" then
        if #rows > MAX_ROWS then lines[#lines + 1] = string.format(L["+%d autres"], #rows - MAX_ROWS) end
        local unread = info.unread or 0
        if unread > 0 then
            lines[#lines + 1] = string.format(L["%d illisible(s) : le jeu cache leur nom ou leurs buffs."], unread)
        elseif #rows == 0 then
            local nobody = info.state == "grouponly" and L["Personne à buffer dans ton groupe."]   -- D40
                or L["Personne à buffer autour de toi."]
            lines[#lines + 1] = (info.around or 0) == 0 and nobody or L["Tournée finie !"]
        end
    end
    if #lines == 0 then return nil end
    return table.concat(lines, "\n")
end

-- Place les titres de partie (groupé seulement, D30) et les lignes ; rend le y libre sous la dernière.
-- Une ligne n'est replacée que si sa place change (attribut sécurisé ou pas, hors combat : Render).
function UI:Layout(rows, kind)
    local counts = {}
    for _, r in ipairs(rows) do counts[r.section] = (counts[r.section] or 0) + 1 end
    local y, used, last = PAD + TOP, 0, nil
    for i = 1, MAX_ROWS do
        local row, r = self.rows[i], rows[i]
        if r then
            if kind and r.section ~= last then
                used, last = used + 1, r.section
                local head = self.heads[used]
                head:ClearAllPoints()
                head:SetPoint("TOPLEFT", self.panel, "TOPLEFT", PAD, -y)
                head:SetText(string.format("%s (%d)", sectionTitle(r.section, kind), counts[r.section]))
                head:Show()
                y = y + HEAD_H
            end
            if row.y ~= y then
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", self.panel, "TOPLEFT", PAD, -y)
                row.y = y
            end
            fillRow(row, r)
            y = y + ROW_H
        else
            row:Hide()
        end
    end
    for j = used + 1, #self.heads do self.heads[j]:Hide() end
    return y
end

-- info : state ("ok" | "noplates" | "grouponly" | "instance" | "nobuffs"), around, unread,
-- group ("raid" | "party" | nil). « grouponly » (D40) n'a pas de message : la case de l'en-tête le dit.
function UI:Render(rows, info)
    if not self.panel or InCombatLockdown() then return end
    if not self.panel.anchored then anchorTop(self.panel) end
    NS.Header:Refresh()
    local nextRow = NS.Cast.NextRow(rows)
    setMacro(self.next, nextRow and NS.Cast.MacroFor(nextRow), nextRow)
    local y = self:Layout(rows, info.group)
    self.panel.count:SetText(string.format(L["%d à buffer"], #rows))
    local msg = footer(rows, info)
    self.panel.msg:ClearAllPoints()
    self.panel.msg:SetPoint("TOPLEFT", PAD, -(y + 2))
    self.panel.msg:SetText(msg or "")
    local msgH = msg and (self.panel.msg:GetStringHeight() + 4) or 0
    self.panel:SetHeight(y + 2 + PAD + msgH)
end
