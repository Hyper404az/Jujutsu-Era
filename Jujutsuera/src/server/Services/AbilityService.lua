local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AbilityConfig = require(ReplicatedStorage.Shared.Config.AbilityConfig)
local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local AbilityService = {
    Name = "AbilityService",
}

function AbilityService:Init(services)
    self._services = services
    self._blackFlashWindows = {}
end

function AbilityService:GetAvailableAbilities(player)
    local clan = player:GetAttribute("Clan") or "Commoner"
    local subTechnique = player:GetAttribute("SubTechnique") or ""
    local set = AbilityConfig.AbilitySets[clan]

    if type(set) == "table" and set[1] == nil then
        set = set[subTechnique] or {}
    end

    local abilities = {}
    for _, abilityId in ipairs(set or {}) do
        local definition = AbilityConfig.Abilities[abilityId]
        if definition then
            table.insert(abilities, definition)
        end
    end

    return abilities
end

function AbilityService:GetAbilityByIdForPlayer(player, abilityId)
    for _, ability in ipairs(self:GetAvailableAbilities(player)) do
        if ability.Id == abilityId then
            return ability
        end
    end

    return nil
end

function AbilityService:IsOnCooldown(player, abilityId)
    local cooldowns = self._services:Get("PlayerStateService"):GetCooldowns(player)
    return (cooldowns[abilityId] or 0) > os.clock()
end

function AbilityService:SetCooldown(player, abilityId, duration)
    local cooldowns = self._services:Get("PlayerStateService"):GetCooldowns(player)
    cooldowns[abilityId] = os.clock() + duration
    self._services:Get("PlayerStateService"):SetCooldowns(player, cooldowns)
end

function AbilityService:_validateCommon(player, abilityDefinition)
    if not player:GetAttribute("HasStarted") then
        return false, "Player has not started."
    end

    if not player:GetAttribute("IsAlive") then
        return false, "Player is not alive."
    end

    if player:GetAttribute("IsStunned") then
        return false, "Player is stunned."
    end

    if player:GetAttribute("DomainLocked") then
        return false, "Abilities are locked."
    end

    if self:IsOnCooldown(player, abilityDefinition.Id) then
        return false, "Ability on cooldown."
    end

    if (player:GetAttribute("Mastery") or 0) < abilityDefinition.MasteryRequirement then
        return false, "Insufficient mastery."
    end

    if abilityDefinition.Type == "Domain" then
        if (player:GetAttribute("Mastery") or 0) < GameplayConfig.DomainMasteryRequirement then
            return false, "Domain mastery requirement not met."
        end
        if not player:GetAttribute("WitnessedDomain") then
            return false, "Domain has not been witnessed."
        end
    end

    return true
end

function AbilityService:_resolveCosts(player, abilityDefinition)
    local clanModifiers = self._services:Get("ClanService"):GetStatModifiers(player)
    local focusCost = abilityDefinition.FocusCost

    if clanModifiers.FocusCostMultiplier then
        focusCost = focusCost * clanModifiers.FocusCostMultiplier
    end

    if player:GetAttribute("EnchantedMode") then
        focusCost = focusCost * GameplayConfig.EnchantedFocusCostMultiplier
    end

    if clanModifiers.SixEyes then
        focusCost = focusCost * self._services:Get("SixEyesService"):GetCostMultiplier(player)
    end

    return math.max(0, math.floor(focusCost)), abilityDefinition.HealthCost or 0
end

function AbilityService:_consumeCosts(player, focusCost, healthCost)
    local playerState = self._services:Get("PlayerStateService")
    if not playerState:ConsumeFocus(player, focusCost) then
        return false, "Not enough Focus."
    end

    if healthCost > 0 then
        if (player:GetAttribute("Health") or 0) <= healthCost then
            playerState:AdjustFocus(player, focusCost)
            return false, "Not enough Health."
        end
        playerState:AdjustHealth(player, -healthCost)
    end

    return true
end

function AbilityService:_playCastPhase(player, abilityDefinition)
    if not abilityDefinition.CastTime or abilityDefinition.CastTime <= 0 then
        return
    end

    self._services:Get("RemoteService"):Broadcast("AbilityCast", {
        AbilityName = abilityDefinition.Name,
        Effect = abilityDefinition.Execution,
        CasterUserId = player.UserId,
        Duration = abilityDefinition.CastTime,
    })

    player:SetAttribute("IsStunned", true)
    task.wait(abilityDefinition.CastTime)
    if player.Parent and player:GetAttribute("IsAlive") then
        player:SetAttribute("IsStunned", false)
    end
end

function AbilityService:_handleBlackFlash(player, abilityDefinition)
    local now = os.clock()
    local window = self._blackFlashWindows[player]

    if not window then
        self._blackFlashWindows[player] = {
            StartedAt = now,
        }
        return false, "Black Flash primed. Press again in the timing window.", false
    end

    self._blackFlashWindows[player] = nil

    local elapsed = now - window.StartedAt
    local success = elapsed >= abilityDefinition.TimingWindowMin and elapsed <= abilityDefinition.TimingWindowMax
    if not success then
        return false, "Black Flash timing missed.", false
    end

    return true, nil, true
