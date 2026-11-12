-- SerialBuffer_Rangs.lua — LES RANGS d'un buff, pour le poser quand même à un joueur trop bas (D54).
--
-- Lancé par son nom, un sort part à son plus haut rang connu, et le jeu le refuse « Target is too low
-- level » à une cible trop basse pour CE rang (règle de vanilla : un rang appris au niveau 22 veut une
-- cible de niveau 12 ou plus ; jamais mesurée au niveau près sur Forever). Un paladin de niveau 30+ ne
-- posait donc plus ni Puissance ni Sagesse aux niveaux 10-12 : D38 apprenait le refus et la ligne
-- sortait (commentaire CurseForge relayé par le user le 2026-11-12). D54 : la ligne repasse au rang
-- inférieur connu du MÊME buff avant de changer de buff (SerialBuffer_Queue.lua, pickRank). Chaque
-- rang a son propre seuil appris (D38, db.tooLow[id du rang]) : aucun niveau codé en dur.
--
-- Le plus haut rang se lance comme avant, par le nom seul ; sa clé reste entry.rank (Buffs), pour que
-- les seuils déjà appris gardent leur sens. Un rang inférieur se lance par « Nom(Rang N) », le
-- sous-texte venant du client (C_Spell.GetSpellSubtext), donc dans sa langue. Sous-texte vide (donnée
-- pas encore chargée) : ce rang est sauté, il revient au prochain SPELLS_CHANGED.
-- Les ids : tables du client Forever (SpellName, Spell.NameSubtext_lang, SpellLevels ; wago.tools,
-- build 1.60.1.70888, lues le 2026-11-12), rang 1 en tête, niveau d'apprentissage en commentaire. Un
-- sort à un seul rang (Rois, Respiration interminable, Marche sur l'eau…) n'a pas de liste : rien ne
-- change pour lui. 132 double B.RANK_IDS (D46), qui ne sert qu'à trouver les noms de ses rangs.
local _, NS = ...
NS = NS or _G.SerialBuffer

local RK = {}
NS.Ranks = RK

RK.IDS = {
    [19740] = { 19740, 19834, 19835, 19836, 19837, 19838, 25291 },   -- Puissance : 4 12 22 32 42 52 60
    [19742] = { 19742, 19850, 19852, 19853, 19854, 25290 },          -- Sagesse : 14 24 34 44 54 60
    [1459]  = { 1459, 1460, 1461, 10156, 10157 },                    -- Intelligence des Arcanes : 1 14 28 42 56
    [1243]  = { 1243, 1244, 1245, 2791, 10937, 10938 },              -- Robustesse : 1 12 24 36 48 60
    [14752] = { 14752, 14818, 14819, 27841 },                        -- Esprit divin : 30 40 50 60
    [976]   = { 976, 10957, 10958 },                                 -- Protection contre l'Ombre : 30 42 56
    [1126]  = { 1126, 5232, 6756, 5234, 8907, 9884, 9885 },          -- Marque du fauve : 1 10 20 30 40 50 60
    [467]   = { 467, 782, 1075, 8914, 9756, 9910 },                  -- Épines : 6 14 24 34 44 54
    [132]   = { 132, 2970, 11743 },                                  -- Détection de l'invisibilité : 26 38 50
}

-- Le client, remplaçable par un test headless.
RK.client = {
    known = function(id) return NS.Buffs.client.known(id) end,
    name = function(id) return NS.Buffs.client.name(id) end,
    subtext = function(id)
        if not (C_Spell and C_Spell.GetSpellSubtext) then return nil end
        local ok, s = pcall(C_Spell.GetSpellSubtext, id)
        if not ok or (issecretvalue and issecretvalue(s)) then return nil end
        return s
    end,
}

-- Les rangs à essayer pour ce buff, du plus haut au plus bas : { id = clé de D38, cast = ce que la
-- macro lance }. Le premier est le nom seul (le plus haut rang connu, clé entry.rank).
function RK.List(e)
    local out = { { id = e.rank or e.id, cast = e.name } }
    local ids, c = RK.IDS[e.id], RK.client
    if not ids then return out end
    local top = 0
    for i, id in ipairs(ids) do if c.known(id) then top = i end end
    for i = top - 1, 1, -1 do
        local id = ids[i]
        local name, sub = c.known(id) and c.name(id), c.subtext(id)
        if id ~= out[1].id and type(name) == "string" and name ~= "" and type(sub) == "string" and sub ~= "" then
            out[#out + 1] = { id = id, cast = name .. "(" .. sub .. ")" }
        end
    end
    return out
end

-- Après Buffs:Resolve (Run, à chaque SPELLS_CHANGED : un rang neuf appris change la liste).
function RK:Attach(known)
    for _, e in pairs(known or {}) do e.ranks = RK.List(e) end
end
