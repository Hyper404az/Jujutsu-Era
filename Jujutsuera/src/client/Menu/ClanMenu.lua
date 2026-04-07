-- ================================================================
-- ClanMenu.lua  |  ModuleScript  (NOVO ARQUIVO)
-- src/client/Menu/ClanMenu.lua
-- Tela de spin de clãs: área de giro + painel de raridades
-- ================================================================

local TweenService = game:GetService("TweenService")
local RunService   = game:GetService("RunService")

-- ── Dados de clãs (adapte ou substitua por require(ClanData)) ──
-- Se você já tem um ClanData.lua em shared/Clans/, faça:
--   local ClanData = require(game:GetService("ReplicatedStorage").Shared.Clans.ClanData)
-- e substitua CLAN_LIST pelo que vem de lá.

local CLAN_LIST = {
    -- { name, rarity, chance (%), color }
    { name = "Gojo",        rarity = "LENDÁRIO",   chance = 0.1,  color = Color3.fromRGB(100, 180, 255) },
    { name = "Zen'in",      rarity = "ÉPICO",      chance = 1.0,  color = Color3.fromRGB(180, 80,  220) },
    { name = "Kamo",        rarity = "ÉPICO",      chance = 1.5,  color = Color3.fromRGB(220, 60,  80)  },
    { name = "Zenin",       rarity = "RARO",       chance = 3.0,  color = Color3.fromRGB(255, 160, 30)  },
    { name = "Haibara",     rarity = "RARO",       chance = 4.4,  color = Color3.fromRGB(255, 140, 50)  },
    { name = "Okkotsu",     rarity = "RARO",       chance = 5.0,  color = Color3.fromRGB(200, 100, 240) },
    { name = "Fushiguro",   rarity = "INCOMUM",    chance = 8.0,  color = Color3.fromRGB(80,  160, 220) },
    { name = "Itadori",     rarity = "INCOMUM",    chance = 9.0,  color = Color3.fromRGB(220, 90,  90)  },
    { name = "Nanami",      rarity = "INCOMUM",    chance = 9.0,  color = Color3.fromRGB(200, 180, 100) },
    { name = "Sem Clã",     rarity = "COMUM",      chance = 30.0, color = Color3.fromRGB(120, 120, 140) },
    { name = "Plebeu",      rarity = "COMUM",      chance = 29.0, color = Color3.fromRGB(100, 100, 120) },
}

-- Cores das raridades
local RARITY_COLORS = {
    ["LENDÁRIO"] = Color3.fromRGB(255, 215, 0),
    ["ÉPICO"]    = Color3.fromRGB(180, 80, 220),
    ["RARO"]     = Color3.fromRGB(80, 160, 240),
    ["INCOMUM"]  = Color3.fromRGB(100, 210, 130),
    ["COMUM"]    = Color3.fromRGB(160, 155, 175),
}

