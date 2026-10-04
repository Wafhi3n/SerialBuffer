-- SerialBuffer_UI.lua — LE TABLEAU SUR LE CÔTÉ (D10) : une ligne par joueur à buffer, en ordre FIFO.
--
-- Palier (a) : le tableau se lit, il ne se clique pas encore (palier b : boutons macro au nom).
-- Deux cadres, pour que le palier (b) n'ait rien à défaire :
--   - le PILOTE, enfant de UIParent : sa visibilité suit un pilote d'état sécurisé, « [combat] hide »
--     (D12). Un Hide() lancé depuis un événement de combat serait refusé dès qu'il portera des
--     boutons sécurisés ; le pilote d'état, lui, passe ;
--   - le PANNEAU, enfant du pilote : /sbuff l'affiche ou le cache, hors combat seulement.
-- Le tableau ne lit QUE ce que SerialBuffer_Run.lua lui passe (rows, état) : jamais le client.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local UI = { rows = {} }
NS.UI = UI

local WIDTH, ROW_H, MAX_ROWS, PAD = 270, 18, 16, 8
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

local function savePosition(panel)
    local point, _, relPoint, x, y = panel:GetPoint(1)
    NS.db.pos = { point = point, relPoint = relPoint, x = x, y = y }
end

local function buildRow(panel, i)
    local row = CreateFrame("Frame", nil, panel)
    row:SetSize(WIDTH - 2 * PAD, ROW_H)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD, -(PAD + 20 + (i - 1) * ROW_H))
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(ROW_H - 2, ROW_H - 2)
    row.icon:SetPoint("LEFT")
    row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
    row.name:SetJustifyH("LEFT")
    row.note = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.note:SetPoint("RIGHT")
    row.note:SetJustifyH("RIGHT")
    row:Hide()
    return row
end

function UI:Build()
    if self.panel then return end
    local driver = CreateFrame("Frame", "SerialBufferDriver", UIParent)
    driver:SetAllPoints(UIParent)
    RegisterStateDriver(driver, "visibility", NS.db.keepInCombat and "show" or "[combat] hide; show")
    local panel = CreateFrame("Frame", "SerialBufferPanel", driver, "BackdropTemplate")
    panel:SetSize(WIDTH, 60)
    panel:SetBackdrop(BACKDROP)
    panel:SetBackdropColor(0, 0, 0, 0.8)
    local p = NS.db.pos
    if p then panel:SetPoint(p.point, UIParent, p.relPoint, p.x, p.y)
    else panel:SetPoint("RIGHT", UIParent, "RIGHT", -40, 60) end
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", function(f) f:StopMovingOrSizing(); savePosition(f) end)
    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.title:SetPoint("TOPLEFT", PAD, -PAD)
    panel.title:SetText("Serial Buffer")
    panel.count = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.count:SetPoint("TOPRIGHT", -PAD, -PAD - 2)
    panel.msg = panel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    panel.msg:SetWidth(WIDTH - 2 * PAD)
    panel.msg:SetJustifyH("LEFT")
    for i = 1, MAX_ROWS do self.rows[i] = buildRow(panel, i) end
    self.driver, self.panel = driver, panel
    panel:SetShown(NS.db.shown)
end

function UI:IsVisible()
    return self.panel ~= nil and self.panel:IsVisible()
end

-- /sbuff : afficher ou cacher. Jamais en combat (le palier b y mettra des boutons sécurisés).
function UI:Toggle()
    if not self.panel then return end
    if InCombatLockdown() then NS:Print(L["Pas pendant un combat."]) return end
    NS.db.shown = not self.panel:IsShown()
    self.panel:SetShown(NS.db.shown)
end

local function fillRow(row, r)
    row.icon:SetTexture(r.buff.icon)
    row.name:SetText(r.name)
    row.name:SetTextColor(classColor(r.class))
    local notes = {}
    if r.pvp then notes[#notes + 1] = L["PvP"] end
    if r.outOfRange then notes[#notes + 1] = L["hors de portée"] end
    notes[#notes + 1] = r.buff.name
    row.note:SetText(table.concat(notes, " · "))
    row:SetAlpha(r.outOfRange and 0.5 or 1)
    row:Show()
end

-- Clés écrites en toutes lettres : la porte de localisation ne voit pas un L[variable].
local function stateMessage(state)
    if state == "instance" then return L["En instance : la tournée est en pause."] end
    if state == "nobuffs" then return L["Ta classe n'a pas de buff à poser sur les autres."] end
    if state == "noplates" then return L["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."] end
    return nil
end

-- Le message du pied : l'état d'abord, sinon pourquoi la liste est vide (spec, « Liste vide »).
local function footer(rows, state, around)
    local m = stateMessage(state)
    if m then return m end
    if #rows > MAX_ROWS then return string.format(L["+%d autres"], #rows - MAX_ROWS) end
    if #rows > 0 then return nil end
    if around == 0 then return L["Personne à buffer autour de toi."] end
    return L["Tournée finie !"]
end

function UI:Render(rows, state, around)
    if not self.panel then return end
    local shown = math.min(#rows, MAX_ROWS)
    for i = 1, MAX_ROWS do
        if i <= shown then fillRow(self.rows[i], rows[i]) else self.rows[i]:Hide() end
    end
    self.panel.count:SetText(string.format(L["%d à buffer"], #rows))
    local msg = footer(rows, state, around)
    self.panel.msg:ClearAllPoints()
    self.panel.msg:SetPoint("TOPLEFT", PAD, -(PAD + 22 + shown * ROW_H))
    self.panel.msg:SetText(msg or "")
    local msgH = msg and (self.panel.msg:GetStringHeight() + 4) or 0
    self.panel:SetHeight(PAD * 2 + 22 + shown * ROW_H + msgH)
end
