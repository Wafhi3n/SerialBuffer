-- SerialBuffer_Queue.lua — LA FILE : qui entre dans le tableau, dans quel ordre, avec quel buff.
--
-- Logique PURE : aucun appel au client. Elle reçoit des instantanés d'unités (SerialBuffer_Units.lua)
-- et deux sondes, aura et portée, que le test headless remplace. Spec docs/specs/serial-buffer.md :
--   D5  PvP caché par défaut (pas toi : te buffer ne te marque pas)  D7  une ligne, le PROCHAIN buff qui manque
--   D8  FIFO, personne ne passe devant                               D9  hors de portée = dehors, sauf groupe
--   D11 un buff à moins de 10 min compte comme manquant              D16 joueur en combat : dehors
--   D18 membre du groupe invisible (autre carte) : dehors
-- RÈGLE DE SÛRETÉ : « je ne sais pas » n'est JAMAIS « il lui manque ». Une aura illisible (erreur,
-- valeur secrète) ou une portée inconnue pour un inconnu écartent le joueur : sinon une restriction
-- du client ferait passer tout le monde pour non buffé.
-- La clé de la file est le GUID : un même joueur arrive par « party1 » ET par « nameplate4 », et un
-- jeton de plaque change de joueur en quelques secondes (relevé R2).
local _, NS = ...
NS = NS or _G.SerialBuffer

local Q = { seq = 0, order = {} }
NS.Queue = Q

Q.REFRESH_BELOW = 600   -- D11 : 10 minutes

function Q:Reset()
    self.seq, self.order = 0, {}
end

-- Le premier buff voulu qui manque. probe.aura rend "absent", un nombre de secondes restantes
-- (math.huge = sans fin), ou nil = illisible. Rend buff, ou nil + "buffed" / "unknown".
local function nextMissing(snap, wanted, probe)
    for _, w in ipairs(wanted) do
        local left = probe.aura(snap.unit, w.name)
        if left == nil then return nil, "unknown" end
        if left == "absent" or (type(left) == "number" and left < Q.REFRESH_BELOW) then return w end
    end
    return nil, "buffed"
end

-- Les filtres qui ne dépendent pas des buffs. Rend true si le joueur peut entrer dans la file.
local function admissible(snap, opts)
    if not snap.guid or not snap.name then return false end   -- secret ou illisible (critère 10)
    if not snap.player or not snap.assist or snap.dead then return false end
    if snap.self then return true end
    if snap.combat then return false end                       -- D16
    if snap.pvp and not opts.showPvP then return false end     -- D5
    if snap.group and not snap.visible then return false end   -- D18
    return true
end

-- Une ligne pour ce joueur, ou nil. wantedFor(classe) → buffs voulus, dans l'ordre.
function Q:Eligible(snap, wantedFor, probe, opts)
    if not admissible(snap, opts or {}) then return nil end
    local buff = nextMissing(snap, wantedFor(snap.class), probe)
    if not buff then return nil end
    local outOfRange = false
    if not snap.self then
        local r = probe.range(snap.unit, buff.name)
        if r ~= true then
            if not snap.group then return nil end   -- D9 ; portée inconnue d'un inconnu : dehors
            outOfRange = (r == false)
        end
    end
    return { guid = snap.guid, name = snap.name, class = snap.class, unit = snap.unit,
             buff = buff, group = snap.group, self = snap.self, outOfRange = outOfRange,
             pvp = (snap.pvp and not snap.self) or false }
end

-- Construit les lignes, triées FIFO. Un joueur qui sort de la file (buffé, parti, en combat…) perd sa
-- place : s'il revient, il entre en fin de file (D8, D11). Rend rows, around (joueurs admis autour,
-- toi non compris : il distingue « personne autour » de « tournée finie »).
function Q:Build(snaps, wantedFor, probe, opts)
    opts = opts or {}
    local rows, seen, around = {}, {}, 0
    for _, snap in ipairs(snaps) do
        if snap.guid and not seen[snap.guid] then
            seen[snap.guid] = true
            if admissible(snap, opts) and not snap.self then around = around + 1 end
            local row = self:Eligible(snap, wantedFor, probe, opts)
            if row then
                if not self.order[row.guid] then
                    self.seq = self.seq + 1
                    self.order[row.guid] = self.seq
                end
                row.seq = self.order[row.guid]
                rows[#rows + 1] = row
            end
        end
    end
    local keep = {}
    for _, row in ipairs(rows) do keep[row.guid] = true end
    for guid in pairs(self.order) do
        if not keep[guid] then self.order[guid] = nil end
    end
    table.sort(rows, function(a, b) return a.seq < b.seq end)
    return rows, around
end

-- Palier (b) : un sort raté renvoie le joueur en fin de file, pour ne pas bloquer « buff suivant ».
function Q:Requeue(guid)
    if self.order[guid] then
        self.seq = self.seq + 1
        self.order[guid] = self.seq
    end
end
