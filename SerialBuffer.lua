-- SerialBuffer.lua — socle : table d'addon, réglages par défaut, SavedVariables, commande /sbuff.
--
-- Chargé APRÈS la locale, AVANT les modules. Les SavedVariables sont prêtes sur l'ADDON_LOADED de
-- CET addon ; les modules démarrent sur PLAYER_LOGIN, quand tous les fichiers du .toc sont chargés
-- (même découpage que LeyLines.lua).
local ADDON, NS = ...
local L = NS.L

NS.VERSION = "0.1.0"   -- = ## Version du .toc ; scripts\bump_version.ps1 -Addon SerialBuffer la tient égale
_G.SerialBuffer = NS

-- Réglages par défaut. CopyDefaults complète la base sans écraser ce que le joueur a changé ;
-- schemaVer sert le jour où une migration de la base devient nécessaire.
NS.DEFAULTS = {
    schemaVer = 1,
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
    if cmd == "version" then
        self:Printf(L["version %s"], self.VERSION)
    else
        self:Print(L["Commandes :"])
        self:Print("/sbuff version - " .. L["affiche la version"])
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
        CopyDefaults(SerialBufferDB, NS.DEFAULTS)
        NS.db = SerialBufferDB
    elseif event == "PLAYER_LOGIN" then
        NS:Printf(L["chargé. Tape /%s pour l'aide."], "sbuff")
    end
end)
