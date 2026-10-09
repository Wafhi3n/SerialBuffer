-- SerialBuffer_Report.lua — « Signaler » : un bug ou une idée, en ticket sur le dépôt GitHub.
--
-- Un addon n'ouvre pas de navigateur : la fenêtre donne un LIEN déjà sélectionné, que le joueur copie
-- (Ctrl+C) et colle dans son navigateur, où le formulaire arrive pré-rempli. Montage de
-- `/ley contribute` (LeyLines_Share.lua), vu en jeu le 2026-09-28.
-- Formulaires : .github/ISSUE_TEMPLATE/bug.yml et suggestion.yml. DEUX formulaires et pas un seul
-- avec une liste « type » : une liste déroulante passée dans le lien ne se pré-remplit pas (mesuré
-- le 2026-09-28) ; seules les zones de texte le font, d'où le champ `env`. Il porte la version de
-- l'addon et du jeu, la langue — JAMAIS le nom du personnage, son royaume ou sa guilde : le ticket
-- est public. Sans compte GitHub, le troisième choix donne la page CurseForge.
-- Entrées : `/sbuff bug`, et le bouton du panneau d'options (SerialBuffer_Options.lua). La fenêtre
-- est en strate DIALOG : au-dessus du panneau d'options du jeu (HIGH, Blizzard_SettingsPanel.xml).
-- Spec : docs/specs/signaler.md (dépôt de l'outillage). Pur et testable : Env, URL (test_signaler).
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local Report = {}
NS.Report = Report

local ADDON = "SerialBuffer"
local NAME  = "Serial Buffer"
local REPO  = "https://github.com/Wafhi3n/SerialBuffer/issues/new?template="
Report.LINKS = {
    bug  = REPO .. "bug.yml",
    idea = REPO .. "suggestion.yml",
    site = "https://www.curseforge.com/wow/addons/serial-buffer",
}

-- RFC 3986 « non réservé » seulement, le reste en %XX octet par octet (comme LeyLines_Share.lua).
local function PercentEncode(s)
    return (s:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- « Serial Buffer 0.3.1-beta | WoW 1.60.1 (70245) | frFR », plus la signature d'une copie du banc
-- (## X-Build, posée par deploy.ps1 ; une release n'en a jamais).
function Report.Env()
    local meta = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
    local version = meta and meta(ADDON, "Version")
    local build = meta and meta(ADDON, "X-Build")
    local wow, num
    if GetBuildInfo then wow, num = GetBuildInfo() end
    local env = string.format("%s %s | WoW %s (%s) | %s", NAME, version or "?", wow or "?", num or "?",
        GetLocale and GetLocale() or "?")
    if build and build ~= "" then env = env .. " | " .. build end
    return env
end

-- Le lien d'un choix : `bug` et `idea` portent l'environnement, `site` est la page CurseForge.
function Report.URL(kind)
    local base = Report.LINKS[kind]
    if not base or kind == "site" then return base end
    return base .. "&env=" .. PercentEncode(Report.Env())
end

local HINTS = {
    bug  = L["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."],
    idea = L["Copie ce lien (Ctrl+C) et ouvre-le dans ton navigateur : le formulaire arrive avec la version déjà remplie."],
    site = L["Pas de compte GitHub ? Copie ce lien (Ctrl+C) et laisse un commentaire sur la page CurseForge."],
}
-- Pas de bouton « Copier » : le jeu ne laisse pas un addon écrire dans le presse-papiers
-- (CopyToClipboard porte HasRestrictions dans la doc du client, comme les gestes de l'hôtel des
-- ventes). Le joueur fait Ctrl+C dans la zone, et on lui confirme que c'est fait.
local COPIED = "|cFF33DD88" .. L["Lien copié : colle-le (Ctrl+V) dans ton navigateur."] .. "|r"

-- La zone du lien : en lecture seule (une frappe remet le lien), tout sélectionné au focus.
local function buildBox(f)
    local bg = f:CreateTexture(nil, "ARTWORK")
    bg:SetPoint("TOPLEFT", 12, -64)
    bg:SetPoint("RIGHT", -12, 0)
    bg:SetHeight(24)
    bg:SetColorTexture(0.1, 0.1, 0.12, 1)
    local box = CreateFrame("EditBox", nil, f)
    box:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -4)
    box:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -6, 4)
    box:SetFontObject("ChatFontNormal")
    box:SetMaxLetters(0)
    box:SetAutoFocus(false)
    box:SetScript("OnEscapePressed", function(b) b:ClearFocus(); f:Hide() end)
    box:SetScript("OnEditFocusGained", function(b) b:HighlightText() end)
    box:SetScript("OnTextChanged", function(b, user)
        if user then b:SetText(b.link or ""); b:HighlightText() end
    end)
    -- Ctrl+C (Cmd+C sur Mac) dans la zone : le jeu copie le lien sélectionné, on le dit au joueur.
    box:SetScript("OnKeyDown", function(b, key)
        if key == "C" and b.link and b.link ~= "" and (IsControlKeyDown() or (IsMetaKeyDown and IsMetaKeyDown())) then
            f.hint:SetText(COPIED)
        end
    end)
    return box
end

local function button(f, label, w, onClick)
    local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetText(label)
    b:SetScript("OnClick", onClick)
    return b
end

local function buildButtons(f)
    f.buttons = {}
    local x = 12
    for _, def in ipairs({ { "bug", L["Bug"], 96 }, { "idea", L["Idée"], 96 },
                           { "site", L["Sans compte GitHub"], 150 } }) do
        local b = button(f, def[2], def[3], function() Report:Show(def[1]) end)
        b:SetPoint("BOTTOMLEFT", x, 12)
        f.buttons[def[1]] = b
        x = x + def[3] + 8
    end
    button(f, L["Fermer"], 90, function() f:Hide() end):SetPoint("BOTTOMRIGHT", -12, 12)
end

function Report:Build()
    -- Nom GLOBAL pour UISpecialFrames (Échap ferme) ; fille d'UIParent, jamais protégée.
    local f = CreateFrame("Frame", "SerialBufferReportFrame", UIParent)
    self.frame = f
    f:SetSize(480, 136)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(frame) frame:StartMoving() end)
    f:SetScript("OnDragStop", function(frame) frame:StopMovingOrSizing() end)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0, 0, 0, 0.85)
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.title:SetPoint("TOPLEFT", 12, -10)
    f.title:SetText(L["Signaler un bug ou proposer une idée"])
    f.hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.hint:SetPoint("TOPLEFT", 12, -30)
    f.hint:SetPoint("RIGHT", -12, 0)
    f.hint:SetJustifyH("LEFT")
    f.box = buildBox(f)
    buildButtons(f)
    tinsert(UISpecialFrames, "SerialBufferReportFrame")
    return f
end

-- Ouvre la fenêtre ; `kind` (facultatif) choisit tout de suite Bug, Idée ou la page CurseForge.
function Report:Open(kind)
    local f = self.frame or self:Build()
    f:Show()
    self:Show(kind)
end

-- Le bouton choisi reste enfoncé (LockHighlight), les autres se relâchent.
function Report:Show(kind)
    local f = self.frame
    for k, b in pairs(f.buttons) do
        if k == kind then b:LockHighlight() else b:UnlockHighlight() end
    end
    f.hint:SetText(HINTS[kind] or L["Un bug, ou une idée pour l'addon ? Choisis ci-dessous : l'addon te donne le lien du formulaire, déjà rempli."])
    f.box.link = kind and Report.URL(kind) or ""
    f.box:SetText(f.box.link)
    -- Curseur au DÉBUT : la zone montre « https://github.com/… », pas la fin du lien (vu le 2026-10-09).
    if kind then f.box:SetFocus(); f.box:SetCursorPosition(0); f.box:HighlightText() else f.box:ClearFocus() end
end
