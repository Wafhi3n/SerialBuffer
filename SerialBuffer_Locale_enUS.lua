-- SerialBuffer_Locale_enUS.lua — overlay ANGLAIS (enUS/enGB). Clé FR → texte EN.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non anglais : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "enUS" and locale ~= "enGB" then return end

local T = {
    ["chargé. Tape /%s aide pour l'aide."]                                          = "loaded. Type /%s help for help.",
    ["version %s"]                                                                  = "version %s",
    ["Commandes :"]                                                                 = "Commands:",
    ["affiche la version"]                                                          = "shows the version",
    ["affiche ou cache le tableau"]                                                 = "shows or hides the panel",
    ["montre ou cache les joueurs PvP"]                                             = "shows or hides PvP-flagged players",
    ["Joueurs PvP affichés."]                                                       = "PvP-flagged players shown.",
    ["Joueurs PvP cachés."]                                                         = "PvP-flagged players hidden.",
    ["Pas pendant un combat."]                                                      = "Not during combat.",
    ["PvP"]                                                                         = "PvP",
    ["hors de portée"]                                                              = "out of range",
    ["En instance : la tournée est en pause."]                                      = "In an instance: the round is paused.",
    ["Ta classe n'a pas de buff à poser sur les autres."]                           = "Your class has no buff to cast on others.",
    ["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."]        = "Friendly player nameplates are off: only you and your group are seen.",
    ["+%d autres"]                                                                  = "+%d more",
    ["Personne à buffer autour de toi."]                                            = "Nobody around you needs a buff.",
    ["Tournée finie !"]                                                             = "Round done!",
    ["%d à buffer"]                                                                 = "%d to buff",
    ["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."]  = "None of your buffs was recognized (ids: %s). Please tell the addon author.",
}
for k, v in pairs(T) do NS.L[k] = v end
