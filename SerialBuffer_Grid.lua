-- SerialBuffer_Grid.lua — LA GRILLE des options (D34, D35) : une colonne par classe de la cible, une
-- ligne par rang (1er choix, 2e…), « comme un tableur ». Chaque case est une ICÔNE qu'on change au
-- clic ou à la molette : vide, puis chacun des buffs de ta classe.
--
-- Spec docs/specs/serial-buffer.md :
--   D34 : une colonne « Toutes » sert de modèle (non sauvegardé), son bouton Remplir la recopie sur la
--         ligne ; ↺ sous une classe remet sa colonne par défaut ; « Tout par défaut » remet toutes les
--         colonnes de ta classe ;
--   D35 : une ligne « Groupe / raid » à part, un choix unique par classe pour les membres de ton
--         groupe ou raid ; vide par défaut, et vide = la colonne du dessus s'applique ;
--   D23 : un buff de mana n'est jamais proposé dans la colonne d'un guerrier ou d'un voleur.
-- Toute la logique des colonnes vit dans SerialBuffer_Buffs.lua (testée sans client) : ce fichier
-- dessine et relaie. Aucun menu déroulant : ils font planter Forever (wow-forever-api).
-- En-têtes : l'icône de classe (atlas « classicon-<classe> », vu sur Forever le 2026-10-05), sinon le
-- début du nom ; le nom complet est dans l'infobulle.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local G = { rows = {} }
NS.Grid = G

local PAD, CELL, COL_W, LABEL_W, HEAD_H, ROW_H = 16, 30, 40, 96, 28, 36
local ALL_X  = PAD + LABEL_W        -- la colonne « Toutes »
local FILL_X = ALL_X + COL_W        -- le bouton Remplir de chaque ligne
local CLS_X  = FILL_X + 36          -- la première colonne de classe
local UNDO_ATLAS, UNDO_FILE = "common-icon-undo", "Interface\\Buttons\\UI-RefreshButton"

-- Le nom traduit d'une classe. LOCALIZED_CLASS_NAMES_MALE n'est posé que sur Mainline
-- (Blizzard_FrameXMLBase/Constants.lua, [AllowLoadGameType mainline]) : sur Camelot, on le lit par
-- C_CreatureInfo.GetClassInfo, documentée pour tous les clients (build 70205). Repli : le jeton.
local names
local function className(class)
    if not names then
        names = {}
        local get = C_CreatureInfo and C_CreatureInfo.GetClassInfo
        for id = 1, get and 13 or 0 do
            local ok, info = pcall(get, id)
            if ok and type(info) == "table" and info.classFile and info.className then
                names[info.classFile] = info.className
            end
        end
    end
    local n = names[class] or (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[class])
    return type(n) == "string" and n or class
end

local function classRGB(class)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

-- Les n premiers CARACTÈRES (UTF-8) : « Prêtre » ne doit pas être coupé au milieu du « ê ».
local function prefix(s, n)
    local out = {}
    for ch in s:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
        if #out >= n then break end
        out[#out + 1] = ch
    end
    return table.concat(out)
end

local function tooltip(owner, text)
    owner:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(text, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    owner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function hasAtlas(name)
    if not (C_Texture and C_Texture.GetAtlasInfo) then return false end
    local ok, info = pcall(C_Texture.GetAtlasInfo, name)
    return ok and info ~= nil
end

local function classHeader(parent, class, x, y)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(COL_W, HEAD_H)
    f:SetPoint("TOPLEFT", x, y)
    local atlas = "classicon-" .. class:lower()
    if hasAtlas(atlas) then
        local t = f:CreateTexture(nil, "ARTWORK")
        t:SetSize(22, 22)
        t:SetPoint("CENTER")
        t:SetAtlas(atlas)
    else
        local fs = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        fs:SetPoint("CENTER")
        fs:SetText(prefix(className(class), 3))
        fs:SetTextColor(classRGB(class))
    end
    f:EnableMouse(true)
    tooltip(f, className(class))
    return f
end

-- ---------------------------------------------------------------- une case

local function cellTooltip(b)
    local c = NS.Buffs.client
    GameTooltip:SetOwner(b, "ANCHOR_TOP")
    if b.id and b.id ~= 0 then
        GameTooltip:SetText(c.name(b.id) or tostring(b.id))
        if not c.known(b.id) then GameTooltip:AddLine(L["non appris"], 1, 0.3, 0.3) end
    elseif b.kind == "group" then
        GameTooltip:SetText(L["Vide : la grille du dessus s'applique."])
    else
        GameTooltip:SetText(L["Vide"])
    end
    GameTooltip:AddLine(b.class and className(b.class) or L["Toutes"], 0.8, 0.8, 0.8)
    GameTooltip:AddLine(L["Clic ou molette : buff suivant. Clic droit : précédent."], 0.6, 0.6, 0.6, true)
    GameTooltip:Show()
end

local function paint(b, id)
    b.id = id
    if id and id ~= 0 then
        local c = NS.Buffs.client
        local known = c.known(id)
        b.icon:SetTexture(c.icon(id))
        b.icon:SetDesaturated(not known)
        b.icon:SetAlpha(known and 1 or 0.6)
        b.icon:Show()
    else
        b.icon:Hide()
    end
end

-- Clic gauche et molette vers le bas : buff suivant ; clic droit et molette vers le haut : précédent.
local function cell(parent, x, y, kind, rank, class)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(CELL, CELL)
    b:SetPoint("TOPLEFT", x + (COL_W - CELL) / 2, y)
    b.kind, b.rank, b.class = kind, rank, class
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.55)
    b.icon = b:CreateTexture(nil, "ARTWORK")
    b.icon:SetPoint("TOPLEFT", 2, -2)
    b.icon:SetPoint("BOTTOMRIGHT", -2, 2)
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(self, button) G:Step(self, button == "RightButton" and -1 or 1) end)
    b:EnableMouseWheel(true)
    b:SetScript("OnMouseWheel", function(self, delta) G:Step(self, delta > 0 and -1 or 1) end)
    b:SetScript("OnEnter", cellTooltip)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

