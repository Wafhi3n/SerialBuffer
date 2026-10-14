-- SerialBuffer_Units.lua — CE QU'ON LIT DU CLIENT : les joueurs autour, leurs buffs, leur portée.
--
-- Faits mesurés sur Forever (build 70205, sonde du 2026-10-04 ; skill public wow-forever-api,
-- « Nameplates » de taint-and-protected-frames.md) :
--   - on VOIT les inconnus par leurs plaques amies : nom, portée et auras se lisent sur « nameplateN » ;
--   - on ne LANCE jamais un sort sur ce jeton : le jeu l'ignore en silence (palier b : macro au nom) ;
--   - le nom complet est « Prénom Nom » avec une espace (GetUnitName(u, true)) ;
--   - les rangs existent : une aura se lit PAR NOM, sinon un autre rang passe inaperçu.
-- Toute valeur secrète est écartée au plus près de l'appel, comme un appel qui lève une erreur : une
-- unité illisible n'entre pas, une aura illisible n'est jamais « absente ». Une aura que le JEU cache
-- (match PvP, rencontre de boss) est « hidden » : la file se fie alors à nos propres sorts (D52).
-- Rien de ce qui est lu ici n'est sauvegardé (spec, Contrat).
local _, NS = ...
NS = NS or _G.SerialBuffer

-- stats : qui a posé les buffs lus (moi / un autre / illisible), et les lectures cachées par le jeu
-- (D52), pour db.diag ; aucun nom de joueur. forceHidden : /sbuff aveugle, pour la séance seulement.
local U = { plates = {}, stats = { me = 0, other = 0, unknown = 0, hidden = 0 }, forceHidden = false }
NS.Units = U

local function sec(v) return issecretvalue ~= nil and issecretvalue(v) end
local function plain(v) if sec(v) then return nil end return v end

-- Les jetons de plaque vivants, tenus par NAME_PLATE_UNIT_ADDED / _REMOVED (SerialBuffer_Run.lua).
function U:PlateAdded(unit) if type(unit) == "string" then self.plates[unit] = true end end
function U:PlateRemoved(unit) if type(unit) == "string" then self.plates[unit] = nil end end

function U:SeedPlates()
    self.plates = {}
    local ok, list = pcall(C_NamePlate.GetNamePlates)
    if not ok or type(list) ~= "table" then return end
    for _, plate in ipairs(list) do
        local unit = plate.unitToken or plate.namePlateUnitToken
        if type(unit) == "string" then self.plates[unit] = true end
    end
end

local function fullName(unit)
    local ok, n = pcall(GetUnitName, unit, true)
    if ok and not sec(n) and type(n) == "string" and n ~= "" then return n end
    return nil
end

-- L'instantané d'une unité, ou nil. Le GUID est la clé de la file : secret ou absent, l'unité sort.
local function snapshot(unit, group)
    if not UnitExists(unit) then return nil end
    local guid = UnitGUID(unit)
    if not guid or sec(guid) then return nil end
    local _, class = UnitClass(unit)
    return {
        unit = unit, guid = guid, name = fullName(unit), class = plain(class),
        player = plain(UnitIsPlayer(unit)), assist = plain(UnitCanAssist("player", unit)),
        dead = plain(UnitIsDeadOrGhost(unit)), combat = plain(UnitAffectingCombat(unit)),
        pvp = plain(UnitIsPVP(unit)), visible = plain(UnitIsVisible(unit)), level = plain(UnitLevel(unit)),
        group = group, self = (unit == "player"),
        tank = NS.Tank and NS.Tank:Is(unit, group) or false,   -- D44 : le rôle donné par le jeu
    }
end

