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

-- La touche brute (« SHIFT-MOUSEWHEELUP »), ou nil.
local function rawKey()
    local ok, key = pcall(GetBindingKey, action())
    if not ok or type(key) ~= "string" or key == "" then return nil end
    return key
end

-- Le nom d'une touche, abrégé comme sur les barres d'action. pcall : jamais éprouvé sur Forever.
local function bindingText(key)
    local ok, text = pcall(GetBindingText, key, 1)   -- comme ActionButton.lua (Forever 70205)
    if ok and type(text) == "string" and text ~= "" then return text end
    return key
end

-- La touche en toutes lettres (l'infobulle), ou nil.
function H.KeyText()
    local key = rawKey()
    return key and bindingText(key)
end

-- La touche pour l'en-tête. L'abréviation du jeu laisse la souris en toutes lettres (« Mouse Wheel
-- Up », vu par le user le 2026-10-11 : elle couvrait la case « Groupe seul ») : la molette et les
-- boutons de la souris prennent un code court, comme dans les addons de barres d'action ; les
-- modificateurs (« s- ») restent ceux du jeu. Hors souris, le texte du jeu tel quel.
function H.ShortKey(key)
    local text = bindingText(key)
    local base = key:match("([^%-]+)$") or key
    local short = (base == "MOUSEWHEELUP" and L["MH"]) or (base == "MOUSEWHEELDOWN" and L["MB"])
    local button = base:match("^BUTTON(%d+)$")
    if button then short = string.format(L["S%d"], tonumber(button)) end
    if not short then return text end
    local long = bindingText(base)
    if #long < #text and text:sub(-#long) == long then return text:sub(1, #text - #long) .. short end
    if long == text then return short end
    return text
end

-- La place de la touche (le bouton entier), entre le libellé de la case et le compteur. CALCULÉE
-- d'après les ancres, pas lue à l'écran : GetLeft/GetRight rendent nil tant que le tableau est
-- caché. Les écarts viennent des ancres elles-mêmes (le titre et le rouage : SerialBuffer_UI.lua ;
-- le scarabée : SerialBuffer_Report.lua), donc un déplacement de l'un d'eux est suivi.
local GAP = 6   -- entre la touche et ses voisins (son ancre sur le compteur, keyButton)

local function offsetX(region)
    local _, _, _, x = region:GetPoint(1)
    return x or 0
end

function H:Room()
    local p, cb = self.panel, self.check
    local left = offsetX(p.title) + p.title:GetStringWidth() + offsetX(cb) + cb:GetWidth()
        + offsetX(cb.label) + cb.label:GetStringWidth()
    local right = p.count:GetStringWidth() - offsetX(p.count) + p.gear:GetWidth() - offsetX(p.gear)
    if p.report then right = right + p.report:GetWidth() - offsetX(p.report) end
    return p:GetWidth() - left - right - 2 * GAP
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
-- recalcule rien (la touche « buff suivant » reste vide, SerialBuffer_UI.lua). Les options ne se
-- touchent pas en combat : leur cadre vit dans le panneau de Blizzard (protégé une fois accroché,
-- skill wow-forever-api) ; leur OnShow les remet de toute façon à l'état de la base.
function H:SetGroupOnly(on)
    NS.db.groupOnly = on and true or false
    self:Refresh()
    if NS.Options.built and not InCombatLockdown() then NS.Options:Refresh() end
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
    b:SetPoint("RIGHT", panel.count, "LEFT", -GAP, 0)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("CENTER")
    b.text:SetWordWrap(false)   -- trop large pour sa place : coupée par « … », pas sur deux lignes
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

-- La coche et la touche, relues de la base et du client : à chaque rendu (hors combat, APRÈS le
-- compteur, dont la largeur compte), sur UPDATE_BINDINGS et après une bascule. Trop large pour sa
-- place, la touche est coupée ; l'infobulle la donne en entier.
function H:Refresh()
    if self.check then self.check:SetChecked(NS.db.groupOnly and true or false) end
    local b = self.key
    if not b then return end
    local key = rawKey()
    b.text:SetWidth(0)   -- 0 : la largeur suit le texte, pour le mesurer
    b.text:SetText(key and ("[" .. H.ShortKey(key) .. "]") or L["touche ?"])
    if key then b.text:SetTextColor(1, 0.82, 0) else b.text:SetTextColor(0.5, 0.5, 0.5) end
    local w, room = b.text:GetStringWidth() + 6, self:Room()
    if w > room then
        w = math.max(room, 12)
        b.text:SetWidth(w - 6)
    end
    b:SetWidth(w)
end

-- Appelé par UI:Build, une fois le titre et le compteur posés.
function H:Build(panel)
    self.panel = panel
    self.check = groupCheck(panel)
    self.key = keyButton(panel)
    local f = CreateFrame("Frame")
    f:RegisterEvent("UPDATE_BINDINGS")
    f:SetScript("OnEvent", function() H:Refresh() end)
    self:Refresh()
end
