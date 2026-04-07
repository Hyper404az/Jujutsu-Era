local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)

local HUDController = {}
HUDController.__index = HUDController

local function formatNumber(value)
    local resolved = math.max(0, math.floor(tonumber(value) or 0))
    local text = tostring(resolved)

    while true do
        local updated, count = string.gsub(text, "^(-?%d+)(%d%d%d)", "%1,%2")
        text = updated
        if count == 0 then
            break
        end
    end

    return text
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function makeLabel(parent, text, size, position, font, textSize, color)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text
    label.Size = size
    label.Position = position
    label.Font = font
    label.TextSize = textSize
    label.TextColor3 = color
    label.Parent = parent
    return label
end

function HUDController.new(network)
    local self = setmetatable({}, HUDController)
    self._network = network
    self._player = Players.LocalPlayer
    self._bars = {}
    self._barLabels = {}
    self._abilityCards = {}
    self._clockAccumulator = 0
    self:_build()
    self:_bind()
    self:RefreshFromServer()
    self:RefreshStats()
    return self
end

function HUDController:_makePanel(parent, size, position, backgroundColor)
    local panel = Instance.new("Frame")
    panel.Size = size
    panel.Position = position
    panel.BackgroundColor3 = backgroundColor or Color3.fromRGB(16, 19, 28)
    panel.BackgroundTransparency = 0.14
    panel.BorderSizePixel = 0
    panel.Parent = parent
    makeCorner(panel, 16)
    makeStroke(panel, Color3.fromRGB(255, 255, 255), 0.9)
    return panel
end

function HUDController:_makeBar(parent, title, yOffset, color)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -32, 0, 26)
    container.Position = UDim2.new(0, 16, 0, yOffset)
    container.BackgroundTransparency = 1
    container.Parent = parent

    local label = makeLabel(
        container,
        title,
        UDim2.new(1, 0, 0, 10),
        UDim2.new(0, 0, 0, 0),
        Enum.Font.GothamBold,
        11,
        Color3.fromRGB(232, 236, 244)
    )
    label.TextXAlignment = Enum.TextXAlignment.Left

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, 0, 0, 12)
    track.Position = UDim2.new(0, 0, 0, 14)
    track.BackgroundColor3 = Color3.fromRGB(32, 37, 49)
    track.BorderSizePixel = 0
    track.Parent = container
    makeCorner(track, 999)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = color
    fill.BorderSizePixel = 0
    fill.Parent = track
    makeCorner(fill, 999)

    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, color:Lerp(Color3.new(1, 1, 1), 0.12)),
        ColorSequenceKeypoint.new(1, color),
    })
    gradient.Parent = fill

    return fill, label
end

function HUDController:_buildControls(panel)
    local title = makeLabel(
        panel,
        "Controls",
        UDim2.new(1, -24, 0, 20),
        UDim2.new(0, 12, 0, 10),
        Enum.Font.GothamBold,
        16,
        Color3.fromRGB(245, 247, 251)
    )
    title.TextXAlignment = Enum.TextXAlignment.Left

    for index, control in ipairs(GameplayConfig.ControlHints) do
        local row = Instance.new("Frame")
        row.Size = UDim2.new(1, -24, 0, 22)
        row.Position = UDim2.new(0, 12, 0, 34 + ((index - 1) * 24))
        row.BackgroundTransparency = 1
        row.Parent = panel

        local keyBadge = Instance.new("TextLabel")
        keyBadge.Size = UDim2.new(0, 58, 0, 20)
        keyBadge.Position = UDim2.new(0, 0, 0, 1)
        keyBadge.BackgroundColor3 = Color3.fromRGB(28, 34, 48)
        keyBadge.BorderSizePixel = 0
        keyBadge.Text = control.Key
        keyBadge.TextColor3 = Color3.fromRGB(244, 246, 250)
        keyBadge.Font = Enum.Font.GothamBold
        keyBadge.TextSize = 11
        keyBadge.Parent = row
        makeCorner(keyBadge, 8)

        local actionLabel = makeLabel(
            row,
            control.Action,
            UDim2.new(1, -68, 1, 0),
            UDim2.new(0, 68, 0, 0),
            Enum.Font.Gotham,
            12,
            Color3.fromRGB(210, 216, 227)
        )
        actionLabel.TextXAlignment = Enum.TextXAlignment.Left
    end
end

