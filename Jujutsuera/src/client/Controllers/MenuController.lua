local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClanConfig = require(ReplicatedStorage.Shared.Config.ClanConfig)

local MenuController = {}
MenuController.__index = MenuController

local RARITY_COLORS = {
    Common = Color3.fromRGB(126, 147, 189),
    Rare = Color3.fromRGB(87, 205, 255),
    Epic = Color3.fromRGB(196, 99, 255),
    Legendary = Color3.fromRGB(255, 212, 94),
}

local THEME = {
    Root = Color3.fromRGB(9, 4, 13),
    Crimson = Color3.fromRGB(183, 24, 43),
    CrimsonDeep = Color3.fromRGB(114, 10, 32),
    PurpleBright = Color3.fromRGB(166, 92, 255),
    Cyan = Color3.fromRGB(72, 222, 255),
    Gold = Color3.fromRGB(255, 206, 92),
    Green = Color3.fromRGB(77, 210, 102),
    Red = Color3.fromRGB(220, 45, 45),
    Blue = Color3.fromRGB(54, 145, 255),
    Surface = Color3.fromRGB(32, 23, 41),
    SurfaceAlt = Color3.fromRGB(56, 44, 71),
    Text = Color3.fromRGB(246, 241, 231),
    TextMuted = Color3.fromRGB(211, 197, 209),
    Shadow = Color3.fromRGB(8, 6, 12),
}

local BUTTON_TWEEN = TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PANEL_TWEEN = TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local PITY_LIMITS = { Legendary = 150, Epic = 50 }
local WHEEL_SLOT_COUNT = 5

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function makeStroke(parent, color, transparency, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Transparency = transparency or 0
    stroke.Thickness = thickness or 1
    stroke.Parent = parent
    return stroke
end

local function makeText(parent, text, position, size, font, textSize, color, zIndex)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Position = position
    label.Size = size
    label.Font = font
    label.Text = text
    label.TextSize = textSize
    label.TextColor3 = color
    label.ZIndex = zIndex or 1
    label.Parent = parent
    return label
end

local function makePanel(parent, size, position, backgroundColor, transparency, radius, zIndex)
    local frame = Instance.new("Frame")
    frame.Size = size
    frame.Position = position
    frame.BackgroundColor3 = backgroundColor
    frame.BackgroundTransparency = transparency or 0
    frame.BorderSizePixel = 0
    frame.ZIndex = zIndex or 1
    frame.Parent = parent
    makeCorner(frame, radius or 12)
    return frame
end

local function addGradient(parent, rotation, colorA, colorB)
    local gradient = Instance.new("UIGradient")
    gradient.Rotation = rotation or 0
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, colorA),
        ColorSequenceKeypoint.new(1, colorB),
    })
    gradient.Parent = parent
    return gradient
end

local function wrapIndex(index, count)
    while index < 1 do
        index = index + count
    end
    while index > count do
        index = index - count
    end
    return index
end

local function toChanceText(value)
    return string.format("%.1f%%", value or 0)
end

local function getClanDefinition(clanName)
    return ClanConfig.Clans[clanName] or ClanConfig.Clans[ClanConfig.DefaultClan]
end

local function getClanDisplayName(clanName)
    local definition = getClanDefinition(clanName)
    return definition.DisplayName or clanName or ClanConfig.DefaultClan
end

local function buildClanFeatureList(clanName, subTechnique)
    local definition = getClanDefinition(clanName)
    local items = {}
    for _, summary in ipairs(definition.BuffSummary or {}) do
        table.insert(items, summary)
    end
    if clanName == "Zenin" and subTechnique and subTechnique ~= "" then
        table.insert(items, "Subtecnica equipada: " .. subTechnique)
    end
    if #items == 0 then
        table.insert(items, "Sem bonus especiais.")
    end
    return items
end

local function computeHigherDelta(currentValue, nextValue)
    if nextValue <= currentValue or currentValue <= 0 then
        return nil
    end
    return math.max(1, math.floor(((nextValue / currentValue) - 1) * 100 + 0.5))
end

local function computeLowerDelta(currentValue, nextValue)
    if nextValue >= currentValue or currentValue <= 0 then
        return nil
    end
    return math.max(1, math.floor((1 - (nextValue / currentValue)) * 100 + 0.5))
end

local function appendUnique(list, value)
    for _, existing in ipairs(list) do
        if existing == value then
            return
        end
    end
    table.insert(list, value)
end

local function buildClanComparison(currentClan, currentSubTechnique, previewClan, previewSubTechnique)
    local currentDefinition = getClanDefinition(currentClan)
    local previewDefinition = getClanDefinition(previewClan)
    local currentModifiers = currentDefinition.Modifiers or {}
    local previewModifiers = previewDefinition.Modifiers or {}
    local currentDamage = currentModifiers.DamageMultipliers or {}
    local previewDamage = previewModifiers.DamageMultipliers or {}
    local losses = {}
    local gains = {}

    local function compareHigher(label, currentValue, nextValue)
        local delta = computeHigherDelta(currentValue, nextValue)
        if delta then
            appendUnique(losses, string.format("%s -%d%%", label, delta))
            appendUnique(gains, string.format("%s +%d%%", label, delta))
        end
    end

    local function compareLower(label, currentValue, nextValue)
        local delta = computeLowerDelta(currentValue, nextValue)
        if delta then
            appendUnique(losses, string.format("%s -%d%%", label, delta))
            appendUnique(gains, string.format("%s +%d%%", label, delta))
        end
    end

    compareHigher("Vida", currentModifiers.MaxHealthMultiplier or 1, previewModifiers.MaxHealthMultiplier or 1)
    compareHigher("Foco", currentModifiers.MaxFocusMultiplier or 1, previewModifiers.MaxFocusMultiplier or 1)
    compareLower("Custo de foco", currentModifiers.FocusCostMultiplier or 1, previewModifiers.FocusCostMultiplier or 1)
    compareHigher("Regeneracao", currentModifiers.RegenMultiplier or 1, previewModifiers.RegenMultiplier or 1)
    compareLower("Resistencia", currentModifiers.ResistanceMultiplier or 1, previewModifiers.ResistanceMultiplier or 1)
    compareHigher("Combate corpo a corpo", currentDamage.Physical or 1, previewDamage.Physical or 1)
    compareHigher("Dano amaldicoado", currentDamage.Cursed or 1, previewDamage.Cursed or 1)
    compareHigher("Dano de dominio", currentDamage.Domain or 1, previewDamage.Domain or 1)
    compareHigher("Dano especial", currentDamage.Special or 1, previewDamage.Special or 1)

    if previewModifiers.SixEyes and not currentModifiers.SixEyes then
        appendUnique(losses, "Sem Seis Olhos")
        appendUnique(gains, "Seis Olhos ativo")
    end
    if previewModifiers.BlackFlash and not currentModifiers.BlackFlash then
        appendUnique(losses, "Sem Black Flash")
        appendUnique(gains, "Black Flash manual")
    end
    if previewModifiers.HasSubTechniques and not currentModifiers.HasSubTechniques then
        appendUnique(losses, "Sem subtecnicas")
        appendUnique(gains, "Subtecnicas Zenin")
    end

    if previewClan == currentClan and previewSubTechnique == currentSubTechnique then
        losses = { "Mesmo cla em destaque" }
        gains = { "Mesmo potencial atual" }
    end

    if #gains < 3 then
        for _, summary in ipairs(previewDefinition.BuffSummary or {}) do
            appendUnique(gains, summary)
            if #gains >= 4 then
                break
            end
        end
    end

    if #losses < 3 then
        for _, summary in ipairs(currentDefinition.BuffSummary or {}) do
            appendUnique(losses, "Perde: " .. summary)
            if #losses >= 4 then
                break
            end
        end
    end

    if #gains == 0 then
        gains = { "Sem ganho estatistico direto" }
    end
    if #losses == 0 then
        losses = { "Sem perda relevante" }
    end
    return losses, gains
