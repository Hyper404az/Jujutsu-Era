local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local CombatService = {
    Name = "CombatService",
}

function CombatService:Init(services)
    self._services = services
    self._activeDomains = {}
end

function CombatService:_getCharacterRoot(character)
    return character and character:FindFirstChild("HumanoidRootPart")
end

function CombatService:_findNearestHumanoidTarget(attacker, maxDistance)
    local attackerRoot = self:_getCharacterRoot(attacker.Character)
    if not attackerRoot then
        return nil
    end

    local closest
    local closestDistance = maxDistance or GameplayConfig.TargetAcquireDistance

    for _, descendant in ipairs(workspace:GetDescendants()) do
        if descendant:IsA("Humanoid") and descendant.Health > 0 then
            local model = descendant.Parent
            local root = model and (self:_getCharacterRoot(model) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"))
            if model and root and model ~= attacker.Character then
                local distance = (attackerRoot.Position - root.Position).Magnitude
                if distance <= closestDistance then
                    closestDistance = distance
                    closest = {
                        Model = model,
                        Humanoid = descendant,
                        Root = root,
                        Player = Players:GetPlayerFromCharacter(model),
                    }
                end
            end
        end
    end

    return closest
end

function CombatService:GetTargetFromPayload(attacker, payload)
    if type(payload) ~= "table" then
        return nil
    end

    local targetModel = payload.TargetModel
    if typeof(targetModel) == "Instance" and targetModel:IsA("Model") then
        local humanoid = targetModel:FindFirstChildOfClass("Humanoid")
        local root = self:_getCharacterRoot(targetModel) or targetModel.PrimaryPart or targetModel:FindFirstChildWhichIsA("BasePart")
        if humanoid and root and targetModel ~= attacker.Character then
            return {
                Model = targetModel,
                Humanoid = humanoid,
                Root = root,
                Player = Players:GetPlayerFromCharacter(targetModel),
            }
        end
    end

    if type(payload.TargetUserId) == "number" then
        local targetPlayer = Players:GetPlayerByUserId(payload.TargetUserId)
        local targetCharacter = targetPlayer and targetPlayer.Character
        local humanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
        local root = self:_getCharacterRoot(targetCharacter)
        if targetPlayer and humanoid and root then
            return {
                Model = targetCharacter,
                Humanoid = humanoid,
                Root = root,
                Player = targetPlayer,
            }
        end
    end

    return self:_findNearestHumanoidTarget(attacker, GameplayConfig.TargetAcquireDistance)
end

function CombatService:ValidateTarget(attacker, targetInfo, maxDistance)
    if not targetInfo then
        return false, "Invalid target."
    end

    local attackerCharacter = attacker.Character
    local attackerRoot = self:_getCharacterRoot(attackerCharacter)
    local targetRoot = targetInfo.Root
    local targetHumanoid = targetInfo.Humanoid

    if not attackerRoot or not targetRoot or not targetHumanoid then
        return false, "Missing humanoid."
    end

    if targetHumanoid.Health <= 0 then
        return false, "Target is down."
    end

    local distance = (attackerRoot.Position - targetRoot.Position).Magnitude
    if distance > maxDistance then
        return false, "Target out of range."
    end

    return true
end

function CombatService:CalculateDamage(attacker, targetInfo, abilityDefinition, context)
    local clanModifiers = self._services:Get("ClanService"):GetStatModifiers(attacker)
    local targetModifiers = targetInfo.Player and self._services:Get("ClanService"):GetStatModifiers(targetInfo.Player) or { ResistanceMultiplier = 1 }
    local damage = abilityDefinition.BaseDamage
    local abilityType = abilityDefinition.Type

    local attackerMultiplier = 1
    if clanModifiers.DamageMultipliers and clanModifiers.DamageMultipliers[abilityType] then
        attackerMultiplier = attackerMultiplier * clanModifiers.DamageMultipliers[abilityType]
    end

    if attacker:GetAttribute("EnchantedMode") then
        attackerMultiplier = attackerMultiplier * GameplayConfig.EnchantedDamageMultiplier
    end

    if context and context.BlackFlashSuccess and abilityDefinition.BlackFlashDamageMultiplier then
        attackerMultiplier = attackerMultiplier * abilityDefinition.BlackFlashDamageMultiplier
    end

    local resistanceMultiplier = targetModifiers.ResistanceMultiplier or 1
    return math.max(1, math.floor(damage * attackerMultiplier * resistanceMultiplier))
end

function CombatService:ApplyDamage(attacker, targetInfo, amount, abilityDefinition)
    local defeatedTarget = false

    if targetInfo.Player then
        defeatedTarget = (targetInfo.Player:GetAttribute("Health") or 0) <= amount
        self._services:Get("PlayerStateService"):AdjustHealth(targetInfo.Player, -amount)
    else
        defeatedTarget = targetInfo.Humanoid.Health <= amount
        targetInfo.Humanoid:TakeDamage(amount)
    end

    self._services:Get("PlayerStateService"):AdjustFocus(attacker, amount * GameplayConfig.DamageToFocusRatio)
    self._services:Get("MissionService"):TrackProgress(attacker, "DealDamage", amount)

    if defeatedTarget then
        self._services:Get("MissionService"):TrackProgress(attacker, "DefeatTarget", 1)
    end

    self._services:Get("RemoteService"):Broadcast("CombatFeedback", {
        Type = abilityDefinition.Type,
        Effect = abilityDefinition.Execution,
        AbilityName = abilityDefinition.Name,
        Position = targetInfo.Root.Position,
        SourcePosition = attacker.Character and attacker.Character:FindFirstChild("HumanoidRootPart") and attacker.Character.HumanoidRootPart.Position or targetInfo.Root.Position,
        Damage = amount,
        AttackerUserId = attacker.UserId,
    })
end

function CombatService:ApplyKnockback(attacker, targetInfo, force)
    if not targetInfo or not targetInfo.Root then
        return
    end

    local attackerRoot = self:_getCharacterRoot(attacker.Character)
    if not attackerRoot then
        return
    end

    local direction = (targetInfo.Root.Position - attackerRoot.Position)
    if direction.Magnitude <= 0.001 then
        direction = attackerRoot.CFrame.LookVector
    else
        direction = direction.Unit
    end

    targetInfo.Root.AssemblyLinearVelocity = (direction * force) + Vector3.new(0, force * 0.22, 0)
end

function CombatService:ApplyPull(attacker, targetInfo, force)
    if not targetInfo or not targetInfo.Root then
        return
    end

    local attackerRoot = self:_getCharacterRoot(attacker.Character)
    if not attackerRoot then
        return
    end

    local direction = (attackerRoot.Position - targetInfo.Root.Position)
    if direction.Magnitude <= 0.001 then
        direction = -attackerRoot.CFrame.LookVector
    else
        direction = direction.Unit
    end

    targetInfo.Root.AssemblyLinearVelocity = (direction * force) + Vector3.new(0, force * 0.08, 0)
end

function CombatService:ApplyEraseBeam(attacker, abilityDefinition)
    local attackerRoot = self:_getCharacterRoot(attacker.Character)
    if not attackerRoot then
        return false
    end

    local direction = attackerRoot.CFrame.LookVector
    local beamLength = abilityDefinition.Range or 70
    local beamRadius = abilityDefinition.BeamRadius or 8
    local beamCenter = attackerRoot.Position + (direction * (beamLength * 0.5))

    local beamPart = Instance.new("Part")
    beamPart.Name = "PurpleTrace"
    beamPart.Anchored = true
    beamPart.CanCollide = false
    beamPart.CanQuery = false
    beamPart.CanTouch = false
    beamPart.Material = Enum.Material.Neon
    beamPart.Color = Color3.fromRGB(182, 92, 255)
    beamPart.Transparency = 0.32
    beamPart.Size = Vector3.new(beamRadius * 2, beamRadius * 2, beamLength)
    beamPart.CFrame = CFrame.lookAt(attackerRoot.Position, attackerRoot.Position + direction) * CFrame.new(0, 0, -beamLength * 0.5)
    beamPart.Parent = workspace
    Debris:AddItem(beamPart, 0.25)

    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = { attacker.Character, beamPart }

    local impacted = {}
    for _, part in ipairs(workspace:GetPartBoundsInBox(beamPart.CFrame, beamPart.Size, overlap)) do
        local model = part:FindFirstAncestorOfClass("Model")
        local humanoid = model and model:FindFirstChildOfClass("Humanoid")
        if model and humanoid and humanoid.Health > 0 and model ~= attacker.Character and not impacted[model] then
            impacted[model] = true

            local targetInfo = {
                Model = model,
                Humanoid = humanoid,
                Root = self:_getCharacterRoot(model) or model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"),
                Player = Players:GetPlayerFromCharacter(model),
            }

            local damage = self:CalculateDamage(attacker, targetInfo, abilityDefinition, nil)
            self:ApplyDamage(attacker, targetInfo, damage, abilityDefinition)

            if targetInfo.Player then
                self._services:Get("PlayerStateService"):SetStunned(targetInfo.Player, true)
                task.delay(0.6, function()
                    if targetInfo.Player.Parent then
                        self._services:Get("PlayerStateService"):SetStunned(targetInfo.Player, false)
                    end
                end)
            end
        end
    end

    self._services:Get("RemoteService"):Broadcast("CombatFeedback", {
        Type = abilityDefinition.Type,
        Effect = abilityDefinition.Execution,
        AbilityName = abilityDefinition.Name,
        Position = attackerRoot.Position + direction * beamLength,
        SourcePosition = attackerRoot.Position,
        Damage = abilityDefinition.BaseDamage,
        AttackerUserId = attacker.UserId,
    })

    return true
end

function CombatService:ActivateDomain(caster, abilityDefinition, targetInfo)
    local targetPlayer = targetInfo and targetInfo.Player
    local challenger = targetPlayer and self._activeDomains[targetPlayer]
    local winner = caster

    if challenger then
        local casterLevel = caster:GetAttribute("Level") or 1
        local challengerLevel = challenger:GetAttribute("Level") or 1

        if challengerLevel > casterLevel then
            winner = challenger
        elseif challengerLevel == casterLevel then
            local casterMastery = caster:GetAttribute("Mastery") or 0
            local challengerMastery = challenger:GetAttribute("Mastery") or 0
            if challengerMastery > casterMastery then
                winner = challenger
            end
        end
    end

    self._activeDomains[caster] = caster
    caster:SetAttribute("WitnessedDomain", true)
    local casterProfile = self._services:Get("DataService"):GetProfile(caster)
    if casterProfile then
        casterProfile.WitnessedDomain = true
        self._services:Get("DataService"):MarkDirty(caster)
    end

    if targetPlayer then
        targetPlayer:SetAttribute("WitnessedDomain", true)
        local targetProfile = self._services:Get("DataService"):GetProfile(targetPlayer)
        if targetProfile then
            targetProfile.WitnessedDomain = true
            self._services:Get("DataService"):MarkDirty(targetPlayer)
        end
        self._services:Get("MissionService"):TrackProgress(targetPlayer, "WitnessDomain", 1)
    end

    task.delay(abilityDefinition.DomainDuration or 12, function()
        self._activeDomains[caster] = nil
    end)

    local casterRoot = self:_getCharacterRoot(caster.Character)
    if casterRoot then
        self._services:Get("RemoteService"):Broadcast("CombatFeedback", {
            Type = "Domain",
            AbilityName = abilityDefinition.Name,
            Position = casterRoot.Position,
            Damage = abilityDefinition.BaseDamage,
            AttackerUserId = caster.UserId,
        })
    end

    return winner == caster
end

return CombatService
