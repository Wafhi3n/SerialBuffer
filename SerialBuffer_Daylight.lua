-- SerialBuffer_Daylight.lua: an optional Daylight UI look for the Serial Buffer panel.
--
-- If Daylight UI isn't installed, this file does nothing. If it is, the panel, the bug report
-- window and the toasts get Daylight UI's frames, fonts, colors and icons. Players can turn this
-- off in Daylight UI under General > Plugins > "SerialBuffer".
--
-- It only uses Daylight UI's public API (DaylightUI/API.md, version 1.7 or later).
-- It never moves or resizes anything, and never touches the secure row buttons themselves:
-- only their text and icons are restyled.
local _, NS = ...
NS = NS or _G.SerialBuffer

local NEEDS_API_MINOR = 7    -- first Daylight UI API version with everything used below
local TITLE_SIZE = 13        -- panel title (its title bar is only 14 px high)
local WINDOW_TITLE_SIZE = 15 -- bug report window title
local ICON_SIZE = 14         -- gear and bug icons (on 16 px buttons)
local CHEVRON_SIZE = 10      -- fold chevron (on a 12 px button)
local CROP = { 0.08, 0.92, 0.08, 0.92 }   -- trims the border off spell icons

-- Daylight UI's chevron points down. Down = panel open, right = panel folded.
local CHEVRON_OPEN, CHEVRON_FOLDED = 0, math.pi / 2

local API, Kit          -- Daylight UI's API and skin kit, set once Daylight UI hands them over
local hoverIcons = {}   -- our header icons: tan normally, accent color on mouseover
local chosenReport      -- which bug report button is selected (bug, idea or site)
local broken = false    -- set after the first error, to switch the skin off

local function getDaylightAPI()
    local dui = _G.DaylightUI
    local api = type(dui) == "table" and dui.API
    if type(api) ~= "table" or api.major ~= 1 or (api.minor or 0) < NEEDS_API_MINOR then return nil end
    return api
end

-- Our hooks run inside Serial Buffer's own functions. If one of them errors, report it once and
-- stop skinning, so Serial Buffer keeps working normally.
local function guarded(fn)
    return function(...)
        if broken then return end
        local ok, err = pcall(fn, ...)
        if not ok then
            broken = true
            geterrorhandler()(err)
        end
    end
end

-- ---------------------------------------------------------------- text helpers

-- colorName is one of Daylight UI's text colors: "VALUE", "TEXT", "LABEL", "OFF", ...
local function setColor(fontString, colorName)
    local c = API.Colors()[colorName]
    if fontString and c then fontString:SetTextColor(c[1], c[2], c[3]) end
end

local function setAccentColor(fontString)
    if fontString then fontString:SetTextColor(API.Accent()) end
end

-- Daylight UI's font (size kept unless given), and optionally a text color.
local function setFont(fontString, size, colorName)
    if not fontString then return end
    Kit.Font(fontString, size)
    if colorName then setColor(fontString, colorName) end
end

-- ---------------------------------------------------------------- header icons

local function colorIcon(icon)
    if icon.button:IsMouseOver() then
        icon:SetVertexColor(API.Accent())
    else
        local c = API.Colors().LABEL
        icon:SetVertexColor(c[1], c[2], c[3])
    end
end

