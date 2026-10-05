-- SerialBuffer_Buffs.lua — CE QUE TA CLASSE POSE : le catalogue des buffs longs, et les COLONNES de la
-- grille des options (quel buff, dans quel ordre, pour quelle classe de la cible).
--
-- Spec docs/specs/serial-buffer.md : D4 (toutes les classes à buff), D7 (prêtre, mage, druide posent
-- tous leurs buffs, l'un après l'autre), D22 (le paladin n'en pose qu'UNE : Rois > Sagesse > Puissance
-- par défaut), D23 (un buff de mana ne va jamais à une classe sans mana), D34 (la grille : par classe
-- de la cible, une colonne de rangs, chaque case une icône), D35 (la ligne « Groupe / raid » : un choix
-- unique par classe, vide par défaut).
-- Logique PURE, testée sans client (tests/test_serialbuffer_list.lua) : SerialBuffer_Grid.lua ne fait
-- que dessiner les colonnes et relayer les clics.
-- On garde le RANG 1 de chaque sort : on teste qu'il est connu, puis on travaille par NOM, parce que
-- Forever garde les rangs et qu'une aura porte l'id du rang lancé (sonde, 2026-10-04). Lancer par nom
-- prend le rang le plus haut connu.
--
-- Seuls 19740 et 19742 (paladin) ont été vus sur Forever. Les autres ids sont ceux de vanilla : si
-- aucun n'est reconnu pour ta classe, Buffs:Resolve le dit une fois dans le chat (un id faux se voit
-- au lieu de se taire). 20911 (Sanctuaire) n'a pas de nom sur Forever (relevé du 2026-10-05 09:55) :
-- la grille le laisse de côté.
local _, NS = ...
NS = NS or _G.SerialBuffer

local B = {}
NS.Buffs = B

B.CATALOG = {
    MAGE   = { 1459 },               -- Intelligence des Arcanes
    PRIEST = { 1243, 14752, 976 },   -- Robustesse, Esprit divin, Protection contre l'Ombre
    DRUID  = { 1126, 467 },          -- Marque du fauve, Épines
}

-- Les bénédictions du paladin, par clé stable.
B.BLESSINGS = {
    MIGHT = 19740, WISDOM = 19742, KINGS = 20217,
    SALVATION = 1038, LIGHT = 19977, SANCTUARY = 20911,
}

-- D22 : l'ordre par défaut. Salut, Lumière et Sanctuaire sont dans la grille (choix du user,
-- 2026-10-05) mais dans aucune colonne par défaut (un tank ne veut pas de Salut).
B.PRIORITY_DEFAULT = { "KINGS", "WISDOM", "MIGHT", "SALVATION", "LIGHT", "SANCTUARY" }
B.DEFAULT_OFF = { [1038] = true, [19977] = true, [20911] = true }
B.PALADIN_RANKS = 3   -- D34 : trois choix par classe, comme la maquette validée par le user

-- Les colonnes de la grille, les neuf classes de Forever, dans l'ordre CLASS_SORT_ORDER de Camelot
-- (Blizzard_FrameXMLBase/Camelot/Constants.lua, build 70205). Écrites ici plutôt que lues : si
-- c'était la liste Mainline qui se chargeait, elle porterait treize classes.
B.CLASSES = { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER" }

-- D23 : les buffs de mana, et les classes qui n'en ont pas l'usage.
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
    -- D38 : le rang que le jeu lance pour ce nom (le plus haut connu ; mesuré R1 : « Blessing of
    -- Might » → 19834, rang 2). nil si illisible : la clé retombe sur l'id de rang 1.
    rank = function(name)
        if not (C_Spell and C_Spell.GetSpellInfo) then return nil end
        local ok, info = pcall(C_Spell.GetSpellInfo, name)
        if ok and type(info) == "table" and type(info.spellID) == "number" then return info.spellID end
        return nil
    end,
}

-- ---------------------------------------------------------------- le catalogue

