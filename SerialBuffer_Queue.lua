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
--   D30 le groupe passe devant (remplace « ni ton groupe » de D8)
--   D37 le choix unique du groupe, puis la colonne en repli        D38 refus « trop bas » APPRIS (db.tooLow)
-- AFFICHAGE, trois parties, FIFO dans chacune (D30, D25) : « group » (ton groupe ou ton raid, à
-- portée), « around » (les autres, à portée), « far » (le groupe hors de portée), tout en bas : la
-- première ligne est toujours quelqu'un qu'on peut buffer, et un clic répété dessus vide la file.
-- Toi : dans « group » si l'instantané te dit groupé (SerialBuffer_Units.lua), sinon à ta place (D8).
-- RÈGLE DE SÛRETÉ : « je ne sais pas » n'est JAMAIS « il lui manque ». Une aura illisible (erreur,
-- valeur secrète) ou une portée inconnue pour un inconnu écartent le joueur : sinon une restriction
-- du client ferait passer tout le monde pour non buffé.
-- La clé de la file est le GUID : un même joueur arrive par « party1 » ET par « nameplate4 », et un
-- jeton de plaque change de joueur en quelques secondes (relevé R2).
local _, NS = ...
NS = NS or _G.SerialBuffer

-- stats : compteurs de diagnostic (SerialBuffer_Run.lua les range dans db.diag), aucun nom de joueur.
local Q = { seq = 0, order = {}, blocked = {}, cast = {}, now = 0, stats = { next = 0, stopMine = 0, stopUnknown = 0 } }
NS.Queue = Q

Q.REFRESH_BELOW = 600     -- D11 : 10 minutes (bénédictions du paladin ; les autres buffs : D28, opts.refreshBelow)
Q.OTHER_KEEP = 1800       -- D27 : la bénédiction d'un autre paladin, bien partie, se laisse
Q.STRONGER_WAIT = 1200    -- D26 : « un sort plus puissant est actif » : on réessaie 20 min plus tard

function Q:Reset()
    self.seq, self.order, self.blocked, self.cast, self.now = 0, {}, {}, {}, 0
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

-- Ce que J'AI posé cette session, et quand. Garde-fou de D27 : un buff que je viens de poser est le
-- mien, même si le jeu ne dit pas qui l'a posé ; sans lui, un lanceur mal lu ferait alterner deux
-- bénédictions sur le même joueur, chacune remplaçant l'autre.
Q.MINE_FOR = 3600
function Q:Cast(guid, buffName, now)
    if not (guid and buffName) then return end
    self.cast[guid] = self.cast[guid] or {}
    self.cast[guid][buffName] = now or self.now
end

local function castByMe(snap, buffName)
    local t = Q.cast[snap.guid] and Q.cast[snap.guid][buffName]
    return t ~= nil and (Q.now - t) < Q.MINE_FOR
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

-- Le buff à proposer, ou nil (plus "unread" si une aura est illisible). probe.aura rend "absent" ou
-- les secondes restantes (math.huge = sans fin), plus « est-ce la mienne » ; nil = illisible. Prêtre,
-- mage, druide : le premier qui manque (D7).
-- D38 : le jeu a déjà refusé ce rang « trop bas » jusqu'à un niveau ≥ celui du joueur.
local function learnedLow(snap, w, low)
    local max = low and low[w.rank or w.id]
    return max ~= nil and type(snap.level) == "number" and snap.level > 0 and snap.level <= max
end

