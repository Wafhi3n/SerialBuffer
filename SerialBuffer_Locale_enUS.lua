-- SerialBuffer_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non anglais : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "enUS" and locale ~= "enGB" then return end

local T = {
    ["chargé. Tape /%s pour l'aide."] = "loaded. Type /%s for help.",
    ["version %s"]                    = "version %s",
    ["Commandes :"]                   = "Commands:",
    ["affiche la version"]            = "shows the version",
}
for k, v in pairs(T) do NS.L[k] = v end
