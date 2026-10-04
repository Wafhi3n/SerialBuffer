-- SerialBuffer_Run.lua — LA BOUCLE : événements, rafraîchissement, et le lien entre les modules.
--
-- client (Units) → file (Queue) → tableau (UI). Le tableau ne se recalcule que s'il est VISIBLE : il
-- ne l'est pas en combat (pilote d'état, D12) ni quand le joueur l'a caché (/sbuff). La portée n'a
-- pas d'événement : un minuteur de 0,5 s rafraîchit tant que le tableau se voit.
-- Démarre sur PLAYER_LOGIN (SerialBuffer.lua), quand tous les fichiers du .toc sont chargés.
local _, NS = ...
NS = NS or _G.SerialBuffer
local L = NS.L

local R = {}
NS.Run = R

local TICK = 0.5

-- Ce que la classe sait poser. Une classe à buffs dont AUCUN id n'est reconnu le dit une fois : les
-- ids non paladin sont ceux de vanilla, pas encore vus sur Forever (SerialBuffer_Buffs.lua).
function R:ResolveBuffs()
    local _, class = UnitClass("player")
    if not NS.Buffs:HasCatalog(class) then self.noBuffs = true return end
    local n = NS.Buffs:Resolve(class)
    self.noBuffs = (n == 0)
    if n == 0 and not self.warned then
        self.warned = true
        local ids = {}
        for _, id in ipairs(NS.Buffs.CATALOG[class] or {}) do ids[#ids + 1] = tostring(id) end
        for _, id in pairs(NS.Buffs.BLESSINGS) do if class == "PALADIN" then ids[#ids + 1] = tostring(id) end end
        NS:Printf(L["Aucun de tes buffs n'est reconnu (ids : %s). Préviens l'auteur de l'addon."],
            table.concat(ids, ", "))
    end
end

local function wantedFor(class) return NS.Buffs:WantedFor(class, NS.db) end

function R:Refresh()
    local state = self.noBuffs and "nobuffs" or NS.Units:State()
    if state == "instance" or state == "nobuffs" then
        NS.UI:Render({}, state, 0)
        return
    end
    local rows, around = NS.Queue:Build(NS.Units:Collect(), wantedFor, NS.Units.probe,
        { showPvP = NS.db.showPvP })
    NS.UI:Render(rows, state, around)
end

-- Après un sort ou une erreur : recalcule tout de suite, pour que la touche « buff suivant » vise
-- déjà le joueur d'après (D13). Rien en combat : Render n'y touche à aucun attribut sécurisé.
local function refreshNow()
    if NS.UI:IsVisible() and not InCombatLockdown() then R:Refresh() end
end

local function onEvent(_, event, arg1, arg2)
    if event == "NAME_PLATE_UNIT_ADDED" then NS.Units:PlateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then NS.Units:PlateRemoved(arg1)
    elseif event == "PLAYER_ENTERING_WORLD" then NS.Units:SeedPlates()
    elseif event == "SPELLS_CHANGED" then R:ResolveBuffs()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then refreshNow()
    elseif event == "UI_ERROR_MESSAGE" then
        local msg = (issecretvalue and issecretvalue(arg2)) and nil or arg2
        local guid = NS.Cast:OnError(msg, GetTime())
        if guid then NS.Queue:Requeue(guid); refreshNow() end
    end
end

-- Les boutons sécurisés ne se construisent pas en combat : un /reload en plein combat attend la fin.
function R:Start()
    if InCombatLockdown() then
        local wait = CreateFrame("Frame")
        wait:RegisterEvent("PLAYER_REGEN_ENABLED")
        wait:SetScript("OnEvent", function(f) f:UnregisterAllEvents(); R:Start() end)
        return
    end
    self:ResolveBuffs()
    NS.UI:Build()
    pcall(NS.Options.Register, NS.Options)   -- l'API Settings jamais éprouvée ici : elle ne casse rien
    NS.Units:SeedPlates()
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
                          "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UI_ERROR_MESSAGE" }) do
        f:RegisterEvent(ev)
    end
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    f:SetScript("OnEvent", onEvent)
    self.frame = f
    self.ticker = C_Timer.NewTicker(TICK, function()
        if NS.UI:IsVisible() then R:Refresh() end
    end)
end
