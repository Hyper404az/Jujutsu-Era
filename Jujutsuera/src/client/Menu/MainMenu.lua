-- ================================================================
-- MainMenu.lua  |  ModuleScript
-- src/client/Menu/MainMenu.lua
-- Tela principal do Jujutsu Era: título + sidebar de navegação
-- ================================================================

local TweenService = game:GetService("TweenService")

-- ── Paleta ─────────────────────────────────────────────────────
local C = {
    BG          = Color3.fromRGB(5,  5,  15),
    OVERLAY     = Color3.fromRGB(8,  6,  22),
    SIDEBAR     = Color3.fromRGB(11, 9,  28),
    SIDEBAR_LINE= Color3.fromRGB(80, 40, 160),
    BTN         = Color3.fromRGB(18, 14, 42),
    BTN_HOVER   = Color3.fromRGB(28, 20, 60),
    BTN_ACTIVE  = Color3.fromRGB(100, 35, 185),
    ACCENT      = Color3.fromRGB(120, 40, 200),
    ACCENT_GLOW = Color3.fromRGB(160, 80, 240),
    GOLD        = Color3.fromRGB(255, 192, 30),
    TEXT        = Color3.fromRGB(235, 230, 255),
    MUTED       = Color3.fromRGB(140, 130, 185),
    DIVIDER     = Color3.fromRGB(35,  28,  65),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local TWEEN_SLOW = TweenInfo.new(0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ── Utilitários ────────────────────────────────────────────────
local function uiCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function uiPadding(parent, px, py)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, py or px)
    p.PaddingBottom = UDim.new(0, py or px)
    p.Parent = parent
    return p
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color        = color or C.ACCENT
    s.Thickness    = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function label(parent, text, size, color, font)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text      = text
    l.TextSize  = size or 16
    l.TextColor3 = color or C.TEXT
    l.Font      = font or Enum.Font.Gotham
    l.TextXAlignment = Enum.TextXAlignment.Center
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.Size      = UDim2.new(1, 0, 1, 0)
    l.Parent    = parent
    return l
end

-- ── Construção da UI ───────────────────────────────────────────
local MainMenu = {}
MainMenu.__index = MainMenu

-- Callbacks públicos (preenchidos pelo MenuController)
MainMenu.OnClanClicked  = nil
MainMenu.OnPlayClicked  = nil
MainMenu.OnSlotsClicked = nil

function MainMenu.new(gui)
    local self = setmetatable({}, MainMenu)
    self._gui  = gui
    self._connections = {}
    self:_build()
    return self
end

function MainMenu:_build()
    -- ── Fundo principal ────────────────────────────────────────
    local root = Instance.new("Frame")
    root.Name              = "MainMenuRoot"
    root.Size              = UDim2.new(1, 0, 1, 0)
    root.BackgroundColor3  = C.BG
    root.BorderSizePixel   = 0
    root.Visible           = false
    root.Parent            = self._gui
    self._root = root

    -- Gradiente de fundo
    local grad = Instance.new("UIGradient")
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(5, 3, 18)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(8, 5, 22)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(3, 3, 12)),
    })
    grad.Rotation = 135
    grad.Parent = root

    -- Linha decorativa superior (energia amaldiçoada)
    local topLine = Instance.new("Frame")
    topLine.Size             = UDim2.new(1, 0, 0, 2)
    topLine.Position         = UDim2.new(0, 0, 0, 0)
    topLine.BackgroundColor3 = C.ACCENT
    topLine.BorderSizePixel  = 0
    topLine.Parent           = root

    local topLineGrad = Instance.new("UIGradient")
    topLineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 10, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 60, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60, 10, 120)),
    })
    topLineGrad.Parent = topLine

    -- ── Bloco central (título + subtítulo) ────────────────────
    local center = Instance.new("Frame")
    center.Name              = "CenterBlock"
    center.AnchorPoint       = Vector2.new(0.5, 0.4)
    center.Position          = UDim2.new(0.5, 0, 0.4, 0)
    center.Size              = UDim2.new(0.45, 0, 0.3, 0)
    center.BackgroundTransparency = 1
    center.Parent            = root

    -- Título principal
    local titleShadow = Instance.new("TextLabel")
    titleShadow.Size              = UDim2.new(1, 4, 0, 70)
    titleShadow.Position          = UDim2.new(0, 4, 0, 4)
    titleShadow.BackgroundTransparency = 1
    titleShadow.Text              = "JUJUTSU ERA"
    titleShadow.TextSize          = 58
    titleShadow.TextColor3        = Color3.fromRGB(80, 20, 140)
    titleShadow.Font               = Enum.Font.GothamBlack
    titleShadow.TextXAlignment     = Enum.TextXAlignment.Center
    titleShadow.Parent             = center

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name               = "Title"
    titleLabel.Size               = UDim2.new(1, 0, 0, 70)
    titleLabel.Position           = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text               = "JUJUTSU ERA"
    titleLabel.TextSize           = 58
    titleLabel.TextColor3         = C.TEXT
    titleLabel.Font                = Enum.Font.GothamBlack
    titleLabel.TextXAlignment      = Enum.TextXAlignment.Center
    titleLabel.Parent              = center
    self._titleLabel = titleLabel

    -- Linha dourada abaixo do título
    local titleLine = Instance.new("Frame")
    titleLine.AnchorPoint       = Vector2.new(0.5, 0)
    titleLine.Position          = UDim2.new(0.5, 0, 0, 76)
    titleLine.Size              = UDim2.new(0.6, 0, 0, 1)
    titleLine.BackgroundColor3  = C.GOLD
    titleLine.BorderSizePixel   = 0
    titleLine.Parent            = center

    -- Subtítulo
    local subLabel = Instance.new("TextLabel")
    subLabel.AnchorPoint        = Vector2.new(0.5, 0)
    subLabel.Position           = UDim2.new(0.5, 0, 0, 84)
    subLabel.Size               = UDim2.new(0.9, 0, 0, 24)
    subLabel.BackgroundTransparency = 1
    subLabel.Text               = "A ERA DOS FEITICEIROS"
    subLabel.TextSize           = 13
    subLabel.TextColor3         = C.MUTED
    subLabel.Font                = Enum.Font.GothamMedium
    subLabel.TextXAlignment      = Enum.TextXAlignment.Center
    subLabel.Parent              = center

    -- Kanji decorativo
    local kanjiLabel = Instance.new("TextLabel")
    kanjiLabel.AnchorPoint         = Vector2.new(0.5, 0)
    kanjiLabel.Position            = UDim2.new(0.5, 0, 0, 112)
    kanjiLabel.Size                = UDim2.new(0.8, 0, 0, 30)
    kanjiLabel.BackgroundTransparency = 1
    kanjiLabel.Text                = "呪術廻戦"
    kanjiLabel.TextSize            = 20
    kanjiLabel.TextColor3          = Color3.fromRGB(100, 60, 170)
    kanjiLabel.Font                 = Enum.Font.Gotham
    kanjiLabel.TextXAlignment       = Enum.TextXAlignment.Center
    kanjiLabel.Parent               = center

    -- ── Sidebar esquerda ──────────────────────────────────────
    local sidebar = Instance.new("Frame")
    sidebar.Name             = "Sidebar"
    sidebar.AnchorPoint      = Vector2.new(0, 0.5)
    sidebar.Position         = UDim2.new(0, 0, 0.5, 0)
    sidebar.Size             = UDim2.new(0, 200, 0.7, 0)
    sidebar.BackgroundColor3 = C.SIDEBAR
    sidebar.BorderSizePixel  = 0
    sidebar.Parent           = root

    uiCorner(sidebar, 0)  -- Sem arredondamento no lado esquerdo (cola na borda)
    stroke(sidebar, C.SIDEBAR_LINE, 1, 0.5)

    -- Gradiente da sidebar
    local sbGrad = Instance.new("UIGradient")
    sbGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(14, 10, 35)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(8, 6, 22)),
    })
    sbGrad.Rotation = 90
    sbGrad.Parent = sidebar

    -- Linha vertical direita da sidebar
    local sbLine = Instance.new("Frame")
    sbLine.AnchorPoint      = Vector2.new(1, 0)
    sbLine.Position         = UDim2.new(1, 0, 0, 0)
    sbLine.Size             = UDim2.new(0, 2, 1, 0)
    sbLine.BackgroundColor3 = C.ACCENT
    sbLine.BorderSizePixel  = 0
    sbLine.Parent           = sidebar

    local sbLineGrad = Instance.new("UIGradient")
    sbLineGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(20, 5, 60)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(120, 40, 210)),
        ColorSequenceKeypoint.new(0.7, Color3.fromRGB(120, 40, 210)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(20, 5, 60)),
    })
    sbLineGrad.Rotation = 90
    sbLineGrad.Parent = sbLine

    -- Logo do jogo dentro da sidebar (topo)
    local sbLogo = Instance.new("TextLabel")
    sbLogo.Size              = UDim2.new(1, -20, 0, 50)
    sbLogo.Position          = UDim2.new(0, 10, 0, 20)
    sbLogo.BackgroundTransparency = 1
    sbLogo.Text              = "⛩  JJE"
    sbLogo.TextSize          = 18
    sbLogo.TextColor3        = C.ACCENT_GLOW
    sbLogo.Font               = Enum.Font.GothamBold
    sbLogo.TextXAlignment     = Enum.TextXAlignment.Left
    sbLogo.Parent             = sidebar

    local sbDivider = Instance.new("Frame")
    sbDivider.Position         = UDim2.new(0, 15, 0, 72)
    sbDivider.Size             = UDim2.new(1, -30, 0, 1)
    sbDivider.BackgroundColor3 = C.DIVIDER
    sbDivider.BorderSizePixel  = 0
    sbDivider.Parent           = sidebar

    -- Label "MENU" acima dos botões
    local menuLabel = Instance.new("TextLabel")
    menuLabel.Position         = UDim2.new(0, 15, 0, 82)
    menuLabel.Size             = UDim2.new(1, -30, 0, 20)
    menuLabel.BackgroundTransparency = 1
    menuLabel.Text             = "MENU"
    menuLabel.TextSize         = 10
    menuLabel.TextColor3       = Color3.fromRGB(80, 65, 130)
    menuLabel.Font              = Enum.Font.GothamBold
    menuLabel.TextXAlignment    = Enum.TextXAlignment.Left
    menuLabel.Parent            = sidebar

    -- ── Botões da sidebar ─────────────────────────────────────
    local navItems = {
        { key = "clan",  icon = "👁",  text = "CLANS",  desc = "Girar & Explorar" },
        { key = "play",  icon = "▶",  text = "JOGAR",  desc = "Entrar no mundo"  },
        { key = "slots", icon = "🎴", text = "SLOTS",  desc = "Personagens"      },
    }

    local btnY = 112
    for _, item in ipairs(navItems) do
        local btn = Instance.new("TextButton")
        btn.Name             = "NavBtn_" .. item.key
        btn.Position         = UDim2.new(0, 10, 0, btnY)
        btn.Size             = UDim2.new(1, -20, 0, 58)
        btn.BackgroundColor3 = C.BTN
        btn.BorderSizePixel  = 0
        btn.Text             = ""
        btn.AutoButtonColor  = false
        btn.Parent           = sidebar
        uiCorner(btn, 8)

        -- Ícone
        local iconL = Instance.new("TextLabel")
        iconL.Position         = UDim2.new(0, 12, 0.5, -12)
        iconL.Size             = UDim2.new(0, 28, 0, 28)
        iconL.BackgroundTransparency = 1
        iconL.Text             = item.icon
        iconL.TextSize         = 20
        iconL.TextColor3       = C.ACCENT_GLOW
        iconL.Font              = Enum.Font.Gotham
        iconL.TextXAlignment    = Enum.TextXAlignment.Center
        iconL.TextYAlignment    = Enum.TextYAlignment.Center
        iconL.Parent            = btn

        -- Nome do botão
        local nameL = Instance.new("TextLabel")
        nameL.Position         = UDim2.new(0, 50, 0, 10)
        nameL.Size             = UDim2.new(1, -60, 0, 20)
        nameL.BackgroundTransparency = 1
        nameL.Text             = item.text
        nameL.TextSize         = 14
        nameL.TextColor3       = C.TEXT
        nameL.Font              = Enum.Font.GothamBold
        nameL.TextXAlignment    = Enum.TextXAlignment.Left
        nameL.Parent            = btn

        -- Descrição
        local descL = Instance.new("TextLabel")
        descL.Position         = UDim2.new(0, 50, 0, 32)
        descL.Size             = UDim2.new(1, -60, 0, 16)
        descL.BackgroundTransparency = 1
        descL.Text             = item.desc
        descL.TextSize         = 10
        descL.TextColor3       = C.MUTED
        descL.Font              = Enum.Font.Gotham
        descL.TextXAlignment    = Enum.TextXAlignment.Left
        descL.Parent            = btn

        -- Barra indicadora lateral (aparece no hover)
        local indicator = Instance.new("Frame")
        indicator.AnchorPoint      = Vector2.new(1, 0.5)
        indicator.Position         = UDim2.new(1, 0, 0.5, 0)
        indicator.Size             = UDim2.new(0, 0, 0.6, 0)
        indicator.BackgroundColor3 = C.ACCENT
        indicator.BorderSizePixel  = 0
        indicator.Parent           = btn
        uiCorner(indicator, 3)

        -- Hover/Click logic
        local function onEnter()
            TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = C.BTN_HOVER }):Play()
            TweenService:Create(indicator, TWEEN_FAST, { Size = UDim2.new(0, 3, 0.6, 0) }):Play()
            TweenService:Create(nameL, TWEEN_FAST, { TextColor3 = C.ACCENT_GLOW }):Play()
        end
        local function onLeave()
            TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = C.BTN }):Play()
            TweenService:Create(indicator, TWEEN_FAST, { Size = UDim2.new(0, 0, 0.6, 0) }):Play()
            TweenService:Create(nameL, TWEEN_FAST, { TextColor3 = C.TEXT }):Play()
        end
        local function onClick()
            TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = C.BTN_ACTIVE }):Play()
            task.delay(0.12, function()
                TweenService:Create(btn, TWEEN_FAST, { BackgroundColor3 = C.BTN }):Play()
                if item.key == "clan"  and self.OnClanClicked  then self.OnClanClicked()  end
                if item.key == "play"  and self.OnPlayClicked  then self.OnPlayClicked()  end
                if item.key == "slots" and self.OnSlotsClicked then self.OnSlotsClicked() end
            end)
        end

        table.insert(self._connections, btn.MouseEnter:Connect(onEnter))
        table.insert(self._connections, btn.MouseLeave:Connect(onLeave))
        table.insert(self._connections, btn.MouseButton1Click:Connect(onClick))

        btnY = btnY + 66
    end

    -- Versão no rodapé da sidebar
    local versionL = Instance.new("TextLabel")
    versionL.AnchorPoint       = Vector2.new(0, 1)
    versionL.Position          = UDim2.new(0, 15, 1, -12)
    versionL.Size              = UDim2.new(1, -30, 0, 18)
    versionL.BackgroundTransparency = 1
    versionL.Text              = "v1.0  ·  Alpha"
    versionL.TextSize          = 10
    versionL.TextColor3        = Color3.fromRGB(60, 50, 100)
    versionL.Font               = Enum.Font.Gotham
    versionL.TextXAlignment     = Enum.TextXAlignment.Left
    versionL.Parent             = sidebar

    -- ── Partículas decorativas (pontinhos flutuantes) ─────────
    -- (simples frames que animam com spawn task — leve)
    task.spawn(function()
        self:_spawnParticles(root)
    end)