-- low : les refus « trop bas » appris (db.tooLow). wanted.single (D37) : le 1er est le choix unique
-- du groupe ; présent sur le joueur, il vaut « servi » pour un lanceur non paladin (la colonne qui
-- suit n'est qu'un repli s'il ne peut pas passer).
local function nextMissing(snap, wanted, probe, refreshBelow, low)
    for i, w in ipairs(wanted) do
        if not isBlocked(snap, w.name) and not learnedLow(snap, w, low) then
            local left, mine = probe.aura(snap.unit, w.name)
            if left == nil then return nil, "unread" end
            if mine ~= true and left ~= "absent" and castByMe(snap, w.name) then mine = true end
            if wanted.exclusive then
                local v = blessingVerdict(left, mine)
                local st = Q.stats
                if v == "next" then st.next = st.next + 1
                elseif v == "stop" and mine == nil then st.stopUnknown = st.stopUnknown + 1
                elseif v == "stop" then st.stopMine = st.stopMine + 1 end
                if v == "take" then return w, left end
                if v == "stop" then return nil end
            elseif needs(left, refreshBelow) then   -- D28 : seuil réglable hors paladin
                return w, left
            elseif wanted.single and i == 1 then     -- D37 : le choix unique est là
                return nil
            end
        end
    end
    return nil
end

-- D38 : un refus « trop bas » sur un joueur de ce niveau. Le seuil ne fait que monter. key = le rang
-- lancé (Buffs, entry.rank). Rien d'autre que des ids et des niveaux : aucune donnée de joueur.
function Q.LearnLow(db, key, level)
    if not (db and key and type(level) == "number" and level > 0) then return end
    db.tooLow = db.tooLow or {}
    if (db.tooLow[key] or 0) < level then db.tooLow[key] = level end
end

-- Un buff de ce rang a RÉUSSI sur ce niveau : un seuil qui disait le contraire redescend en dessous.
function Q.LearnOk(db, key, level)
    local t = db and db.tooLow
    if not (t and key and type(level) == "number" and t[key] and t[key] >= level) then return end
    t[key] = (level > 1) and (level - 1) or nil
end

-- Les filtres qui ne dépendent pas des buffs. Rend true si le joueur peut entrer dans la file, sinon
-- false, plus "unread" pour un joueur ami dont le NOM est illisible (critère 10 ; en instance, le
-- verrou Map en rend : D31) : le tableau les compte, pour qu'une liste vide ne passe pas pour finie.
local function admissible(snap, opts)
    if not snap.guid then return false end                    -- GUID secret ou absent (critère 10)
    if not snap.player or not snap.assist or snap.dead then return false end
    if not snap.name then return false, "unread" end
    if snap.self then return true end
    if snap.combat and not snap.group then return false end    -- D16, les inconnus seulement (D39)
    if snap.pvp and not opts.showPvP then return false end     -- D5
    if snap.group and not snap.visible then return false end   -- D18
    return true
end

-- Une ligne pour ce joueur, ou nil (plus "unread" si son nom ou une de ses auras est illisible).
-- wantedFor(classe, membre du groupe) → buffs voulus, dans l'ordre (D35 : le groupe a sa ligne à lui).
function Q:Eligible(snap, wantedFor, probe, opts)
    opts = opts or {}
    local ok, why = admissible(snap, opts)
    if not ok then return nil, why end
    local buff, info = nextMissing(snap, wantedFor(snap.class, snap.group), probe, opts.refreshBelow, opts.tooLow)
    if not buff then return nil, info end   -- info : "unread", ou rien
    -- D39 : le temps qui reste au buff que la ligne refait (nil s'il est absent), et son heure de fin.
    local left = (type(info) == "number" and info ~= math.huge) and info or nil
    local now = opts.now or self.now
    local outOfRange = false
    if not snap.self then
        local r = probe.range(snap.unit, buff.name)
        if r ~= true then
            if not snap.group then return nil end   -- D9 ; portée inconnue d'un inconnu : dehors
            outOfRange = (r == false)
        end
    end
    local section = outOfRange and "far" or (snap.group and "group" or "around")   -- D30
    return { guid = snap.guid, name = snap.name, class = snap.class, unit = snap.unit, level = snap.level,
             buff = buff, group = snap.group, self = snap.self, outOfRange = outOfRange, section = section,
             left = left, expiresAt = left and (now + left) or nil,
             pvp = (snap.pvp and not snap.self) or false }
end

Q.SECTIONS = { "group", "around", "far" }   -- l'ordre des parties du tableau (D30, D25)
local RANK = { group = 1, around = 2, far = 3 }

-- Construit les lignes, triées par partie puis FIFO. Un joueur qui sort de la file (buffé, parti, en
-- combat…) perd sa place : s'il revient, il entre en fin de file (D8, D11). Rend rows, around (joueurs
-- admis autour, toi non compris : il distingue « personne autour » de « tournée finie ») et unread
-- (joueurs amis écartés parce que leur nom ou une de leurs auras est illisible).
function Q:Build(snaps, wantedFor, probe, opts)
    opts = opts or {}
    self.now = opts.now or self.now
    local rows, seen, around, unread = {}, {}, 0, 0
    for _, snap in ipairs(snaps) do
        if snap.guid and not seen[snap.guid] then
            seen[snap.guid] = true
            if admissible(snap, opts) and not snap.self then around = around + 1 end
            local row, why = self:Eligible(snap, wantedFor, probe, opts)
            if why == "unread" then unread = unread + 1 end
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
        if a.section ~= b.section then return RANK[a.section] < RANK[b.section] end
        return a.seq < b.seq
    end)
    return rows, around, unread
end

-- D39 : le temps qui reste au buff d'une ligne à l'instant now (0 passé l'heure de fin), ou nil si
-- la ligne n'en a pas (buff absent). En combat, rien n'est relu : on décompte depuis expiresAt.
function Q.Remaining(row, now)
    if not (row and row.expiresAt) then return nil end
    return math.max(0, row.expiresAt - now)
end

-- Palier (b) : un sort raté renvoie le joueur en fin de file, pour ne pas bloquer « buff suivant ».
function Q:Requeue(guid)
    if self.order[guid] then
        self.seq = self.seq + 1
        self.order[guid] = self.seq
    end
end
