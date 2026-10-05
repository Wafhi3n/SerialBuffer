-- SerialBuffer_Grid.lua — LA GRILLE des options (D33) : une ligne par buff, une colonne par classe de
-- la cible, « comme un tableur ». Une case cochée = ce buff se pose sur cette classe.
--
-- Spec docs/specs/serial-buffer.md : D33 (la grille), D22 (le paladin : les lignes suivent sa priorité,
-- réglée par les flèches de chaque ligne ; aucun menu déroulant, ils font planter Forever), D23 (les
-- cases buff de mana × guerrier, voleur sont grisées, jamais cochables).
-- La logique des cases vit dans SerialBuffer_Buffs.lua (Cell, SetCell, Locked, MovePriority), testée
-- sans client ; ce fichier ne fait que dessiner et relayer les clics.
-- Colonnes : NS.Buffs.CLASSES, les neuf classes de Forever. En-tête : l'icône de classe (atlas
-- « classicon-<classe> », celui de la création de personnage de Camelot), sinon le début du nom ;
-- le nom complet est dans l'infobulle.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local G = { rows = {} }
NS.Grid = G

local PAD, ROW_H, HEAD_H, LABEL_W, COL_W, ARROWS_W = 16, 26, 28, 210, 40, 40

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
        GameTooltip:SetText(text)
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

local function arrow(row, template, x, label, delta, i)
    local b = CreateFrame("Button", nil, row, template)
    b:SetSize(18, 16)
    b:SetPoint("LEFT", x, 0)
    b:SetScript("OnClick", function() G:Move(i, delta) end)
    tooltip(b, label)
    return b
end

local function cell(row, c, class, i)
    local cb = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("LEFT", LABEL_W + (c - 1) * COL_W + (COL_W - 24) / 2, 0)
    cb.class = class
    cb:SetScript("OnClick", function(b) G:Toggle(i, class, b:GetChecked() and true or false) end)
    return cb
end

local function gridRow(parent, i, y, paladin)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(LABEL_W + COL_W * #NS.Buffs.CLASSES, ROW_H)
    row:SetPoint("TOPLEFT", PAD, y)
    local x = 0
    if paladin then
        row.up = arrow(row, "UIPanelScrollUpButtonTemplate", 0, L["Monter"], -1, i)
        row.down = arrow(row, "UIPanelScrollDownButtonTemplate", 20, L["Descendre"], 1, i)
        x = ARROWS_W
    end
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", x, 0)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.label:SetWidth(LABEL_W - x - 30)
    row.label:SetJustifyH("LEFT")
    row.label:SetWordWrap(false)
    row.cells = {}
    for c, class in ipairs(NS.Buffs.CLASSES) do row.cells[c] = cell(row, c, class, i) end
    return row
end

-- Construit la grille sous y, pour la classe du joueur ; rend le y libre suivant.
function G:Build(parent, y, class)
    self.class = class
    local head = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", PAD, y - 8)
    head:SetText(class == "PALADIN" and L["Priorité des bénédictions"] or L["Buffs proposés"])
    for c, cl in ipairs(NS.Buffs.CLASSES) do classHeader(parent, cl, PAD + LABEL_W + (c - 1) * COL_W, y) end
    y = y - HEAD_H
    for i = 1, #NS.Buffs:Catalog(class, NS.db) do
        self.rows[i] = gridRow(parent, i, y, class == "PALADIN")
        y = y - ROW_H
    end
    return y
end

-- Remet chaque ligne et chaque case à l'état de la base (à l'ouverture, et après chaque clic).
function G:Refresh()
    if not self.class then return end
    local B, paladin = NS.Buffs, self.class == "PALADIN"
    local cat = B:Catalog(self.class, NS.db)
    self.cat = cat
    for i, row in ipairs(self.rows) do
        local e = cat[i]
        if e then
            local missing = paladin and L["non apprise"] or L["non appris"]
            local label = e.known and e.name or (e.name .. " (" .. missing .. ")")
            row.icon:SetTexture(e.icon)
            row.label:SetText(paladin and (i .. ". " .. label) or label)
            for _, cb in ipairs(row.cells) do
                local locked = B:Locked(e.id, cb.class)
                cb:SetEnabled(not locked)
                cb:SetAlpha(locked and 0.35 or 1)
                cb:SetChecked(B:Cell(e.id, cb.class, NS.db))
            end
            if row.up then
                row.up:SetEnabled(i > 1)
                row.down:SetEnabled(i < #cat)
            end
        end
    end
end

function G:Toggle(i, class, on)
    local e = self.cat and self.cat[i]
    if e then NS.Buffs:SetCell(e.id, class, on, NS.db) end
    self:Refresh()
end

function G:Move(i, delta)
    if NS.Buffs:MovePriority(NS.db, i, delta) then self:Refresh() end
end