end

function MainMenu:_spawnParticles(parent)
    local rng = Random.new()
    while self._root and self._root.Parent do
        if not self._root.Visible then
            task.wait(0.5)
            continue
        end
        local dot = Instance.new("Frame")
        dot.Size             = UDim2.new(0, rng:NextInteger(2, 5), 0, rng:NextInteger(2, 5))
        dot.Position         = UDim2.new(rng:NextNumber(0.15, 0.95), 0, 1.05, 0)
        dot.BackgroundColor3 = rng:NextInteger(0, 1) == 0 and C.ACCENT or C.GOLD
        dot.BackgroundTransparency = 0.4
        dot.BorderSizePixel  = 0
        dot.ZIndex           = 0
        dot.Parent           = parent
        uiCorner(dot, 50)

        local targetX = dot.Position.X.Scale + rng:NextNumber(-0.05, 0.05)
        TweenService:Create(dot, TweenInfo.new(
            rng:NextNumber(4, 8), Enum.EasingStyle.Linear, Enum.EasingDirection.Out
        ), {
            Position = UDim2.new(targetX, 0, -0.05, 0),
            BackgroundTransparency = 1,
        }):Play()

        task.delay(8, function()
            if dot and dot.Parent then dot:Destroy() end
        end)
        task.wait(rng:NextNumber(0.3, 0.8))
    end
end

function MainMenu:Show()
    self._root.Visible = true
    self._root.BackgroundTransparency = 1
    TweenService:Create(self._root, TWEEN_MED, { BackgroundTransparency = 0 }):Play()

    -- Animar título entrando
    if self._titleLabel then
        self._titleLabel.TextTransparency = 1
        TweenService:Create(self._titleLabel, TWEEN_SLOW, { TextTransparency = 0 }):Play()
    end
end

function MainMenu:Hide()
    TweenService:Create(self._root, TWEEN_MED, { BackgroundTransparency = 1 }):Play()
    task.delay(0.36, function()
        if self._root then self._root.Visible = false end
    end)
end

function MainMenu:Destroy()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    if self._root then self._root:Destroy() end
end

return MainMenu