local function add(out, unit, group)
    local ok, s = pcall(snapshot, unit, group)
    if ok and s then out[#out + 1] = s end
end

-- "raid", "party", ou nil si tu es seul : le titre de la partie du groupe dans le tableau (D30).
function U:GroupKind()
    if IsInRaid() then return "raid" end
    if IsInGroup() then return "party" end
    return nil
end

-- Toi, ton groupe ou ton raid, puis les plaques (withPlates : jamais en instance, D31 ; elles y sont
-- interdites). La file dédoublonne par GUID : un membre du groupe vu aussi par sa plaque garde son
-- jeton de groupe, arrivé le premier ; toi, ton « raidN » est écarté par ton « player ».
-- Toi : membre du groupe seulement si tu es groupé (D30) ; seul, tu gardes ta place d'arrivée (D8).
function U:Collect(withPlates)
    local out = {}
    add(out, "player", self:GroupKind() ~= nil)
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do add(out, "raid" .. i, true) end
    else
        for i = 1, GetNumSubgroupMembers() do add(out, "party" .. i, true) end
    end
    if withPlates then
        for unit in pairs(self.plates) do add(out, unit, false) end
    end
    return out
end

-- D52 : un mort perd ses buffs. fn(guid) pour toi et chaque membre du groupe ou du raid mort ou
-- fantôme. Appelé à chaque tic du combat (SerialBuffer_Run.lua) : le tableau y est figé, mais un allié
-- meurt et revient pendant qu'on se bat. Un GUID ou un état secret : on ne sait pas, rien n'est dit.
local function deadGuid(unit)
    if not UnitExists(unit) or not plain(UnitIsDeadOrGhost(unit)) then return nil end
    return plain(UnitGUID(unit))
end

function U:Deaths(fn)
    local units = { "player" }
    local raid = IsInRaid()
    local n = raid and GetNumGroupMembers() or GetNumSubgroupMembers()
    for i = 1, n do units[#units + 1] = (raid and "raid" or "party") .. i end
    for _, unit in ipairs(units) do
        local ok, guid = pcall(deadGuid, unit)
        if ok and guid then fn(guid) end
    end
end

-- Les deux sondes de la file (SerialBuffer_Queue.lua).
U.probe = {}

-- L'aura vient-elle de moi ? true, false, ou nil = illisible. Exactement comme Blizzard
-- (AuraUtil.lua) : « (sourceUnit ~= nil) and UnitIsUnit("player", sourceUnit) or false ». Mes propres
-- auras portent toujours sourceUnit ; sans lui, le lanceur n'est pas moi.
-- PAS isFromPlayerOrPlayerPet : il veut dire « posé par UN joueur », pas « par moi ». Mesuré le
-- 2026-10-04 (db.diag, foule de la banque d'Ironforge) : avec lui en secours, 2197 lectures sur 2197
-- passaient pour les miennes, et D27 ne pouvait jamais jouer.
local function fromMe(a)
    local src = a.sourceUnit
    if src == nil then return false end
    if sec(src) then return nil end
    local ok, same = pcall(UnitIsUnit, "player", src)
    if not ok or sec(same) then return nil end
    return same and true or false
end

-- La durée totale de l'aura (D45 : un buff court a son seuil), ou nil si illisible.
local function duration(a)
    local d = a.duration
    if sec(d) or type(d) ~= "number" or d <= 0 then return nil end
    return d
end

local function plainCall(f, ...)
    if not f then return nil end
    local ok, v, w = pcall(f, ...)
    if not ok then return nil end
    return plain(v), plain(w)
end

-- Sous restriction, même hors combat, la lecture d'une aura ne rend RIEN, sans erreur (doc du jeu :
-- RequiresNonSecretAura ; SecretWhenUnitAuraRestricted : combat, rencontre, mythique+, match PvP).
-- Ce rien n'est pas « absente » (règle de sûreté, SerialBuffer_Queue.lua) : D52 le dit « caché ».
-- Trois signes, un seul suffit : ShouldAurasBeSecret ; la restriction « match PvP » active ; un champ
-- de bataille ou une arène. Le dernier est un filet : un joueur l'a vu en champ de bataille
-- (CurseForge, 2026-10-14, « it doesn't register the buff on yourself or allys ») sans qu'on sache
-- lequel des deux premiers le dit (ses relevés SB1 / SB3 sont attendus). Mesuré le 2026-10-11
-- (1.60.1.70338) : ShouldAurasBeSecret rend false en ville et en donjon hors combat.
local PVP_MATCH = (Enum and Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.PvPMatch) or 3

function U:AurasHidden()
    if self.forceHidden then return true end
    if plainCall(C_Secrets and C_Secrets.ShouldAurasBeSecret) == true then return true end
    local state = plainCall(C_RestrictedActions and C_RestrictedActions.GetAddOnRestrictionState, PVP_MATCH)
    if type(state) == "number" and state > 0 then return true end
    local _, kind = plainCall(IsInInstance)
    return kind == "pvp" or kind == "arena"
end

-- "absent", "hidden" (le jeu cache les auras, D52), ou les secondes restantes (math.huge : sans fin),
-- « est-ce la mienne » et la durée totale ; nil = illisible. /sbuff aveugle (U.forceHidden) rend
-- "hidden" sans rien lire : tout passe par nos propres sorts, comme en champ de bataille.
function U.probe.aura(unit, buffName)
    if U.forceHidden then U.stats.hidden = U.stats.hidden + 1; return "hidden" end
    local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, buffName, "HELPFUL")
    if not ok or sec(a) then return nil end
    if issecrettable and issecrettable(a) then return nil end
    if a == nil then
        if not U:AurasHidden() then return "absent" end
        U.stats.hidden = U.stats.hidden + 1
        return "hidden"
    end
    local e = a.expirationTime
    if sec(e) then return nil end
    local mine = fromMe(a)
    local st = U.stats
    if mine == true then st.me = st.me + 1 elseif mine == false then st.other = st.other + 1
    else st.unknown = st.unknown + 1 end
    if type(e) ~= "number" or e <= 0 then return math.huge, mine end
    return math.max(0, e - GetTime()), mine, duration(a)
end

-- true, false, ou nil = inconnu.
function U.probe.range(unit, buffName)
    local ok, r = pcall(C_Spell.IsSpellInRange, buffName, unit)
    if not ok or sec(r) then return nil end
    return r
end

-- "instance" : seuls toi et ton groupe ou ton raid (D31 ; plaques interdites, noms parfois secrets).
-- "noplates" : les plaques des joueurs amis sont coupées, seuls toi et ton groupe sont vus. "ok" sinon.
function U:State()
    local inside = IsInInstance()
    if inside then return "instance" end
    local get = (C_CVar and C_CVar.GetCVar) or GetCVar
    if get and get("nameplateShowFriendlyPlayers") == "0" then return "noplates" end
    return "ok"
end