-- ── Paleta ─────────────────────────────────────────────────────
local C = {
    BG          = Color3.fromRGB(5,  5,  15),
    PANEL       = Color3.fromRGB(10, 8,  24),
    CARD        = Color3.fromRGB(15, 12, 32),
    CARD_HOVER  = Color3.fromRGB(22, 18, 45),
    ACCENT      = Color3.fromRGB(120, 40, 200),
    ACCENT_GLOW = Color3.fromRGB(160, 80, 240),
    GOLD        = Color3.fromRGB(255, 192, 30),
    TEXT        = Color3.fromRGB(235, 230, 255),
    MUTED       = Color3.fromRGB(140, 130, 185),
    DIVIDER     = Color3.fromRGB(35,  28,  65),
    SPIN_BTN    = Color3.fromRGB(100, 30, 180),
    SPIN_BTN_H  = Color3.fromRGB(130, 50, 220),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.35, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- ── Utilitários ────────────────────────────────────────────────
local function uiCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color        = color or C.ACCENT
    s.Thickness    = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ── Módulo ─────────────────────────────────────────────────────
local ClanMenu = {}
ClanMenu.__index = ClanMenu

ClanMenu.OnBackClicked = nil

function ClanMenu.new(gui)
    local self = setmetatable({}, ClanMenu)
    self._gui         = gui
    self._connections = {}
    self._spinning    = false
    self:_build()
    return self
end

function ClanMenu:_build()
    -- ── Root ──────────────────────────────────────────────────
    local root = Instance.new("Frame")
    root.Name             = "ClanMenuRoot"
    root.Size             = UDim2.new(1, 0, 1, 0)
    root.BackgroundColor3 = C.BG
    root.BorderSizePixel  = 0
    root.Visible          = false
    root.Parent           = self._gui
    self._root = root

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(5,  3, 18)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(3,  3, 12)),
    })
    bgGrad.Rotation = 135
    bgGrad.Parent = root

    -- Linha decorativa topo
    local topLine = Instance.new("Frame")
    topLine.Size             = UDim2.new(1, 0, 0, 2)
    topLine.BackgroundColor3 = C.ACCENT
    topLine.BorderSizePixel  = 0
    topLine.Parent           = root
    local tlGrad = Instance.new("UIGradient")
    tlGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 10, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 60, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60, 10, 120)),
    })
    tlGrad.Parent = topLine

    -- ── Cabeçalho ─────────────────────────────────────────────
    local header = Instance.new("Frame")
    header.Size             = UDim2.new(1, 0, 0, 60)
    header.Position         = UDim2.new(0, 0, 0, 2)
    header.BackgroundColor3 = C.PANEL
    header.BorderSizePixel  = 0
    header.Parent           = root

    local headerTitle = Instance.new("TextLabel")
    headerTitle.Position         = UDim2.new(0, 24, 0, 0)
    headerTitle.Size             = UDim2.new(0.5, 0, 1, 0)
    headerTitle.BackgroundTransparency = 1
    headerTitle.Text             = "👁  CLÃS"
    headerTitle.TextSize         = 22
    headerTitle.TextColor3       = C.TEXT
    headerTitle.Font              = Enum.Font.GothamBold
    headerTitle.TextXAlignment    = Enum.TextXAlignment.Left
    headerTitle.Parent            = header

    local headerSub = Instance.new("TextLabel")
    headerSub.AnchorPoint        = Vector2.new(1, 0.5)
    headerSub.Position           = UDim2.new(1, -24, 0.5, 0)
    headerSub.Size               = UDim2.new(0.4, 0, 0, 20)
    headerSub.BackgroundTransparency = 1
    headerSub.Text               = "Descubra seu clã"
    headerSub.TextSize           = 12
    headerSub.TextColor3         = C.MUTED
    headerSub.Font                = Enum.Font.Gotham
    headerSub.TextXAlignment      = Enum.TextXAlignment.Right
    headerSub.Parent              = header

    -- Linha inferior do header
    local hLine = Instance.new("Frame")
    hLine.AnchorPoint      = Vector2.new(0, 1)
    hLine.Position         = UDim2.new(0, 0, 1, 0)
    hLine.Size             = UDim2.new(1, 0, 0, 1)
    hLine.BackgroundColor3 = C.DIVIDER
    hLine.BorderSizePixel  = 0
    hLine.Parent           = header

    -- ── Layout principal: spin (esquerda) + lista (direita) ───
    local content = Instance.new("Frame")
    content.Position         = UDim2.new(0, 0, 0, 64)
    content.Size             = UDim2.new(1, 0, 1, -64)
    content.BackgroundTransparency = 1
    content.Parent           = root

    -- ── PAINEL ESQUERDO: área de giro ─────────────────────────
    local spinPanel = Instance.new("Frame")
    spinPanel.Size             = UDim2.new(0.52, -2, 1, 0)
    spinPanel.BackgroundColor3 = C.PANEL
    spinPanel.BorderSizePixel  = 0
    spinPanel.Parent           = content

    local spGrad = Instance.new("UIGradient")
    spGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(12, 9, 30)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(7,  5, 20)),
    })
    spGrad.Rotation = 90
    spGrad.Parent = spinPanel

    -- Círculo de spin (visual do giro)
    local spinCircleOuter = Instance.new("Frame")
    spinCircleOuter.AnchorPoint       = Vector2.new(0.5, 0.42)
    spinCircleOuter.Position          = UDim2.new(0.5, 0, 0.42, 0)
    spinCircleOuter.Size              = UDim2.new(0, 220, 0, 220)
    spinCircleOuter.BackgroundColor3  = Color3.fromRGB(18, 12, 42)
    spinCircleOuter.BorderSizePixel   = 0
    spinCircleOuter.Parent            = spinPanel
    uiCorner(spinCircleOuter, 110)
    stroke(spinCircleOuter, C.ACCENT, 2)
    self._spinCircle = spinCircleOuter

    -- Círculo interno
    local spinCircleInner = Instance.new("Frame")
    spinCircleInner.AnchorPoint      = Vector2.new(0.5, 0.5)
    spinCircleInner.Position         = UDim2.new(0.5, 0, 0.5, 0)
    spinCircleInner.Size             = UDim2.new(0, 180, 0, 180)
    spinCircleInner.BackgroundColor3 = Color3.fromRGB(12, 8, 30)
    spinCircleInner.BorderSizePixel  = 0
    spinCircleInner.Parent           = spinCircleOuter
    uiCorner(spinCircleInner, 90)

    -- Ícone de clã dentro do círculo
    local clanIcon = Instance.new("TextLabel")
    clanIcon.AnchorPoint       = Vector2.new(0.5, 0.45)
    clanIcon.Position          = UDim2.new(0.5, 0, 0.45, 0)
    clanIcon.Size              = UDim2.new(0, 160, 0, 80)
    clanIcon.BackgroundTransparency = 1
    clanIcon.Text              = "?"
    clanIcon.TextSize          = 52
    clanIcon.TextColor3        = C.MUTED
    clanIcon.Font               = Enum.Font.GothamBold
    clanIcon.TextXAlignment     = Enum.TextXAlignment.Center
    clanIcon.TextYAlignment     = Enum.TextYAlignment.Center
    clanIcon.Parent             = spinCircleInner
    self._clanIcon = clanIcon

    -- Nome do resultado
    local resultName = Instance.new("TextLabel")
    resultName.AnchorPoint       = Vector2.new(0.5, 0)
    resultName.Position          = UDim2.new(0.5, 0, 0.62, 0)
    resultName.Size              = UDim2.new(0, 160, 0, 30)
    resultName.BackgroundTransparency = 1
    resultName.Text              = "Clique para girar"
    resultName.TextSize          = 14
    resultName.TextColor3        = C.MUTED
    resultName.Font               = Enum.Font.GothamMedium
    resultName.TextXAlignment     = Enum.TextXAlignment.Center
    resultName.Parent             = spinCircleInner
    self._resultName = resultName

    -- Rarity tag do resultado
    local resultRarity = Instance.new("TextLabel")
    resultRarity.AnchorPoint        = Vector2.new(0.5, 0)
    resultRarity.Position           = UDim2.new(0.5, 0, 0.82, 0)
    resultRarity.Size               = UDim2.new(0, 120, 0, 22)
    resultRarity.BackgroundTransparency = 1
    resultRarity.Text               = ""
    resultRarity.TextSize           = 11
    resultRarity.TextColor3         = C.GOLD
    resultRarity.Font                = Enum.Font.GothamBold
    resultRarity.TextXAlignment      = Enum.TextXAlignment.Center
    resultRarity.Parent              = spinCircleInner
    self._resultRarity = resultRarity

    -- Contador de spins
    local spinCountLabel = Instance.new("TextLabel")
    spinCountLabel.AnchorPoint       = Vector2.new(0.5, 0)
    spinCountLabel.Position          = UDim2.new(0.5, 0, 0, 16)
    spinCountLabel.Size              = UDim2.new(0.8, 0, 0, 24)
    spinCountLabel.BackgroundTransparency = 1
    spinCountLabel.Text              = "Spins disponíveis: ∞"
    spinCountLabel.TextSize          = 12
    spinCountLabel.TextColor3        = C.MUTED
    spinCountLabel.Font               = Enum.Font.Gotham
    spinCountLabel.TextXAlignment     = Enum.TextXAlignment.Center
    spinCountLabel.Parent             = spinPanel
    self._spinCountLabel = spinCountLabel

    -- ── Botão GIRAR ───────────────────────────────────────────
    local spinBtn = Instance.new("TextButton")
    spinBtn.AnchorPoint      = Vector2.new(0.5, 1)
    spinBtn.Position         = UDim2.new(0.5, 0, 1, -28)
    spinBtn.Size             = UDim2.new(0, 180, 0, 50)
    spinBtn.BackgroundColor3 = C.SPIN_BTN
    spinBtn.BorderSizePixel  = 0
    spinBtn.Text             = ""
    spinBtn.AutoButtonColor  = false
    spinBtn.Parent           = spinPanel
    uiCorner(spinBtn, 10)
    stroke(spinBtn, C.ACCENT_GLOW, 1)
    self._spinBtn = spinBtn

    local spinBtnLabel = Instance.new("TextLabel")
    spinBtnLabel.Size              = UDim2.new(1, 0, 1, 0)
    spinBtnLabel.BackgroundTransparency = 1
    spinBtnLabel.Text              = "⟳  GIRAR"
    spinBtnLabel.TextSize          = 16
    spinBtnLabel.TextColor3        = C.TEXT
    spinBtnLabel.Font               = Enum.Font.GothamBold
    spinBtnLabel.TextXAlignment     = Enum.TextXAlignment.Center
    spinBtnLabel.Parent             = spinBtn
    self._spinBtnLabel = spinBtnLabel

    table.insert(self._connections, spinBtn.MouseEnter:Connect(function()
        if not self._spinning then
            TweenService:Create(spinBtn, TWEEN_FAST, { BackgroundColor3 = C.SPIN_BTN_H }):Play()
        end
    end))
    table.insert(self._connections, spinBtn.MouseLeave:Connect(function()
        TweenService:Create(spinBtn, TWEEN_FAST, { BackgroundColor3 = C.SPIN_BTN }):Play()
    end))
    table.insert(self._connections, spinBtn.MouseButton1Click:Connect(function()
        self:_doSpin()
    end))

    -- ── PAINEL DIREITO: lista de clãs ─────────────────────────
    local listPanel = Instance.new("Frame")
    listPanel.AnchorPoint      = Vector2.new(1, 0)
    listPanel.Position         = UDim2.new(1, 0, 0, 0)
    listPanel.Size             = UDim2.new(0.48, 0, 1, 0)
    listPanel.BackgroundColor3 = Color3.fromRGB(8, 6, 20)
    listPanel.BorderSizePixel  = 0
    listPanel.Parent           = content

    -- Linha separadora esquerda
    local listLine = Instance.new("Frame")
    listLine.Size             = UDim2.new(0, 1, 1, 0)
    listLine.BackgroundColor3 = C.DIVIDER
    listLine.BorderSizePixel  = 0
    listLine.Parent           = listPanel

    -- Título da lista
    local listHeader = Instance.new("Frame")
    listHeader.Size             = UDim2.new(1, 0, 0, 48)
    listHeader.Position         = UDim2.new(0, 0, 0, 0)
    listHeader.BackgroundColor3 = Color3.fromRGB(10, 8, 24)
    listHeader.BorderSizePixel  = 0
    listHeader.Parent           = listPanel

    local listTitle = Instance.new("TextLabel")
    listTitle.Position         = UDim2.new(0, 16, 0, 0)
    listTitle.Size             = UDim2.new(0.6, 0, 1, 0)
    listTitle.BackgroundTransparency = 1
    listTitle.Text             = "TODOS OS CLÃS"
    listTitle.TextSize         = 13
    listTitle.TextColor3       = C.TEXT
    listTitle.Font              = Enum.Font.GothamBold
    listTitle.TextXAlignment    = Enum.TextXAlignment.Left
    listTitle.Parent            = listHeader

    local chanceLabelH = Instance.new("TextLabel")
    chanceLabelH.AnchorPoint        = Vector2.new(1, 0.5)
    chanceLabelH.Position           = UDim2.new(1, -16, 0.5, 0)
    chanceLabelH.Size               = UDim2.new(0, 60, 0, 20)
    chanceLabelH.BackgroundTransparency = 1
    chanceLabelH.Text               = "CHANCE"
    chanceLabelH.TextSize           = 10
    chanceLabelH.TextColor3         = C.MUTED
    chanceLabelH.Font                = Enum.Font.GothamBold
    chanceLabelH.TextXAlignment      = Enum.TextXAlignment.Right
    chanceLabelH.Parent              = listHeader

    -- Divider abaixo do header da lista
    local lhLine = Instance.new("Frame")
    lhLine.AnchorPoint      = Vector2.new(0, 1)
    lhLine.Position         = UDim2.new(0, 0, 1, 0)
    lhLine.Size             = UDim2.new(1, 0, 0, 1)
    lhLine.BackgroundColor3 = C.DIVIDER
    lhLine.BorderSizePixel  = 0
    lhLine.Parent           = listHeader

    -- ScrollingFrame para a lista
    local scroll = Instance.new("ScrollingFrame")
    scroll.Position          = UDim2.new(0, 1, 0, 50)
    scroll.Size              = UDim2.new(1, -1, 1, -50)
    scroll.BackgroundTransparency = 1
    scroll.BorderSizePixel   = 0
    scroll.ScrollBarThickness = 3
    scroll.ScrollBarImageColor3 = C.ACCENT
    scroll.CanvasSize        = UDim2.new(0, 0, 0, 0)
    scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
    scroll.Parent            = listPanel

    local listLayout = Instance.new("UIListLayout")
    listLayout.SortOrder    = Enum.SortOrder.LayoutOrder
    listLayout.Padding      = UDim.new(0, 0)
    listLayout.Parent       = scroll

    -- Popular lista com clãs
    for i, clan in ipairs(CLAN_LIST) do
        local rarityColor = RARITY_COLORS[clan.rarity] or C.MUTED

        local row = Instance.new("Frame")
        row.Name             = "ClanRow_" .. i
        row.Size             = UDim2.new(1, 0, 0, 46)
        row.BackgroundColor3 = i % 2 == 0 and C.CARD or Color3.fromRGB(11, 9, 26)
        row.BorderSizePixel  = 0
        row.LayoutOrder      = i
        row.Parent           = scroll

        -- Barra de raridade (left accent)
        local rarityBar = Instance.new("Frame")
        rarityBar.Size             = UDim2.new(0, 3, 0.7, 0)
        rarityBar.AnchorPoint      = Vector2.new(0, 0.5)
        rarityBar.Position         = UDim2.new(0, 8, 0.5, 0)
        rarityBar.BackgroundColor3 = rarityColor
        rarityBar.BorderSizePixel  = 0
        rarityBar.Parent           = row
        uiCorner(rarityBar, 2)

        -- Nome do clã
        local clanNameL = Instance.new("TextLabel")
        clanNameL.Position        = UDim2.new(0, 20, 0, 6)
        clanNameL.Size            = UDim2.new(0.55, 0, 0, 18)
        clanNameL.BackgroundTransparency = 1
        clanNameL.Text            = clan.name
        clanNameL.TextSize        = 13
        clanNameL.TextColor3      = C.TEXT
        clanNameL.Font             = Enum.Font.GothamMedium
        clanNameL.TextXAlignment   = Enum.TextXAlignment.Left
        clanNameL.Parent           = row

        -- Tag de raridade
        local rarityTag = Instance.new("TextLabel")
        rarityTag.Position        = UDim2.new(0, 20, 0, 26)
        rarityTag.Size            = UDim2.new(0.55, 0, 0, 14)
        rarityTag.BackgroundTransparency = 1
        rarityTag.Text            = clan.rarity
        rarityTag.TextSize        = 9
        rarityTag.TextColor3      = rarityColor
        rarityTag.Font             = Enum.Font.GothamBold
        rarityTag.TextXAlignment   = Enum.TextXAlignment.Left
        rarityTag.Parent           = row

        -- Percentual
        local chanceL = Instance.new("TextLabel")
        chanceL.AnchorPoint       = Vector2.new(1, 0.5)
        chanceL.Position          = UDim2.new(1, -16, 0.5, 0)
        chanceL.Size              = UDim2.new(0, 56, 0, 36)
        chanceL.BackgroundTransparency = 1
        chanceL.Text              = string.format("%.1f%%", clan.chance)
        chanceL.TextSize          = 13
        chanceL.TextColor3        = rarityColor
        chanceL.Font               = Enum.Font.GothamBold
        chanceL.TextXAlignment     = Enum.TextXAlignment.Right
        chanceL.Parent             = row

        -- Barra de probabilidade visual
        local probTrack = Instance.new("Frame")
        probTrack.AnchorPoint      = Vector2.new(1, 0)
        probTrack.Position         = UDim2.new(1, -16, 0, 34)
        probTrack.Size             = UDim2.new(0, 56, 0, 2)
        probTrack.BackgroundColor3 = Color3.fromRGB(25, 20, 45)
        probTrack.BorderSizePixel  = 0
        probTrack.Parent           = row
        uiCorner(probTrack, 1)

        local probFill = Instance.new("Frame")
        probFill.Size             = UDim2.new(math.min(clan.chance / 30, 1), 0, 1, 0)
        probFill.BackgroundColor3 = rarityColor
        probFill.BorderSizePixel  = 0
        probFill.Parent           = probTrack
        uiCorner(probFill, 1)

        -- Hover
        local function rowEnter()
            TweenService:Create(row, TWEEN_FAST, { BackgroundColor3 = C.CARD_HOVER }):Play()
        end
        local function rowLeave()
            TweenService:Create(row, TWEEN_FAST, {
                BackgroundColor3 = i % 2 == 0 and C.CARD or Color3.fromRGB(11, 9, 26)
            }):Play()
        end
        local detector = Instance.new("TextButton")
        detector.Size              = UDim2.new(1, 0, 1, 0)
        detector.BackgroundTransparency = 1
        detector.Text              = ""
        detector.BorderSizePixel   = 0
        detector.Parent            = row
        table.insert(self._connections, detector.MouseEnter:Connect(rowEnter))
        table.insert(self._connections, detector.MouseLeave:Connect(rowLeave))
    end

    -- ── Botão VOLTAR (canto inferior esquerdo) ────────────────
    local backBtn = Instance.new("TextButton")
    backBtn.Name             = "BackButton"
    backBtn.AnchorPoint      = Vector2.new(0, 1)
    backBtn.Position         = UDim2.new(0, 18, 1, -18)
    backBtn.Size             = UDim2.new(0, 130, 0, 40)
    backBtn.BackgroundColor3 = Color3.fromRGB(20, 15, 40)
    backBtn.BorderSizePixel  = 0
    backBtn.Text             = "← VOLTAR"
    backBtn.TextSize         = 13
    backBtn.TextColor3       = C.MUTED
    backBtn.Font              = Enum.Font.GothamMedium
    backBtn.AutoButtonColor   = false
    backBtn.Parent            = root
    uiCorner(backBtn, 8)
    stroke(backBtn, C.DIVIDER, 1)
    self._backBtn = backBtn

    table.insert(self._connections, backBtn.MouseEnter:Connect(function()
        TweenService:Create(backBtn, TWEEN_FAST, {
            BackgroundColor3 = Color3.fromRGB(30, 22, 58),
            TextColor3 = C.TEXT,
        }):Play()
    end))
    table.insert(self._connections, backBtn.MouseLeave:Connect(function()
        TweenService:Create(backBtn, TWEEN_FAST, {
            BackgroundColor3 = Color3.fromRGB(20, 15, 40),
            TextColor3 = C.MUTED,
        }):Play()
    end))
    table.insert(self._connections, backBtn.MouseButton1Click:Connect(function()
        if self.OnBackClicked then self.OnBackClicked() end
    end))
