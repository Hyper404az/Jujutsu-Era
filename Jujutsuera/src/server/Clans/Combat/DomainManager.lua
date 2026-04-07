-- src/server/Combat/DomainManager.lua
local DomainManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Configurações Globais de Domínio
DomainManager.ActiveDomains = {} -- Rastreia quem está dentro de qual domínio

function DomainManager.CastDomain(caster, domainName)
    local character = caster.Character
    if not character then return end

    print("🌌 " .. caster.Name .. " expandiu o domínio: " .. domainName)

    -- 1. CRIAR A ESFERA (Visual)
    local shell = Instance.new("Part")
    shell.Name = "DomainShell_" .. caster.Name
    shell.Shape = Enum.PartType.Ball
    shell.Material = Enum.Material.ForceField
    shell.Anchored = true
    shell.CanCollide = false -- Jogadores ficam presos por lógica, não só colisão
    shell.Position = character.HumanoidRootPart.Position
    shell.Size = Vector3.new(1, 1, 1)
    shell.Parent = game.Workspace
    
    -- Tween para crescer a esfera
    local growTween = TweenService:Create(shell, TweenInfo.new(1.5), {Size = Vector3.new(60, 60, 60)})
    growTween:Play()

    -- 2. MARCAR QUEM PRESENCIOU (Regra do seu GDD)
    local players = game.Players:GetPlayers()
    for _, targetPlayer in ipairs(players) do
        local targetChar = targetPlayer.Character
        if targetChar then
            local distance = (targetChar.HumanoidRootPart.Position - shell.Position).Magnitude
            if distance < 35 then -- Se estiver dentro do raio de 60 (raio 30)
                
                -- ATUALIZA ATRIBUTO: Agora este jogador pode desbloquear o próprio domínio futuramente
                if not targetPlayer:GetAttribute("WitnessedDomain") then
                    targetPlayer:SetAttribute("WitnessedDomain", true)
                end
                
                -- Lógica de "Hit Garantido" (Sure-Hit) começaria aqui
                print(targetPlayer.Name .. " foi pego no domínio!")
            end
        end
    end

    -- 3. AUTO-DESTRUIÇÃO (Domínios não são eternos)
    task.delay(20, function()
        -- Tween para sumir e depois Destroy()
        shell:Destroy()
    end)
end

return DomainManager