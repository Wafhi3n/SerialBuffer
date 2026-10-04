-- SerialBuffer_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non espagnol : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "esES" and locale ~= "esMX" then return end

local T = {
    ["chargé. Tape /%s pour l'aide."] = "cargado. Escribe /%s para ver la ayuda.",
    ["version %s"]                    = "versión %s",
    ["Commandes :"]                   = "Comandos:",
    ["affiche la version"]            = "muestra la versión",
}
for k, v in pairs(T) do NS.L[k] = v end
