-- SerialBuffer_Buffs.lua — CE QUE TA CLASSE POSE : le catalogue des buffs longs et la table du paladin.
--
-- Spec docs/specs/serial-buffer.md : D4 (toutes les classes à buff), D14 (tous cochés par défaut),
-- D22 (le paladin pose la PREMIÈRE bénédiction de sa liste de priorité qu'il connaît : Rois > Sagesse >
-- Puissance par défaut, réglable dans les options), D23 (un buff de mana ne va jamais à une classe sans
-- mana : pas de Sagesse ni d'Intelligence des Arcanes pour un guerrier ou un voleur), D33 (la GRILLE
-- buffs × classes des options : une case cochée = ce buff se pose sur cette classe).
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

-- D22 : l'ordre de priorité par défaut. D33 : les six bénédictions sont dans la grille (choix du user,
-- 2026-10-05), mais Salut, Lumière et Sanctuaire y sont décochées partout tant qu'on ne les coche pas
-- (un tank ne veut pas de Salut).
B.PRIORITY_DEFAULT = { "KINGS", "WISDOM", "MIGHT", "SALVATION", "LIGHT", "SANCTUARY" }
B.DEFAULT_OFF = { [1038] = true, [19977] = true, [20911] = true }

-- D33 : les colonnes de la grille, les neuf classes de Forever, dans l'ordre CLASS_SORT_ORDER de
-- Camelot (Blizzard_FrameXMLBase/Camelot/Constants.lua, build 70205). Écrites ici plutôt que lues :
-- si c'était la liste Mainline qui se chargeait, elle porterait treize classes.
B.CLASSES = { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER" }

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

-- L'ordre de priorité du joueur (db.priority, réglé dans les options), complété par les bénédictions
-- qu'il ne contient pas encore, à la fin, dans l'ordre par défaut : une priorité sauvée avant D33 n'en
-- avait que trois. Une clé inconnue ou en double est ignorée.
function B:Priority(db)
    local p = db and db.priority
    if type(p) ~= "table" or #p == 0 then return self.PRIORITY_DEFAULT end
    local out, seen = {}, {}
    for _, key in ipairs(p) do
        if self.BLESSINGS[key] and not seen[key] then out[#out + 1] = key; seen[key] = true end
    end
    for _, key in ipairs(self.PRIORITY_DEFAULT) do
        if not seen[key] then out[#out + 1] = key end
    end
    return out
end

-- D22 : les flèches d'une ligne de la grille échangent la bénédiction i avec sa voisine. Rend true si
-- l'ordre a changé ; il est alors gardé, complet, dans db.priority.
function B:MovePriority(db, i, delta)
    local p = {}
    for k, v in ipairs(self:Priority(db)) do p[k] = v end
    local j = i + delta
    if not (p[i] and p[j]) then return false end
    p[i], p[j] = p[j], p[i]
    db.priority = p
    return true
end

-- D23 : une case qui ne se coche jamais (buff de mana sur une classe sans mana).
function B:Locked(id, targetClass)
    return (self.MANA_BUFFS[id] and self.NO_MANA[targetClass]) and true or false
end

-- D33 : la case (buff, classe de la cible) est-elle cochée ? db.classBuffs[classe][id] ne garde que
-- ce qui s'écarte du défaut : coché (D14), sauf Salut, Lumière et Sanctuaire (DEFAULT_OFF).
-- Une classe illisible (nil) prend le défaut.
function B:Cell(id, targetClass, db)
    if self:Locked(id, targetClass) then return false end
    local t = db and db.classBuffs and targetClass and db.classBuffs[targetClass]
    local v = t and t[id]
    if v ~= nil then return v end
    return not self.DEFAULT_OFF[id]
end

function B:SetCell(id, targetClass, on, db)
    if not (db and targetClass) or self:Locked(id, targetClass) then return end
    db.classBuffs = db.classBuffs or {}
    db.classBuffs[targetClass] = db.classBuffs[targetClass] or {}
    if (on and true or false) == (not self.DEFAULT_OFF[id]) then on = nil end
    db.classBuffs[targetClass][id] = on
end

-- schemaVer 2 (D33) : la case globale d'avant la grille (db.off[id] = true) devient décochée pour
-- toutes les classes. Rend true si la base a changé.
function B:Migrate(db)
    if type(db) ~= "table" or (db.schemaVer or 1) >= 2 then return false end
    for id, v in pairs(type(db.off) == "table" and db.off or {}) do
        if v then
            for _, class in ipairs(self.CLASSES) do self:SetCell(id, class, false, db) end
        end
    end
    db.off, db.schemaVer = nil, 2
    return true
end

-- Les buffs voulus pour une cible, dans l'ordre : ceux dont la case (buff, classe de la cible) est
-- cochée (D33 ; D23 en fait partie). Paladin : ses bénédictions connues et cochées, dans l'ordre de
-- priorité (D22), marquées EXCLUSIVES : il n'en pose qu'UNE, la première que la cible peut recevoir
-- (une cible trop basse pour la première passe à la suivante : SerialBuffer_Queue.lua).
function B:WantedFor(targetClass, db)
    if self.class == "PALADIN" then
        local out = { exclusive = true }
        for _, key in ipairs(self:Priority(db)) do
            local e = self.blessings and self.blessings[key]
            if e and self:Cell(e.id, targetClass, db) then out[#out + 1] = e end
        end
        return out
    end
    local out = {}
    for _, e in ipairs(self.list or {}) do
        if self:Cell(e.id, targetClass, db) then out[#out + 1] = e end
    end
    return out
end

-- Pour la grille des options : tout le catalogue de la classe, connu ou non, dans l'ordre affiché
-- (le paladin : l'ordre de sa priorité, avec la clé de chaque bénédiction).
function B:Catalog(class, db)
    local ids, keys = {}, {}
    if class == "PALADIN" then
        for _, key in ipairs(self:Priority(db)) do ids[#ids + 1] = self.BLESSINGS[key]; keys[#ids] = key end
    else
        for _, id in ipairs(self.CATALOG[class] or {}) do ids[#ids + 1] = id end
    end
    local out, c = {}, self.client
    for i, id in ipairs(ids) do
        out[#out + 1] = { id = id, key = keys[i], name = c.name(id) or tostring(id), icon = c.icon(id),
                          known = c.known(id) }
    end
    return out
end
