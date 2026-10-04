-- SerialBuffer_Options.lua — LES OPTIONS, dans le panneau d'options du jeu (Options > AddOns).
--
-- Spec docs/specs/serial-buffer.md : D22 (priorité des bénédictions, réglable ICI), D14 (un buff se
-- décoche), D5 (joueurs PvP), D23 (rappel : pas de buff de mana aux classes sans mana).
-- Prudences, toutes deux liées au client Forever (skill public wow-forever-api) :
--   - AUCUN menu déroulant : ouvrir un menu du système Menu depuis un addon fait planter le client
--     (taint-and-protected-frames.md, « Menus »). L'ordre se règle avec Monter / Descendre ;
--   - l'API Settings n'a jamais été éprouvée par nos addons sur ce client : son inscription passe par
--     pcall, et le contenu ne se construit qu'à la première ouverture du panneau.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local O = { rows = {}, checks = {} }
NS.Options = O

local PAD, LINE = 16, 28

local function checkbox(parent, x, y, label, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    cb:SetPoint("TOPLEFT", x, y)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    cb.label:SetText(label)
    cb.get = get
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    return cb
end

local function header(parent, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fs:SetPoint("TOPLEFT", PAD, y)
    fs:SetText(text)
    return fs
end

local function setOff(id, checked)
    NS.db.off = NS.db.off or {}
    NS.db.off[id] = (not checked) or nil
end

-- D22 : Monter / Descendre échangent deux bénédictions de la priorité, gardée dans db.priority.
function O:Move(i, delta)
    local p = {}
    for k, v in ipairs(NS.Buffs:Priority(NS.db)) do p[k] = v end
    local j = i + delta
    if j < 1 or j > #p then return end
    p[i], p[j] = p[j], p[i]
    NS.db.priority = p
    self:Refresh()
end

local function priorityRow(parent, i, y)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(560, 26)
    row:SetPoint("TOPLEFT", PAD, y)
    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(24, 24)
    row.check:SetPoint("LEFT")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(20, 20)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 4, 0)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 6, 0)
    row.up = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.up:SetSize(90, 22)
    row.up:SetPoint("LEFT", 300, 0)
    row.up:SetText(L["Monter"])
    row.up:SetScript("OnClick", function() O:Move(i, -1) end)
    row.down = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.down:SetSize(90, 22)
    row.down:SetPoint("LEFT", row.up, "RIGHT", 6, 0)
    row.down:SetText(L["Descendre"])
    row.down:SetScript("OnClick", function() O:Move(i, 1) end)
    return row
end

-- Construit le contenu une fois, à la première ouverture. Rend le y libre suivant.
function O:Build(panel)
    local _, class = UnitClass("player")
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText("Serial Buffer")
    local y = -PAD - 34
    if class == "PALADIN" then
        header(panel, y, L["Priorité des bénédictions"]); y = y - 22
        for i = 1, #NS.Buffs:Priority(NS.db) do
            self.rows[i] = priorityRow(panel, i, y); y = y - LINE
        end
    elseif NS.Buffs:HasCatalog(class) then
        header(panel, y, L["Buffs proposés"]); y = y - 22
        for _, e in ipairs(NS.Buffs:Catalog(class, NS.db)) do
            local id = e.id
            local label = e.known and e.name or (e.name .. " (" .. L["non appris"] .. ")")
            self.checks[#self.checks + 1] = checkbox(panel, PAD, y, label,
                function() return not (NS.db.off and NS.db.off[id]) end, function(v) setOff(id, v) end)
            y = y - LINE
        end
    end
    local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    note:SetPoint("TOPLEFT", PAD, y - 4)
    note:SetWidth(560)
    note:SetJustifyH("LEFT")
    note:SetText(L["Les buffs de mana (Sagesse, Intelligence des Arcanes) ne vont jamais aux guerriers ni aux voleurs."])
    y = y - 36
    self.checks[#self.checks + 1] = checkbox(panel, PAD, y, L["Montrer les joueurs marqués PvP"],
        function() return NS.db.showPvP end, function(v) NS.db.showPvP = v end)
    self.built = true
end

-- Remet chaque contrôle à l'état de la base (à chaque ouverture, et après Monter / Descendre).
function O:Refresh()
    for _, cb in ipairs(self.checks) do cb:SetChecked(cb.get() and true or false) end
    local _, class = UnitClass("player")
    if class ~= "PALADIN" then return end
    local cat = NS.Buffs:Catalog("PALADIN", NS.db)
    for i, row in ipairs(self.rows) do
        local e = cat[i]
        if e then
            local id = e.id
            row.icon:SetTexture(e.icon)
            row.label:SetText(i .. ". " .. e.name .. (e.known and "" or (" (" .. L["non apprise"] .. ")")))
            row.check:SetChecked(not (NS.db.off and NS.db.off[id]))
            row.check:SetScript("OnClick", function(b) setOff(id, b:GetChecked() and true or false) end)
            row.up:SetEnabled(i > 1)
            row.down:SetEnabled(i < #cat)
        end
    end
end

function O:Register()
    if not (Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory) then return end
    local panel = CreateFrame("Frame")
    panel:SetScript("OnShow", function(f)
        if not O.built then O:Build(f) end
        O:Refresh()
    end)
    local ok, cat = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Serial Buffer")
    if not ok or not cat then return end
    if pcall(Settings.RegisterAddOnCategory, cat) then self.panel, self.category = panel, cat end
end

-- /sbuff options
function O:Open()
    if InCombatLockdown() then NS:Print(L["Pas pendant un combat."]) return end
    local ok = self.category and Settings.OpenToCategory
        and pcall(Settings.OpenToCategory, self.category:GetID())
    if not ok then NS:Print(L["Options indisponibles sur ce client."]) end
end
