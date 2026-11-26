-- SerialBuffer_Daylight.lua — the panel in the Daylight UI look, when Daylight UI is installed.
--
-- Built only on Daylight UI's public API (DaylightUI/API.md, version 1.7 or later):
-- me.RegisterSkin hands over Daylight UI's Kit once Serial Buffer has loaded, and Daylight UI runs
-- it out of combat. Without Daylight UI, or with its window skins turned off, nothing here runs.
-- Daylight UI lists "SerialBuffer" under General > Plugins, with a switch to turn the skin off.
--
-- What changes: the panel's background and border, fonts and text colors, the header's icons, the
-- check boxes (Daylight UI's switches), the bug report window and the toasts.
-- What stays: every size, position and anchor (UI:Layout and Header:Room keep their numbers), the
-- secure rows themselves (only their font strings and icons are touched, never the buttons), the
-- class colors of the names and the colors that carry meaning (out of range, buffed, expired).
local _, NS = ...
NS = NS or _G.SerialBuffer

local Skin = {}
NS.Daylight = Skin

local MIN_MINOR = 7     -- API.Media, API.Colors and the Kit calls used here
local TITLE_SIZE = 13   -- Daylight UI's "body" size: the panel's title bar is only 14 px high
local HEAD_SIZE = 15    -- "head": the bug report window's title
local ICON = 14         -- the header's icons (gear, bug), on 16 px buttons
local CHEVRON = 10      -- the fold button's chevron, on a 12 px button
local CROP = { 0.08, 0.92, 0.08, 0.92 }   -- spell icons without the game's rim
-- Daylight UI's chevron points down: down = unfolded, right = folded to the title bar.
local OPEN, FOLDED = 0, math.pi / 2

local API, Kit
local icons = {}        -- [texture] = its button: tan at rest, the accent under the mouse
local broken = false

-- Daylight UI's API, if it's there and recent enough.
local function daylight()
    local dui = _G.DaylightUI
    local api = type(dui) == "table" and dui.API
    if type(api) ~= "table" or api.major ~= 1 or (api.minor or 0) < MIN_MINOR then return nil end
    return api
end

-- Hooks on Serial Buffer's own functions run in its code paths: an error in the skin is reported
-- once, then the skin stops, and Serial Buffer goes on as if it weren't there.
local function safe(fn)
    return function(...)
        if broken then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            broken = true
            geterrorhandler()(err)
        end
    end
end

local function ink(fs, key)
    local c = API.Colors()[key]
    if fs and c then fs:SetTextColor(c[1], c[2], c[3]) end
end

local function accent(fs)
    if fs then fs:SetTextColor(API.Accent()) end
end

-- The Daylight UI font on a font string, its size kept unless given, then its color.
local function text(fs, size, key)
    if not fs then return end
    Kit.Font(fs, size)
    if key then ink(fs, key) end
end

-- ---------------------------------------------------------------- icon buttons

local function paintIcon(t)
    local b = icons[t]
    if b and b:IsMouseOver() then
        t:SetVertexColor(API.Accent())
    else
        local c = API.Colors().LABEL
        t:SetVertexColor(c[1], c[2], c[3])
    end
end

-- A header button drawn as one of Daylight UI's icons (a file in its Media folder, used where it
-- is): the game's art hidden, the icon tan at rest and in the accent under the mouse. The button
-- keeps its size, its clicks and its tooltip.
local function iconButton(b, file, size)
    Kit.Strip(b)
    local t = b:CreateTexture(nil, "OVERLAY")
    t:SetSize(size, size)
    t:SetPoint("CENTER")
    t:SetTexture(API.Media(file))
    icons[t] = b
    b:HookScript("OnEnter", function() paintIcon(t) end)
    b:HookScript("OnLeave", function() paintIcon(t) end)
    paintIcon(t)
    return t
end

-- The fold button (D53): a chevron, down while the panel is open, right while it's folded.
-- paintFold sets the game's + / − art again on every toggle, so it's hidden again here.
local function paintFold()
    local b = NS.UI.panel and NS.UI.panel.fold
    if not (b and b.chevron) then return end
    local art = b:GetNormalTexture()
    if art then art:SetAlpha(0) end
    b.chevron:SetRotation(NS.db.collapsed and FOLDED or OPEN)
end

-- ---------------------------------------------------------------- the panel

-- "[F]" in white when a key is bound, "key?" dimmed when none is: Header:Refresh paints it gold
-- or gray each time, so this runs after it.
local function paintKey()
    local b = NS.Header.key
    if not b then return end
    ink(b.text, NS.Header.KeyText() and "VALUE" or "OFF")
end

local function header(panel)
    text(panel.title, TITLE_SIZE, "VALUE")
    text(panel.count)
    accent(panel.count)   -- how many are left to buff: the one number the panel is there for
    panel.fold.chevron = iconButton(panel.fold, "ui-chevron.png", CHEVRON)
    paintFold()
    iconButton(panel.gear, "ui-options.png", ICON)
    if panel.report then iconButton(panel.report, "ui-bug.png", ICON) end
    local H = NS.Header
    if H.check then
        Kit.Check(H.check)
        text(H.check.label, nil, "TEXT")
    end
    if H.key then text(H.key.text) end
    paintKey()