end

function MenuController.new(network)
    local self = setmetatable({}, MenuController)
    self._network = network
    self._player = Players.LocalPlayer
    self._wheelSlots = {}
    self._spinButtons = {}
    self._decisionButtons = {}
    self._offerButtons = {}
    self._rateLabels = {}
    self._chanceByClan = {}
    self._rateSummary = {}
    self._spinRollPool = {}
    self._spinPending = false
    self._spinDecisionPending = false
    self._spinDecisionSubmitting = false
    self._spinAnimationToken = 0
    self._spinRequestId = 0
    self._wheelIndex = 1
    self:_buildSpinRollPool()
    self:_build()
    self:_bind()
    self:ShowMainView()
    self:Refresh()
    return self
end

function MenuController:_buildSpinRollPool()
    local pool = {}
    local chanceByClan = {}
    local totalWeight = 0
    local summary = { Common = 0, Rare = 0, Epic = 0, Legendary = 0 }

    for _, config in pairs(ClanConfig.Clans) do
        totalWeight = totalWeight + (config.Weight or 0)
    end

    for clanName, clanData in pairs(ClanConfig.Clans) do
        local chance = totalWeight > 0 and ((clanData.Weight or 0) / totalWeight) * 100 or 0
        summary[clanData.Rarity] = (summary[clanData.Rarity] or 0) + chance
        chanceByClan[clanName] = chance
        table.insert(pool, {
            Clan = clanName,
            DisplayName = clanData.DisplayName or clanName,
            Chance = chance,
            Rarity = clanData.Rarity,
            AccentColor = RARITY_COLORS[clanData.Rarity] or THEME.Text,
        })
    end

    table.sort(pool, function(left, right)
        if left.Chance == right.Chance then
            return left.DisplayName < right.DisplayName
        end
        return left.Chance > right.Chance
    end)

    self._spinRollPool = pool
    self._chanceByClan = chanceByClan
    self._rateSummary = summary
end

function MenuController:_createMenuBlur()
    local blur = Lighting:FindFirstChild("JEMenuBlur")
    if not blur then
        blur = Instance.new("BlurEffect")
        blur.Name = "JEMenuBlur"
        blur.Size = 18
        blur.Enabled = false
        blur.Parent = Lighting
    end
    self._menuBlur = blur
end

function MenuController:_buildBackground(root)
    root.BackgroundColor3 = THEME.Root
    root.BackgroundTransparency = 0.14
    addGradient(root, 325, Color3.fromRGB(32, 7, 17), Color3.fromRGB(91, 26, 94))

    local haze = Instance.new("Frame")
    haze.Size = UDim2.fromScale(1, 1)
    haze.BackgroundTransparency = 0.42
    haze.BackgroundColor3 = Color3.fromRGB(44, 7, 15)
    haze.BorderSizePixel = 0
    haze.Parent = root
    addGradient(haze, 0, Color3.fromRGB(12, 4, 9), Color3.fromRGB(108, 21, 39))

    local leftGlow = makePanel(root, UDim2.new(0, 360, 0, 360), UDim2.new(0, -80, 0.22, 0), THEME.Crimson, 0.48, 999, 0)
    addGradient(leftGlow, 20, THEME.Crimson, THEME.PurpleBright)
    local rightGlow = makePanel(root, UDim2.new(0, 340, 0, 340), UDim2.new(1, -260, 0.04, 0), THEME.PurpleBright, 0.54, 999, 0)
    addGradient(rightGlow, 65, THEME.PurpleBright, THEME.Crimson)

    local orbDefinitions = {
        { Size = 44, Position = UDim2.new(0.14, 0, 0.16, 0), Color = THEME.Gold, Transparency = 0.2 },
        { Size = 54, Position = UDim2.new(0.24, 0, 0.78, 0), Color = Color3.fromRGB(255, 148, 238), Transparency = 0.26 },
        { Size = 38, Position = UDim2.new(0.72, 0, 0.22, 0), Color = THEME.Cyan, Transparency = 0.22 },
        { Size = 30, Position = UDim2.new(0.83, 0, 0.67, 0), Color = THEME.Gold, Transparency = 0.24 },
    }

    for _, orb in ipairs(orbDefinitions) do
        local glow = Instance.new("Frame")
        glow.AnchorPoint = Vector2.new(0.5, 0.5)
        glow.Position = orb.Position
        glow.Size = UDim2.new(0, orb.Size, 0, orb.Size)
        glow.BackgroundColor3 = orb.Color
        glow.BackgroundTransparency = orb.Transparency
        glow.BorderSizePixel = 0
        glow.Parent = root
        makeCorner(glow, 999)
    end
end

function MenuController:_bindPanelHover(frame, label, normalColor, hoverColor)
    local originalText = label and label.TextColor3 or nil

    frame.MouseEnter:Connect(function()
        TweenService:Create(frame, BUTTON_TWEEN, { BackgroundColor3 = hoverColor }):Play()
        if label and originalText then
            TweenService:Create(label, BUTTON_TWEEN, { TextColor3 = THEME.Text }):Play()
        end
    end)

    frame.MouseLeave:Connect(function()
        TweenService:Create(frame, BUTTON_TWEEN, { BackgroundColor3 = normalColor }):Play()
        if label and originalText then
            TweenService:Create(label, BUTTON_TWEEN, { TextColor3 = originalText }):Play()
        end
    end)
end

