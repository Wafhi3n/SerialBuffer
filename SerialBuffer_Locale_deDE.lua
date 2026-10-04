-- SerialBuffer_Locale_deDE.lua — overlay ALLEMAND. Clé FR → texte DE.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non allemand : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

if (GetLocale and GetLocale() or "enUS") ~= "deDE" then return end

local T = {
    ["chargé. Tape /%s aide pour l'aide."]                                          = "geladen. Gib /%s hilfe für die Hilfe ein.",
    ["version %s"]                                                                  = "Version %s",
    ["Commandes :"]                                                                 = "Befehle:",
    ["affiche la version"]                                                          = "zeigt die Version",
    ["affiche ou cache le tableau"]                                                 = "zeigt oder verbirgt die Tabelle",
    ["montre ou cache les joueurs PvP"]                                             = "zeigt oder verbirgt PvP-Spieler",
    ["Joueurs PvP affichés."]                                                       = "PvP-Spieler werden angezeigt.",
    ["Joueurs PvP cachés."]                                                         = "PvP-Spieler werden ausgeblendet.",
    ["Pas pendant un combat."]                                                      = "Nicht während eines Kampfes.",
    ["PvP"]                                                                         = "PvP",
    ["hors de portée"]                                                              = "außer Reichweite",
    ["En instance : la tournée est en pause."]                                      = "In einer Instanz: die Runde pausiert.",
    ["Ta classe n'a pas de buff à poser sur les autres."]                           = "Deine Klasse hat keinen Buff für andere.",
    ["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."]        = "Namensplaketten freundlicher Spieler sind aus: nur du und deine Gruppe werden gesehen.",
    ["+%d autres"]                                                                  = "+%d weitere",
    ["Personne à buffer autour de toi."]                                            = "Niemand in deiner Nähe braucht einen Buff.",
    ["Tournée finie !"]                                                             = "Runde fertig!",
    ["%d à buffer"]                                                                 = "%d zu buffen",
    ["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."]  = "Keiner deiner Buffs wurde erkannt (IDs: %s). Bitte melde es dem Addon-Autor.",
    ["Monter"] = "Nach oben",
    ["Descendre"] = "Nach unten",
    ["Priorité des bénédictions"] = "Segen-Priorität",
    ["Buffs proposés"] = "Angebotene Buffs",
    ["non appris"] = "nicht erlernt",
    ["non apprise"] = "nicht erlernt",
    ["Les buffs de mana (Sagesse, Intelligence des Arcanes, Esprit divin) ne vont jamais aux guerriers ni aux voleurs."] = "Mana-Buffs (Weisheit, Arkane Intelligenz, Göttlicher Willen) gehen nie an Krieger oder Schurken.",
    ["Montrer les joueurs marqués PvP"] = "PvP-markierte Spieler anzeigen",
    ["Options indisponibles sur ce client."] = "Optionen auf diesem Client nicht verfügbar.",
    ["ouvre les options"] = "öffnet die Optionen",
    ["Buff suivant"] = "Nächster Buff",
    ["Rafraîchir un buff s'il lui reste moins de %d min"] = "Buff erneuern, wenn weniger als %d Min. übrig sind",
}
for k, v in pairs(T) do NS.L[k] = v end
