-- SerialBuffer_Locale_deDE.lua — overlay ALLEMAND. Clé FR → texte DE.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non allemand : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

if (GetLocale and GetLocale() or "enUS") ~= "deDE" then return end

local T = {
    ["chargé. Tape /%s pour l'aide."] = "geladen. Gib /%s für die Hilfe ein.",
    ["version %s"]                    = "Version %s",
    ["Commandes :"]                   = "Befehle:",
    ["affiche la version"]            = "zeigt die Version",
}
for k, v in pairs(T) do NS.L[k] = v end