function MenuController:_makePrimaryButton(parent, text, position, accentColor)
    local frame = Instance.new("TextButton")
    frame.Size = UDim2.new(0, 240, 0, 48)
    frame.Position = position
    frame.BackgroundColor3 = THEME.Surface
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = parent
    makeCorner(frame, 12)
    makeStroke(frame, accentColor, 0.25, 1.25)
    addGradient(frame, 0, THEME.SurfaceAlt, THEME.Surface)

    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(0, 6, 1, -12)
    accent.Position = UDim2.new(0, 10, 0, 6)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = frame
    makeCorner(accent, 999)

    local label = makeText(frame, text, UDim2.new(0, 28, 0, 0), UDim2.new(1, -38, 1, 0), Enum.Font.GothamBold, 18, THEME.Text, 3)
    label.TextXAlignment = Enum.TextXAlignment.Left
    self:_bindPanelHover(frame, label, THEME.Surface, Color3.fromRGB(66, 45, 80))
    return frame
end

function MenuController:_makeOfferButton(parent, text, subtext, order, accentColor, callback)
    local frame = Instance.new("TextButton")
    frame.Size = UDim2.new(1, 0, 0, 52)
    frame.Position = UDim2.new(0, 0, 0, (order - 1) * 62)
    frame.BackgroundColor3 = Color3.fromRGB(27, 23, 34)
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = parent
    makeCorner(frame, 12)
    makeStroke(frame, accentColor, 0.15, 1.2)
    addGradient(frame, 0, Color3.fromRGB(18, 20, 30), Color3.fromRGB(43, 34, 55))

    local leftBlock = makePanel(frame, UDim2.new(0, 34, 1, -8), UDim2.new(0, 4, 0, 4), accentColor, 0.08, 10, 3)
    addGradient(leftBlock, 90, accentColor, Color3.fromRGB(33, 24, 20))

    local mainLabel = makeText(frame, text, UDim2.new(0, 46, 0, 6), UDim2.new(1, -98, 0, 20), Enum.Font.GothamBold, 13, THEME.Text, 3)
    mainLabel.TextXAlignment = Enum.TextXAlignment.Left
    mainLabel.TextScaled = true
    local subLabel = makeText(frame, subtext, UDim2.new(0, 46, 0, 28), UDim2.new(1, -104, 0, 14), Enum.Font.Gotham, 10, THEME.TextMuted, 3)
    subLabel.TextXAlignment = Enum.TextXAlignment.Left
    subLabel.TextScaled = true

    local pricePill = makePanel(frame, UDim2.new(0, 54, 0, 24), UDim2.new(1, -60, 0.5, -12), THEME.Gold, 0.05, 8, 3)
    addGradient(pricePill, 90, THEME.Gold, Color3.fromRGB(255, 158, 74))
    local priceLabel = makeText(pricePill, order == 1 and "FREE" or tostring(order), UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBlack, 11, Color3.fromRGB(43, 24, 8), 4)
    priceLabel.TextScaled = true

    self:_bindPanelHover(frame, mainLabel, Color3.fromRGB(27, 23, 34), Color3.fromRGB(52, 39, 67))
    frame.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    table.insert(self._offerButtons, { Button = frame })
    return frame
end

function MenuController:_makeFooterButton(parent, text, position, accentColor, callback)
    local frame = Instance.new("TextButton")
    frame.Size = UDim2.new(0, 220, 1, 0)
    frame.Position = position
    frame.BackgroundColor3 = Color3.fromRGB(42, 18, 26)
    frame.BorderSizePixel = 0
    frame.Text = ""
    frame.AutoButtonColor = false
    frame.Parent = parent
    makeCorner(frame, 12)
    makeStroke(frame, accentColor, 0.08, 1.3)
    addGradient(frame, 0, Color3.fromRGB(72, 27, 43), Color3.fromRGB(38, 20, 28))

    local label = makeText(frame, text, UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBlack, 14, THEME.Text, 3)
    label.TextScaled = true
    self:_bindPanelHover(frame, label, Color3.fromRGB(42, 18, 26), Color3.fromRGB(72, 27, 43))

    frame.MouseButton1Click:Connect(function()
        if callback then
            callback()
        end
    end)

    return frame
end

function MenuController:_makeWheelSlot(parent, index)
    local isCenter = index == 3
    local size = isCenter and 106 or 92
    local xScale = 0.12 + ((index - 1) * 0.19)

    local slot = makePanel(parent, UDim2.new(0, size, 0, size), UDim2.new(xScale, 0, 0.52, 0), Color3.fromRGB(28, 34, 56), 0.15, 999, 4)
    slot.AnchorPoint = Vector2.new(0.5, 0.5)
    makeStroke(slot, Color3.fromRGB(88, 182, 255), isCenter and 0.04 or 0.28, isCenter and 2 or 1.3)
    addGradient(slot, 90, Color3.fromRGB(18, 27, 49), Color3.fromRGB(46, 63, 93))

    local inner = makePanel(slot, UDim2.new(1, -14, 1, -14), UDim2.new(0, 7, 0, 7), Color3.fromRGB(15, 19, 34), 0.16, 999, 5)
    makeStroke(inner, THEME.Cyan, 0.68, 1)

    local nameLabel = makeText(inner, "CLAN", UDim2.new(0, 6, 0.28, 0), UDim2.new(1, -12, 0, 28), Enum.Font.GothamBlack, isCenter and 18 or 15, THEME.Text, 6)
    nameLabel.TextScaled = true
    local chanceLabel = makeText(inner, "0.0%", UDim2.new(0, 10, 1, -28), UDim2.new(1, -20, 0, 14), Enum.Font.GothamBold, 10, THEME.TextMuted, 6)
    chanceLabel.TextScaled = true

    local glow = Instance.new("Frame")
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.new(0.5, 0, 0.5, 0)
    glow.Size = UDim2.new(1, 18, 1, 18)
    glow.BackgroundTransparency = 0.82
    glow.BorderSizePixel = 0
    glow.ZIndex = 3
    glow.Parent = slot
    makeCorner(glow, 999)

    self._wheelSlots[index] = {
        Slot = slot,
        NameLabel = nameLabel,
        ChanceLabel = chanceLabel,
        Glow = glow,
        IsCenter = isCenter,
        BaseSize = size,
    }
end

