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
    ["En instance : seul ton groupe est listé."]                                    = "In an instance: only your group is listed.",
    ["Ta classe n'a pas de buff à poser sur les autres."]                           = "Your class has no buff to cast on others.",
    ["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."]        = "Friendly player nameplates are off: only you and your group are seen.",
    ["+%d autres"]                                                                  = "+%d more",
    ["Personne à buffer autour de toi."]                                            = "Nobody around you needs a buff.",
    ["Tournée finie !"]                                                             = "Round done!",
    ["%d à buffer"]                                                                 = "%d to buff",
    ["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."]  = "None of your buffs was recognized (ids: %s). Please tell the addon author.",
    ["non appris"] = "not learned",
    ["Une bénédiction par classe : le 1er choix, sinon le suivant"] = "One blessing per class: the 1st choice, otherwise the next",
    ["Tes buffs par classe, dans l'ordre"] = "Your buffs per class, in order",
    ["Toutes"] = "All",
    ["Choix %d"] = "Choice %d",
    ["Buff %d"] = "Buff %d",
    ["Groupe / raid"] = "Group / raid",
    ["Vide"] = "Empty",
    ["Vide : la grille du dessus s'applique."] = "Empty: the grid above applies.",
    ["Clic ou molette : buff suivant. Clic droit : précédent."] = "Click or mouse wheel: next buff. Right-click: previous.",
    ["Remplir : recopie la case « Toutes » sur toutes les classes"] = "Fill: copies the \"All\" box to every class",
    ["Remettre cette classe par défaut"] = "Reset this class to default",
    ["Tout par défaut"] = "Reset all",
    ["buffé"] = "buffed",
    ["groupe changé"] = "group changed",
    ["expiré"] = "expired",
    ["%d min"] = "%d min",
    ["%d s"] = "%d s",
    ["Groupe / raid : un choix unique pour les membres de ton groupe ou raid ; vide, la grille du dessus s'applique. Un buff de mana n'est jamais proposé aux guerriers ni aux voleurs."] = "Group / raid: a single choice for the members of your group or raid; empty, the grid above applies. A mana buff is never offered to warriors or rogues.",
    ["Options : quels buffs sur quelles classes"] = "Options: which buffs on which classes",
    ["%d illisible(s) : le jeu cache leur nom ou leurs buffs."] = "%d unreadable: the game hides their name or their buffs.",
    ["Raid"] = "Raid",
    ["Groupe"] = "Group",
    ["Autour de toi"] = "Around you",
    ["Hors de portée"] = "Out of range",
    ["Montrer les joueurs marqués PvP"] = "Show PvP-flagged players",
    ["Options indisponibles sur ce client."] = "Options are unavailable on this client.",
    ["ouvre les options"] = "opens the options",
    ["Buff suivant"] = "Next buff",
    ["Rafraîchir un buff s'il lui reste moins de %d min"] = "Refresh a buff with less than %d min left",
}
for k, v in pairs(T) do NS.L[k] = v end
