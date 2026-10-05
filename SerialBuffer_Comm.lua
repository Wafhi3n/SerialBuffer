-- SerialBuffer_Comm.lua — LA COORDINATION, palier 1 : annoncer au groupe ce que tu poses, et recevoir
-- ce que posent les autres Serial Buffer du groupe (docs/specs/coordination.md).
--
-- Rien ici ne change ce que ton tableau propose : on annonce et on montre (options, sous la grille).
-- Mesuré sur Forever (spec, relevés R1 à R1 ter, 2026-10-05) : un message d'addon en PARTY arrive
-- au groupe, et en raid à ton seul sous-groupe ; RAID traverse les sous-groupes. L'expéditeur arrive
-- au nom complet « Prénom Nom ». D'où : RAID en raid, PARTY en groupe, jamais seul.
-- Prudences :
--   - en combat de boss, le verrou Chat rend secrets le texte et l'expéditeur de CHAT_MSG_* (skill
--     public wow-forever-api) : toute valeur secrète est jetée avant d'être comparée ou indexée ;
--   - un expéditeur se relie à un membre par la table nom complet → jeton, refaite au changement du
--     groupe : ton propre écho et les inconnus sont écartés sans comparer les noms à la main ;
--   - seul un lanceur qui a des buffs parle (un guerrier avec l'addon ne répond pas aux demandes) ;
--   - un envoi pendant un verrou de messagerie attend ; rien n'est sauvegardé du réseau (aucun nom).
local _, NS = ...
NS = NS or _G.SerialBuffer

local C = { peers = {}, roster = {}, wantA = false, wantR = false, forceA = false,
            stats = { sent = 0, recv = 0, self = 0, stranger = 0, bad = 0, secret = 0, deferred = 0, refused = 0 } }
NS.Comm = C

C.PREFIX, C.VERSION, C.MAX_BYTES = "SBUF", "1", 255
-- L'ordre des neuf entrées d'une annonce, FIGÉ par le contrat v1 (spec) : jamais lu dans la grille,
-- qu'un réordonnancement de l'affichage ne change pas ce qui circule.
C.WIRE_CLASSES = { "WARRIOR", "PALADIN", "PRIEST", "SHAMAN", "DRUID", "ROGUE", "MAGE", "WARLOCK", "HUNTER" }
C.DEBOUNCE, C.JITTER, C.RETRY = 2, 2, 5   -- secondes : regrouper, étaler les réponses, réessayer

local function sec(v) return issecretvalue ~= nil and issecretvalue(v) end

-- ---------------------------------------------------------------- le codec (pur)

-- « 1|A|PALADIN|20217|0|1243+976|…|<since> » : la classe du lanceur, ses neuf entrées (plan[classe]
-- = ids) et, ajout du palier 2 compatible v1, l'heure du serveur de son arrivée dans le groupe.
function C.Encode(caster, plan, since)
    local parts = { C.VERSION, "A", caster }
    for _, cl in ipairs(C.WIRE_CLASSES) do
        local ids, s = plan and plan[cl], {}
        for i, id in ipairs(ids or {}) do s[i] = tostring(id) end
        parts[#parts + 1] = (#s > 0) and table.concat(s, "+") or "0"
    end
    if type(since) == "number" then parts[#parts + 1] = tostring(math.floor(since)) end
    return table.concat(parts, "|")
end

function C.Request() return C.VERSION .. "|R" end

local function decodeIds(e)
    local ids = {}
    if e == "0" then return ids end
    for tok in (e .. "+"):gmatch("([^+]*)%+") do
        if tok == "" or tok:find("%D") then return nil end
        ids[#ids + 1] = tonumber(tok)
    end
    return ids
end

-- { kind = "R" } ou { kind = "A", caster, plan } ; nil pour tout ce qui n'est pas la version 1 bien
-- formée (trop long, autre version, autre sorte, moins de neuf entrées, id non numérique). Un champ
-- en trop est ignoré.
function C.Decode(msg)
    if type(msg) ~= "string" or #msg > C.MAX_BYTES then return nil end
    local f = {}
    for field in (msg .. "|"):gmatch("([^|]*)|") do f[#f + 1] = field end
    if f[1] ~= C.VERSION then return nil end
    if f[2] == "R" then return { kind = "R" } end
    if f[2] ~= "A" or type(f[3]) ~= "string" or not f[3]:match("^%u+$") then return nil end
    if #f < 3 + #C.WIRE_CLASSES then return nil end
    local plan = {}
    for i, cl in ipairs(C.WIRE_CLASSES) do
        local ids = decodeIds(f[3 + i])
        if not ids then return nil end
        plan[cl] = ids
    end
    -- Palier 2 : l'heure d'arrivée, chiffres seulement ; absente ou mal formée : 0, le plus ancien.
    local s = f[4 + #C.WIRE_CLASSES]
    local since = (s and s:match("^%d+$")) and tonumber(s) or 0
    return { kind = "A", caster = f[3], plan = plan, since = since }
end

-- Le jeton du membre du groupe qui a envoyé ce message, ou nil plus la raison ("self" : ton propre
-- écho ; "stranger" : pas de ton groupe). roster : nom complet → jeton ; isMe(jeton) → bool.
function C.Accept(sender, roster, me, isMe)
    if type(sender) ~= "string" then return nil, "stranger" end
    if sender == me then return nil, "self" end
    local unit = roster[sender]
    if not unit then return nil, "stranger" end
    if isMe(unit) then return nil, "self" end
    return unit
end

-- ---------------------------------------------------------------- le client

local function fullName(unit)
    local ok, n = pcall(GetUnitName, unit, true)
    if ok and type(n) == "string" and n ~= "" and not sec(n) then return n end
    return nil
end

-- La table nom complet → jeton des membres (toi compris en raid). Un membre qui n'y est plus sort
-- des lignes des autres.
function C:BuildRoster()
    local map = {}
    local function add(unit)
        if UnitExists(unit) then
            local n = fullName(unit)
            if n then map[n] = unit end
        end
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do add("raid" .. i) end
    else
        for i = 1, GetNumSubgroupMembers() do add("party" .. i) end
    end
    self.roster, self.me = map, fullName("player")
    local gone = false
    for name in pairs(self.peers) do
        if not map[name] then self.peers[name], gone = nil, true end
    end
    if gone then self:Announce() end   -- palier 2 : un plus ancien parti libère sa bénédiction
end

local function channel()
    if IsInRaid() then return "RAID" end
    if IsInGroup() then return "PARTY" end
    return nil
end

local function locked()
    local f = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
    if not f then return false end
    local ok, v = pcall(f)
    return ok and v == true
end

-- Seul un lanceur qui a des buffs parle (spec, palier 1).
function C:CanSpeak()
    local B = NS.Buffs
    return B.class ~= nil and B:HasCatalog(B.class) and not (NS.Run and NS.Run.noBuffs)
end

function C:Schedule(delay)
    if self.timer then return end
    self.timer = C_Timer.NewTimer(delay, function() C.timer = nil; C:Flush() end)
end

function C:SendRaw(msg, ch)
    local ok, res = pcall(C_ChatInfo.SendAddonMessage, C.PREFIX, msg, ch)
    if ok and (res == nil or res == 0 or res == true) then
        self.stats.sent = self.stats.sent + 1
        return true
    end
    self.stats.refused = self.stats.refused + 1
    return false
end

-- Envoie ce qui attend. Une annonce identique à la dernière ne repart pas, sauf en réponse à une
-- demande (forceA).
function C:Flush()
    local ch = channel()
    if not ch or not self:CanSpeak() then self.wantA, self.wantR = false, false; return end
    if locked() then
        self.stats.deferred = self.stats.deferred + 1
        self:Schedule(C.RETRY)
        return
    end
    if self.wantR and self:SendRaw(C.Request(), ch) then self.wantR = false end
    if self.wantA then
        local msg = C.Encode(NS.Buffs.class, NS.Buffs:GroupPlan(NS.db), self.since)
        if (msg ~= self.lastA or self.forceA) and self:SendRaw(msg, ch) then self.lastA = msg end
        self.wantA, self.forceA = false, false
        self.stats.seniors, self.stats.juniors = NS.Share.Rank(self.peers, self:Me())
    end
end

-- Toi, pour la répartition (palier 2) : ton nom complet et ton heure d'arrivée dans le groupe.
function C:Me()
    return { name = self.me, since = self.since or math.huge }
end

-- Ton heure d'arrivée dans le groupe : gardée dans la base tant que tu restes groupé, pour qu'un
-- /reload ne fasse pas de toi le plus récent (toute la répartition se décalerait). Elle expire au
-- bout de COORD_TTL : c'est une valeur déduite, elle ne doit pas survivre à une autre soirée.
C.COORD_TTL = 6 * 3600
local function now()
    return (GetServerTime and GetServerTime()) or time()
end

function C:LoadSince()
    local s = NS.db.coordSince
    if IsInGroup() and type(s) == "number" and now() - s < C.COORD_TTL then
        self.since = s
    else
        self.since, NS.db.coordSince = nil, nil
    end
end

-- Ta grille a changé, ou ce que tu connais : l'annonce part, regroupée (une seule pour plusieurs clics).
function C:Announce()
    if not channel() then return end
    self.wantA = true
    self:Schedule(C.DEBOUNCE)
end

-- Tu arrives dans un groupe, te connectes ou recharges en groupe : demander aux autres de s'annoncer.
function C:Hello()
    if not channel() then return end
    self.wantR, self.wantA, self.forceA = true, true, true
    self:Schedule(C.DEBOUNCE)
end

function C:OnMessage(prefix, msg, ch, sender)
    if sec(prefix) or prefix ~= C.PREFIX then return end
    if sec(msg) or sec(ch) or sec(sender) then self.stats.secret = self.stats.secret + 1; return end
    if type(sender) == "string" and sender ~= self.me and not self.roster[sender] then self:BuildRoster() end
    local unit, why = C.Accept(sender, self.roster, self.me, function(u) return UnitIsUnit(u, "player") end)
    if not unit then self.stats[why] = self.stats[why] + 1; return end
    local m = C.Decode(msg)
    if not m then self.stats.bad = self.stats.bad + 1; return end
    self.stats.recv = self.stats.recv + 1
    if m.kind == "R" then
        if self:CanSpeak() then
            self.wantA, self.forceA = true, true
            self:Schedule(1 + math.random() * C.JITTER)   -- un raid ne répond pas d'un bloc
        end
        return
    end
    self.peers[sender] = { caster = m.caster, plan = m.plan, unit = unit, since = m.since }
    self:Announce()   -- palier 2 : la répartition d'un plus ancien a pu changer la tienne
    if NS.Grid then NS.Grid:RefreshPeers() end
end

-- Arrivée dans un groupe : ton heure est posée (sauf si un /reload l'a déjà relue) ; départ : effacée.
function C:OnRoster()
    local was = self.grouped
    self.grouped = channel() ~= nil
    self:BuildRoster()
    if self.grouped and not self.since then
        self.since = now()
        NS.db.coordSince = self.since
    end
    if was and not self.grouped then self.since, NS.db.coordSince = nil, nil end
    if not self.grouped then self.peers = {} end
    if self.grouped and not was then self:Hello() end
    if NS.Grid then NS.Grid:RefreshPeers() end
end

local function onEvent(_, event, ...)
    if event == "CHAT_MSG_ADDON" then C:OnMessage(...)
    elseif event == "GROUP_ROSTER_UPDATE" then C:OnRoster()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if C.wantA or C.wantR then C:Schedule(1) end
    end
end

-- /sbuff groupe : les autres Serial Buffer reçus, et les buffs qu'ils posent au groupe (dans le chat,
-- pour toi seul).
-- Les noms des buffs d'un plan, sans doublon (« Rois, Sagesse »), ou « - ».
local function planText(plan)
    local seen, buffs = {}, {}
    for _, cl in ipairs(C.WIRE_CLASSES) do
        for _, id in ipairs(plan and plan[cl] or {}) do
            if not seen[id] then
                seen[id] = true
                buffs[#buffs + 1] = NS.Buffs.client.name(id) or tostring(id)
            end
        end
    end
    return #buffs > 0 and table.concat(buffs, ", ") or "-"
end

-- /sbuff groupe : ta répartition, puis les autres Serial Buffer reçus (palier 2 : un paladin dit
-- s'il passe avant ou après toi), dans le chat, pour toi seul.
function C:PrintPeers()
    local L = NS.L
    if not self.grouped then NS:Print(L["Pas de groupe."]) return end
    if self:CanSpeak() then NS:Printf("%s : %s", L["Toi, après répartition"], planText(NS.Buffs:GroupPlan(NS.db))) end
    local names = {}
    for name in pairs(self.peers) do names[#names + 1] = name end
    table.sort(names)
    if #names == 0 then NS:Print(L["Aucun autre Serial Buffer dans ton groupe."]) return end
    NS:Print(L["Serial Buffer dans ton groupe :"])
    for _, name in ipairs(names) do
        local p, rank = self.peers[name], ""
        if p.caster == "PALADIN" then
            rank = NS.Share.Senior({ since = p.since, name = name }, self:Me()) and L[" (avant toi)"] or L[" (après toi)"]
        end
        NS:Printf("%s%s : %s", name, rank, planText(p.plan))
    end
end

-- Démarre après la boucle (SerialBuffer_Run.lua), quand la classe est lue.
function C:Start()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, C.PREFIX)
    end
    local f = CreateFrame("Frame")
    for _, ev in ipairs({ "CHAT_MSG_ADDON", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED" }) do
        f:RegisterEvent(ev)
    end
    f:SetScript("OnEvent", onEvent)
    self.frame = f
    -- Palier 2 : ce que les paladins plus anciens ont pris, pour Buffs (tableau et annonce).
    NS.Buffs.taken = function(targetClass) return NS.Share.Taken(C.peers, C:Me(), targetClass) end
    self:LoadSince()  -- AVANT le premier OnRoster : un /reload garde ta place
    self.grouped = false
    self:OnRoster()   -- déjà groupé au /reload : demande aux autres
end
