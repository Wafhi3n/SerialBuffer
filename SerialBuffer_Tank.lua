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
-- (Buffs.SHORT_BUFFS) a sa ligne et sa case « à tous », décochée par défaut. Décochée, Épines va aux
-- tanks, les autres à toi et à ton groupe ; cochée (db.shortAll[id]), à tous ceux qui ne l'ont pas.
-- Une ligne par buff : deux noms de sort ne tiennent pas côte à côte dans 300 px. Le seuil est à
-- droite de la première.
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
T.LINE_H = 18

-- D47 : les buffs courts de la classe, dans l'ordre du catalogue ; une ligne chacun.
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

local function allCheck(panel, y, id)
    local spell = NS.Buffs.client.name(id) or "?"
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("TOPLEFT", 6, -y)
    cb.id = id
    cb.label = cb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cb.label:SetPoint("LEFT", cb, "RIGHT", 1, 0)
    cb.label:SetText(string.format(L["%s à tous"], spell))
    cb:SetHitRectInsets(0, -(cb.label:GetStringWidth() + 2), 0, 0)
    cb:SetScript("OnClick", function(self) T:SetAll(id, self:GetChecked()); refresh() end)
    cb:SetScript("OnEnter", function(self) tooltip(self, string.format(L["%s à tous"], spell), allTip(id, spell)) end)
    cb:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return cb
end

-- La case de la 1re ligne partage sa ligne avec le seuil : un nom de sort trop long est coupé (« … »)
-- avant le texte du seuil, au lieu de passer dessous ; l'infobulle garde le nom entier. Calculé sur
-- la géométrie posée ici (case à 6 px du bord, libellé 1 px après ses 18 px, seuil à 8 px du bord
-- droit) : le panneau n'est pas encore placé quand on le construit, GetLeft y rendrait nil.
local function fit(panel, cb, short)
    local room = panel:GetWidth() - 8 - short.text:GetStringWidth() - 6 - (6 + 18 + 1)
    if room <= 0 or cb.label:GetStringWidth() <= room then return end
    cb.label:SetWidth(room)
    cb.label:SetWordWrap(false)
    cb:SetHitRectInsets(0, -(room + 2), 0, 0)
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

-- Appelé par UI:Build sous le titre (y = haut de la 1re ligne). Rend la hauteur prise (0 : aucune).
function T:BuildLine(panel, y)
    local ids = self:LineIds(NS.Buffs.class)
    if not ids[1] then return 0 end
    self.checks = {}
    for i, id in ipairs(ids) do self.checks[i] = allCheck(panel, y + (i - 1) * self.LINE_H, id) end
    self.short = shortButton(panel, y)
    self:RefreshLine()
    fit(panel, self.checks[1], self.short)
    return self.LINE_H * #ids
end

-- Les coches et le seuil, relus de la base (à chaque rendu et après un geste).
function T:RefreshLine()
    for _, cb in ipairs(self.checks or {}) do cb:SetChecked(self:IsAll(cb.id)) end
    if self.short then self.short.text:SetText(string.format(L["courts : sous %d min"], NS.db.refreshShort or 2)) end
end