end

-- ── Lógica de spin ─────────────────────────────────────────────
function ClanMenu:_doSpin()
    if self._spinning then return end
    self._spinning = true
    self._spinBtnLabel.Text = "⟳  GIRANDO..."
    self._clanIcon.Text     = "?"
    self._resultName.Text   = ""
    self._resultRarity.Text = ""

    -- Animar círculo girando
    local spins = 0
    local maxSpins = math.random(18, 28)
    local delay = 0.04

    local function spinStep()
        if spins >= maxSpins then
            -- Resultado final
            local result = self:_pickClan()
            self._clanIcon.Text     = string.sub(result.name, 1, 2)
            self._clanIcon.TextColor3 = RARITY_COLORS[result.rarity] or C.TEXT
            self._resultName.Text   = result.name
            self._resultName.TextColor3 = C.TEXT
            self._resultRarity.Text = "✦ " .. result.rarity .. " ✦"
            self._resultRarity.TextColor3 = RARITY_COLORS[result.rarity] or C.GOLD
            self._spinBtnLabel.Text = "⟳  GIRAR NOVAMENTE"
            self._spinning = false

            -- Pulsar o círculo ao revelar
            TweenService:Create(self._spinCircle, TweenInfo.new(0.12), {
                Size = UDim2.new(0, 236, 0, 236)
            }):Play()
            task.delay(0.12, function()
                TweenService:Create(self._spinCircle, TweenInfo.new(0.15), {
                    Size = UDim2.new(0, 220, 0, 220)
                }):Play()
            end)
            return
        end

        -- Mostrar clã aleatório durante animação
        local randClan = CLAN_LIST[math.random(1, #CLAN_LIST)]
        self._clanIcon.Text = string.sub(randClan.name, 1, 2)
        self._clanIcon.TextColor3 = RARITY_COLORS[randClan.rarity] or C.MUTED

        spins = spins + 1
        delay = delay * 1.06  -- Vai desacelerando
        task.delay(delay, spinStep)
    end

    spinStep()
end

function ClanMenu:_pickClan()
    -- Rolagem ponderada por chance
    local roll = math.random() * 100
    local cumulative = 0
    for _, clan in ipairs(CLAN_LIST) do
        cumulative = cumulative + clan.chance
        if roll <= cumulative then
            return clan
        end
    end
    return CLAN_LIST[#CLAN_LIST]
end

-- ── Show / Hide ────────────────────────────────────────────────
function ClanMenu:Show()
    self._root.Visible = true
    self._root.BackgroundTransparency = 1
    TweenService:Create(self._root, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 0
    }):Play()
end

function ClanMenu:Hide()
    TweenService:Create(self._root, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.26, function()
        if self._root then self._root.Visible = false end
    end)
end

function ClanMenu:Destroy()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    if self._root then self._root:Destroy() end
end

return ClanMenu