function MenuController:_buildMainView(root)
    self._mainView = Instance.new("Frame")
    self._mainView.Size = UDim2.fromScale(1, 1)
    self._mainView.BackgroundTransparency = 1
    self._mainView.Parent = root

    local title = makeText(self._mainView, "JUJUTSU ERA", UDim2.new(0, 52, 0, 48), UDim2.new(0, 380, 0, 90), Enum.Font.GothamBlack, 42, THEME.Text, 3)
    title.TextScaled = true
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.TextStrokeColor3 = Color3.fromRGB(111, 15, 35)
    title.TextStrokeTransparency = 0.35

    local subtitle = makeText(self._mainView, "Menu inspirado no painel premium do video de referencia.", UDim2.new(0, 54, 0, 138), UDim2.new(0, 420, 0, 24), Enum.Font.Gotham, 14, THEME.TextMuted, 3)
    subtitle.TextXAlignment = Enum.TextXAlignment.Left

    local buttons = Instance.new("Frame")
    buttons.BackgroundTransparency = 1
    buttons.Size = UDim2.new(0, 280, 0, 160)
    buttons.Position = UDim2.new(0, 52, 0, 208)
    buttons.Parent = self._mainView

    local playButton = self:_makePrimaryButton(buttons, "JOGAR", UDim2.new(0, 0, 0, 0), THEME.Cyan)
    playButton.MouseButton1Click:Connect(function()
        self._network:Fire("PlayRequest")
        workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
        self._root.Visible = false
        if self._menuBlur then
            self._menuBlur.Enabled = false
        end
    end)

    local clanButton = self:_makePrimaryButton(buttons, "GIROS DE CLA", UDim2.new(0, 0, 0, 66), THEME.Crimson)
    clanButton.MouseButton1Click:Connect(function()
        self:ShowClanView()
    end)

    local summaryCard = makePanel(self._mainView, UDim2.new(0, 360, 0, 180), UDim2.new(1, -408, 0, 86), Color3.fromRGB(26, 16, 31), 0.08, 18, 2)
    makeStroke(summaryCard, THEME.Gold, 0.18, 1.2)
    addGradient(summaryCard, 0, Color3.fromRGB(48, 18, 28), Color3.fromRGB(24, 14, 33))

    makeText(summaryCard, "RESUMO", UDim2.new(0, 20, 0, 16), UDim2.new(0, 110, 0, 26), Enum.Font.GothamBlack, 22, THEME.Gold, 3)
    self._mainClanLabel = makeText(summaryCard, "", UDim2.new(0, 20, 0, 56), UDim2.new(1, -40, 0, 30), Enum.Font.GothamBold, 20, THEME.Text, 3)
    self._mainClanLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._mainSpinsLabel = makeText(summaryCard, "", UDim2.new(0, 20, 0, 92), UDim2.new(1, -40, 0, 22), Enum.Font.Gotham, 15, THEME.TextMuted, 3)
    self._mainSpinsLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._mainStatusLabel = makeText(summaryCard, "Abra a tela de giros para usar o preview e confirmar a troca.", UDim2.new(0, 20, 0, 124), UDim2.new(1, -40, 0, 40), Enum.Font.Gotham, 13, THEME.TextMuted, 3)
    self._mainStatusLabel.TextWrapped = true
    self._mainStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    self._mainStatusLabel.TextYAlignment = Enum.TextYAlignment.Top
end

