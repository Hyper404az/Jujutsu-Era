local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DomainConfig = require(ReplicatedStorage.Shared.Domain.DomainConfig)
local DomainEligibility = require(ReplicatedStorage.Shared.Domain.DomainEligibility)
local DomainEffects = require(script.Parent.DomainEffects)

local DomainService = {
    Name = "DomainService",
}

function DomainService:Init(services)
    self._services = services
    self._activeDomainState = nil
    self._activeCaster = nil
end

function DomainService:RefreshPlayerDomainState(player)
    player:SetAttribute("HasDomain", DomainEligibility.HasDomainAccess(player))

    if player:GetAttribute("DomainActive") == nil then
        player:SetAttribute("DomainActive", false)
    end

    if player:GetAttribute("DomainCooldown") == nil then
        player:SetAttribute("DomainCooldown", 0)
    end
end

function DomainService:IsAnyDomainActive()
    return self._activeDomainState ~= nil
end

function DomainService:TerminateDomain(reason)
    local state = self._activeDomainState
    if not state then
        return
    end

    local caster = self._activeCaster
    self._activeDomainState = nil
    self._activeCaster = nil

    state:Destroy()

    if caster and caster.Parent then
        caster:SetAttribute("DomainActive", false)
        caster:SetAttribute("DomainLocked", false)
        self._services:Get("RemoteService"):FireClient(caster, "ServerMessage", {
            Type = "Info",
            Text = string.format("Domain ended (%s).", reason or "Completed"),
        })
    end
end

function DomainService:_activate(player, domainKey, config)
    self._services:Get("PlayerStateService"):SetFocus(player, 0)
    player:SetAttribute("DomainActive", true)
    player:SetAttribute("DomainCooldown", config.Cooldown)
    player:SetAttribute("DomainLocked", false)

    self._activeCaster = player
    self._activeDomainState = DomainEffects.Apply(self, player, domainKey, config)

    self._services:Get("RemoteService"):Broadcast("CombatFeedback", {
        Type = "Domain",
        AbilityName = config.Name,
        Position = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position or Vector3.zero,
        Damage = 0,
        AttackerUserId = player.UserId,
    })

    task.delay(config.Duration, function()
        if self._activeCaster == player and self._activeDomainState then
            self:TerminateDomain("DurationExpired")
        end
    end)
end

function DomainService:HandleActivationRequest(player)
    if self:IsAnyDomainActive() then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = "A domain is already active.",
        })
        return
    end

    local ok, reason, domainKey, config = DomainEligibility.CanActivate(player)
    if not ok then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = reason or "Domain activation failed.",
        })
        return
    end

    if not DomainConfig[domainKey] then
        self._services:Get("RemoteService"):FireClient(player, "ServerMessage", {
            Type = "Error",
            Text = "Domain configuration is missing.",
        })
        return
    end

    self:_activate(player, domainKey, config)
end

function DomainService:_cooldownLoop()
    while true do
        task.wait(1)

        for _, player in ipairs(Players:GetPlayers()) do
            local cooldown = player:GetAttribute("DomainCooldown") or 0
            if cooldown > 0 then
                player:SetAttribute("DomainCooldown", math.max(0, cooldown - 1))
            end
        end

        if self._activeDomainState then
            self._activeDomainState:Tick()
        end
    end
end

function DomainService:Start()
    Players.PlayerAdded:Connect(function(player)
        self:RefreshPlayerDomainState(player)
    end)

    Players.PlayerRemoving:Connect(function(player)
        if self._activeCaster == player then
            self:TerminateDomain("CasterLeft")
        end
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self:RefreshPlayerDomainState(player)
    end

    game:BindToClose(function()
        self:TerminateDomain("ServerShutdown")
    end)

    task.spawn(function()
        self:_cooldownLoop()
    end)
end

return DomainService
