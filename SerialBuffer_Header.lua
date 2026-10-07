-- SerialBuffer_Header.lua — L'EN-TÊTE DU TABLEAU : la case « Groupe seul » et la touche « buff suivant ».
--
-- D40 (user, 2026-10-07) : une case coupe les joueurs autour de toi ; seuls toi et ton groupe ou ton
-- raid restent listés (db.groupOnly). La même case est dans les options, et /sbuff autour la bascule.
-- Le filtre lui-même vit dans SerialBuffer_Run.lua : case cochée, aucune plaque n'est lue.
-- D41 (user, 2026-10-07) : la touche assignée à « buff suivant » s'affiche à gauche du compteur ; un
-- clic ouvre la page Raccourcis du JEU sur la section « Serial Buffer » (choix du user : l'interface de
-- Blizzard, pas une capture maison, qui prendrait une touche à une autre action sans le montrer).
-- Relue à chaque UPDATE_BINDINGS, donc dès qu'on la change dans cette page.
-- Deux cadres ordinaires, enfants du panneau protégé : aucun attribut sécurisé ; seuls leur texte,
-- leur largeur et la coche changent après la construction, ce que le combat permet.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local H = {}
NS.Header = H

local function action() return "CLICK " .. NS.Cast.NEXT_BUTTON .. ":LeftButton" end   -- Bindings.xml

-- La touche, abrégée comme sur les barres d'action, ou nil. pcall : jamais éprouvé sur Forever.
function H.KeyText()
    local ok, key = pcall(GetBindingKey, action())
    if not ok or type(key) ~= "string" or key == "" then return nil end
    local okText, text = pcall(GetBindingText, key, 1)   -- comme ActionButton.lua (Forever 70205)
    if okText and type(text) == "string" and text ~= "" then return text end
    return key
end

-- La page Raccourcis du jeu, déroulée jusqu'à la section « Serial Buffer » : son nom est la valeur de
-- BINDING_HEADER_SERIALBUFFER (SerialBuffer_Cast.lua), que Blizzard_SettingsDefinitions_Frame donne à
-- la section. L'id de la page n'existe qu'une fois les réglages du jeu chargés : lu au clic.
function H:OpenBindings()
    if InCombatLockdown() then NS:Print(L["Pas pendant un combat."]) return end
    local id = Settings and Settings.KEYBINDINGS_CATEGORY_ID
    local ok = id and Settings.OpenToCategory
        and pcall(Settings.OpenToCategory, id, _G.BINDING_HEADER_SERIALBUFFER)
    if not ok then NS:Print(L["Page des raccourcis indisponible : Échap > Options > Raccourcis > Serial Buffer."]) end
end

-- D40 : la case, la case des options et /sbuff autour passent tous par ici. Hors combat, le tableau
-- suit tout de suite ; en combat il est figé (D36) et prend le réglage à la sortie ; caché, il ne
-- recalcule rien (la touche « buff suivant » reste vide, SerialBuffer_UI.lua).
function H:SetGroupOnly(on)
    NS.db.groupOnly = on and true or false
    self:Refresh()
    if NS.Options.built then NS.Options:Refresh() end
    if NS.UI:IsVisible() then NS.Run:Refresh() end
end

local function tooltip(owner, title, line)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(line, 1, 1, 1, true)
    GameTooltip:Show()
end

local function hideTooltip() GameTooltip:Hide() end

-- La case, juste après le titre ; son libellé est cliquable aussi.
local function groupCheck(panel)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("LEFT", panel.title, "RIGHT", 4, 0)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 1, 0)
    cb.label:SetText(L["Groupe seul"])
    cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 2), 0, 0)
    cb:SetScript("OnClick", function(self) H:SetGroupOnly(self:GetChecked()) end)
    cb:SetScript("OnEnter", function(self)
        tooltip(self, L["Groupe seul"],
            L["Coché : seuls toi et ton groupe ou ton raid sont listés ; les joueurs autour de toi sont ignorés."])
    end)
    cb:SetScript("OnLeave", hideTooltip)
    return cb
end

-- La touche, à gauche du compteur : « [F] », ou « touche ? » en gris si aucune n'est assignée.
local function keyButton(panel)
    local b = CreateFrame("Button", nil, panel)
    b:SetHeight(14)
    b:SetPoint("RIGHT", panel.count, "LEFT", -6, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.15)
    b:SetScript("OnClick", function() H:OpenBindings() end)
    b:SetScript("OnEnter", function(self)
        local key = H.KeyText()
        tooltip(self, key and string.format(L["Touche « buff suivant » : %s"], key)
            or L["Aucune touche pour « buff suivant »."], L["Clic : la page Raccourcis du jeu, section Serial Buffer."])
    end)
    b:SetScript("OnLeave", hideTooltip)
    return b
end

-- La coche et la touche, relues de la base et du client : à chaque rendu (hors combat), sur
-- UPDATE_BINDINGS et après une bascule.
function H:Refresh()
    if self.check then self.check:SetChecked(NS.db.groupOnly and true or false) end
    local b = self.key
    if not b then return end
    local key = H.KeyText()
    b.text:SetText(key and ("[" .. key .. "]") or L["touche ?"])
    if key then b.text:SetTextColor(1, 0.82, 0) else b.text:SetTextColor(0.5, 0.5, 0.5) end
    b:SetWidth(b.text:GetStringWidth() + 6)
end

-- Appelé par UI:Build, une fois le titre et le compteur posés.
function H:Build(panel)
    self.check = groupCheck(panel)
    self.key = keyButton(panel)
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:SetScript("OnEvent", function() H:Refresh() end)
    self:Refresh()
end
