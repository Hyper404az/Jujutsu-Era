-- src/client/HUD/HUDController.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Player = Players.LocalPlayer

local ClanData = require(ReplicatedStorage.Shared.Clans.ClanData)

-- Imagine que você já criou os ScreenGuis no Roblox Studio
local hudGuis = Player.PlayerGui:WaitForChild("CombatHUD")
local focusBar = hudGuis.BottomCenter.FocusBar.Fill
local skillListContainer = hudGuis.RightSide.SkillList

local function UpdateSkillList()
    local clanName = Player:GetAttribute("Clan")
    local subTech = Player:GetAttribute("SubTechnique") -- Para os Zenin
    local currentMastery = Player:GetAttribute("Mastery") or 0
    local witnessedDomain = Player:GetAttribute("WitnessedDomain") or false
    
    if not clanName or not ClanData.Clans[clanName] then return end
    
    local skills = ClanData.Clans[clanName].Skills
    if subTech and ClanData.Clans[clanName].HasSubTechniques then
        skills = ClanData.Clans[clanName].SubTechniques[subTech]
    end

    -- Limpa a lista atual na UI
    for _, child in ipairs(skillListContainer:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end

    -- Popula a lista na tela (Direita)
    for index, skill in pairs(skills) do
        local isDomain = (index == "Domain")
        local isUnlocked = (currentMastery >= skill.ReqMaestria)
        
        if isDomain and not witnessedDomain then
            isUnlocked = false
        end

        print(string.format("[%s] %s | Req: %d | Status: %s", 
            isDomain and "G" or skill.Key.Name, 
            skill.Name, 
            skill.ReqMaestria, 
            isUnlocked and "Liberado ✅" or "Bloqueado 🔒"
        ))
        
        -- Aqui você clonaria um Template de UI e preencheria com esses dados
    end
end

-- Escuta mudanças nos atributos para atualizar a tela em tempo real
Player:GetAttributeChangedSignal("Focus"):Connect(function()
    local focus = Player:GetAttribute("Focus") or 0
    -- Anima a barra azul de Foco (TweenService)
    focusBar.Size = UDim2.new(focus / 100, 0, 1, 0)
end)

Player:GetAttributeChangedSignal("Mastery"):Connect(UpdateSkillList)
Player:GetAttributeChangedSignal("Clan"):Connect(UpdateSkillList)