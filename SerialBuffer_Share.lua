-- SerialBuffer_Share.lua — LA RÉPARTITION entre paladins du groupe (coordination, palier 2, C4).
--
-- Spec docs/specs/coordination.md, « Palier 2 » : le plus ancien dans le groupe garde sa
-- bénédiction ; chaque paladin plus récent prend, dans SES préférences pour le groupe, la première
-- qu'aucun plus ancien n'a annoncée pour cette classe. « Plus ancien » : l'heure du serveur à
-- laquelle il est entré dans le groupe (annoncée), puis l'ordre des noms à égalité ; une heure
-- absente (client du palier 1) compte comme la plus ancienne. Tous les clients ont les mêmes
-- chiffres : ils tranchent pareil.
-- Logique PURE (tests/test_serialbuffer_comm.lua) : SerialBuffer_Comm.lua la branche sur Buffs.taken.
local _, NS = ...
NS = NS or _G.SerialBuffer

local S = {}
NS.Share = S

-- a passe-t-il devant b ? a, b = { since = heure d'arrivée ou nil, name = nom complet }.
function S.Senior(a, b)
    local sa, sb = a.since or 0, b.since or 0
    if sa ~= sb then return sa < sb end
    return (a.name or "") < (b.name or "")
end

-- Les bénédictions que les paladins plus anciens que me ont annoncées pour cette classe : un
-- ensemble id → true. peers : nom complet → { caster, plan, since } (SerialBuffer_Comm.lua).
function S.Taken(peers, me, targetClass)
    local taken = {}
    for name, p in pairs(peers or {}) do
        if p.caster == "PALADIN" and S.Senior({ since = p.since, name = name }, me) then
            local ids = p.plan and p.plan[targetClass]
            if ids and ids[1] then taken[ids[1]] = true end
        end
    end
    return taken
end

-- Combien de paladins du groupe passent devant me, et combien derrière (diagnostic).
function S.Rank(peers, me)
    local before, after = 0, 0
    for name, p in pairs(peers or {}) do
        if p.caster == "PALADIN" then
            if S.Senior({ since = p.since, name = name }, me) then before = before + 1 else after = after + 1 end
        end
    end
    return before, after
end