-- Replaces a button's art with one of Daylight UI's icons. The button keeps its size, clicks and
-- tooltip. API.Media points at the file inside Daylight UI's folder; nothing is copied.
local function useDaylightIcon(button, file, size)
    Kit.Strip(button)
    local icon = button:CreateTexture(nil, "OVERLAY")
    icon:SetSize(size, size)
    icon:SetPoint("CENTER")
    icon:SetTexture(API.Media(file))
    icon.button = button
    hoverIcons[#hoverIcons + 1] = icon
    button:HookScript("OnEnter", function() colorIcon(icon) end)
    button:HookScript("OnLeave", function() colorIcon(icon) end)
    colorIcon(icon)
    return icon
end

-- Serial Buffer puts its + / - art back on every fold, so hide it again and turn the chevron.
local function updateChevron()
    local fold = NS.UI.panel and NS.UI.panel.fold
    if not (fold and fold.chevron) then return end
    local art = fold:GetNormalTexture()
    if art then art:SetAlpha(0) end
    fold.chevron:SetRotation(NS.db.collapsed and CHEVRON_FOLDED or CHEVRON_OPEN)
end

-- ---------------------------------------------------------------- the panel

-- The "next buff" key: white when a key is bound, dimmed when not. Header:Refresh colors it
-- gold or gray each time, so this runs right after it.
local function colorKeyText()
    local key = NS.Header.key
    if key then setColor(key.text, NS.Header.KeyText() and "VALUE" or "OFF") end
end

local function skinHeader(panel)
    setFont(panel.title, TITLE_SIZE, "VALUE")
    setFont(panel.count)
    setAccentColor(panel.count)   -- buffs left to cast: the number that matters most
    panel.fold.chevron = useDaylightIcon(panel.fold, "ui-chevron.png", CHEVRON_SIZE)
    updateChevron()
    useDaylightIcon(panel.gear, "ui-options.png", ICON_SIZE)
    if panel.report then useDaylightIcon(panel.report, "ui-bug.png", ICON_SIZE) end

    local header = NS.Header
    if header.check then   -- "Group only" check box
        Kit.Check(header.check)
        setFont(header.check.label, nil, "TEXT")
    end
    if header.key then setFont(header.key.text) end
    colorKeyText()
end

-- The "For everyone:" line of short buffs under the header (only some classes have it).
local function skinShortBuffLine()
    local line = NS.Tank
    if not line then return end
    setFont(line.label, nil, "LABEL")
    for _, check in ipairs(line.checks or {}) do
        Kit.Check(check)
        if check.icon then check.icon:SetTexCoord(unpack(CROP)) end
    end
    if line.short then setFont(line.short.text, nil, "LABEL") end
end

-- The rows are secure buttons, so only their text and icons are restyled.
-- Serial Buffer resets each note to row.noteRGB when it fills a row, so that gets the new color.
local function skinRows()
    local label = API.Colors().LABEL
    for _, row in ipairs(NS.UI.rows) do
        setFont(row.name)
        setFont(row.note)
        row.noteRGB = { label[1], label[2], label[3] }
        row.icon:SetTexCoord(unpack(CROP))
    end
    for _, heading in ipairs(NS.UI.heads) do setFont(heading, nil, "LABEL") end
end

local function skinPanel()
    local panel = NS.UI.panel
    Kit.Window(panel)   -- Daylight UI's window background, with the accent line along the top
    skinHeader(panel)
    skinShortBuffLine()
    setFont(panel.msg, nil, "LABEL")
    skinRows()
    hooksecurefunc(NS.Header, "Refresh", guarded(colorKeyText))
    hooksecurefunc(NS.UI, "SetCollapsed", guarded(updateChevron))
    NS.Header:Refresh()   -- the new font changes text widths, so let the header re-measure
end

-- ---------------------------------------------------------------- the bug report window

-- Serial Buffer marks the chosen button with LockHighlight. Daylight UI's buttons have no
-- highlight art, so the chosen one gets accent-colored text instead.
local function highlightChoice(kind)
    local frame = NS.Report.frame
    if not frame then return end
    for k, button in pairs(frame.buttons) do
        local label = button:GetFontString()
        if k == kind then setAccentColor(label) else setColor(label, "TEXT") end
    end
    chosenReport = kind
end

local function skinReportWindow(frame)
    Kit.Window(frame)
    setFont(frame.title, WINDOW_TITLE_SIZE, "VALUE")
    setFont(frame.hint, nil, "TEXT")
    Kit.EditBox(frame.box)
    for _, child in ipairs({ frame:GetChildren() }) do
        if child:GetObjectType() == "Button" then Kit.Button(child) end
    end
end

-- ---------------------------------------------------------------- toasts

-- The game reuses toast frames, so each one is skinned the first time it shows.
local skinnedToasts = setmetatable({}, { __mode = "k" })

local function skinToast(toast)
    if skinnedToasts[toast] then return end
    skinnedToasts[toast] = true
    Kit.Strip(toast, { [toast.Icon] = true })   -- keep the icon
    API.Skin(toast, { window = true })
    setFont(toast.Title, nil, "LABEL")
    setFont(toast.Text, nil, "TEXT")
end

-- ---------------------------------------------------------------- start

local function applySkin()
    skinPanel()

    local report = NS.Report
    if report then
        if report.frame then skinReportWindow(report.frame) end   -- already built
        hooksecurefunc(report, "Build", guarded(function() skinReportWindow(report.frame) end))
        hooksecurefunc(report, "Show", guarded(function(_, kind) highlightChoice(kind) end))
    end

    if NS.Toast and type(_G.AlertFrame_ShowNewAlert) == "function" then
        hooksecurefunc("AlertFrame_ShowNewAlert", guarded(function(toast)
            -- only Serial Buffer's own toasts
            if type(toast) == "table" and NS.Toast.system and toast.queue == NS.Toast.system then
                skinToast(toast)
            end
        end))
    end
end

-- The player picked a new accent color in Daylight UI: redo everything drawn in it.
local function repaint()
    if not (Kit and NS.UI.panel) then return end
    setAccentColor(NS.UI.panel.count)
    for _, icon in ipairs(hoverIcons) do colorIcon(icon) end
    if NS.Report and NS.Report.frame then highlightChoice(chosenReport) end
end

-- Serial Buffer builds its panel at login (after the fight, if you log in during one). Waiting
-- for UI:Build means the panel always exists when we register. Daylight UI then runs the skin
-- outside of combat.
local registered = false
hooksecurefunc(NS.UI, "Build", function()
    if registered then return end
    registered = true
    API = getDaylightAPI()
    if not API then return end   -- no Daylight UI, or a version that's too old

    local plugin = API.For("SerialBuffer")
    plugin.RegisterSkin("SerialBuffer", function(kit)
        if not NS.UI.panel then return false end
        Kit = kit
        applySkin()
    end)
    plugin.On("StyleChanged", guarded(repaint))
end)
