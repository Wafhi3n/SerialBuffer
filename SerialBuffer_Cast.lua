-- SerialBuffer_Cast.lua — LE LANCER : le texte de macro d'une ligne, la touche « buff suivant », et ce
-- qu'on fait d'un sort raté.
--
-- Mesuré sur Forever (build 70205, sonde du 2026-10-04, relevé R4 de la spec) : le jeu IGNORE un sort
-- lancé sur un jeton de plaque, mais un bouton sécurisé de type macro qui cible par le NOM COMPLET
-- (« Prénom Nom », avec une espace) buffe l'inconnu. D'où la macro :
--     /cleartarget
--     /targetexact Prénom Nom
--     /cast [@target,exists,help,nodead] <sort>
-- /cleartarget et [exists] : si le nom ne cible personne (joueur parti), RIEN ne part ; sans eux, le
-- sort partait sur la cible d'avant (relevé du 2026-10-04 16:57). Pas de /targetlasttarget (D20) : le
-- dernier joueur buffé reste ciblé. Toi : [@player], qui ne touche pas à ta cible.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local C = {}
NS.Cast = C

C.NEXT_BUTTON = "SerialBufferNextButton"
C.MAX_MACRO = 255
C.RECENT = 2   -- secondes : une erreur au-delà ne vient pas de notre clic

-- Les libellés du menu des raccourcis (Bindings.xml).
_G.BINDING_HEADER_SERIALBUFFER = "Serial Buffer"
_G["BINDING_NAME_CLICK " .. C.NEXT_BUTTON .. ":LeftButton"] = L["Buff suivant"]

-- Le texte de macro d'une ligne de la file, ou nil (nom ou sort absent, macro trop longue).
function C.MacroFor(row)
    if not (row and row.buff and row.buff.name) then return nil end
    local text
    if row.self then
        text = "/cast [@player] " .. row.buff.name
    elseif row.name then
        text = "/cleartarget\n/targetexact " .. row.name .. "\n/cast [@target,exists,help,nodead] " .. row.buff.name
    end
    if text and #text <= C.MAX_MACRO then return text end
    return nil
end

-- La touche « buff suivant » prend le premier de la file qui est à portée (D9 : un membre du groupe
-- hors de portée reste dans le tableau, mais la touche le saute).
function C.NextRow(rows)
    for _, row in ipairs(rows) do
        if not row.outOfRange and C.MacroFor(row) then return row end
    end
    return nil
end

-- ---------------------------------------------------------------- sort raté → fin de file

-- Seules les erreurs qui tiennent à la CIBLE renvoient le joueur en fin de file (spec, « Le sort
-- échoue »). Un « sort pas prêt » (temps de recharge global, touche martelée) ne doit pas faire
-- tourner la file. Comparées aux globales du client (traduites), lues à l'usage : une globale absente
-- ne compte pas.
C.TARGET_ERRORS = { "SPELL_FAILED_LINE_OF_SIGHT", "SPELL_FAILED_OUT_OF_RANGE", "ERR_OUT_OF_RANGE",
                    "SPELL_FAILED_LOWLEVEL", "SPELL_FAILED_BAD_TARGETS" }

function C.IsTargetError(msg)
    if type(msg) ~= "string" then return false end
    for _, key in ipairs(C.TARGET_ERRORS) do
        local s = _G[key]
        if type(s) == "string" and s ~= "" and (msg == s or msg == s .. ".") then return true end
    end
    return false
end

-- Le dernier clic, noté par les boutons (SerialBuffer_UI.lua). Une ligne : le GUID de son joueur.
function C:NoteClick(guid, now)
    self.last = guid and { guid = guid, t = now } or nil
end

-- UI_ERROR_MESSAGE : rend le GUID à renvoyer en fin de file, ou nil.
function C:OnError(msg, now)
    local last = self.last
    if not last or (now - last.t) > self.RECENT then return nil end
    if not self.IsTargetError(msg) then return nil end
    self.last = nil
    return last.guid
end
