-- SerialBuffer.lua — socle : table d'addon, réglages par défaut, SavedVariables, commande /sbuff.
--
-- Chargé APRÈS la locale, AVANT les modules. Les SavedVariables sont prêtes sur l'ADDON_LOADED de
-- CET addon ; les modules démarrent sur PLAYER_LOGIN, quand tous les fichiers du .toc sont chargés
-- (même découpage que LeyLines.lua).
local ADDON, NS = ...
local L = NS.L

NS.VERSION = "0.3.2-beta"   -- = ## Version du .toc ; scripts\bump_version.ps1 -Addon SerialBuffer la tient égale
_G.SerialBuffer = NS

-- Réglages par défaut. CopyDefaults complète la base sans écraser ce que le joueur a changé ;
-- schemaVer sert le jour où une migration de la base devient nécessaire.
-- Que des RÉGLAGES (spec, Contrat) : jamais un nom de joueur ni un GUID, un secret sauvegardé
-- empoisonnerait la base.
NS.DEFAULTS = {
    schemaVer = 3,          -- 3 : la grille D34 remplace off, priority et classBuffs (Buffs:Migrate)
    shown = true,           -- le tableau (/sbuff)
    showPvP = false,        -- D5 : joueurs PvP cachés par défaut
    orders = {},            -- D34 : lanceur -> classe de la cible -> ids par rang (0 = vide) ; seuls les écarts au défaut
    groupPick = {},         -- D35 : lanceur -> classe de la cible -> id du choix unique pour le groupe (absent = vide)
    tooLow = {},            -- D38 : rang de sort lancé -> niveau max refusé « Target is too low level » (appris)
    refreshMin = 45,        -- D28 : hors paladin, un buff qui a moins de ces minutes se rafraîchit
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

function NS:Slash(msg)
    local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
    if cmd == "" then
        if self.UI then self.UI:Toggle() end
    elseif cmd == "pvp" then
        self.db.showPvP = not self.db.showPvP
        self:Print(self.db.showPvP and L["Joueurs PvP affichés."] or L["Joueurs PvP cachés."])
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
        self:Print("/sbuff pvp - " .. L["montre ou cache les joueurs PvP"])
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
        NS:Printf(L["chargé. Tape /%s aide pour l'aide."], "sbuff")
        NS.Run:Start()
    end
end)