local function fillButton(parent, y, kind, rank)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(28, 22)
    b:SetPoint("TOPLEFT", FILL_X + 4, y - 4)
    b:SetText("»")
    b:SetScript("OnClick", function() G:Fill(kind, rank) end)
    tooltip(b, L["Remplir : recopie la case « Toutes » sur toutes les classes"])
    return b
end

local function undoButton(parent, x, y, class)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(18, 18)
    b:SetPoint("TOPLEFT", x + (COL_W - 18) / 2, y)
    local atlas = hasAtlas(UNDO_ATLAS)
    for _, layer in ipairs({ "ARTWORK", "HIGHLIGHT" }) do
        local t = b:CreateTexture(nil, layer)
        t:SetAllPoints()
        if atlas then t:SetAtlas(UNDO_ATLAS) else t:SetTexture(UNDO_FILE) end
        if layer == "HIGHLIGHT" then t:SetBlendMode("ADD"); t:SetAlpha(0.4) end
    end
    b:SetScript("OnClick", function() G:Reset(class) end)
    tooltip(b, L["Remettre cette classe par défaut"])
    return b
end

-- ---------------------------------------------------------------- la grille

-- Une ligne : son libellé, sa case « Toutes », Remplir, puis une case par classe. Rend le y suivant.
function G:BuildRow(parent, y, kind, rank, label)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("TOPLEFT", PAD, y - 11)
    fs:SetWidth(LABEL_W - 4)
    fs:SetJustifyH("LEFT")
    fs:SetText(label)
    local row = { all = cell(parent, ALL_X, y, kind, rank, nil), cells = {} }
    fillButton(parent, y, kind, rank)
    for i, cl in ipairs(NS.Buffs.CLASSES) do
        row.cells[i] = cell(parent, CLS_X + (i - 1) * COL_W, y, kind, rank, cl)
    end
    self.rows[#self.rows + 1] = row
    return y - ROW_H
end

-- Construit la grille sous y, pour la classe du joueur ; rend le y libre suivant.
function G:Build(parent, y, caster)
    local B = NS.Buffs
    self.caster, self.all, self.allGroup = caster, B:DefaultOrder(caster, nil), 0
    local head = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", PAD, y)
    head:SetText(caster == "PALADIN" and L["Une bénédiction par classe : le 1er choix, sinon le suivant"]
        or L["Tes buffs par classe, dans l'ordre"])
    y = y - 22
    local all = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    all:SetPoint("CENTER", parent, "TOPLEFT", ALL_X + COL_W / 2, y - HEAD_H / 2)
    all:SetText(L["Toutes"])
    for i, cl in ipairs(B.CLASSES) do classHeader(parent, cl, CLS_X + (i - 1) * COL_W, y) end
    y = y - HEAD_H
    local fmt = caster == "PALADIN" and L["Choix %d"] or L["Buff %d"]
    for r = 1, B:Ranks(caster) do y = self:BuildRow(parent, y, "rank", r, string.format(fmt, r)) end
    y = self:BuildRow(parent, y - 6, "group", nil, L["Groupe / raid"])
    for i, cl in ipairs(B.CLASSES) do undoButton(parent, CLS_X + (i - 1) * COL_W, y - 2, cl) end
    local resetAll = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    resetAll:SetSize(130, 22)
    resetAll:SetPoint("TOPLEFT", PAD, y)
    resetAll:SetText(L["Tout par défaut"])
    resetAll:SetScript("OnClick", function() G:Reset(nil) end)
    return y - 28
end

-- Remet chaque case à l'état de la base (à l'ouverture, et après chaque geste).
function G:Refresh()
    if not self.caster then return end
    local B, c, db = NS.Buffs, self.caster, NS.db
    for _, row in ipairs(self.rows) do
        local a = row.all
        paint(a, a.kind == "group" and self.allGroup or self.all[a.rank])
        for _, b in ipairs(row.cells) do
            paint(b, b.kind == "group" and B:GroupPick(c, b.class, db) or B:Order(c, b.class, db)[b.rank])
        end
    end
end

function G:Step(b, delta)
    local B, c, db = NS.Buffs, self.caster, NS.db
    if b.kind == "group" then
        local cur = b.class and B:GroupPick(c, b.class, db) or self.allGroup
        local v = B:Cycle(B:Choices(c, b.class, nil, nil), cur, delta)
        if b.class then B:SetGroupPick(c, b.class, v, db) else self.allGroup = v end
    elseif b.class then
        B:SetOrder(c, b.class, B:StepColumn(c, b.class, B:Order(c, b.class, db), b.rank, delta), db)
    else
        self.all = B:StepColumn(c, nil, self.all, b.rank, delta)
    end
    self:Refresh()
    if GameTooltip:IsOwned(b) then cellTooltip(b) end
end

function G:Fill(kind, rank)
    local B = NS.Buffs
    if kind == "group" then B:FillGroup(self.caster, self.allGroup, NS.db)
    else B:Fill(self.caster, rank, self.all[rank] or 0, NS.db) end
    self:Refresh()
end

-- class = nil : « Tout par défaut », la colonne « Toutes » comprise.
function G:Reset(class)
    local B = NS.Buffs
    if class then B:ResetClass(self.caster, class, NS.db)
    else
        B:ResetAll(self.caster, NS.db)
        self.all, self.allGroup = B:DefaultOrder(self.caster, nil), 0
    end
    self:Refresh()
end