function MenuController:_buildClanView(root)
    self._clanView = Instance.new("Frame")
    self._clanView.Size = UDim2.fromScale(1, 1)
    self._clanView.BackgroundTransparency = 1
    self._clanView.Visible = false
    self._clanView.Parent = root

    local caption = makeText(self._clanView, "SEU CLA", UDim2.new(0.5, -90, 0, 24), UDim2.new(0, 180, 0, 22), Enum.Font.GothamBold, 16, THEME.TextMuted, 3)
    caption.TextScaled = true
    self._currentClanLabel = makeText(self._clanView, "COMMONER", UDim2.new(0.5, -140, 0, 48), UDim2.new(0, 280, 0, 42), Enum.Font.GothamBlack, 32, THEME.Gold, 4)
    self._currentClanLabel.TextScaled = true
    self._currentClanLabel.TextStrokeColor3 = Color3.fromRGB(111, 22, 12)
    self._currentClanLabel.TextStrokeTransparency = 0.25
    self._currentClanRarityLabel = makeText(self._clanView, "", UDim2.new(0.5, -110, 0, 92), UDim2.new(0, 220, 0, 20), Enum.Font.GothamBold, 12, THEME.Cyan, 3)
    self._currentClanRarityLabel.TextScaled = true
    self._currentSubTechniqueLabel = makeText(self._clanView, "", UDim2.new(0.5, -120, 0, 116), UDim2.new(0, 240, 0, 18), Enum.Font.Gotham, 11, THEME.TextMuted, 3)
    self._currentSubTechniqueLabel.TextScaled = true

    local leftColumn = Instance.new("Frame")
    leftColumn.BackgroundTransparency = 1
    leftColumn.Size = UDim2.new(0, 180, 0, 320)
    leftColumn.Position = UDim2.new(0, 34, 0, 150)
    leftColumn.Parent = self._clanView
    self:_makeOfferButton(leftColumn, "GRATIS DE CLA", "Usa 1 spin gratis", 1, THEME.Gold, function() self:_beginSpinRequest() end)
    self:_makeOfferButton(leftColumn, "GIRO", "Rolar uma vez", 2, THEME.Cyan, function() self:_beginSpinRequest() end)
    self:_makeOfferButton(leftColumn, "GIRO COM YEN", "Ainda nao conectado", 3, Color3.fromRGB(91, 209, 255), function() self:_showStatus("Loja em yen ainda nao esta conectada neste build.") end)
    self:_makeOfferButton(leftColumn, "GIRO DE CLA x10", "Em breve", 4, THEME.Gold, function() self:_showStatus("Spin x10 ainda nao esta conectado neste build.") end)
    self:_makeOfferButton(leftColumn, "LOJA PREMIUM", "Pacotes e passes", 5, THEME.PurpleBright, function() self:_showStatus("Loja premium ainda nao esta conectada neste build.") end)

    local ratePanel = makePanel(self._clanView, UDim2.new(0, 180, 0, 124), UDim2.new(1, -206, 0, 24), Color3.fromRGB(33, 22, 41), 0.08, 14, 2)
    makeStroke(ratePanel, THEME.Cyan, 0.22, 1.1)
    addGradient(ratePanel, 90, Color3.fromRGB(43, 30, 54), Color3.fromRGB(27, 19, 37))

    local rateY = 10
    for _, rarity in ipairs({ "Rare", "Epic", "Legendary", "Common" }) do
        local chip = makePanel(ratePanel, UDim2.new(1, -16, 0, 24), UDim2.new(0, 8, 0, rateY), RARITY_COLORS[rarity], 0.2, 8, 3)
        makeStroke(chip, RARITY_COLORS[rarity], 0.08, 1)
        local label = makeText(chip, "", UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0), Enum.Font.GothamBold, 11, THEME.Text, 4)
        label.TextScaled = true
        self._rateLabels[rarity] = label
        rateY = rateY + 28
    end

    local wheelPanel = makePanel(self._clanView, UDim2.new(0, 600, 0, 350), UDim2.new(0.5, -300, 0, 150), Color3.fromRGB(29, 19, 34), 0.2, 18, 2)
    makeStroke(wheelPanel, THEME.PurpleBright, 0.12, 1.2)
    addGradient(wheelPanel, 90, Color3.fromRGB(32, 19, 47), Color3.fromRGB(18, 15, 31))
    local panelTitle = makeText(wheelPanel, "SELECAO DE GIROS", UDim2.new(0, 0, 0, 18), UDim2.new(1, 0, 0, 28), Enum.Font.GothamBlack, 25, THEME.Text, 3)
    panelTitle.TextScaled = true

    local wheelWindow = makePanel(wheelPanel, UDim2.new(1, -64, 0, 164), UDim2.new(0, 32, 0, 62), Color3.fromRGB(59, 62, 95), 0.36, 16, 3)
    makeStroke(wheelWindow, Color3.fromRGB(100, 157, 255), 0.16, 1.3)
    addGradient(wheelWindow, 0, Color3.fromRGB(57, 66, 110), Color3.fromRGB(40, 47, 78))

    local pointer = Instance.new("Frame")
    pointer.AnchorPoint = Vector2.new(0.5, 0)
    pointer.Position = UDim2.new(0.5, 0, 0, -12)
    pointer.Size = UDim2.new(0, 6, 0, 188)
    pointer.BackgroundColor3 = THEME.Gold
    pointer.BackgroundTransparency = 0.14
    pointer.BorderSizePixel = 0
    pointer.Parent = wheelWindow
    makeCorner(pointer, 999)

    for index = 1, WHEEL_SLOT_COUNT do
        self:_makeWheelSlot(wheelWindow, index)
    end

    local banner = makePanel(wheelPanel, UDim2.new(0, 170, 0, 36), UDim2.new(0.5, -85, 0, 212), THEME.Red, 0.06, 10, 3)
    addGradient(banner, 90, Color3.fromRGB(214, 45, 42), Color3.fromRGB(120, 18, 18))
    makeStroke(banner, Color3.fromRGB(255, 177, 177), 0.18, 1)
    self._spinBannerLabel = makeText(banner, "GRATIS 0", UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBlack, 15, THEME.Text, 4)
    self._spinBannerLabel.TextScaled = true

    local actionRow = Instance.new("Frame")
    actionRow.BackgroundTransparency = 1
    actionRow.Size = UDim2.new(1, -60, 0, 40)
    actionRow.Position = UDim2.new(0, 30, 0, 264)
    actionRow.Parent = wheelPanel

    table.insert(self._spinButtons, { Button = self:_makeFooterButton(actionRow, "GIROS DE VOW VINCULANTES", UDim2.new(0, 0, 0, 0), THEME.PurpleBright, function() self:_showStatus("Vow Vinculantes ainda nao esta conectado neste build.") end), Decorative = true })
    table.insert(self._spinButtons, { Button = self:_makeFooterButton(actionRow, "GIRAR UMA VEZ", UDim2.new(0, 180, 0, 0), THEME.Blue, function() self:_beginSpinRequest() end) })
    table.insert(self._spinButtons, { Button = self:_makeFooterButton(actionRow, "GIRO RAPIDO", UDim2.new(0, 342, 0, 0), THEME.Gold, function() self:_showStatus("Giro rapido ainda nao esta conectado neste build.") end), Decorative = true })

    self._spinStatusLabel = makeText(wheelPanel, "Use o giro simples para rolar e confirmar a troca no popup central.", UDim2.new(0, 28, 0, 312), UDim2.new(1, -56, 0, 24), Enum.Font.Gotham, 12, THEME.TextMuted, 3)
    self._spinStatusLabel.TextWrapped = true

    local rightPanel = makePanel(self._clanView, UDim2.new(0, 214, 0, 336), UDim2.new(1, -248, 0, 180), Color3.fromRGB(28, 20, 35), 0.08, 18, 2)
    makeStroke(rightPanel, THEME.Cyan, 0.16, 1.2)
    addGradient(rightPanel, 90, Color3.fromRGB(37, 24, 47), Color3.fromRGB(18, 14, 26))

    local pityLegendaryCard = makePanel(rightPanel, UDim2.new(1, -24, 0, 42), UDim2.new(0, 12, 0, 14), THEME.Gold, 0.2, 12, 3)
    makeStroke(pityLegendaryCard, THEME.Gold, 0.16, 1.1)
    self._legendaryPityLabel = makeText(pityLegendaryCard, "", UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0), Enum.Font.GothamBlack, 14, THEME.Text, 4)
    self._legendaryPityLabel.TextScaled = true

    local pityEpicCard = makePanel(rightPanel, UDim2.new(1, -24, 0, 42), UDim2.new(0, 12, 0, 64), THEME.PurpleBright, 0.2, 12, 3)
    makeStroke(pityEpicCard, THEME.PurpleBright, 0.12, 1.1)
    self._epicPityLabel = makeText(pityEpicCard, "", UDim2.new(0, 10, 0, 0), UDim2.new(1, -20, 1, 0), Enum.Font.GothamBlack, 14, THEME.Text, 4)
    self._epicPityLabel.TextScaled = true

    self._benefitsTitleLabel = makeText(rightPanel, "VANTAGENS", UDim2.new(0, 16, 0, 120), UDim2.new(1, -32, 0, 20), Enum.Font.GothamBlack, 16, THEME.Text, 3)
    self._benefitsTitleLabel.TextScaled = true
    local benefitsCard = makePanel(rightPanel, UDim2.new(1, -24, 1, -154), UDim2.new(0, 12, 0, 146), Color3.fromRGB(18, 18, 24), 0.12, 14, 3)
    makeStroke(benefitsCard, THEME.Cyan, 0.22, 1)
    self._benefitsList = Instance.new("Frame")
    self._benefitsList.Size = UDim2.new(1, -18, 1, -18)
    self._benefitsList.Position = UDim2.new(0, 9, 0, 9)
    self._benefitsList.BackgroundTransparency = 1
    self._benefitsList.Parent = benefitsCard
    Instance.new("UIListLayout", self._benefitsList).Padding = UDim.new(0, 6)

    local footer = Instance.new("Frame")
    footer.BackgroundTransparency = 1
    footer.Size = UDim2.new(1, -68, 0, 42)
    footer.Position = UDim2.new(0, 34, 1, -58)
    footer.Parent = self._clanView
    self:_makeFooterButton(footer, "SAIDA", UDim2.new(0, 0, 0, 0), THEME.Red, function() self:ShowMainView() end)
    self:_makeFooterButton(footer, "GIROS DE VOW VINCULANTES", UDim2.new(0, 248, 0, 0), THEME.PurpleBright, function() self:_showStatus("Vow Vinculantes ainda nao esta conectado neste build.") end)
    table.insert(self._spinButtons, { Button = self:_makeFooterButton(footer, "GIROS DE CLA", UDim2.new(1, -220, 0, 0), THEME.Red, function() self:_beginSpinRequest() end) })
end