end

function AbilityService:ExecuteAbility(player, payload)
    if type(payload) ~= "table" or type(payload.AbilityId) ~= "string" then
        return
    end

    local abilityDefinition = self:GetAbilityByIdForPlayer(player, payload.AbilityId)
    if not abilityDefinition then
        self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
            Success = false,
            Reason = "Ability not available.",
        })
        return
    end

    local ok, reason = self:_validateCommon(player, abilityDefinition)
    if not ok then
        self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
            Success = false,
            AbilityId = abilityDefinition.Id,
            Reason = reason,
        })
        return
    end

    local blackFlashSuccess = false
    if abilityDefinition.Execution == "BlackFlash" then
        local flashOk, flashReason, wasSuccess = self:_handleBlackFlash(player, abilityDefinition)
        if not flashOk then
            self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
                Success = false,
                AbilityId = abilityDefinition.Id,
                Reason = flashReason,
            })
            return
        end
        blackFlashSuccess = wasSuccess
    end

    local targetInfo = self._services:Get("CombatService"):GetTargetFromPayload(player, payload)
    if abilityDefinition.Execution ~= "Domain" then
        local validTarget, targetReason = self._services:Get("CombatService"):ValidateTarget(player, targetInfo, abilityDefinition.Range)
        if not validTarget then
            self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
                Success = false,
                AbilityId = abilityDefinition.Id,
                Reason = targetReason,
            })
            return
        end
    end

    local focusCost, healthCost = self:_resolveCosts(player, abilityDefinition)
    local costOk, costReason = self:_consumeCosts(player, focusCost, healthCost)
    if not costOk then
        self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
            Success = false,
            AbilityId = abilityDefinition.Id,
            Reason = costReason,
        })
        return
    end

    self:_playCastPhase(player, abilityDefinition)

    if abilityDefinition.Execution == "Domain" then
        local domainWon = self._services:Get("CombatService"):ActivateDomain(player, abilityDefinition, targetInfo)
        if not domainWon then
            self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
                Success = false,
                AbilityId = abilityDefinition.Id,
                Reason = "Domain conflict lost.",
            })
            return
        end
    elseif abilityDefinition.Execution == "EraseBeam" then
        self._services:Get("CombatService"):ApplyEraseBeam(player, abilityDefinition)
    else
        local damage = self._services:Get("CombatService"):CalculateDamage(player, targetInfo, abilityDefinition, {
            BlackFlashSuccess = blackFlashSuccess,
        })
        self._services:Get("CombatService"):ApplyDamage(player, targetInfo, damage, abilityDefinition)

        if abilityDefinition.Execution == "StunDamage" then
            local targetPlayer = targetInfo and targetInfo.Player
            if targetPlayer then
                self._services:Get("PlayerStateService"):SetStunned(targetPlayer, true)
            end
            task.delay(abilityDefinition.StunDuration or 1, function()
                if targetPlayer and targetPlayer.Parent then
                    self._services:Get("PlayerStateService"):SetStunned(targetPlayer, false)
                end
            end)
        elseif abilityDefinition.Execution == "RepulseBurst" then
            self._services:Get("CombatService"):ApplyKnockback(player, targetInfo, abilityDefinition.KnockbackForce or 90)

            local targetPlayer = targetInfo and targetInfo.Player
            if targetPlayer then
                self._services:Get("PlayerStateService"):SetStunned(targetPlayer, true)
                task.delay(abilityDefinition.StunDuration or 0.4, function()
                    if targetPlayer.Parent then
                        self._services:Get("PlayerStateService"):SetStunned(targetPlayer, false)
                    end
                end)
            end
        elseif abilityDefinition.Execution == "AttractionBurst" then
            self._services:Get("CombatService"):ApplyPull(player, targetInfo, abilityDefinition.PullForce or 80)

            local targetPlayer = targetInfo and targetInfo.Player
            if targetPlayer then
                self._services:Get("PlayerStateService"):SetStunned(targetPlayer, true)
                task.delay(abilityDefinition.StunDuration or 0.25, function()
                    if targetPlayer.Parent then
                        self._services:Get("PlayerStateService"):SetStunned(targetPlayer, false)
                    end
                end)
            end
        end
    end

    self:SetCooldown(player, abilityDefinition.Id, abilityDefinition.Cooldown)
    self._services:Get("ProgressionService"):RecordAbilityUse(player, abilityDefinition.Id)

    if self._services:Get("ClanService"):GetStatModifiers(player).SixEyes then
        self._services:Get("SixEyesService"):OnAbilityUsed(player)
    end

    self._services:Get("RemoteService"):FireClient(player, "AbilityResult", {
        Success = true,
        AbilityId = abilityDefinition.Id,
        Reason = "Ability executed.",
    })
end

return AbilityService
