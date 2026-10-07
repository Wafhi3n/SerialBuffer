-- SerialBuffer_Run.lua — LA BOUCLE : événements, rafraîchissement, et le lien entre les modules.
--
-- client (Units) → file (Queue) → tableau (UI). Le tableau ne se recalcule que s'il est VISIBLE (pas
-- caché par /sbuff) et HORS COMBAT : en combat il reste affiché mais figé (D36), ses lignes se grisent
-- au fil de nos sorts, et il se recalcule à la sortie. La portée n'a pas d'événement : un minuteur de
-- 0,5 s rafraîchit tant que le tableau se voit.
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
    if NS.Comm.frame then NS.Comm:Announce() end   -- coordination : ce que tu connais a pu changer
end

local function wantedFor(class, inGroup) return NS.Buffs:WantedFor(class, NS.db, inGroup) end

-- En instance, la liste ne lit que toi et ton groupe ou ton raid (D31) : pas de plaques. Dehors aussi
-- quand la case « Groupe seul » est cochée (D40, état « grouponly »).
-- Jamais en combat (D36, tableau figé) : rien n'est relu, et la file garde l'ordre d'avant le pull
-- (sinon D16 écarterait chaque joueur en combat, qui reviendrait en fin de file après).
function R:Refresh()
    if InCombatLockdown() then return end
    if self.noBuffs then
        NS.UI:Render({}, { state = "nobuffs", around = 0, unread = 0 })
        return
    end
    local state = NS.Units:State()
    if state ~= "instance" and NS.db.groupOnly then state = "grouponly" end
    local withPlates = state ~= "instance" and state ~= "grouponly"
    local rows, around, unread = NS.Queue:Build(NS.Units:Collect(withPlates), wantedFor,
        NS.Units.probe, { showPvP = NS.db.showPvP, now = GetTime(), refreshBelow = (NS.db.refreshMin or 45) * 60,
                          tooLow = NS.db.tooLow })
    NS.UI:Render(rows, { state = state, around = around, unread = unread, group = NS.Units:GroupKind() })
end

-- Après un sort ou une erreur : recalcule tout de suite, pour que la touche « buff suivant » vise
-- déjà le joueur d'après (D13). Rien en combat : Render n'y touche à aucun attribut sécurisé.
local function refreshNow()
    if NS.UI:IsVisible() and not InCombatLockdown() then R:Refresh() end
end

local function onEvent(_, event, arg1, arg2, arg3)
    if event == "NAME_PLATE_UNIT_ADDED" then NS.Units:PlateAdded(arg1)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then NS.Units:PlateRemoved(arg1)
    elseif event == "PLAYER_ENTERING_WORLD" then NS.Units:SeedPlates()
    elseif event == "SPELLS_CHANGED" then R:ResolveBuffs()
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then R:OnCast(arg3); refreshNow()
    elseif event == "UI_ERROR_MESSAGE" then R:OnError(arg1, arg2)
    elseif event == "PLAYER_REGEN_DISABLED" then NS.UI:CombatStart()          -- D36 : le tableau se fige
    elseif event == "PLAYER_REGEN_ENABLED" then refreshNow()                    -- D36 : il se recalcule
    elseif event == "GROUP_ROSTER_UPDATE" then
        if InCombatLockdown() then NS.UI:MarkStale() else refreshNow() end    -- jetons de groupe à jour
    end
end

local function plainString(v)
    if issecretvalue and issecretvalue(v) then return nil end
    return type(v) == "string" and v or nil
end

-- Une erreur du jeu juste après un de nos clics : trop bas (D24) ou cible (fin de file). Son NOM
-- (GetGameMessageInfo) est noté dans db.seenErrors : pas une donnée de joueur, juste ce que le client
-- appelle ainsi, pour vérifier après coup les noms qu'on attend.
function R:OnError(errorType, message)
    if not NS.Cast:Recent(GetTime()) then return end   -- pas juste après un de nos clics
    local okName, name = pcall(GetGameMessageInfo, errorType)
    name = okName and plainString(name) or nil
    local msg = plainString(message)
    if name then
        NS.db.seenErrors = NS.db.seenErrors or {}
        NS.db.seenErrors[name] = msg or true
    end
    local kind, click = NS.Cast:OnError(name, msg, GetTime())
    if kind == "lowlevel" then
        NS.Queue:TooLow(click.guid, click.buff, click.level)          -- D24 : ce joueur, cette séance
        local e = NS.Buffs:ByName(click.buff)
        NS.Queue.LearnLow(NS.db, e and e.rank, click.level)           -- D38 : ce rang, pour tous, gardé
    elseif kind == "stronger" then NS.Queue:Stronger(click.guid, click.buff, GetTime())
    elseif kind == "target" then NS.Queue:Requeue(click.guid) end
    if kind then refreshNow() end
end

-- Un de NOS clics vient de réussir (même sort, dans la fenêtre du clic) : la file retient que ce buff
-- sur ce joueur est le mien (garde-fou de D27).
function R:OnCast(spellID)
    local click = NS.Cast:Recent(GetTime())
    if not click or not click.buff or (issecretvalue and issecretvalue(spellID)) then return end
    local name = C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
    if name == click.buff then
        NS.Queue:Cast(click.guid, click.buff, GetTime())
        local e = NS.Buffs:ByName(click.buff)
        NS.Queue.LearnOk(NS.db, e and e.rank, click.level)            -- D38 : un seuil faux se corrige
        if InCombatLockdown() then NS.UI:MarkDone(click.guid) end   -- D36 : la ligne se grise
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
    -- Diagnostic de la session (D27 non mesuré) : relu dans les SavedVariables après un /reload.
    -- comm : les messages de la coordination (envoyés, reçus, écartés), des comptes, aucun nom.
    NS.db.diag = { aura = NS.Units.stats, queue = NS.Queue.stats, comm = NS.Comm.stats,
                   since = date("%Y-%m-%d %H:%M") }
    NS.UI:Build()
    pcall(NS.Options.Register, NS.Options)   -- l'API Settings jamais éprouvée ici : elle ne casse rien
    NS.Units:SeedPlates()
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED",
                          "PLAYER_ENTERING_WORLD", "SPELLS_CHANGED", "UI_ERROR_MESSAGE",
                          "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "GROUP_ROSTER_UPDATE" }) do
        f:RegisterEvent(ev)
    end
    f:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    f:SetScript("OnEvent", onEvent)
    self.frame = f
    NS.Comm:Start()   -- coordination, palier 1 : annoncer et recevoir dans le groupe
    -- Hors combat : recalcul. En combat (D36, tableau figé) : seul le temps restant descend (D39).
    self.ticker = C_Timer.NewTicker(TICK, function()
        if not NS.UI:IsVisible() then return end
        if InCombatLockdown() then NS.UI:CombatTick(GetTime()) else R:Refresh() end
    end)
end
