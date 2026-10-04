-- SerialBuffer_Buffs.lua — CE QUE TA CLASSE POSE : le catalogue des buffs longs et la table du paladin.
--
-- Spec docs/specs/serial-buffer.md : D4 (toutes les classes à buff), D14 (tous cochés par défaut),
-- D22 (le paladin pose la PREMIÈRE bénédiction de sa liste de priorité qu'il connaît : Rois > Sagesse >
-- Puissance par défaut, réglable dans les options), D23 (un buff de mana ne va jamais à une classe sans
-- mana : pas de Sagesse ni d'Intelligence des Arcanes pour un guerrier ou un voleur).
-- On garde le RANG 1 de chaque sort : on teste qu'il est connu, puis on travaille par NOM, parce que
-- Forever garde les rangs et qu'une aura porte l'id du rang lancé (sonde, 2026-10-04). Lancer par nom
-- prend le rang le plus haut connu.
--
-- Seuls 19740 et 19742 (paladin) ont été vus sur Forever. Les autres ids sont ceux de vanilla : si
-- aucun n'est reconnu pour ta classe, Buffs:Resolve le dit une fois dans le chat (un id faux se voit
-- au lieu de se taire).
local _, NS = ...
NS = NS or _G.SerialBuffer

local B = {}
NS.Buffs = B

B.CATALOG = {
    MAGE   = { 1459 },               -- Intelligence des Arcanes
    PRIEST = { 1243, 14752, 976 },   -- Robustesse, Esprit divin, Protection contre l'Ombre
    DRUID  = { 1126, 467 },          -- Marque du fauve, Épines
}

-- Les bénédictions du paladin, par clé stable (la table du joueur garde la clé, pas l'id).
B.BLESSINGS = {
    MIGHT = 19740, WISDOM = 19742, KINGS = 20217,
    SALVATION = 1038, LIGHT = 19977, SANCTUARY = 20911,
}

-- D22 : l'ordre de priorité par défaut. Salut n'y est pas : un tank n'en veut pas.
B.PRIORITY_DEFAULT = { "KINGS", "WISDOM", "MIGHT" }

-- D23 : les buffs de mana, et les classes qui n'en ont pas l'usage. Un paladin ne pose qu'UNE
-- bénédiction par cible ; un prêtre, un mage ou un druide posent tous leurs buffs, l'un après l'autre.
B.MANA_BUFFS = { [19742] = true, [1459] = true, [14752] = true }   -- Sagesse, Intelligence, Esprit divin
B.NO_MANA = { WARRIOR = true, ROGUE = true }

-- Le client, remplaçable par un test headless.
B.client = {
    known = function(id)
        if C_SpellBook and C_SpellBook.IsSpellKnown then
            local ok, k = pcall(C_SpellBook.IsSpellKnown, id)
            if ok and k then return true end
        end
        if IsPlayerSpell then
            local ok, k = pcall(IsPlayerSpell, id)
            if ok and k then return true end
        end
        return false
    end,
    name = function(id) return C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(id) end,
    icon = function(id) return C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(id) end,
}

local function entry(id)
    local c = B.client
    if not c.known(id) then return nil end
    local name = c.name(id)
    if type(name) ~= "string" or name == "" then return nil end
    return { id = id, name = name, icon = c.icon(id) }
end

-- Lit ce que le personnage connaît. Rend le nombre de buffs reconnus.
--   self.list      : buffs non paladin, dans l'ordre du catalogue (D7 : le prochain qui manque)
--   self.blessings : clé → buff, pour le paladin
function B:Resolve(class)
    self.class, self.list, self.blessings = class, {}, {}
    local n = 0
    if class == "PALADIN" then
        for key, id in pairs(self.BLESSINGS) do
            local e = entry(id)
            if e then e.key = key; self.blessings[key] = e; n = n + 1 end
        end
    else
        for _, id in ipairs(self.CATALOG[class] or {}) do
            local e = entry(id)
            if e then self.list[#self.list + 1] = e; n = n + 1 end
        end
    end
    return n
end

function B:HasCatalog(class)
    return class == "PALADIN" or self.CATALOG[class] ~= nil
end

-- L'ordre de priorité du joueur (db.priority, réglé dans les options), sinon celui par défaut.
function B:Priority(db)
    local p = db and db.priority
    if type(p) == "table" and #p > 0 then return p end
    return self.PRIORITY_DEFAULT
end

-- Ce buff sert-il à cette classe de cible ? (D23)
function B:Useful(e, targetClass)
    return not (self.MANA_BUFFS[e.id] and self.NO_MANA[targetClass])
end

-- Les buffs voulus pour une cible, dans l'ordre. db.off[id] = true : buff décoché (D14 : rien ne
-- l'est par défaut). Paladin : UNE bénédiction, la première de la priorité qu'il connaît, qui est
-- cochée et qui sert à la cible (D22, D23) ; une bénédiction inconnue cède sa place à la suivante.
function B:WantedFor(targetClass, db)
    local off = db and db.off or {}
    if self.class == "PALADIN" then
        for _, key in ipairs(self:Priority(db)) do
            local e = self.blessings and self.blessings[key]
            if e and not off[e.id] and self:Useful(e, targetClass) then return { e } end
        end
        return {}
    end
    local out = {}
    for _, e in ipairs(self.list or {}) do
        if not off[e.id] and self:Useful(e, targetClass) then out[#out + 1] = e end
    end
    return out
end

-- Pour les options : tout le catalogue de la classe, connu ou non, dans l'ordre affiché.
function B:Catalog(class, db)
    local ids = {}
    if class == "PALADIN" then
        for _, key in ipairs(self:Priority(db)) do ids[#ids + 1] = self.BLESSINGS[key] end
    else
        for _, id in ipairs(self.CATALOG[class] or {}) do ids[#ids + 1] = id end
    end
    local out, c = {}, self.client
    for _, id in ipairs(ids) do
        out[#out + 1] = { id = id, name = c.name(id) or tostring(id), icon = c.icon(id), known = c.known(id) }
    end
    return out
end