function HUDController:_buildAbilitySlots(panel)
    local title = makeLabel(
        panel,
        "Technique Slots",
        UDim2.new(1, -24, 0, 20),
        UDim2.new(0, 12, 0, 10),
        Enum.Font.GothamBold,
        16,
        Color3.fromRGB(245, 247, 251)
    )
    title.TextXAlignment = Enum.TextXAlignment.Left

    for index = 1, GameplayConfig.HudAbilitySlots do
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, -24, 0, 36)
        card.Position = UDim2.new(0, 12, 0, 38 + ((index - 1) * 40))
        card.BackgroundColor3 = Color3.fromRGB(24, 28, 39)
        card.BorderSizePixel = 0
        card.Parent = panel
        makeCorner(card, 10)

        local slotLabel = makeLabel(
            card,
            tostring(index),
            UDim2.new(0, 24, 1, 0),
            UDim2.new(0, 10, 0, 0),
            Enum.Font.GothamBlack,
            15,
            Color3.fromRGB(245, 229, 168)
        )

        local nameLabel = makeLabel(
            card,
            "Empty Slot",
            UDim2.new(0.56, 0, 1, 0),
            UDim2.new(0, 42, 0, 0),
            Enum.Font.GothamBold,
            12,
            Color3.fromRGB(237, 240, 246)
        )
        nameLabel.TextXAlignment = Enum.TextXAlignment.Left

        local metaLabel = makeLabel(
            card,
            "Equip a technique",
            UDim2.new(0.32, 0, 1, 0),
            UDim2.new(1, -118, 0, 0),
            Enum.Font.Gotham,
            11,
            Color3.fromRGB(180, 188, 201)
        )
        metaLabel.TextXAlignment = Enum.TextXAlignment.Right

        self._abilityCards[index] = {
            SlotLabel = slotLabel,
            NameLabel = nameLabel,
            MetaLabel = metaLabel,
            Card = card,
        }
    end
end

function HUDController:_build()
    local playerGui = self._player:WaitForChild("PlayerGui")
    local existing = playerGui:FindFirstChild("JERuntimeHUD")
    if existing then
        existing:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "JERuntimeHUD"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui
    self._gui = gui

    local controlsPanel = self:_makePanel(gui, UDim2.new(0, 250, 0, 158), UDim2.new(0, 18, 0, 18), Color3.fromRGB(18, 22, 34))
    self:_buildControls(controlsPanel)

    self._missionCard = self:_makePanel(gui, UDim2.new(0, 420, 0, 88), UDim2.new(0.5, -210, 0, 18), Color3.fromRGB(22, 25, 36))
    local missionTitle = makeLabel(
        self._missionCard,
        "Mission Board",
        UDim2.new(1, -24, 0, 18),
        UDim2.new(0, 12, 0, 10),
        Enum.Font.GothamBold,
        15,
        Color3.fromRGB(245, 247, 251)
    )
    missionTitle.TextXAlignment = Enum.TextXAlignment.Left

    self._missionLabel = makeLabel(
        self._missionCard,
        "",
        UDim2.new(1, -24, 1, -34),
        UDim2.new(0, 12, 0, 30),
        Enum.Font.Gotham,
        13,
        Color3.fromRGB(232, 215, 178)
    )
    self._missionLabel.TextWrapped = true
    self._missionLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._missionLabel.TextYAlignment = Enum.TextYAlignment.Top

    local economyPanel = self:_makePanel(gui, UDim2.new(0, 300, 0, 168), UDim2.new(0, 18, 1, -188), Color3.fromRGB(17, 20, 31))
    self._infoLabel = makeLabel(
        economyPanel,
        "",
        UDim2.new(1, -24, 0, 74),
        UDim2.new(0, 12, 0, 12),
        Enum.Font.Gotham,
        13,
        Color3.fromRGB(229, 234, 243)
    )
    self._infoLabel.TextWrapped = true
    self._infoLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._infoLabel.TextYAlignment = Enum.TextYAlignment.Top

    self._yenLabel = makeLabel(
        economyPanel,
        "Yen 0",
        UDim2.new(1, -24, 0, 18),
        UDim2.new(0, 12, 0, 94),
        Enum.Font.GothamBold,
        14,
        Color3.fromRGB(255, 226, 132)
    )
    self._yenLabel.TextXAlignment = Enum.TextXAlignment.Left

    self._fragmentLabel = makeLabel(
        economyPanel,
        "Fragmentos 0",
        UDim2.new(1, -24, 0, 18),
        UDim2.new(0, 12, 0, 116),
        Enum.Font.GothamBold,
        14,
        Color3.fromRGB(130, 229, 255)
    )
    self._fragmentLabel.TextXAlignment = Enum.TextXAlignment.Left

    self._clockLabel = makeLabel(
        economyPanel,
        "Server 00:00:00",
        UDim2.new(1, -24, 0, 18),
        UDim2.new(0, 12, 1, -28),
        Enum.Font.Gotham,
        12,
        Color3.fromRGB(183, 191, 205)
    )
    self._clockLabel.TextXAlignment = Enum.TextXAlignment.Left

    local statusPanel = self:_makePanel(gui, UDim2.new(0, 520, 0, 128), UDim2.new(0.5, -260, 1, -150), Color3.fromRGB(20, 21, 32))
    self._levelLabel = makeLabel(
        statusPanel,
        "",
        UDim2.new(1, -24, 0, 18),
        UDim2.new(0, 12, 0, 10),
        Enum.Font.GothamBold,
        16,
        Color3.fromRGB(246, 247, 249)
    )
    self._levelLabel.TextXAlignment = Enum.TextXAlignment.Left

    self._bars.XP, self._barLabels.XP = self:_makeBar(statusPanel, "XP", 36, Color3.fromRGB(240, 189, 76))
    self._bars.Health, self._barLabels.Health = self:_makeBar(statusPanel, "HP", 66, Color3.fromRGB(203, 83, 101))
    self._bars.Focus, self._barLabels.Focus = self:_makeBar(statusPanel, "Cursed Energy", 96, Color3.fromRGB(78, 171, 255))

    local loadoutPanel = self:_makePanel(gui, UDim2.new(0, 332, 0, 246), UDim2.new(1, -350, 1, -266), Color3.fromRGB(17, 21, 33))
    self:_buildAbilitySlots(loadoutPanel)

    self._messageLabel = makeLabel(
        gui,
        "",
        UDim2.new(0, 520, 0, 24),
        UDim2.new(0.5, -260, 1, -24),
        Enum.Font.Gotham,
        14,
        Color3.fromRGB(245, 243, 247)
    )
