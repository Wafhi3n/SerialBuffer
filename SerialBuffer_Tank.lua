-- SerialBuffer_Tank.lua — LES TANKS (D44) et les lignes des buffs courts sous l'en-tête (D44, D45, D47).
--
-- D44 (user, 2026-10-11, après un joueur sur Reddit : « I play a druid. It constantly wants to renew
-- my 10 minute thorns ») : Épines (Buffs.TANK_ONLY) ne va qu'aux TANKS. Un tank, c'est un membre du
-- groupe à qui le JEU donne le rôle Tank, ou la marque main tank du raid : « pas besoin de désigner le
-- tank, le jeu a déjà une feature pour désigner qui est tank, heal et dps » (user, même jour ; une
-- première version faisait désigner au clic droit ou par `/sbuff tank`, retirée avant d'être vue).
-- Le même joueur a répondu qu'Épines aux petits niveaux de passage aide beaucoup : la case « Épines à
-- tous » (db.tankAll), sur une ligne sous l'en-tête, la rouvre à tout le monde. La même ligne règle le
-- seuil des buffs courts (D45, db.refreshShort : SerialBuffer_Queue.lua).
-- D47 (user, 2026-10-11, avec le démoniste de D46 : « comme pour Épines, sur les buffs à durée
-- mineure, il faut que les gens puissent cocher pour opt-in, opt-out ») : CHAQUE buff court
-- (Buffs.SHORT_BUFFS) a sa case « à tous », décochée par défaut. Décochée, Épines va aux tanks, les
-- autres à toi et à ton groupe ; cochée (db.shortAll[id]), à tous ceux qui ne l'ont pas. Sur une
-- capture de la ligne d'Épines, le user : « pour le design, c'est pas mieux de mettre une icône au
-- lieu de XX for everyone ? ». D'où UNE ligne : « À tous : », puis case + icône par buff (le nom est
-- dans l'infobulle), le seuil à droite. Deux noms de sort, eux, ne tenaient pas dans 300 px.
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
    -- Vrai / faux, comme le code de Blizzard qui la lit (SecureGroupHeaders.lua) : un 1 compte aussi.
    return (ok2 and not sec(mt) and mt) and true or false
end

local function refresh()
    if NS.UI and NS.UI:IsVisible() and not InCombatLockdown() then NS.Run:Refresh() end
end

-- ---------------------------------------------------------------- la ligne sous l'en-tête

T.SHORT_MIN, T.SHORT_MAX = 1, 9   -- minutes (un buff court dure 10 min)
T.LINE_H, T.ICON = 18, 16

-- D47 : les buffs courts de la classe, dans l'ordre du catalogue ; une case chacun.
function T:LineIds(class)
    local out = {}
    for _, id in ipairs(NS.Buffs:Ids(class)) do
        if NS.Buffs.SHORT_BUFFS[id] then out[#out + 1] = id end
    end
    return out
end

-- Le premier buff court de la classe (celui de la ligne du seuil), ou nil : pas de ligne.
function T:HasLine(class) return self:LineIds(class)[1] end

-- La case « à tous » de ce buff : Épines garde db.tankAll (D44), les autres db.shortAll[id] (D47).
function T:IsAll(id)
    if NS.Buffs.TANK_ONLY[id] then return NS.db.tankAll == true end
    return type(NS.db.shortAll) == "table" and NS.db.shortAll[id] == true
end

function T:SetAll(id, on)
    if NS.Buffs.TANK_ONLY[id] then NS.db.tankAll = on and true or false return end
    if type(NS.db.shortAll) ~= "table" then NS.db.shortAll = {} end
    NS.db.shortAll[id] = on and true or nil
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

local function allTip(id, spell)
    if NS.Buffs.TANK_ONLY[id] then
        return string.format(L["Coché : %s va à tous ceux qui ne l'ont pas. Décoché : aux tanks de ton groupe seulement (rôle Tank, ou main tank du raid)."], spell)
    end
    return string.format(L["Coché : %s va à tous ceux qui ne l'ont pas. Décoché : à toi et à ton groupe seulement."], spell)
end

-- Une case et l'icône du sort juste après ; un clic sur l'icône coche aussi (zone de clic élargie), et
-- l'infobulle donne le nom du sort et la règle. Placée par BuildLine.
local function allCheck(panel, id)
    local spell = NS.Buffs.client.name(id) or "?"
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb.id = id
    cb.icon = cb:CreateTexture(nil, "ARTWORK")
    cb.icon:SetSize(T.ICON, T.ICON)
    cb.icon:SetPoint("LEFT", cb, "RIGHT", 1, 0)
    cb.icon:SetTexture(NS.Buffs.client.icon(id))
    cb:SetHitRectInsets(0, -(T.ICON + 2), 0, 0)
    cb:SetScript("OnClick", function(self) T:SetAll(id, self:GetChecked()); T:RefreshLine(); refresh() end)
    cb:SetScript("OnEnter", function(self)
        tooltip(self, string.format(L["%s à tous"], spell), allTip(id, spell))
        if (NS.Buffs.unstocked or {})[id] then   -- D48
            GameTooltip:AddLine(L["Composant manquant : ce buff n'est pas proposé tant que tu n'en as pas."], 1, 0.3, 0.3, true)
            GameTooltip:Show()
        end
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
-- « À tous : » une fois, puis case + icône pour chaque buff court, le seuil à droite.
function T:BuildLine(panel, y)
    local ids = self:LineIds(NS.Buffs.class)
    if not ids[1] then return 0 end
    local label = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", panel, "TOPLEFT", 8, -y - self.LINE_H / 2)
    label:SetText(L["À tous :"])
    self.checks = {}
    local anchor, gap = label, 2
    for i, id in ipairs(ids) do
        local cb = allCheck(panel, id)
        cb:SetPoint("LEFT", anchor, "RIGHT", gap, 0)
        self.checks[i], anchor, gap = cb, cb.icon, 8
    end
    self.short = shortButton(panel, y)
    self:RefreshLine()
    return self.LINE_H
end

-- Les coches et le seuil, relus de la base (à chaque rendu et après un geste). Une icône décochée est
-- grisée : en couleur, le buff va à tous. Rouge : son composant manque (D48, Buffs.unstocked).
function T:RefreshLine()
    local missing = NS.Buffs.unstocked or {}
    for _, cb in ipairs(self.checks or {}) do
        local on = self:IsAll(cb.id)
        cb:SetChecked(on)
        cb.icon:SetDesaturated(not on)
        if missing[cb.id] then cb.icon:SetVertexColor(1, 0.3, 0.3) else cb.icon:SetVertexColor(1, 1, 1) end
    end
    if self.short then self.short.text:SetText(string.format(L["courts : sous %d min"], NS.db.refreshShort or 2)) end
end
