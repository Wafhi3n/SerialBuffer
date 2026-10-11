-- SerialBuffer.lua — socle : table d'addon, réglages par défaut, SavedVariables, commande /sbuff.
--
-- Chargé APRÈS la locale, AVANT les modules. Les SavedVariables sont prêtes sur l'ADDON_LOADED de
-- CET addon ; les modules démarrent sur PLAYER_LOGIN, quand tous les fichiers du .toc sont chargés
-- (même découpage que LeyLines.lua).
local ADDON, NS = ...
local L = NS.L

NS.VERSION = "0.5.0"   -- = ## Version du .toc ; scripts\bump_version.ps1 -Addon SerialBuffer la tient égale
_G.SerialBuffer = NS

-- Réglages par défaut. CopyDefaults complète la base sans écraser ce que le joueur a changé ;
-- schemaVer sert le jour où une migration de la base devient nécessaire.
-- Que des RÉGLAGES (spec, Contrat) : jamais un nom de joueur ni un GUID, un secret sauvegardé
-- empoisonnerait la base.
NS.DEFAULTS = {
    schemaVer = 3,          -- 3 : la grille D34 remplace off, priority et classBuffs (Buffs:Migrate)
    shown = true,           -- le tableau (/sbuff)
    showPvP = false,        -- D5 : joueurs PvP cachés par défaut
    groupOnly = false,      -- D40 : coché, les joueurs autour sont ignorés (toi et ton groupe ou raid seuls)
    orders = {},            -- D34 : lanceur -> classe de la cible -> ids par rang (0 = vide) ; seuls les écarts au défaut
    groupPick = {},         -- D35 : lanceur -> classe de la cible -> id du choix unique pour le groupe (absent = vide)
    tooLow = {},            -- D38 : rang de sort lancé -> niveau max refusé « Target is too low level » (appris)
    coordWho = "none",      -- coordination C1 : qui peut régler ta ligne Groupe / raid (none / leader / anyone)
    refreshMin = 45,        -- D28 : hors paladin, un buff qui a moins de ces minutes se rafraîchit
    refreshShort = 2,       -- D45 : pareil pour un buff court (15 min ou moins : Épines, 10 min)
    tankAll = false,        -- D44 : coché, Épines (buff réservé aux tanks) va à tous ceux qui ne l'ont pas
    shortAll = {},          -- D47 : buff court coché « à tous » (id -> true) ; absent : toi et ton groupe
}

local function CopyDefaults(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            CopyDefaults(dst[k], v)
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
end

function NS:Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ccffSerial Buffer|r " .. tostring(msg))
end

function NS:Printf(fmt, ...)
    self:Print(string.format(fmt, ...))
end

-- Une commande à deux états ne change qu'avec on / off. Tapée seule (ou avec un autre mot), elle DIT
-- l'état et le mot qui le change, sans y toucher (règle du user du 2026-10-11, skill publique
-- `chat-output` : sur LeyLines, `/ley signal` tapé pour voir l'état le rallumait). `isOn` = l'état,
-- `set(bool)` le change, `on` / `off` = la ligne de chaque état.
local ON_OFF = { on = true, off = false }
function NS:TwoState(name, arg, isOn, set, on, off)
    local want = ON_OFF[arg]
    if want ~= nil and want ~= isOn then set(want); isOn = want end
    local line = isOn and on or off
    if want == nil then line = line .. " " .. string.format(L["(/sbuff %s %s pour changer)"], name, isOn and "off" or "on") end
    self:Print(line)
end

function NS:Slash(msg)
    local cmd, arg = (msg or ""):match("^%s*(%S*)%s*(%S*)")
    cmd, arg = (cmd or ""):lower(), (arg or ""):lower()
    if cmd == "" then
        if self.UI then self.UI:Toggle() end
    elseif cmd == "pvp" then
        self:TwoState("pvp", arg, self.db.showPvP == true, function(v) self.db.showPvP = v end,
            L["Joueurs PvP affichés."], L["Joueurs PvP cachés."])
    elseif cmd == "autour" or cmd == "around" then   -- D40 : « on » = les joueurs autour sont listés
        self:TwoState(cmd, arg, not self.db.groupOnly, function(v) self.Header:SetGroupOnly(not v) end,
            L["Joueurs autour listés."], L["Joueurs autour ignorés : seuls toi et ton groupe sont listés."])
    elseif cmd == "touche" or cmd == "key" then       -- D41
        local key = self.Header.KeyText()
        self:Print(key and string.format(L["Touche « buff suivant » : %s"], key) or L["Aucune touche pour « buff suivant »."])
        self.Header:OpenBindings()
    elseif cmd == "options" then
        if self.Options then self.Options:Open() end
    elseif cmd == "version" then
        self:Printf(L["version %s"], self.VERSION)
    elseif cmd == "groupe" or cmd == "group" then
        if self.Comm then self.Comm:PrintPeers() end
    elseif cmd == "bug" then
        if self.Report then self.Report:Open("bug") end
    elseif cmd == "idea" or cmd == "idee" or cmd == "idée" then
        if self.Report then self.Report:Open("idea") end
    else
        self:Print(L["Commandes :"])
        self:Print("/sbuff - " .. L["affiche ou cache le tableau"])
        self:Print("/sbuff pvp [on|off] - " .. L["montre ou cache les joueurs PvP"])
        self:Print("/sbuff autour [on|off] - " .. L["montre ou ignore les joueurs autour de toi (groupe seul)"])
        self:Print("/sbuff touche - " .. L["ta touche « buff suivant », et la page des raccourcis pour la changer"])
        self:Print("/sbuff options - " .. L["ouvre les options"])
        self:Print("/sbuff groupe - " .. L["liste les Serial Buffer de ton groupe"])
        self:Print("/sbuff version - " .. L["affiche la version"])
        self:Print("/sbuff bug - " .. L["signaler un bug ou proposer une idée (lien vers un ticket GitHub)"])
    end
end

SLASH_SERIALBUFFER1 = "/sbuff"
SlashCmdList["SERIALBUFFER"] = function(msg) NS:Slash(msg) end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" and arg1 == ADDON then
        SerialBufferDB = SerialBufferDB or {}
        CopyDefaults(SerialBufferDB, NS.DEFAULTS)   -- une base neuve naît en schemaVer 3 : rien à migrer
        NS.Buffs:Migrate(SerialBufferDB)
        NS.db = SerialBufferDB
    elseif event == "PLAYER_LOGIN" then
        -- Muet à la connexion, sauf la première après une installation ou une mise à jour (règle
        -- `chat-output` du 2026-10-11 ; jusqu'à la v0.4.1, « chargé » à chaque connexion). seenVersion
        -- vit dans la base du COMPTE : une ligne par compte, pas par perso.
        if NS.db.seenVersion ~= NS.VERSION then
            NS.db.seenVersion = NS.VERSION
            NS:Printf(L["version %s. Tape /%s aide pour l'aide."], NS.VERSION, "sbuff")
        end
        if NS.Toast then NS.Toast:Init() end
        NS.Run:Start()
    end
end)
