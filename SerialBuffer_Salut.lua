-- SerialBuffer_Salut.lua — LE SALUT DE FOREVER (docs/specs/salut.md).
--
-- Sur Forever (vu le 2026-10-16), Salvation (1038) n'est plus une bénédiction : un buff d'une heure,
-- -30 % de menace, qui s'ajoute à la Rois et ne se pose que sur ton groupe ; Mass Salvation (25895,
-- niveau 60, un Symbol of Kings) le donne à toute une CLASSE du raid ; Revoke (1325499) le retire.
-- On le veut sur tout le monde sauf les tanks (D44 : rôle du jeu, marque main tank). D'où, dans la
-- partie du groupe, après les bénédictions : une ligne par classe (Mass Salvation, S-Q7) ou par
-- joueur (Salvation : sans Mass Salvation, ou un seul non-tank dans la classe, S-Q4), tanks exceptés,
-- puis une ligne Revoke par tank qui le porte. Seulement en groupe avec un tank ; l'icône de l'en-tête
-- les éteint (db.salutOff, allumé par défaut, S-Q1).
-- Une aura illisible ou cachée (combat, champ de bataille, D52) : AUCUNE ligne. Le mode à l'aveugle
-- dirait que tout le monde manque de Salut et le proposerait à tout le groupe.
-- Les lignes ont leur propre clé (« guid#salut », « salut:CLASSE ») : un joueur peut avoir une ligne
-- de bénédiction ET une de Salut, et MarkDone, Requeue, TooLow ne doivent toucher que la bonne.
local _, NS = ...
NS = NS or _G.SerialBuffer

local S = {}
NS.Salut = S

S.SALVATION, S.MASS, S.REVOKE = 1038, 25895, 1325499
S.SYMBOL = 21177    -- Symbol of Kings, composant de Mass Salvation (id de l'Era, à confirmer en jeu)
S.REFRESH = 600     -- s : sous 10 min, reproposé, comme une bénédiction (D11)

-- Les sorts que le personnage connaît (id, nom, icône), et les noms des DEUX auras : celle de Mass
-- Salvation porte son propre nom (capture du user), et un autre paladin peut l'avoir posée.
function S:Resolve()
    local c = NS.Buffs.client
    local function spell(id)
        if not c.known(id) then return nil end
        local n = c.name(id)
        if type(n) ~= "string" or n == "" then return nil end
        return { id = id, name = n, icon = c.icon(id) }
    end
    self.spells = { salv = spell(S.SALVATION), mass = spell(S.MASS), revoke = spell(S.REVOKE) }
    self.names = {}
    for _, id in ipairs({ S.SALVATION, S.MASS }) do
        local n = c.name(id)
        if type(n) == "string" and n ~= "" then self.names[#self.names + 1] = n end
    end
end

-- Toi et ton groupe ou ton raid : qui compte pour le Salut (vivant, visible, lisible).
local function member(snap)
    if not (snap.guid and snap.name and snap.player and snap.assist) or snap.dead then return false end
    if snap.self then return snap.group == true end
    return snap.group == true and snap.visible ~= false
end

-- Le groupe compte-t-il un tank ? Sans tank, ni icône ni lignes (S-Q1).
function S.HasTank(snaps)
    for _, snap in ipairs(snaps) do
        if member(snap) and snap.tank then return true end
    end
    return false
end

-- true : il a un Salut (l'un ou l'autre nom) pour plus de REFRESH secondes ; false : non ; nil :
-- illisible ou caché, on ne sait pas.
local function has(probe, snap, names)
    local low = false
    for _, n in ipairs(names) do
        local left = probe.aura(snap.unit, n)
        if left == nil or left == "hidden" then return nil end
        if type(left) == "number" then
            if left > S.REFRESH then return true end
            low = true
        end
    end
    return false, low
end

local function row(snap, spell, key, probe, label)
    local far = not snap.self and probe.range(snap.unit, spell.name) == false
    return { guid = key, name = label or snap.name, class = snap.class, unit = snap.unit, level = snap.level,
             buff = spell, group = true, self = snap.self, outOfRange = far, section = far and "far" or "group",
             salut = true }
end

-- La cible d'une ligne de classe : le premier à portée, sinon le premier (la ligne passe « loin »).
local function classRow(list, spell, probe, label)
    for _, snap in ipairs(list) do
        if snap.self or probe.range(snap.unit, spell.name) ~= false then
            return row(snap, spell, "salut:" .. snap.class, probe, label)
        end
    end
    return row(list[1], spell, "salut:" .. list[1].class, probe, label)
end

-- Les lignes de Salut. opts : spells (Resolve), names (les deux noms d'aura), symbols (nombre de
-- Symbol of Kings ; nil = illisible, on ne bascule pas pour autant sur Salvation), className(classe).
function S.Build(snaps, probe, opts)
    local sp, names = opts.spells or {}, opts.names or {}
    if not sp.salv or not names[1] or not S.HasTank(snaps) then return {} end
    local byClass, order, tanks = {}, {}, {}
    for _, snap in ipairs(snaps) do
        if member(snap) then
            local got = has(probe, snap, names)
            if got == nil then return {} end
            if snap.tank then
                if got then tanks[#tanks + 1] = snap end
            elseif not got and snap.class then
                if not byClass[snap.class] then byClass[snap.class] = {}; order[#order + 1] = snap.class end
                table.insert(byClass[snap.class], snap)
            end
        end
    end
    local mass = sp.mass and opts.symbols ~= 0
    local out = {}
    for _, class in ipairs(order) do
        local list = byClass[class]
        if mass and #list >= 2 then
            local label = string.format("%s (%d)", opts.className and opts.className(class) or class, #list)
            out[#out + 1] = classRow(list, sp.mass, probe, label)
        else
            for _, snap in ipairs(list) do out[#out + 1] = row(snap, sp.salv, snap.guid .. "#salut", probe) end
        end
    end
    if sp.revoke then
        for _, snap in ipairs(tanks) do out[#out + 1] = row(snap, sp.revoke, snap.guid .. "#revoke", probe) end
    end
    return out
end

-- Les lignes de Salut à la fin de la partie du groupe (S-Q8), celles hors de portée tout en bas.
function S.Merge(rows, extra)
    if not extra[1] then return rows end
    local out, placed = {}, false
    local function group()
        for _, r in ipairs(extra) do if r.section == "group" then out[#out + 1] = r end end
        placed = true
    end
    for _, r in ipairs(rows) do
        if not placed and r.section ~= "group" then group() end
        out[#out + 1] = r
    end
    if not placed then group() end
    for _, r in ipairs(extra) do if r.section == "far" then out[#out + 1] = r end end
    return out
end

local function className(class)
    local names = _G.LOCALIZED_CLASS_NAMES_MALE
    return (names and names[class]) or class
end

-- Au rendu (Run:Refresh, hors combat) : self.active dit si l'icône de l'en-tête se montre (paladin qui
-- connaît Salvation, groupé, avec un tank) ; les lignes, si en plus l'icône est allumée.
function S:Rows(snaps, probe)
    self.active = NS.Buffs.class == "PALADIN" and self.spells ~= nil and self.spells.salv ~= nil
        and S.HasTank(snaps)
    if not self.active or NS.db.salutOff then return {} end
    return S.Build(snaps, probe, { spells = self.spells, names = self.names,
                                   symbols = NS.Buffs.client.count(S.SYMBOL), className = className })
end

function S:SetOn(on)
    NS.db.salutOff = (not on) or nil
    NS.Header:Refresh()
    if NS.UI:IsVisible() and not InCombatLockdown() then NS.Run:Refresh() end
end