-- Ce que la classe du LANCEUR sait poser, dans l'ordre par défaut.
function B:Ids(caster)
    if caster ~= "PALADIN" then return self.CATALOG[caster] or {} end
    local out = {}
    for _, key in ipairs(self.PRIORITY_DEFAULT) do out[#out + 1] = self.BLESSINGS[key] end
    return out
end

function B:HasCatalog(class)
    return class == "PALADIN" or self.CATALOG[class] ~= nil
end

-- Les classes de lanceur qui ont une grille (la base est commune au compte : une grille chacune).
function B:Casters()
    local out = { "PALADIN" }
    for c in pairs(self.CATALOG) do out[#out + 1] = c end
    table.sort(out)
    return out
end

-- rank : la clé des refus « trop bas » appris (D38), le rang lancé, sinon l'id de rang 1.
local function entry(id)
    local c = B.client
    if not c.known(id) then return nil end
    local name = c.name(id)
    if type(name) ~= "string" or name == "" then return nil end
    return { id = id, name = name, icon = c.icon(id), rank = (c.rank and c.rank(name)) or id }
end

-- Le buff connu de ce nom, ou nil (Run : relier un clic à son rang).
function B:ByName(name)
    for _, e in pairs(self.known or {}) do
        if e.name == name then return e end
    end
    return nil
end

-- Lit ce que le personnage connaît (self.known : id → buff). Rend le nombre de buffs reconnus.
function B:Resolve(class)
    self.class, self.known = class, {}
    local n = 0
    for _, id in ipairs(self:Ids(class)) do
        local e = entry(id)
        if e then self.known[id] = e; n = n + 1 end
    end
    return n
end

-- D23 : un buff jamais proposé à cette classe de cible.
function B:Locked(id, targetClass)
    return (self.MANA_BUFFS[id] and self.NO_MANA[targetClass]) and true or false
end

-- ---------------------------------------------------------------- les colonnes (D34)

-- Rangs d'une colonne : trois pour le paladin, un par buff pour les autres.
function B:Ranks(caster)
    if caster == "PALADIN" then return self.PALADIN_RANKS end
    return #(self.CATALOG[caster] or {})
end

local function owns(caster, id)
    for _, x in ipairs(B:Ids(caster)) do if x == id then return true end end
    return false
end

-- Une colonne propre : autant de rangs que Ranks, 0 pour une case vide ; un id étranger au lanceur,
-- interdit à la cible (D23) ou déjà pris plus haut devient 0.
local function clean(caster, t, list)
    local out, seen = {}, {}
    for i = 1, B:Ranks(caster) do
        local id = type(list) == "table" and list[i] or 0
        if type(id) ~= "number" or seen[id] or not owns(caster, id) or B:Locked(id, t) then id = 0 end
        if id ~= 0 then seen[id] = true end
        out[i] = id
    end
    return out
end

local function same(a, b)
    for i = 1, math.max(#a, #b) do if a[i] ~= b[i] then return false end end
    return true
end

-- db[field][caster], créé à la demande.
local function bucket(db, field, caster, create)
    if type(db) ~= "table" then return nil end
    if type(db[field]) ~= "table" then
        if not create then return nil end
        db[field] = {}
    end
    if type(db[field][caster]) ~= "table" then
        if not create then return nil end
        db[field][caster] = {}
    end
    return db[field][caster]
end

-- La colonne par défaut : l'ordre du catalogue, sans les buffs écartés d'office ni ceux de D23.
function B:DefaultOrder(caster, t)
    local out = {}
    for _, id in ipairs(self:Ids(caster)) do
        if #out < self:Ranks(caster) and not self.DEFAULT_OFF[id] and not self:Locked(id, t) then
            out[#out + 1] = id
        end
    end
    return clean(caster, t, out)
end

function B:Order(caster, t, db)
    local s = bucket(db, "orders", caster)
    if s and t and s[t] then return clean(caster, t, s[t]) end
    return self:DefaultOrder(caster, t)
end

-- Seul un écart au défaut est gardé.
function B:SetOrder(caster, t, list, db)
    if not (db and t) then return end
    list = clean(caster, t, list)
    if same(list, self:DefaultOrder(caster, t)) then
        local s = bucket(db, "orders", caster)
        if s then s[t] = nil end
    else
        bucket(db, "orders", caster, true)[t] = list
    end
end

-- D35 : le choix unique de la ligne « Groupe / raid » (0 = vide : la colonne s'applique).
function B:GroupPick(caster, t, db)
    local s = bucket(db, "groupPick", caster)
    local id = s and t and s[t]
    if type(id) == "number" and owns(caster, id) and not self:Locked(id, t) then return id end
    return 0
end

function B:SetGroupPick(caster, t, id, db)
    if not (db and t) then return end
    local ok = type(id) == "number" and owns(caster, id) and not self:Locked(id, t)
    if ok then bucket(db, "groupPick", caster, true)[t] = id
    else
        local s = bucket(db, "groupPick", caster)
        if s then s[t] = nil end
    end
end

-- Les valeurs d'une case, dans l'ordre du cycle : vide, puis les buffs du lanceur que le client sait
-- nommer, ni interdits à la cible (D23) ni pris à un AUTRE rang de la colonne. t = nil : la colonne
-- « Toutes », sans interdit. column = nil : une case seule (D35).
function B:Choices(caster, t, column, rank)
    local used = {}
    for i, id in ipairs(column or {}) do
        if i ~= rank and id ~= 0 then used[id] = true end
    end
    local out = { 0 }
    for _, id in ipairs(self:Ids(caster)) do
        if not used[id] and not self:Locked(id, t) and self.client.name(id) then out[#out + 1] = id end
    end
    return out
end

-- La valeur d'après (delta = 1) ou d'avant (-1) dans le cycle ; une valeur absente repart du début.
function B:Cycle(choices, v, delta)
    local i = 1
    for k, x in ipairs(choices) do if x == v then i = k end end
    return choices[(i - 1 + delta) % #choices + 1]
end

-- Une copie de la colonne où la case `rank` a avancé d'un cran.
function B:StepColumn(caster, t, column, rank, delta)
    local out = {}
    for i, v in ipairs(column) do out[i] = v end
    out[rank] = self:Cycle(self:Choices(caster, t, column, rank), column[rank] or 0, delta)
    return out
end

-- Remplir (D34) : met id au rang `rank` dans la colonne de chaque classe. Une classe à qui ce buff est
-- interdit (D23) garde sa case ; un id déjà à un autre rang de la colonne échange sa place.
function B:Fill(caster, rank, id, db)
    for _, t in ipairs(self.CLASSES) do
        if not self:Locked(id, t) then
            local col = self:Order(caster, t, db)
            if id ~= 0 then
                for j, x in ipairs(col) do
                    if j ~= rank and x == id then col[j] = col[rank] end
                end
            end
            col[rank] = id
            self:SetOrder(caster, t, col, db)
        end
    end
end

function B:FillGroup(caster, id, db)
    for _, t in ipairs(self.CLASSES) do
        if not self:Locked(id, t) then self:SetGroupPick(caster, t, id, db) end
    end
end

-- ↺ sous une classe : sa colonne et sa case du groupe reviennent au défaut. « Tout par défaut » :
-- toutes les colonnes du LANCEUR (pas celles des autres classes du compte).
function B:ResetClass(caster, t, db)
    for _, field in ipairs({ "orders", "groupPick" }) do
        local s = bucket(db, field, caster)
        if s then s[t] = nil end
    end
end

function B:ResetAll(caster, db)
    for _, field in ipairs({ "orders", "groupPick" }) do
        if type(db[field]) == "table" then db[field][caster] = nil end
    end
end

-- ---------------------------------------------------------------- ce que la file demande

-- Les buffs voulus pour une cible, dans l'ordre de sa colonne. Le paladin n'en pose qu'UNE : la liste
-- est EXCLUSIVE, la file prend la première que la cible peut recevoir (D24, D27, D38).
-- Un membre du groupe prend d'abord le choix unique de la ligne « Groupe / raid » s'il est rempli et
-- appris (D35), puis la colonne en repli (D37) ; la liste est alors marquée SINGLE : pour un lanceur
-- non paladin, le choix unique présent vaut « servi », la colonne ne sert que s'il ne peut pas passer.
function B:WantedFor(targetClass, db, inGroup)
    local c = self.class
    local out = { exclusive = (c == "PALADIN") or nil }
    local pick = inGroup and self:GroupPick(c, targetClass, db) or 0
    local ids = self:Order(c, targetClass, db)
    if pick ~= 0 and self.known and self.known[pick] then
        local col = ids
        ids, out.single = { pick }, true
        for _, id in ipairs(col) do
            if id ~= pick then ids[#ids + 1] = id end
        end
    end
    for _, id in ipairs(ids) do
        local e = id ~= 0 and self.known and self.known[id]
        if e then out[#out + 1] = e end
    end
    return out
end

-- ---------------------------------------------------------------- migration (schemaVer 3)

-- Ce que voulaient les réglages d'avant : la v0.1.0 (off[id] = décoché partout, priority = ordre du
-- paladin) et la grille D33 (classBuffs[cible][id] = coché ou non).
local function legacyOn(id, t, db)
    if B:Locked(id, t) then return false end
    local cb = type(db.classBuffs) == "table" and db.classBuffs[t]
    if type(cb) == "table" and cb[id] ~= nil then return cb[id] and true or false end
    if type(db.off) == "table" and db.off[id] then return false end
    return not B.DEFAULT_OFF[id]
end

local function legacyIds(caster, db)
    if caster ~= "PALADIN" then return B.CATALOG[caster] end
    local out, seen = {}, {}
    for _, key in ipairs(type(db.priority) == "table" and db.priority or {}) do
        if B.BLESSINGS[key] and not seen[key] then out[#out + 1] = B.BLESSINGS[key]; seen[key] = true end
    end
    for _, key in ipairs(B.PRIORITY_DEFAULT) do
        if not seen[key] then out[#out + 1] = B.BLESSINGS[key] end
    end
    return out
end

-- Chaque classe de lanceur reçoit les colonnes équivalentes (les ids sont fixes : nul besoin de
-- savoir qui se connecte). Rend true si la base a changé.
function B:Migrate(db)
    if type(db) ~= "table" or (db.schemaVer or 1) >= 3 then return false end
    for _, c in ipairs(self:Casters()) do
        for _, t in ipairs(self.CLASSES) do
            local list = {}
            for _, id in ipairs(legacyIds(c, db)) do
                if #list < self:Ranks(c) and legacyOn(id, t, db) then list[#list + 1] = id end
            end
            self:SetOrder(c, t, list, db)
        end
    end
    db.off, db.classBuffs, db.priority, db.schemaVer = nil, nil, nil, 3
    return true
end
