-- SerialBuffer_Queue.lua — LA FILE : qui entre dans le tableau, dans quel ordre, avec quel buff.
--
-- Logique PURE : aucun appel au client. Elle reçoit des instantanés d'unités (SerialBuffer_Units.lua)
-- et deux sondes, aura et portée, que le test headless remplace. Spec docs/specs/serial-buffer.md :
--   D5  PvP caché par défaut (pas toi : te buffer ne te marque pas)  D7  une ligne, le PROCHAIN buff qui manque
--   D8  FIFO, personne ne passe devant                               D9  hors de portée = dehors, sauf groupe
--   D11 un buff à moins de 10 min compte comme manquant              D16 joueur en combat : dehors
--   D18 membre du groupe invisible (autre carte) : dehors              D24 trop bas pour un buff : dehors pour CE buff
--   D26 « sort plus puissant actif » : dehors pour CE buff, 20 min     D27 paladin : celle d'un autre (> 30 min) → la suivante
--   D28 hors paladin : un buff qui a plus que le seuil des options (45 min par défaut) : servi
-- AFFICHAGE : les joueurs à portée d'abord (FIFO), puis les membres du groupe hors de portée (FIFO) :
-- la première ligne est toujours quelqu'un qu'on peut buffer, et un clic répété dessus vide la file.
-- RÈGLE DE SÛRETÉ : « je ne sais pas » n'est JAMAIS « il lui manque ». Une aura illisible (erreur,
-- valeur secrète) ou une portée inconnue pour un inconnu écartent le joueur : sinon une restriction
-- du client ferait passer tout le monde pour non buffé.
-- La clé de la file est le GUID : un même joueur arrive par « party1 » ET par « nameplate4 », et un
-- jeton de plaque change de joueur en quelques secondes (relevé R2).
local _, NS = ...
NS = NS or _G.SerialBuffer

-- stats : compteurs de diagnostic (SerialBuffer_Run.lua les range dans db.diag), aucun nom de joueur.
local Q = { seq = 0, order = {}, blocked = {}, now = 0, stats = { next = 0, stopMine = 0, stopUnknown = 0 } }
NS.Queue = Q

Q.REFRESH_BELOW = 600     -- D11 : 10 minutes (bénédictions du paladin ; les autres buffs : D28, opts.refreshBelow)
Q.OTHER_KEEP = 1800       -- D27 : la bénédiction d'un autre paladin, bien partie, se laisse
Q.STRONGER_WAIT = 1200    -- D26 : « un sort plus puissant est actif » : on réessaie 20 min plus tard

function Q:Reset()
    self.seq, self.order, self.blocked, self.now = 0, {}, {}, 0
    self.stats = { next = 0, stopMine = 0, stopUnknown = 0 }
end

-- Le jeu a refusé ce buff sur ce joueur. On ne le lui propose plus, jusqu'à ce qu'il gagne un niveau
-- (D24, « trop bas ») ou pendant STRONGER_WAIT (D26, « plus puissant actif »). Mémoire de session :
-- rien n'est sauvegardé (spec, Contrat).
local function block(guid, buffName, rule)
    if not (guid and buffName) then return end
    Q.blocked[guid] = Q.blocked[guid] or {}
    Q.blocked[guid][buffName] = rule
end

function Q:TooLow(guid, buffName, level)
    block(guid, buffName, { level = type(level) == "number" and level or 0 })
end

function Q:Stronger(guid, buffName, now)
    block(guid, buffName, { untilT = (now or self.now) + self.STRONGER_WAIT })
end

local function isBlocked(snap, buffName)
    local rule = Q.blocked[snap.guid] and Q.blocked[snap.guid][buffName]
    if not rule then return false end
    local over = (rule.level and type(snap.level) == "number" and snap.level > rule.level)
        or (rule.untilT and Q.now > rule.untilT)
    if over then Q.blocked[snap.guid][buffName] = nil; return false end
    return true
end

local function needs(left, below)
    return left == "absent" or (type(left) == "number" and left < (below or Q.REFRESH_BELOW))
end

-- Paladin (liste EXCLUSIVE) : il ne garde qu'UNE bénédiction à lui par joueur. Rend "take" (proposer
-- celle-ci), "next" (passer à la suivante) ou "stop" (le joueur est servi). mine : true si c'est la
-- sienne, false si celle d'un autre, nil si le lanceur est illisible.
local function blessingVerdict(left, mine)
    if needs(left) then return "take" end                    -- absente, ou qui expire (D11) : qui l'a posée importe peu
    if mine == false then return (left > Q.OTHER_KEEP) and "next" or "take" end   -- D27
    return "stop"   -- la mienne, ou lanceur illisible : ne jamais écraser sa propre bénédiction par une autre
end

-- Le buff à proposer, ou nil. probe.aura rend "absent" ou les secondes restantes (math.huge = sans
-- fin), plus « est-ce la mienne » ; nil = illisible. Prêtre, mage, druide : le premier qui manque (D7).
local function nextMissing(snap, wanted, probe, refreshBelow)
    for _, w in ipairs(wanted) do
        if not isBlocked(snap, w.name) then
            local left, mine = probe.aura(snap.unit, w.name)
            if left == nil then return nil end
            if wanted.exclusive then
                local v = blessingVerdict(left, mine)
                local st = Q.stats
                if v == "next" then st.next = st.next + 1
                elseif v == "stop" and mine == nil then st.stopUnknown = st.stopUnknown + 1
                elseif v == "stop" then st.stopMine = st.stopMine + 1 end
                if v == "take" then return w end
                if v == "stop" then return nil end
            elseif needs(left, refreshBelow) then   -- D28 : seuil réglable hors paladin
                return w
            end
        end
    end
    return nil
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
    local buff = nextMissing(snap, wantedFor(snap.class), probe, (opts or {}).refreshBelow)
    if not buff then return nil end
    local outOfRange = false
    if not snap.self then
        local r = probe.range(snap.unit, buff.name)
        if r ~= true then
            if not snap.group then return nil end   -- D9 ; portée inconnue d'un inconnu : dehors
            outOfRange = (r == false)
        end
    end
    return { guid = snap.guid, name = snap.name, class = snap.class, unit = snap.unit, level = snap.level,
             buff = buff, group = snap.group, self = snap.self, outOfRange = outOfRange,
             pvp = (snap.pvp and not snap.self) or false }
end

-- Construit les lignes, triées FIFO, les joueurs à portée d'abord. Un joueur qui sort de la file
-- (buffé, parti, en combat…) perd sa place : s'il revient, il entre en fin de file (D8, D11). Rend
-- rows, around (joueurs admis autour, toi non compris : il distingue « personne autour » de « tournée
-- finie »).
function Q:Build(snaps, wantedFor, probe, opts)
    opts = opts or {}
    self.now = opts.now or self.now
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
    table.sort(rows, function(a, b)
        if a.outOfRange ~= b.outOfRange then return not a.outOfRange end
        return a.seq < b.seq
    end)
    return rows, around
end

-- Palier (b) : un sort raté renvoie le joueur en fin de file, pour ne pas bloquer « buff suivant ».
function Q:Requeue(guid)
    if self.order[guid] then
        self.seq = self.seq + 1
        self.order[guid] = self.seq
    end
end
