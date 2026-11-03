-- SerialBuffer_Touche.lua — LA TOUCHE « BUFF SUIVANT » EN COMBAT (docs/specs/touche-en-combat.md).
--
-- En combat, un addon ne peut plus toucher aux attributs d'un bouton sécurisé (D36) : réécrite par
-- nous, la touche viserait sans fin le même joueur. Un code RESTREINT attaché au bouton
-- (SecureHandlerWrapScript), que le jeu exécute dans son environnement protégé, le peut : hors
-- combat, on dépose sur le bouton la liste figée (jeton + macro de chaque ligne qui lance encore en
-- combat) ; à chaque appui en combat, ce code passe à la ligne suivante et réécrit la macro AVANT
-- que le bouton ne lance.
-- Lu dans la source de Blizzard (Forever, Blizzard_RestrictedAddOnEnvironment, 2026-10-16), pas
-- mesuré : ce code n'a pas GetTime, et ne peut rien lire d'un cadre non protégé en combat (« Invalid
-- frame handle ») ; il ne sait donc pas si le sort a porté : un appui passe TOUJOURS au suivant.
-- Le bouton reçoit l'appui ET le relâché (Bindings.xml, runOnUp) : le code n'avance que sur celui
-- qui lance, que dit l'attribut useOnKeyDown (SecureActionButton_ShouldUseOnKeyDown), posé hors
-- combat d'après le CVar ActionButtonUseKeyDown.
local _, NS = ...
NS = NS or _G.SerialBuffer

local T = {}
NS.Touche = T

T.MAX = 40   -- un raid entier

-- Exécuté par le jeu avant chaque clic du bouton, avec self, button, down. Hors combat, il ne fait
-- rien (la macro posée par le rendu fait foi). Au bout de la liste, il rend false : le clic est
-- annulé, rien ne part. sb-hit dit au code normal quelle ligne vient d'être visée (0 : aucune).
T.SNIPPET = [[
if not SecureCmdOptionParse("[combat] 1") then return end
if (down and true or false) ~= (self:GetAttribute("useOnKeyDown") and true or false) then return end
local n = self:GetAttribute("sb-n") or 0
local pos = self:GetAttribute("sb-pos") or 0
while pos < n do
    pos = pos + 1
    local u = self:GetAttribute("sb-u" .. pos)
    if u == "player" or (UnitExists(u) and not UnitIsDead(u) and not UnitIsGhost(u)) then
        self:SetAttribute("sb-pos", pos)
        self:SetAttribute("sb-hit", pos)
        self:SetAttribute("macrotext", self:GetAttribute("sb-m" .. pos))
        return
    end
end
self:SetAttribute("sb-pos", n)
self:SetAttribute("sb-hit", 0)
return false
]]

-- La liste figée : dans l'ordre de la file, les lignes qui lancent encore en combat (D36 : toi, et
-- ton groupe par son jeton), avec leur macro. Hors de portée compris (D9 ne vaut que hors combat) :
-- en combat tout le monde bouge, et un sort hors de portée ne part pas, on réappuie.
function T.List(rows)
    local list = {}
    for _, row in ipairs(rows or {}) do
        local macro = NS.Cast.CombatClickable(row) and NS.Cast.MacroFor(row)
        if macro then
            list[#list + 1] = { unit = row.self and "player" or row.unit, macro = macro, guid = row.guid,
                                buff = row.buff.name, level = row.level }
            if #list >= T.MAX then break end
        end
    end
    return list
end

local function set(b, key, value)
    if b:GetAttribute(key) ~= value then b:SetAttribute(key, value) end
end

-- Hors combat seulement (le rendu, le tableau caché) : dépose la liste sur le bouton, repart du début.
-- La macro d'un appui en combat est restée sur le bouton : on remet celle du rendu (b.macro), que
-- setMacro croit déjà posée.
function T:Load(b, rows)
    if not b or InCombatLockdown() then return end
    local list = T.List(rows)
    for i, e in ipairs(list) do
        set(b, "sb-u" .. i, e.unit)
        set(b, "sb-m" .. i, e.macro)
    end
    for i = #list + 1, b.combatList and #b.combatList or 0 do
        set(b, "sb-u" .. i, nil)
        set(b, "sb-m" .. i, nil)
    end
    set(b, "sb-n", #list)
    set(b, "sb-pos", 0)
    set(b, "sb-hit", 0)
    set(b, "useOnKeyDown", GetCVarBool("ActionButtonUseKeyDown") and true or false)
    set(b, "macrotext", b.macro)
    b.combatList, b.notedPos = list, 0
end

-- Après chaque clic (code normal). En combat : la ligne que le code restreint vient de viser est
-- notée comme un clic sur elle ; son sort réussi la grise et, à l'aveugle, la file le retient (D52).
-- Le relâché, ou un appui au bout de la liste, ne note rien de neuf. Hors combat : noté comme avant
-- (le crochet OnClick du bouton peut avoir sauté quand le jeu a enveloppé OnClick).
function T.OnPostClick(b)
    if not InCombatLockdown() then NS.Cast:NoteClick(b, GetTime(), false) return end
    local hit = b:GetAttribute("sb-hit")
    if type(hit) ~= "number" or hit < 1 or hit == b.notedPos then return end
    b.notedPos = hit
    local e = b.combatList and b.combatList[hit]
    if e then NS.Cast:NoteKey(e, GetTime()) end
end

-- Une fois, à la construction de la touche (hors combat).
function T:Build(b)
    local header = CreateFrame("Frame", nil, UIParent, "SecureHandlerBaseTemplate")
    SecureHandlerWrapScript(b, "OnClick", header, T.SNIPPET)
    b:HookScript("PostClick", T.OnPostClick)
    self.header = header
end
