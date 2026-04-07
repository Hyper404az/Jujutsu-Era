local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

local DomainEffects = {}

local function getCharacterRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

local function makeVisual(caster, config, color)
    local root = getCharacterRoot(caster.Character)
    if not root then
        return nil
    end

    local shell = Instance.new("Part")
    shell.Name = "DomainShell_" .. caster.UserId
    shell.Shape = Enum.PartType.Ball
    shell.Anchored = true
    shell.CanCollide = false
    shell.CanTouch = false
    shell.CanQuery = false
    shell.Material = Enum.Material.ForceField
    shell.Color = color
    shell.Transparency = 0.65
    shell.Size = Vector3.new(config.Radius * 2, config.Radius * 2, config.Radius * 2)
    shell.Position = root.Position
    shell.Parent = workspace
    return shell
end

local function ensureTargetState(state, model, humanoid)
    local target = state.Affected[model]
    if target then
        return target
    end

    target = {
        Humanoid = humanoid,
        OriginalWalkSpeed = humanoid.WalkSpeed,
        OriginalJumpPower = humanoid.JumpPower,
        Player = Players:GetPlayerFromCharacter(model),
    }
    state.Affected[model] = target
    return target
end

function DomainEffects.Apply(domainService, caster, domainKey, config)
    local state = {
        DomainKey = domainKey,
        Caster = caster,
        Config = config,
        Active = true,
        Affected = {},
        Connections = {},
        CasterBuff = nil,
        Visual = nil,
    }

    if domainKey == "Gojo" then
        state.Visual = makeVisual(caster, config, Color3.fromRGB(119, 141, 255))
    else
        state.Visual = makeVisual(caster, config, Color3.fromRGB(77, 67, 97))
    end

    local function cleanupTarget(target)
        if target.Player and target.Player.Parent then
            target.Player:SetAttribute("IsStunned", false)
            target.Player:SetAttribute("DomainLocked", false)
        end

        if target.Humanoid and target.Humanoid.Parent then
            target.Humanoid.WalkSpeed = target.OriginalWalkSpeed
            target.Humanoid.JumpPower = target.OriginalJumpPower
        end
    end

    function state:Tick()
        if not self.Active then
            return
        end

        local casterRoot = getCharacterRoot(self.Caster.Character)
        if not casterRoot then
            return
        end

        if self.Visual and self.Visual.Parent then
            self.Visual.Position = casterRoot.Position
        end

        local overlap = OverlapParams.new()
        overlap.FilterType = Enum.RaycastFilterType.Exclude
        overlap.FilterDescendantsInstances = self.Visual and { self.Visual } or {}

        local parts = workspace:GetPartBoundsInRadius(casterRoot.Position, self.Config.Radius, overlap)
        local seen = {}

        for _, part in ipairs(parts) do
            local model = part:FindFirstAncestorOfClass("Model")
            local humanoid = model and model:FindFirstChildOfClass("Humanoid")
            if model and humanoid and humanoid.Health > 0 and model ~= self.Caster.Character and not seen[model] then
                seen[model] = true

                if self.DomainKey == "Gojo" then
                    local target = ensureTargetState(self, model, humanoid)
                    humanoid.WalkSpeed = 0
                    humanoid.JumpPower = 0

                    if target.Player then
                        target.Player:SetAttribute("IsStunned", true)
                        target.Player:SetAttribute("DomainLocked", true)
                        domainService._services:Get("PlayerStateService"):AdjustHealth(target.Player, -4)
                    else
                        humanoid:TakeDamage(4)
                    end
                end
            end
        end

        if self.DomainKey == "Zenin_TenShadows" then
            if not self.CasterBuff then
                local humanoid = self.Caster.Character and self.Caster.Character:FindFirstChildOfClass("Humanoid")
                if humanoid then
                    self.CasterBuff = {
                        Humanoid = humanoid,
                        OriginalWalkSpeed = humanoid.WalkSpeed,
                    }
                    humanoid.WalkSpeed = humanoid.WalkSpeed + 4
                    self.Caster:SetAttribute("SummonDamageMultiplier", 1.25)
                    self.Caster:SetAttribute("MultiShikigamiActive", true)
                end
            end
        end
    end

    function state:Destroy()
        if not self.Active then
            return
        end
        self.Active = false

        for _, connection in ipairs(self.Connections) do
            connection:Disconnect()
        end

        for _, target in pairs(self.Affected) do
            cleanupTarget(target)
        end

        if self.CasterBuff then
            local humanoid = self.CasterBuff.Humanoid
            if humanoid and humanoid.Parent then
                humanoid.WalkSpeed = self.CasterBuff.OriginalWalkSpeed
            end
        end

        if self.Caster and self.Caster.Parent then
            self.Caster:SetAttribute("SummonDamageMultiplier", 1)
            self.Caster:SetAttribute("MultiShikigamiActive", false)
        end

        if self.Visual then
            self.Visual:Destroy()
        end
    end

    table.insert(state.Connections, caster.AncestryChanged:Connect(function(_, parent)
        if not parent then
            domainService:TerminateDomain("CasterLeft")
        end
    end))

    table.insert(state.Connections, caster:GetAttributeChangedSignal("IsAlive"):Connect(function()
        if caster:GetAttribute("IsAlive") ~= true then
            domainService:TerminateDomain("CasterDied")
        end
    end))

    if state.Visual then
        Debris:AddItem(state.Visual, config.Duration + 2)
    end

    return state
end

return DomainEffects