end

-- The short buffs' line under the header (D44, D45, D47). Only for classes that have one.
local function tankLine()
    local T = NS.Tank
    if not T then return end
    text(T.label, nil, "LABEL")
    for _, cb in ipairs(T.checks or {}) do
        Kit.Check(cb)
        if cb.icon then cb.icon:SetTexCoord(CROP[1], CROP[2], CROP[3], CROP[4]) end
    end
    if T.short then text(T.short.text, nil, "LABEL") end
end

-- The rows are secure buttons: only their font strings and icon change, never the button.
-- fillRow sets the note back to row.noteRGB on every fill, so that becomes Daylight UI's label tan.
local function rows(UI)
    local label = API.Colors().LABEL
    for _, row in ipairs(UI.rows) do
        text(row.name)
        text(row.note)
        row.noteRGB = { label[1], label[2], label[3] }
        row.icon:SetTexCoord(CROP[1], CROP[2], CROP[3], CROP[4])
    end
    for _, head in ipairs(UI.heads) do text(head, nil, "LABEL") end
end

function Skin.Panel()
    local UI = NS.UI
    local panel = UI.panel
    -- Strips the tooltip backdrop and puts Daylight UI's window shell behind the panel, with the
    -- accent line along its top. The title isn't one Kit.Window knows, so it isn't moved.
    Kit.Window(panel)
    header(panel)
    tankLine()
    text(panel.msg, nil, "LABEL")
    rows(UI)
    hooksecurefunc(NS.Header, "Refresh", safe(paintKey))
    hooksecurefunc(UI, "SetCollapsed", safe(paintFold))
    NS.Header:Refresh()   -- the key's room again, now that the title and count are in the new font
end

-- ---------------------------------------------------------------- the bug report window

-- The chosen button (Bug, Idea, No GitHub account) stays lit with LockHighlight. Daylight UI's
-- buttons have no highlight art, so the chosen one gets its words in the accent instead.
local function paintChoice(kind)
    local f = NS.Report.frame
    if not f then return end
    for k, b in pairs(f.buttons) do
        local fs = b:GetFontString()
        if k == kind then accent(fs) else ink(fs, "TEXT") end
    end
    Skin.choice = kind
end

function Skin.Report(f)
    Kit.Window(f)   -- its background and the link box's go with the game's art
    text(f.title, HEAD_SIZE, "VALUE")
    text(f.hint, nil, "TEXT")
    Kit.EditBox(f.box)
    for _, child in ipairs({ f:GetChildren() }) do
        if child:GetObjectType() == "Button" then Kit.Button(child) end
    end
end

-- ---------------------------------------------------------------- the toasts

-- The game reuses its toast frames: each one is dressed the first time it shows.
local toasts = setmetatable({}, { __mode = "k" })
local function dressToast(f)
    if toasts[f] then return end
    toasts[f] = true
    Kit.Strip(f, { [f.Icon] = true })
    API.Skin(f, { window = true })
    text(f.Title, nil, "LABEL")
    text(f.Text, nil, "TEXT")
end

-- ---------------------------------------------------------------- start

function Skin.Apply()
    Skin.Panel()
    local R = NS.Report
    if R then
        if R.frame then Skin.Report(R.frame) end
        hooksecurefunc(R, "Build", safe(function() Skin.Report(R.frame) end))
        hooksecurefunc(R, "Show", safe(function(_, kind) paintChoice(kind) end))
    end
    if NS.Toast and type(_G.AlertFrame_ShowNewAlert) == "function" then
        hooksecurefunc("AlertFrame_ShowNewAlert", safe(function(f)
            if type(f) == "table" and NS.Toast.system and f.queue == NS.Toast.system then dressToast(f) end
        end))
    end
end

-- The player changed Daylight UI's accent: repaint what's drawn in it.
function Skin.Repaint()
    if not (Kit and NS.UI.panel) then return end
    accent(NS.UI.panel.count)
    for t in pairs(icons) do paintIcon(t) end
    if NS.Report and NS.Report.frame then paintChoice(Skin.choice) end
end

-- Registered once the panel exists: UI:Build runs on PLAYER_LOGIN, after a fight when the player
-- logs in or reloads in one (Run:Start). Daylight UI then runs the skin out of combat.
local registered = false
hooksecurefunc(NS.UI, "Build", function()
    if registered then return end
    registered = true
    API = daylight()
    if not API then return end
    local me = API.For("SerialBuffer")
    me.RegisterSkin("SerialBuffer", function(kit)
        if not NS.UI.panel then return false end
        Kit = kit
        Skin.Apply()
    end)
    me.On("StyleChanged", safe(function() Skin.Repaint() end))
end)
