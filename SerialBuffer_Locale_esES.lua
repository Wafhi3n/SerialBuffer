-- SerialBuffer_Locale_esES.lua — overlay ESPAGNOL (esES/esMX). Clé FR → texte ES.
-- Chargé APRÈS SerialBuffer_Locale.lua (qui crée NS.L). Sur un client non espagnol : early-return.
local _, NS = ...
NS = NS or _G.SerialBuffer
if not NS or not NS.L then return end

local locale = GetLocale and GetLocale() or "enUS"
if locale ~= "esES" and locale ~= "esMX" then return end

local T = {
    ["chargé. Tape /%s aide pour l'aide."]                                          = "cargado. Escribe /%s ayuda para ver la ayuda.",
    ["version %s"]                                                                  = "versión %s",
    ["Commandes :"]                                                                 = "Comandos:",
    ["affiche la version"]                                                          = "muestra la versión",
    ["affiche ou cache le tableau"]                                                 = "muestra u oculta la tabla",
    ["montre ou cache les joueurs PvP"]                                             = "muestra u oculta a los jugadores JcJ",
    ["Joueurs PvP affichés."]                                                       = "Jugadores JcJ visibles.",
    ["Joueurs PvP cachés."]                                                         = "Jugadores JcJ ocultos.",
    ["Pas pendant un combat."]                                                      = "No durante un combate.",
    ["PvP"]                                                                         = "JcJ",
    ["hors de portée"]                                                              = "fuera de alcance",
    ["En instance : seul ton groupe est listé."]                                    = "En una instancia: solo se muestra tu grupo.",
    ["Ta classe n'a pas de buff à poser sur les autres."]                           = "Tu clase no tiene beneficios para lanzar a otros.",
    ["Plaques des joueurs amis coupées : seuls toi et ton groupe sont vus."]        = "Placas de jugadores amistosos desactivadas: solo se ve a ti y a tu grupo.",
    ["+%d autres"]                                                                  = "+%d más",
    ["Personne à buffer autour de toi."]                                            = "Nadie a tu alrededor necesita un beneficio.",
    ["Tournée finie !"]                                                             = "¡Ronda terminada!",
    ["%d à buffer"]                                                                 = "%d por bufear",
    ["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."]  = "Ninguno de tus beneficios fue reconocido (ids: %s). Avisa al autor del addon.",
    ["Monter"] = "Subir",
    ["Descendre"] = "Bajar",
    ["Priorité des bénédictions"] = "Prioridad de bendiciones",
    ["Buffs proposés"] = "Beneficios ofrecidos",
    ["non appris"] = "no aprendido",
    ["non apprise"] = "no aprendida",
    ["Une case cochée : ce buff se pose sur cette classe. Grisée : buff de mana, jamais aux guerriers ni aux voleurs."] = "Casilla marcada: este beneficio va a esta clase. En gris: beneficio de maná, nunca para guerreros ni pícaros.",
    ["Options : quels buffs sur quelles classes"] = "Opciones: qué beneficios en qué clases",
    ["%d illisible(s) : le jeu cache leur nom ou leurs buffs."] = "%d ilegible(s): el juego oculta su nombre o sus beneficios.",
    ["Raid"] = "Banda",
    ["Groupe"] = "Grupo",
    ["Autour de toi"] = "A tu alrededor",
    ["Hors de portée"] = "Fuera de alcance",
    ["Montrer les joueurs marqués PvP"] = "Mostrar jugadores marcados JcJ",
    ["Options indisponibles sur ce client."] = "Opciones no disponibles en este cliente.",
    ["ouvre les options"] = "abre las opciones",
    ["Buff suivant"] = "Siguiente beneficio",
    ["Rafraîchir un buff s'il lui reste moins de %d min"] = "Renovar un beneficio si le quedan menos de %d min",
}
for k, v in pairs(T) do NS.L[k] = v end