function MenuController:_buildModal(root)
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.fromScale(1, 1)
    backdrop.BackgroundColor3 = Color3.fromRGB(8, 4, 10)
    backdrop.BackgroundTransparency = 0.36
    backdrop.BorderSizePixel = 0
    backdrop.Visible = false
    backdrop.ZIndex = 20
    backdrop.Parent = root
    self._modalBackdrop = backdrop

    local modal = makePanel(backdrop, UDim2.new(0, 468, 0, 286), UDim2.new(0.5, -234, 0.5, -143), Color3.fromRGB(70, 73, 87), 0.06, 14, 21)
    makeStroke(modal, Color3.fromRGB(154, 168, 214), 0.12, 1.2)
    addGradient(modal, 90, Color3.fromRGB(89, 94, 114), Color3.fromRGB(61, 64, 79))
    self._modalCard = modal

    local modalTitle = makeText(modal, "MUDAR DE CLA?", UDim2.new(0, 0, 0, 14), UDim2.new(1, 0, 0, 28), Enum.Font.GothamBlack, 28, THEME.Text, 22)
    modalTitle.TextScaled = true
    local modalSubtitle = makeText(modal, "ACAO NAO PODE SER REVERENCIADA", UDim2.new(0, 0, 0, 46), UDim2.new(1, 0, 0, 18), Enum.Font.GothamBold, 11, THEME.Text, 22)
    modalSubtitle.TextScaled = true

    makeText(modal, "ATUAL", UDim2.new(0, 20, 0, 74), UDim2.new(0, 54, 0, 18), Enum.Font.GothamBlack, 10, THEME.Text, 22).TextScaled = true
    makeText(modal, "NOVO", UDim2.new(1, -74, 0, 74), UDim2.new(0, 54, 0, 18), Enum.Font.GothamBlack, 10, THEME.Text, 22).TextScaled = true

    local currentCircle = makePanel(modal, UDim2.new(0, 92, 0, 92), UDim2.new(0, 28, 0, 94), Color3.fromRGB(31, 54, 90), 0.14, 999, 22)
    makeStroke(currentCircle, THEME.Blue, 0.04, 2)
    self._modalCurrentName = makeText(currentCircle, "URO", UDim2.new(0, 8, 0, 28), UDim2.new(1, -16, 0, 28), Enum.Font.GothamBlack, 20, THEME.Gold, 23)
    self._modalCurrentName.TextScaled = true
    self._modalCurrentChance = makeText(currentCircle, "0.0%", UDim2.new(0, 16, 1, -26), UDim2.new(1, -32, 0, 14), Enum.Font.GothamBold, 9, THEME.Text, 23)
    self._modalCurrentChance.TextScaled = true
    local arrow = makeText(modal, ">>", UDim2.new(0.5, -22, 0, 122), UDim2.new(0, 44, 0, 40), Enum.Font.GothamBlack, 28, THEME.Gold, 23)
    arrow.TextScaled = true

    local previewCircle = makePanel(modal, UDim2.new(0, 92, 0, 92), UDim2.new(1, -120, 0, 94), Color3.fromRGB(19, 69, 84), 0.12, 999, 22)
    makeStroke(previewCircle, THEME.Cyan, 0.04, 2)
    self._modalPreviewName = makeText(previewCircle, "INO", UDim2.new(0, 8, 0, 28), UDim2.new(1, -16, 0, 28), Enum.Font.GothamBlack, 20, THEME.Cyan, 23)
    self._modalPreviewName.TextScaled = true
    self._modalPreviewChance = makeText(previewCircle, "0.0%", UDim2.new(0, 16, 1, -26), UDim2.new(1, -32, 0, 14), Enum.Font.GothamBold, 9, THEME.Text, 23)
    self._modalPreviewChance.TextScaled = true

    local lossesCard = makePanel(modal, UDim2.new(0, 152, 0, 92), UDim2.new(0, 18, 0, 178), Color3.fromRGB(40, 41, 52), 0.16, 10, 22)
    local gainsCard = makePanel(modal, UDim2.new(0, 152, 0, 92), UDim2.new(1, -170, 0, 178), Color3.fromRGB(40, 41, 52), 0.16, 10, 22)
    self._modalLossList = Instance.new("Frame")
    self._modalLossList.Size = UDim2.new(1, -16, 1, -12)
    self._modalLossList.Position = UDim2.new(0, 8, 0, 6)
    self._modalLossList.BackgroundTransparency = 1
    self._modalLossList.ZIndex = 23
    self._modalLossList.Parent = lossesCard
    Instance.new("UIListLayout", self._modalLossList).Padding = UDim.new(0, 4)
    self._modalGainList = Instance.new("Frame")
    self._modalGainList.Size = UDim2.new(1, -16, 1, -12)
    self._modalGainList.Position = UDim2.new(0, 8, 0, 6)
    self._modalGainList.BackgroundTransparency = 1
    self._modalGainList.ZIndex = 23
    self._modalGainList.Parent = gainsCard
    Instance.new("UIListLayout", self._modalGainList).Padding = UDim.new(0, 4)

    local confirm = Instance.new("TextButton")
    confirm.Size = UDim2.new(0, 96, 0, 38)
    confirm.Position = UDim2.new(0.5, -114, 1, -52)
    confirm.BackgroundColor3 = THEME.Green
    confirm.BorderSizePixel = 0
    confirm.Text = ""
    confirm.AutoButtonColor = false
    confirm.ZIndex = 22
    confirm.Parent = modal
    makeCorner(confirm, 10)
    self._modalConfirmLabel = makeText(confirm, "SIM", UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBlack, 18, THEME.Text, 23)
    self._modalConfirmLabel.TextScaled = true

    local reject = Instance.new("TextButton")
    reject.Size = UDim2.new(0, 96, 0, 38)
    reject.Position = UDim2.new(0.5, 18, 1, -52)
    reject.BackgroundColor3 = THEME.Red
    reject.BorderSizePixel = 0
    reject.Text = ""
    reject.AutoButtonColor = false
    reject.ZIndex = 22
    reject.Parent = modal
    makeCorner(reject, 10)
    self._modalRejectLabel = makeText(reject, "NAO", UDim2.new(0, 0, 0, 0), UDim2.fromScale(1, 1), Enum.Font.GothamBlack, 18, THEME.Text, 23)
    self._modalRejectLabel.TextScaled = true

    confirm.MouseButton1Click:Connect(function() self:_submitSpinDecision(true) end)
    reject.MouseButton1Click:Connect(function() self:_submitSpinDecision(false) end)
    table.insert(self._decisionButtons, { Button = confirm, Label = self._modalConfirmLabel, DefaultText = "SIM" })
    table.insert(self._decisionButtons, { Button = reject, Label = self._modalRejectLabel, DefaultText = "NAO" })
end

function MenuController:_build()
    self:_createMenuBlur()
    local playerGui = self._player:WaitForChild("PlayerGui")
    local gui = Instance.new("ScreenGui")
    gui.Name = "JERuntimeMenu"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.Parent = playerGui

    self._root = Instance.new("Frame")
    self._root.Size = UDim2.fromScale(1, 1)
    self._root.BorderSizePixel = 0
    self._root.Parent = gui

    self:_buildBackground(self._root)
    self:_buildMainView(self._root)
    self:_buildClanView(self._root)
    self:_buildModal(self._root)
