-- SerialBuffer_Toast.lua — ce qui arrive sans geste du joueur passe en toast, pas dans le chat.
--
-- Règle du user du 2026-10-11 (skill publique `chat-output`) : le chat ne répond qu'à un geste du
-- joueur (commande, clic, raccourci). « X a réglé ta ligne Groupe / raid » vient du réseau (Comm:OnSet) :
-- un toast. Le toast est celui du JEU, la pile des hauts faits et du butin (AlertFrame) ; même code
-- que LeyLines_Toast.lua, vu en jeu le 2026-10-11 (en combat compris, deux toasts empilés).
-- L'inscription se fait UNE fois, au PLAYER_LOGIN, hors combat comme aux mesures. Sans AlertFrame
-- (tests, autre client), un toast ne fait rien : pas de repli dans le chat.
local _, NS = ...

local Toast = {}
NS.Toast = Toast

local TITLE         = "Serial Buffer"   -- le nom de l'addon, comme le préfixe du chat : pas traduit
local SHOWN, QUEUED = 2, 6              -- toasts visibles à la fois, en attente derrière

local function SetUp(frame, title, text)
    frame.Title:SetText(title)
    frame.Text:SetText(text)
end

function Toast:Init()
    if self.system or not (AlertFrame and AlertFrame.AddQueuedAlertFrameSubSystem) then return end
    self.system = AlertFrame:AddQueuedAlertFrameSubSystem("SerialBufferToastTemplate", SetUp, SHOWN, QUEUED)
end

-- Rend vrai si le toast s'affiche ou attend son tour dans la file.
function Toast:Show(text)
    if not self.system then return false end
    return self.system:AddAlert(TITLE, text) and true or false
end