end

function HUDController:_formatMissionText(payload)
    if not payload or not payload.Id or payload.Id == "" then
        return "Sem missao ativa. Fale com um NPC de missao no mapa."
    end

    local rewardParts = {
        string.format("%s XP", formatNumber(payload.RewardXP or 0)),
    }

    if (payload.RewardYen or 0) > 0 then
        table.insert(rewardParts, string.format("%s Yen", formatNumber(payload.RewardYen)))
    end

    if (payload.RewardFragments or 0) > 0 then
        table.insert(rewardParts, string.format("%s Frag", formatNumber(payload.RewardFragments)))
    end

    return string.format(
        "[%s] %s\nProgress %d/%d   Reward %s",
        payload.Category or "Missao",
        payload.Name or "Missao",
        payload.Progress or 0,
        payload.Goal or 0,
        table.concat(rewardParts, " | ")
    )
end

function HUDController:_setMessage(text, messageType)
    local palette = {
        Success = Color3.fromRGB(162, 249, 183),
        Error = Color3.fromRGB(255, 171, 171),
        Info = Color3.fromRGB(222, 230, 242),
    }

    self._messageLabel.TextTransparency = 1
    self._messageLabel.TextColor3 = palette[messageType] or Color3.fromRGB(245, 243, 247)
    self._messageLabel.Text = text or ""

    TweenService:Create(self._messageLabel, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        TextTransparency = 0,
    }):Play()
end

function HUDController:_updateClock()
    local success, serverTime = pcall(function()
        return workspace:GetServerTimeNow()
    end)

    if not success then
        return
    end

    local clock = DateTime.fromUnixTimestamp(math.floor(serverTime)):ToLocalTime()
    self._clockLabel.Text = string.format("Server %02d:%02d:%02d", clock.Hour, clock.Minute, clock.Second)
end

function HUDController:_bind()
    local observed = {
        "Health",
        "MaxHealth",
        "Focus",
        "MaxFocus",
        "Clan",
        "SubTechnique",
        "Level",
        "XP",
        "XPToNextLevel",
        "Mastery",
        "Rank",
        "ProgressionPhase",
        "Faction",
        "CanChooseFaction",
        "EnchantedMode",
        "Yen",
        "Fragments",
        "HasStarted",
    }

    for _, attributeName in ipairs(observed) do
        self._player:GetAttributeChangedSignal(attributeName):Connect(function()
            self:RefreshStats()
        end)
    end

    self._network:GetEvent("MissionUpdate").OnClientEvent:Connect(function(payload)
        self._missionLabel.Text = self:_formatMissionText(payload)
    end)

    self._network:GetEvent("ServerMessage").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end

        self:_setMessage(payload.Text or "", payload.Type)
    end)

    self._network:GetEvent("AbilityResult").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end

        self:_setMessage(payload.Reason or "", payload.Success and "Success" or "Error")
    end)

    for _, attributeName in ipairs({ "Clan", "SubTechnique", "Mastery" }) do
        self._player:GetAttributeChangedSignal(attributeName):Connect(function()
            self:RefreshFromServer()
        end)
    end

    RunService.RenderStepped:Connect(function(deltaTime)
        self._clockAccumulator += deltaTime
        if self._clockAccumulator >= GameplayConfig.HudClockRefreshRate then
            self._clockAccumulator = 0
            self:_updateClock()
        end
    end)
