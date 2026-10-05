-- SerialBuffer_Options.lua — LES OPTIONS, dans le panneau d'options du jeu (Options > AddOns).
--
-- Spec docs/specs/serial-buffer.md : D34 et D35 (la grille par classe et sa ligne « Groupe / raid »,
-- SerialBuffer_Grid.lua), D28 (seuil de rafraîchissement hors paladin), D5 (joueurs PvP), D32 (le
-- rouage du tableau ouvre ce panneau : O:Open).
-- Prudences, toutes deux liées au client Forever (skill public wow-forever-api) :
--   - AUCUN menu déroulant : ouvrir un menu du système Menu depuis un addon fait planter le client
--     (taint-and-protected-frames.md, « Menus »). L'ordre se règle avec les flèches de la grille ;
--   - l'API Settings n'a jamais été éprouvée par nos addons sur ce client : son inscription passe par
--     pcall, et le contenu ne se construit qu'à la première ouverture du panneau.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local O = { checks = {} }
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

-- D28 : le seuil de rafraîchissement (hors paladin), en minutes, par pas de 5, entre 10 et 55.
local STEP, MIN_REFRESH, MAX_REFRESH = 5, 10, 55

function O:StepRefresh(delta)
    local v = (NS.db.refreshMin or 45) + delta
    NS.db.refreshMin = math.max(MIN_REFRESH, math.min(MAX_REFRESH, v))
    self:Refresh()
end

local function refreshRow(panel, y)
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(560, 26)
    row:SetPoint("TOPLEFT", PAD, y)
    row.minus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.minus:SetSize(28, 22)
    row.minus:SetPoint("LEFT")
    row.minus:SetText("-")
    row.minus:SetScript("OnClick", function() O:StepRefresh(-STEP) end)
    row.plus = CreateFrame("Button", nil, row, "UIPanelButtonTemplate")
    row.plus:SetSize(28, 22)
    row.plus:SetPoint("LEFT", row.minus, "RIGHT", 4, 0)
    row.plus:SetText("+")
    row.plus:SetScript("OnClick", function() O:StepRefresh(STEP) end)
    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    row.label:SetPoint("LEFT", row.plus, "RIGHT", 8, 0)
    return row
end

-- Coordination, palier 3 (C1) : qui peut régler ta ligne Groupe / raid à ta place. Trois cases
-- qui s'excluent (aucun menu déroulant : ils font planter Forever). Rend le y libre suivant.
local WHO = { "none", "leader", "anyone" }

function O:WhoRow(panel, y)
    local head = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    head:SetPoint("TOPLEFT", PAD, y - 4)
    head:SetText(L["Qui peut régler ta ligne Groupe / raid :"])
    local xs = { PAD, PAD + 120, PAD + 330 }
    for i, value in ipairs(WHO) do
        -- Clés écrites en toutes lettres pour la porte de localisation.
        local label = (i == 1 and L["personne"]) or (i == 2 and L["le chef et ses assistants"]) or L["n'importe qui du groupe"]
        self.checks[#self.checks + 1] = checkbox(panel, xs[i], y - 24, label,
            function() return (NS.db.coordWho or "none") == value end,
            function()
                NS.db.coordWho = value
                O:Refresh()
                NS.Comm:Announce()   -- les autres apprennent s'ils peuvent régler ta ligne
            end)
    end
    return y - 54
end

-- Construit le contenu une fois, à la première ouverture.
function O:Build(panel)
    local _, class = UnitClass("player")
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", PAD, -PAD)
    title:SetText("Serial Buffer")
    local y = -PAD - 30
    if NS.Buffs:HasCatalog(class) then
        y = NS.Grid:Build(panel, y, class)
        y = self:WhoRow(panel, y)
        local note = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        note:SetPoint("TOPLEFT", PAD, y - 6)
        note:SetWidth(600)
        note:SetJustifyH("LEFT")
        note:SetText(L["Groupe / raid : un choix unique pour les membres de ton groupe ou raid ; vide, la grille du dessus s'applique. Un buff de mana n'est jamais proposé aux guerriers ni aux voleurs."])
        y = y - 36
        if class ~= "PALADIN" then
            self.refreshRow = refreshRow(panel, y); y = y - LINE - 4
        end
    end
    self.checks[#self.checks + 1] = checkbox(panel, PAD, y, L["Montrer les joueurs marqués PvP"],
        function() return NS.db.showPvP end, function(v) NS.db.showPvP = v end)
    self.built = true
end

-- Remet chaque contrôle à l'état de la base (à chaque ouverture, et après un clic).
function O:Refresh()
    for _, cb in ipairs(self.checks) do cb:SetChecked(cb.get() and true or false) end
    if self.refreshRow then
        local v = NS.db.refreshMin or 45
        self.refreshRow.label:SetText(string.format(L["Rafraîchir un buff s'il lui reste moins de %d min"], v))
        self.refreshRow.minus:SetEnabled(v > MIN_REFRESH)
        self.refreshRow.plus:SetEnabled(v < MAX_REFRESH)
    end
    NS.Grid:Refresh()
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

-- /sbuff options, et le rouage du tableau (D32).
function O:Open()
    if InCombatLockdown() then NS:Print(L["Pas pendant un combat."]) return end
    local ok = self.category and Settings.OpenToCategory
        and pcall(Settings.OpenToCategory, self.category:GetID())
    if not ok then NS:Print(L["Options indisponibles sur ce client."]) end
end
