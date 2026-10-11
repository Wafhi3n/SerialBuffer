-- SerialBuffer_Tank.lua — LES TANKS (D44) et la ligne du druide sous l'en-tête (D44, D45).
--
-- D44 (user, 2026-10-11, après un joueur sur Reddit : « I play a druid. It constantly wants to renew
-- my 10 minute thorns ») : Épines (Buffs.TANK_ONLY) ne va qu'aux TANKS. Un tank, c'est un membre du
-- groupe à qui le JEU donne le rôle Tank, ou la marque main tank du raid : « pas besoin de désigner le
-- tank, le jeu a déjà une feature pour désigner qui est tank, heal et dps » (user, même jour ; une
-- première version faisait désigner au clic droit ou par `/sbuff tank`, retirée avant d'être vue).
-- Le même joueur a répondu qu'Épines aux petits niveaux de passage aide beaucoup : la case « Épines à
-- tous » (db.tankAll), sur une ligne sous l'en-tête, la rouvre à tout le monde. La même ligne règle le
-- seuil des buffs courts (D45, db.refreshShort : SerialBuffer_Queue.lua). Elle n'existe que pour une
-- classe qui a un buff réservé aux tanks (aujourd'hui le druide).
-- Le rôle et la marque main tank n'ont jamais été lus sur Forever : pcall, et une valeur secrète ou
-- illisible vaut « pas tank ».
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local T = {}
NS.Tank = T

local function sec(v) return issecretvalue ~= nil and issecretvalue(v) end

-- Ce joueur est-il un tank ? Seulement dans ton groupe : le rôle n'existe que là.
function T:Is(unit, group)
    if not group then return false end
    local ok, role = pcall(UnitGroupRolesAssigned, unit)
    if ok and not sec(role) and role == "TANK" then return true end
    local ok2, mt = pcall(GetPartyAssignment, "MAINTANK", unit)
    return ok2 and not sec(mt) and mt == true
end

local function refresh()
    if NS.UI and NS.UI:IsVisible() and not InCombatLockdown() then NS.Run:Refresh() end
end

-- ---------------------------------------------------------------- la ligne sous l'en-tête

T.SHORT_MIN, T.SHORT_MAX = 1, 9   -- minutes (un buff court dure 10 min)

function T:HasLine(class)
    for _, id in ipairs(NS.Buffs:Ids(class)) do
        if NS.Buffs.TANK_ONLY[id] then return id end
    end
    return nil
end

local function tooltip(owner, title, line)
    GameTooltip:SetOwner(owner, "ANCHOR_LEFT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(line, 1, 1, 1, true)
    GameTooltip:Show()
end

function T:StepShort(delta)
    local v = (NS.db.refreshShort or 2) + delta
    NS.db.refreshShort = math.max(self.SHORT_MIN, math.min(self.SHORT_MAX, v))
    self:RefreshLine()
    if NS.Options and NS.Options.built and not InCombatLockdown() then NS.Options:Refresh() end
    refresh()
end

local function allCheck(panel, y, spell)
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("TOPLEFT", 6, -y)
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 1, 0)
    cb.label:SetText(string.format(L["%s à tous"], spell))
    cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 2), 0, 0)
    cb:SetScript("OnClick", function(self) NS.db.tankAll = self:GetChecked() and true or false; refresh() end)
    cb:SetScript("OnEnter", function(self)
        tooltip(self, string.format(L["%s à tous"], spell), string.format(L["Coché : %s va à tous ceux qui ne l'ont pas. Décoché : aux tanks de ton groupe seulement (rôle Tank, ou main tank du raid)."], spell))
    end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cb
end

local function shortButton(panel, y)
    local b = CreateFrame("Button", nil, panel)
    b:SetSize(120, 16)
    b:SetPoint("TOPRIGHT", -8, -y - 1)
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    b.text:SetPoint("RIGHT")
    local hl = b:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.12)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", function(_, button) T:StepShort(button == "RightButton" and -1 or 1) end)
    b:EnableMouseWheel(true)
    b:SetScript("OnMouseWheel", function(_, delta) T:StepShort(delta > 0 and 1 or -1) end)
    b:SetScript("OnEnter", function(self)
        tooltip(self, L["Buffs courts"], string.format(L["Un buff de 10 min est reproposé quand il lui reste moins de %d min. Clic, clic droit ou molette : changer."], NS.db.refreshShort or 2))
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return b
end

-- Appelé par UI:Build sous le titre (y = haut de la ligne). Rend la hauteur prise (0 : pas de ligne).
function T:BuildLine(panel, y)
    local id = self:HasLine(NS.Buffs.class)
    if not id then return 0 end
    local spell = NS.Buffs.client.name(id) or "?"
    self.check, self.short = allCheck(panel, y, spell), shortButton(panel, y)
    self:RefreshLine()
    return 18
end

-- La coche et le seuil, relus de la base (à chaque rendu et après un geste).
function T:RefreshLine()
    if self.check then self.check:SetChecked(NS.db.tankAll and true or false) end
    if self.short then self.short.text:SetText(string.format(L["courts : sous %d min"], NS.db.refreshShort or 2)) end
end