end

function HUDController:RefreshStats()
    local hasStarted = self._player:GetAttribute("HasStarted") == true
    self._gui.Enabled = hasStarted
    if not hasStarted then
        return
    end

    local health = self._player:GetAttribute("Health") or 0
    local maxHealth = self._player:GetAttribute("MaxHealth") or 100
    local focus = self._player:GetAttribute("Focus") or 0
    local maxFocus = self._player:GetAttribute("MaxFocus") or 100
    local xp = self._player:GetAttribute("XP") or 0
    local xpToNext = self._player:GetAttribute("XPToNextLevel") or 0
    local level = self._player:GetAttribute("Level") or 1
    local rank = self._player:GetAttribute("Rank") or "Grade 4"
    local clan = self._player:GetAttribute("Clan") or "Commoner"
    local subTechnique = self._player:GetAttribute("SubTechnique") or ""
    local mastery = self._player:GetAttribute("Mastery") or 0
    local phase = self._player:GetAttribute("ProgressionPhase") or "Iniciante"
    local faction = self._player:GetAttribute("Faction") or "Unaffiliated"
    local canChooseFaction = self._player:GetAttribute("CanChooseFaction") == true
    local enchanted = self._player:GetAttribute("EnchantedMode") == true

    self._bars.XP.Size = UDim2.new(xpToNext <= 0 and 1 or math.clamp(xp / xpToNext, 0, 1), 0, 1, 0)
    self._bars.Health.Size = UDim2.new(maxHealth > 0 and math.clamp(health / maxHealth, 0, 1) or 0, 0, 1, 0)
    self._bars.Focus.Size = UDim2.new(maxFocus > 0 and math.clamp(focus / maxFocus, 0, 1) or 0, 0, 1, 0)

    self._levelLabel.Text = string.format("Level %d   %s", level, rank)
    self._barLabels.XP.Text = xpToNext <= 0
        and "XP  MAX LEVEL"
        or string.format("XP  %s/%s", formatNumber(xp), formatNumber(xpToNext))
    self._barLabels.Health.Text = string.format("HP  %s/%s", formatNumber(health), formatNumber(maxHealth))
    self._barLabels.Focus.Text = string.format("Cursed Energy  %s/%s", formatNumber(focus), formatNumber(maxFocus))

    self._infoLabel.Text = string.format(
        "Clan %s%s\nFaccao %s%s\nFase %s   Maestria %s\nEnchanted %s",
        clan,
        subTechnique ~= "" and (" [" .. subTechnique .. "]") or "",
        faction,
        canChooseFaction and "" or " (bloqueada ate Lv.30)",
        phase,
        formatNumber(mastery),
        enchanted and "ACTIVE" or "READY"
    )

    self._yenLabel.Text = string.format("Yen  %s", formatNumber(self._player:GetAttribute("Yen") or 0))
    self._fragmentLabel.Text = string.format("Fragmentos  %s", formatNumber(self._player:GetAttribute("Fragments") or 0))
    self:_updateClock()
end

function HUDController:RefreshFromServer()
    local state = self._network:Invoke("GetClientState")
    local abilities = state.Abilities or {}

    for index = 1, GameplayConfig.HudAbilitySlots do
        local card = self._abilityCards[index]
        local ability = abilities[index]

        if ability then
            card.SlotLabel.Text = ability.Key or tostring(index)
            card.NameLabel.Text = ability.Name or "Technique"
            card.MetaLabel.Text = string.format("CE %s | CD %.1fs", formatNumber(ability.FocusCost or 0), ability.Cooldown or 0)
            card.Card.BackgroundColor3 = Color3.fromRGB(24, 28, 39)
        else
            card.SlotLabel.Text = tostring(index)
            card.NameLabel.Text = "Empty Slot"
            card.MetaLabel.Text = "Not equipped"
            card.Card.BackgroundColor3 = Color3.fromRGB(20, 24, 33)
        end
    end

    self._missionLabel.Text = self:_formatMissionText(state.Mission)
end

return HUDController