end

function MenuController:_setWheelEntry(slotData, entry)
    slotData.NameLabel.Text = string.upper(entry.DisplayName)
    slotData.ChanceLabel.Text = toChanceText(entry.Chance)
    slotData.NameLabel.TextColor3 = slotData.IsCenter and entry.AccentColor or THEME.Text
    slotData.ChanceLabel.TextColor3 = entry.AccentColor
    slotData.Glow.BackgroundColor3 = entry.AccentColor
    slotData.Glow.BackgroundTransparency = slotData.IsCenter and 0.72 or 0.84
    local stroke = slotData.Slot:FindFirstChildOfClass("UIStroke")
    if stroke then
        stroke.Color = entry.AccentColor
    end
end

function MenuController:_renderWheelAround(centerIndex)
    local pool = self._spinRollPool
    if #pool == 0 then
        return
    end
    self._wheelIndex = wrapIndex(centerIndex, #pool)
    for slotIndex = 1, WHEEL_SLOT_COUNT do
        local poolIndex = wrapIndex(self._wheelIndex + (slotIndex - 3), #pool)
        self:_setWheelEntry(self._wheelSlots[slotIndex], pool[poolIndex])
    end
end

function MenuController:_findWheelIndexForClan(clanName)
    for index, entry in ipairs(self._spinRollPool) do
        if entry.Clan == clanName then
            return index
        end
    end
    return 1
end

function MenuController:_pulseCenterSlot()
    local centerSlot = self._wheelSlots[3]
    if not centerSlot then
        return
    end
    centerSlot.Slot.Size = UDim2.new(0, centerSlot.BaseSize, 0, centerSlot.BaseSize)
    TweenService:Create(centerSlot.Slot, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, centerSlot.BaseSize + 8, 0, centerSlot.BaseSize + 8),
    }):Play()
    task.delay(0.12, function()
        if centerSlot and centerSlot.Slot then
            TweenService:Create(centerSlot.Slot, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                Size = UDim2.new(0, centerSlot.BaseSize, 0, centerSlot.BaseSize),
            }):Play()
        end
    end)
end

function MenuController:_startSpinAnimation()
    self._spinAnimationToken = self._spinAnimationToken + 1
    local animationToken = self._spinAnimationToken
    local poolCount = #self._spinRollPool
    if poolCount == 0 then
        return
    end
    task.spawn(function()
        local currentIndex = self._wheelIndex
        local tickDelay = 0.05
        while self._spinPending and self._spinAnimationToken == animationToken do
            currentIndex = wrapIndex(currentIndex + 1, poolCount)
            self:_renderWheelAround(currentIndex)
            task.wait(tickDelay)
            if tickDelay < 0.095 then
                tickDelay = tickDelay + 0.0018
            end
        end
    end)
end

function MenuController:_stopSpinAnimation(finalClan)
    self._spinAnimationToken = self._spinAnimationToken + 1
    if finalClan and finalClan ~= "" then
        self:_renderWheelAround(self:_findWheelIndexForClan(finalClan))
        self:_pulseCenterSlot()
    end
end

function MenuController:_setSpinButtonsEnabled(enabled)
    for _, entry in ipairs(self._offerButtons) do
        entry.Button.Active = enabled
    end
    for _, entry in ipairs(self._spinButtons) do
        entry.Button.Active = enabled or entry.Decorative == true
    end
end

function MenuController:_setDecisionButtonsEnabled(enabled)
    for _, entry in ipairs(self._decisionButtons) do
        entry.Button.Active = enabled
        entry.Label.Text = enabled and entry.DefaultText or "..."
    end
end

function MenuController:_showStatus(text)
    if self._spinStatusLabel then
        self._spinStatusLabel.Text = text
    end
    if self._mainStatusLabel then
        self._mainStatusLabel.Text = text
    end
end

