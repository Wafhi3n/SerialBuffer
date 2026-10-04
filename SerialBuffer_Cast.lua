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

-- ---------------------------------------------------------------- sort raté

-- Seules les erreurs qui tiennent à la CIBLE comptent ; un « sort pas prêt » (temps de recharge global,
-- clic martelé) ne doit pas faire tourner la file. MESURÉ sur Forever (build 70205, 2026-10-04,
-- db.seenErrors) : un sort refusé arrive sous le nom GÉNÉRIQUE « ERR_SPELL_FAILED_S » (GetGameMessageInfo),
-- la raison n'étant que dans le TEXTE (« Target is too low level ») ; « pas prêt » arrive sous
-- « ERR_SPELL_COOLDOWN ». On compare donc surtout le texte aux globales du client (traduites : la langue
-- n'y change rien) ; le nom ne sert que pour les erreurs qui ont le leur. Deux suites :
--   "lowlevel" : la cible est trop basse pour CE buff, elle sort de la liste pour lui (D24) ;
--   "target"   : hors de vue, hors de portée, cible invalide : le joueur repasse en fin de file.
C.TARGET_ERRORS = { SPELL_FAILED_LINE_OF_SIGHT = true, SPELL_FAILED_OUT_OF_RANGE = true,
                    ERR_OUT_OF_RANGE = true, SPELL_FAILED_BAD_TARGETS = true }

local function textIs(msg, key)
    local s = _G[key]
    return type(s) == "string" and s ~= "" and (msg == s or msg == s .. ".")
end

function C.Classify(errorName, msg)
    if type(errorName) == "string" and C.TARGET_ERRORS[errorName] then return "target" end
    if type(msg) ~= "string" then return nil end
    if textIs(msg, "SPELL_FAILED_LOWLEVEL") then return "lowlevel" end
    for key in pairs(C.TARGET_ERRORS) do
        if textIs(msg, key) then return "target" end
    end
    return nil
end

-- Le dernier clic, noté par les boutons (SerialBuffer_UI.lua) : le joueur, le buff, son niveau.
function C:NoteClick(b, now)
    self.last = (b and b.guid) and { guid = b.guid, buff = b.buffName, level = b.level, t = now } or nil
end

-- Le dernier clic, s'il date de moins de RECENT secondes.
function C:Recent(now)
    local last = self.last
    if last and (now - last.t) <= self.RECENT then return last end
    return nil
end

-- UI_ERROR_MESSAGE : rend kind ("lowlevel" | "target") et le clic qu'elle concerne, ou nil.
function C:OnError(errorName, msg, now)
    local last = self.last
    if not last or (now - last.t) > self.RECENT then return nil end
    local kind = self.Classify(errorName, msg)
    if not kind then return nil end
    self.last = nil
    return kind, last
end