function MenuController:_setListItems(container, items, bulletColor)
    for _, child in ipairs(container:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    for _, item in ipairs(items) do
        local row = Instance.new("Frame")
        row.BackgroundTransparency = 1
        row.Size = UDim2.new(1, 0, 0, 18)
        row.ZIndex = container.ZIndex or 4
        row.Parent = container
        local bullet = makeText(row, "o", UDim2.new(0, 0, 0, -1), UDim2.new(0, 12, 0, 18), Enum.Font.GothamBold, 12, bulletColor, (container.ZIndex or 4) + 1)
        bullet.TextScaled = true
        local label = makeText(row, item, UDim2.new(0, 14, 0, 0), UDim2.new(1, -14, 0, 18), Enum.Font.Gotham, 11, THEME.Text, (container.ZIndex or 4) + 1)
        label.TextScaled = true
        label.TextXAlignment = Enum.TextXAlignment.Left
    end
end

function MenuController:_showConfirmModal(payload)
    local currentClan = self._player:GetAttribute("Clan") or ClanConfig.DefaultClan
    local currentSubTechnique = self._player:GetAttribute("SubTechnique") or ""
    local previewClan = payload.Clan or ClanConfig.DefaultClan
    local previewSubTechnique = payload.SubTechnique or ""
    local currentChance = self._chanceByClan[currentClan] or 0
    local previewChance = self._chanceByClan[previewClan] or 0
    local losses, gains = buildClanComparison(currentClan, currentSubTechnique, previewClan, previewSubTechnique)

    self._modalCurrentName.Text = string.upper(getClanDisplayName(currentClan))
    self._modalCurrentChance.Text = toChanceText(currentChance)
    self._modalPreviewName.Text = string.upper(getClanDisplayName(previewClan))
    self._modalPreviewChance.Text = toChanceText(previewChance)
    self:_setListItems(self._modalLossList, losses, Color3.fromRGB(255, 194, 140))
    self:_setListItems(self._modalGainList, gains, Color3.fromRGB(147, 255, 214))
    self:_setDecisionButtonsEnabled(true)

    self._modalBackdrop.Visible = true
    self._modalBackdrop.BackgroundTransparency = 1
    self._modalCard.Position = UDim2.new(0.5, -234, 0.5, -126)
    TweenService:Create(self._modalBackdrop, PANEL_TWEEN, { BackgroundTransparency = 0.36 }):Play()
    TweenService:Create(self._modalCard, PANEL_TWEEN, { Position = UDim2.new(0.5, -234, 0.5, -143) }):Play()
end

function MenuController:_hideConfirmModal()
    if not self._modalBackdrop.Visible then
        return
    end
    TweenService:Create(self._modalBackdrop, PANEL_TWEEN, { BackgroundTransparency = 1 }):Play()
    TweenService:Create(self._modalCard, PANEL_TWEEN, { Position = UDim2.new(0.5, -234, 0.5, -126) }):Play()
    task.delay(0.22, function()
        if self._modalBackdrop then
            self._modalBackdrop.Visible = false
        end
    end)
end

function MenuController:_beginSpinRequest()
    if self._spinPending or self._spinDecisionPending then
        return
    end
    local spins = self._player:GetAttribute("Spins") or 0
    if spins <= 0 then
        self:_showStatus("Voce nao tem giros disponiveis.")
        return
    end

    self._spinPending = true
    self._spinDecisionPending = false
    self._spinDecisionSubmitting = false
    self._spinRequestId = self._spinRequestId + 1
    local requestId = self._spinRequestId
    self:_setSpinButtonsEnabled(false)
    self:_showStatus("Girando cla...")
    self:_startSpinAnimation()
    self._network:Fire("ClanSpinRequest")

    task.delay(4.5, function()
        if self._spinPending and self._spinRequestId == requestId then
            self._spinPending = false
            self:_setSpinButtonsEnabled(true)
            self:_stopSpinAnimation(self._player:GetAttribute("Clan"))
            self:_showStatus("O giro demorou demais. Tente novamente.")
            self:Refresh()
        end
    end)
end

function MenuController:_submitSpinDecision(accept)
    if not self._spinDecisionPending or self._spinDecisionSubmitting then
        return
    end
    self._spinDecisionSubmitting = true
    self:_setDecisionButtonsEnabled(false)
    self:_showStatus(accept and "Confirmando troca de cla..." or "Mantendo cla atual...")
    self._network:Fire("ClanSpinDecisionRequest", { Accept = accept == true })
end

function MenuController:ShowMainView()
    self._mainView.Visible = true
    self._clanView.Visible = false
    self:_hideConfirmModal()
end

function MenuController:ShowClanView()
    self._mainView.Visible = false
    self._clanView.Visible = true
end

function MenuController:_bind()
    self._network:GetEvent("ClanSpinPreview").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end
        self._spinPending = false
        self._spinDecisionPending = true
        self._spinDecisionSubmitting = false
        self:_stopSpinAnimation(payload.Clan)
        self:_showConfirmModal(payload)
        self:_showStatus("Resultado obtido. Decida se deseja trocar de cla.")
        self:Refresh()
    end)

    self._network:GetEvent("ClanSpinResult").OnClientEvent:Connect(function(payload)
        self._spinPending = false
        self._spinDecisionPending = false
        self._spinDecisionSubmitting = false
        self:_setSpinButtonsEnabled(true)
        self:_hideConfirmModal()

        if type(payload) == "table" and payload.Accepted then
            self:_stopSpinAnimation(payload.Clan)
            self:_showStatus(string.format("Cla alterado para %s.", getClanDisplayName(payload.Clan)))
        elseif type(payload) == "table" and payload.KeptClan then
            self:_stopSpinAnimation(payload.Clan)
            self:_showStatus("Cla atual mantido.")
        else
            self:_stopSpinAnimation(self._player:GetAttribute("Clan"))
            self:_showStatus("Resultado do giro recebido.")
        end

        self:Refresh()
    end)

    self._network:GetEvent("ServerMessage").OnClientEvent:Connect(function(payload)
        if type(payload) ~= "table" then
            return
        end
        if payload.Type == "Error" then
            self._spinPending = false
            self._spinDecisionPending = false
            self._spinDecisionSubmitting = false
            self:_setSpinButtonsEnabled(true)
            self:_hideConfirmModal()
            self:_stopSpinAnimation(self._player:GetAttribute("Clan"))
        end
        self:_showStatus(payload.Text or "")
        self:Refresh()
    end)

    for _, attributeName in ipairs({
        "Clan",
        "SubTechnique",
        "Spins",
        "HasStarted",
        "ClanLegendaryPity",
        "ClanEpicPity",
    }) do
        self._player:GetAttributeChangedSignal(attributeName):Connect(function()
            self:Refresh()
        end)
    end
end

function MenuController:Refresh()
    local clan = self._player:GetAttribute("Clan") or ClanConfig.DefaultClan
    local subTechnique = self._player:GetAttribute("SubTechnique") or ""
    local spins = self._player:GetAttribute("Spins") or 0
    local legendaryPity = self._player:GetAttribute("ClanLegendaryPity") or 0
    local epicPity = self._player:GetAttribute("ClanEpicPity") or 0
    local clanDefinition = getClanDefinition(clan)
    local clanDisplay = getClanDisplayName(clan)
    local rarityLabel = ClanConfig.RarityLabels[clanDefinition.Rarity] or clanDefinition.Rarity
    local rarityColor = RARITY_COLORS[clanDefinition.Rarity] or THEME.Text
    local hasStarted = self._player:GetAttribute("HasStarted") == true

    if self._mainClanLabel then
        self._mainClanLabel.Text = "Cla atual: " .. clanDisplay
    end
    if self._mainSpinsLabel then
        self._mainSpinsLabel.Text = string.format("Giros disponiveis: %d", spins)
    end
    if self._currentClanLabel then
        self._currentClanLabel.Text = string.upper(clanDisplay)
        self._currentClanLabel.TextColor3 = rarityColor
    end
    if self._currentClanRarityLabel then
        self._currentClanRarityLabel.Text = string.format("RARIDADE %s  |  %s", string.upper(rarityLabel), toChanceText(self._chanceByClan[clan] or 0))
        self._currentClanRarityLabel.TextColor3 = rarityColor
    end
    if self._currentSubTechniqueLabel then
        self._currentSubTechniqueLabel.Text = subTechnique ~= "" and ("SUBTECNICA: " .. subTechnique) or "SEM SUBTECNICA EXTRA"
    end
    if self._spinBannerLabel then
        self._spinBannerLabel.Text = string.format("GRATIS %d", spins)
    end
    if self._legendaryPityLabel then
        self._legendaryPityLabel.Text = string.format("Piedade Lendaria %d/%d", legendaryPity, PITY_LIMITS.Legendary)
    end
    if self._epicPityLabel then
        self._epicPityLabel.Text = string.format("Piedade Epica %d/%d", epicPity, PITY_LIMITS.Epic)
    end
    if self._benefitsTitleLabel then
        self._benefitsTitleLabel.Text = "VANTAGENS DO CLA " .. string.upper(clanDisplay)
    end
    if self._benefitsList then
        self:_setListItems(self._benefitsList, buildClanFeatureList(clan, subTechnique), rarityColor)
    end

    for rarity, label in pairs(self._rateLabels) do
        label.Text = string.format("%s  %.1f%%", string.upper(rarity), self._rateSummary[rarity] or 0)
        label.TextColor3 = RARITY_COLORS[rarity] or THEME.Text
    end

    if not self._spinPending and not self._spinDecisionPending then
        self:_renderWheelAround(self:_findWheelIndexForClan(clan))
    end

    self._root.Visible = not hasStarted
    if self._menuBlur then
        self._menuBlur.Enabled = not hasStarted
    end
end

return MenuController
