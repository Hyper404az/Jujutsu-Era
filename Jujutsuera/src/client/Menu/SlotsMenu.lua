-- ================================================================
-- SlotsMenu.lua  |  ModuleScript
-- src/client/Menu/SlotsMenu.lua
-- Tela de gerenciamento de personagens/slots secundários
-- ================================================================

local TweenService = game:GetService("TweenService")
local Players      = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

-- ── Paleta ─────────────────────────────────────────────────────
local C = {
    BG          = Color3.fromRGB(5,  5,  15),
    PANEL       = Color3.fromRGB(10, 8,  24),
    CARD        = Color3.fromRGB(14, 11, 32),
    CARD_HOVER  = Color3.fromRGB(20, 16, 44),
    CARD_EMPTY  = Color3.fromRGB(10, 8,  25),
    ACCENT      = Color3.fromRGB(120, 40, 200),
    ACCENT_GLOW = Color3.fromRGB(160, 80, 240),
    GOLD        = Color3.fromRGB(255, 192, 30),
    TEXT        = Color3.fromRGB(235, 230, 255),
    MUTED       = Color3.fromRGB(140, 130, 185),
    HINT        = Color3.fromRGB(80,  70, 120),
    DIVIDER     = Color3.fromRGB(35,  28,  65),
    CREATE_BTN  = Color3.fromRGB(100, 30, 180),
    CREATE_H    = Color3.fromRGB(130, 50, 220),
    DELETE_BTN  = Color3.fromRGB(100, 20, 30),
}

local TWEEN_FAST = TweenInfo.new(0.18, Enum.EasingStyle.Quad,  Enum.EasingDirection.Out)
local TWEEN_MED  = TweenInfo.new(0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

-- Máximo de slots disponíveis
local MAX_SLOTS = 4

-- Classes disponíveis para criação
local CLASSES = {
    { name = "Feiticeiro",   icon = "⚡", desc = "Especialista em CE" },
    { name = "Exorcista",    icon = "🗡", desc = "Combate corpo-a-corpo" },
    { name = "Curandeiro",   icon = "💫", desc = "Suporte e inversão" },
    { name = "Técnico",      icon = "🔮", desc = "Técnicas especializadas" },
}

-- ── Utilitários ────────────────────────────────────────────────
local function uiCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, trans)
    local s = Instance.new("UIStroke")
    s.Color        = color or C.ACCENT
    s.Thickness    = thickness or 1
    s.Transparency = trans or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

-- ── Módulo ─────────────────────────────────────────────────────
local SlotsMenu = {}
SlotsMenu.__index = SlotsMenu

SlotsMenu.OnBackClicked = nil

function SlotsMenu.new(gui)
    local self = setmetatable({}, SlotsMenu)
    self._gui         = gui
    self._connections = {}
    self._slots       = {}   -- dados dos slots (carregado do DataStore via server na implementação real)
    self._createModal = nil
    self:_build()
    return self
end

function SlotsMenu:_build()
    -- ── Root ──────────────────────────────────────────────────
    local root = Instance.new("Frame")
    root.Name             = "SlotsMenuRoot"
    root.Size             = UDim2.new(1, 0, 1, 0)
    root.BackgroundColor3 = C.BG
    root.BorderSizePixel  = 0
    root.Visible          = false
    root.Parent           = self._gui
    self._root = root

    local bgGrad = Instance.new("UIGradient")
    bgGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(5, 3, 18)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(3, 3, 12)),
    })
    bgGrad.Rotation = 135
    bgGrad.Parent = root

    -- Linha topo
    local topLine = Instance.new("Frame")
    topLine.Size             = UDim2.new(1, 0, 0, 2)
    topLine.BackgroundColor3 = C.ACCENT
    topLine.BorderSizePixel  = 0
    topLine.Parent           = root
    local tlG = Instance.new("UIGradient")
    tlG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0,   Color3.fromRGB(60, 10, 120)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(160, 60, 255)),
        ColorSequenceKeypoint.new(1,   Color3.fromRGB(60, 10, 120)),
    })
    tlG.Parent = topLine

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
    headerTitle.Text             = "🎴  SLOTS"
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
    headerSub.Text               = "Personagens secundários"
    headerSub.TextSize           = 12
    headerSub.TextColor3         = C.MUTED
    headerSub.Font                = Enum.Font.Gotham
    headerSub.TextXAlignment      = Enum.TextXAlignment.Right
    headerSub.Parent              = header

    local hLine = Instance.new("Frame")
    hLine.AnchorPoint      = Vector2.new(0, 1)
    hLine.Position         = UDim2.new(0, 0, 1, 0)
    hLine.Size             = UDim2.new(1, 0, 0, 1)
    hLine.BackgroundColor3 = C.DIVIDER
    hLine.BorderSizePixel  = 0
    hLine.Parent           = header

    -- ── Área dos slots ────────────────────────────────────────
    local slotsArea = Instance.new("Frame")
    slotsArea.Position         = UDim2.new(0, 0, 0, 64)
    slotsArea.Size             = UDim2.new(1, 0, 1, -64)
    slotsArea.BackgroundTransparency = 1
    slotsArea.Parent           = root

    -- Texto de descrição acima dos slots
    local descL = Instance.new("TextLabel")
    descL.Position         = UDim2.new(0, 32, 0, 20)
    descL.Size             = UDim2.new(0.6, 0, 0, 20)
    descL.BackgroundTransparency = 1
    descL.Text             = "Crie e gerencie seus personagens alternativos"
    descL.TextSize         = 13
    descL.TextColor3       = C.MUTED
    descL.Font              = Enum.Font.Gotham
    descL.TextXAlignment    = Enum.TextXAlignment.Left
    descL.Parent            = slotsArea

    -- Contador de slots
    local slotCount = Instance.new("TextLabel")
    slotCount.AnchorPoint        = Vector2.new(1, 0)
    slotCount.Position           = UDim2.new(1, -32, 0, 20)
    slotCount.Size               = UDim2.new(0, 120, 0, 20)
    slotCount.BackgroundTransparency = 1
    slotCount.Text               = "0 / " .. MAX_SLOTS .. " slots usados"
    slotCount.TextSize           = 11
    slotCount.TextColor3         = C.HINT
    slotCount.Font                = Enum.Font.Gotham
    slotCount.TextXAlignment      = Enum.TextXAlignment.Right
    slotCount.Parent              = slotsArea
    self._slotCount = slotCount

    -- Grid de slots
    local grid = Instance.new("Frame")
    grid.Position         = UDim2.new(0, 24, 0, 54)
    grid.Size             = UDim2.new(1, -48, 0, 340)
    grid.BackgroundTransparency = 1
    grid.Parent           = slotsArea
    self._grid = grid

    local gridLayout = Instance.new("UIGridLayout")
    gridLayout.CellSize        = UDim2.new(0.5, -8, 0, 160)
    gridLayout.CellPadding     = UDim2.new(0, 16, 0, 16)
    gridLayout.SortOrder       = Enum.SortOrder.LayoutOrder
    gridLayout.Parent          = grid

    -- Criar os 4 slots
    self._slotFrames = {}
    for i = 1, MAX_SLOTS do
        self:_buildSlotCard(grid, i)
    end

    -- ── Informações abaixo do grid ────────────────────────────
    local infoBox = Instance.new("Frame")
    infoBox.Position         = UDim2.new(0, 24, 0, 420)
    infoBox.Size             = UDim2.new(1, -48, 0, 60)
    infoBox.BackgroundColor3 = Color3.fromRGB(12, 9, 28)
    infoBox.BorderSizePixel  = 0
    infoBox.Parent           = slotsArea
    uiCorner(infoBox, 8)
    stroke(infoBox, C.DIVIDER, 1)

    local infoText = Instance.new("TextLabel")
    infoText.Position         = UDim2.new(0, 16, 0, 0)
    infoText.Size             = UDim2.new(1, -32, 1, 0)
    infoText.BackgroundTransparency = 1
    infoText.Text             = "ℹ  Cada slot possui progressão independente. O personagem principal e os secundários compartilham Robux e Gamepasses, mas não XP nem Clã."
    infoText.TextSize         = 11
    infoText.TextColor3       = C.HINT
    infoText.Font              = Enum.Font.Gotham
    infoText.TextWrapped       = true
    infoText.TextXAlignment    = Enum.TextXAlignment.Left
    infoText.TextYAlignment    = Enum.TextYAlignment.Center
    infoText.Parent            = infoBox

    -- ── Botão VOLTAR ──────────────────────────────────────────
    local backBtn = Instance.new("TextButton")
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

function SlotsMenu:_buildSlotCard(parent, index)
    local data = self._slots[index]  -- nil = slot vazio
    local isEmpty = data == nil

    local card = Instance.new("Frame")
    card.Name             = "Slot_" .. index
    card.BackgroundColor3 = isEmpty and C.CARD_EMPTY or C.CARD
    card.BorderSizePixel  = 0
    card.LayoutOrder      = index
    card.Parent           = parent
    uiCorner(card, 10)

    if isEmpty then
        stroke(card, C.DIVIDER, 1, 0.3)
    else
        stroke(card, C.ACCENT, 1, 0.5)
    end

    self._slotFrames[index] = card

    if isEmpty then
        -- Slot vazio — botão de criação
        local plusIcon = Instance.new("TextLabel")
        plusIcon.AnchorPoint       = Vector2.new(0.5, 0.38)
        plusIcon.Position          = UDim2.new(0.5, 0, 0.38, 0)
        plusIcon.Size              = UDim2.new(0, 44, 0, 44)
        plusIcon.BackgroundColor3  = Color3.fromRGB(18, 14, 38)
        plusIcon.BorderSizePixel   = 0
        plusIcon.Text              = "+"
        plusIcon.TextSize          = 28
        plusIcon.TextColor3        = C.HINT
        plusIcon.Font               = Enum.Font.GothamBold
        plusIcon.TextXAlignment     = Enum.TextXAlignment.Center
        plusIcon.TextYAlignment     = Enum.TextYAlignment.Center
        plusIcon.Parent             = card
        uiCorner(plusIcon, 22)

        local emptyLabel = Instance.new("TextLabel")
        emptyLabel.AnchorPoint       = Vector2.new(0.5, 0)
        emptyLabel.Position          = UDim2.new(0.5, 0, 0.62, 0)
        emptyLabel.Size              = UDim2.new(0.9, 0, 0, 18)
        emptyLabel.BackgroundTransparency = 1
        emptyLabel.Text              = "Slot " .. index .. " — Vazio"
        emptyLabel.TextSize          = 12
        emptyLabel.TextColor3        = C.HINT
        emptyLabel.Font               = Enum.Font.Gotham
        emptyLabel.TextXAlignment     = Enum.TextXAlignment.Center
        emptyLabel.Parent             = card

        local createBtn = Instance.new("TextButton")
        createBtn.AnchorPoint      = Vector2.new(0.5, 1)
        createBtn.Position         = UDim2.new(0.5, 0, 1, -12)
        createBtn.Size             = UDim2.new(0.75, 0, 0, 32)
        createBtn.BackgroundColor3 = C.CREATE_BTN
        createBtn.BorderSizePixel  = 0
        createBtn.Text             = "Criar Personagem"
        createBtn.TextSize         = 11
        createBtn.TextColor3       = C.TEXT
        createBtn.Font              = Enum.Font.GothamMedium
        createBtn.AutoButtonColor   = false
        createBtn.Parent            = card
        uiCorner(createBtn, 7)

        table.insert(self._connections, createBtn.MouseEnter:Connect(function()
            TweenService:Create(createBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_H }):Play()
        end))
        table.insert(self._connections, createBtn.MouseLeave:Connect(function()
            TweenService:Create(createBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_BTN }):Play()
        end))
        table.insert(self._connections, createBtn.MouseButton1Click:Connect(function()
            self:_openCreateModal(index)
        end))

        table.insert(self._connections, card.MouseEnter:Connect(function()
            TweenService:Create(card, TWEEN_FAST, { BackgroundColor3 = C.CARD_HOVER }):Play()
        end))
        table.insert(self._connections, card.MouseLeave:Connect(function()
            TweenService:Create(card, TWEEN_FAST, { BackgroundColor3 = C.CARD_EMPTY }):Play()
        end))
    else
        -- Slot preenchido
        local slotTitle = Instance.new("TextLabel")
        slotTitle.Position         = UDim2.new(0, 12, 0, 12)
        slotTitle.Size             = UDim2.new(1, -50, 0, 16)
        slotTitle.BackgroundTransparency = 1
        slotTitle.Text             = "Personagem " .. index
        slotTitle.TextSize         = 10
        slotTitle.TextColor3       = C.HINT
        slotTitle.Font              = Enum.Font.GothamBold
        slotTitle.TextXAlignment    = Enum.TextXAlignment.Left
        slotTitle.Parent            = card

        -- Ícone de classe
        local classIcon = Instance.new("TextLabel")
        classIcon.AnchorPoint      = Vector2.new(0.5, 0)
        classIcon.Position         = UDim2.new(0.5, 0, 0, 30)
        classIcon.Size             = UDim2.new(0, 50, 0, 50)
        classIcon.BackgroundColor3 = Color3.fromRGB(18, 14, 38)
        classIcon.BorderSizePixel  = 0
        classIcon.Text             = data.classIcon or "⚡"
        classIcon.TextSize         = 26
        classIcon.TextColor3       = C.TEXT
        classIcon.Font              = Enum.Font.Gotham
        classIcon.TextXAlignment    = Enum.TextXAlignment.Center
        classIcon.TextYAlignment    = Enum.TextYAlignment.Center
        classIcon.Parent            = card
        uiCorner(classIcon, 10)

        local charName = Instance.new("TextLabel")
        charName.AnchorPoint       = Vector2.new(0.5, 0)
        charName.Position          = UDim2.new(0.5, 0, 0, 86)
        charName.Size              = UDim2.new(0.9, 0, 0, 18)
        charName.BackgroundTransparency = 1
        charName.Text              = data.name or "Sem nome"
        charName.TextSize          = 14
        charName.TextColor3        = C.TEXT
        charName.Font               = Enum.Font.GothamBold
        charName.TextXAlignment     = Enum.TextXAlignment.Center
        charName.Parent             = card

        local charClass = Instance.new("TextLabel")
        charClass.AnchorPoint       = Vector2.new(0.5, 0)
        charClass.Position          = UDim2.new(0.5, 0, 0, 106)
        charClass.Size              = UDim2.new(0.9, 0, 0, 15)
        charClass.BackgroundTransparency = 1
        charClass.Text              = data.class or "Feiticeiro"
        charClass.TextSize          = 11
        charClass.TextColor3        = C.MUTED
        charClass.Font               = Enum.Font.Gotham
        charClass.TextXAlignment     = Enum.TextXAlignment.Center
        charClass.Parent             = card

        -- Botão de deletar
        local delBtn = Instance.new("TextButton")
        delBtn.AnchorPoint      = Vector2.new(1, 0)
        delBtn.Position         = UDim2.new(1, -10, 0, 10)
        delBtn.Size             = UDim2.new(0, 28, 0, 28)
        delBtn.BackgroundColor3 = Color3.fromRGB(20, 10, 14)
        delBtn.BorderSizePixel  = 0
        delBtn.Text             = "✕"
        delBtn.TextSize         = 11
        delBtn.TextColor3       = Color3.fromRGB(160, 60, 70)
        delBtn.Font              = Enum.Font.GothamBold
        delBtn.AutoButtonColor   = false
        delBtn.Parent            = card
        uiCorner(delBtn, 14)

        table.insert(self._connections, delBtn.MouseButton1Click:Connect(function()
            self:_deleteSlot(index)
        end))

        -- Botão selecionar/jogar com esse personagem
        local selectBtn = Instance.new("TextButton")
        selectBtn.AnchorPoint      = Vector2.new(0.5, 1)
        selectBtn.Position         = UDim2.new(0.5, 0, 1, -12)
        selectBtn.Size             = UDim2.new(0.75, 0, 0, 30)
        selectBtn.BackgroundColor3 = C.CREATE_BTN
        selectBtn.BorderSizePixel  = 0
        selectBtn.Text             = "Selecionar"
        selectBtn.TextSize         = 11
        selectBtn.TextColor3       = C.TEXT
        selectBtn.Font              = Enum.Font.GothamMedium
        selectBtn.AutoButtonColor   = false
        selectBtn.Parent            = card
        uiCorner(selectBtn, 7)

        table.insert(self._connections, selectBtn.MouseEnter:Connect(function()
            TweenService:Create(selectBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_H }):Play()
        end))
        table.insert(self._connections, selectBtn.MouseLeave:Connect(function()
            TweenService:Create(selectBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_BTN }):Play()
        end))
        -- Na implementação real, dispara evento para o servidor selecionar o personagem
        table.insert(self._connections, selectBtn.MouseButton1Click:Connect(function()
            print("Selecionado personagem no slot " .. index)
            -- game:GetService("ReplicatedStorage").Remotes.SelectSlot:FireServer(index)
        end))
    end
end

function SlotsMenu:_openCreateModal(slotIndex)
    if self._createModal then return end

    -- Overlay escurecido
    local overlay = Instance.new("Frame")
    overlay.Size             = UDim2.new(1, 0, 1, 0)
    overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    overlay.BackgroundTransparency = 0.45
    overlay.BorderSizePixel  = 0
    overlay.ZIndex           = 20
    overlay.Parent           = self._root
    self._createModal = overlay

    -- Modal central
    local modal = Instance.new("Frame")
    modal.AnchorPoint      = Vector2.new(0.5, 0.5)
    modal.Position         = UDim2.new(0.5, 0, 0.5, 0)
    modal.Size             = UDim2.new(0, 380, 0, 340)
    modal.BackgroundColor3 = Color3.fromRGB(12, 9, 28)
    modal.BorderSizePixel  = 0
    modal.ZIndex           = 21
    modal.Parent           = overlay
    uiCorner(modal, 14)
    stroke(modal, C.ACCENT, 1, 0.3)

    -- Header do modal
    local modalTitle = Instance.new("TextLabel")
    modalTitle.Position         = UDim2.new(0, 20, 0, 18)
    modalTitle.Size             = UDim2.new(0.7, 0, 0, 24)
    modalTitle.BackgroundTransparency = 1
    modalTitle.Text             = "Criar Personagem — Slot " .. slotIndex
    modalTitle.TextSize         = 16
    modalTitle.TextColor3       = C.TEXT
    modalTitle.Font              = Enum.Font.GothamBold
    modalTitle.TextXAlignment    = Enum.TextXAlignment.Left
    modalTitle.ZIndex            = 22
    modalTitle.Parent            = modal

    -- Fechar modal
    local closeBtn = Instance.new("TextButton")
    closeBtn.AnchorPoint      = Vector2.new(1, 0)
    closeBtn.Position         = UDim2.new(1, -14, 0, 14)
    closeBtn.Size             = UDim2.new(0, 28, 0, 28)
    closeBtn.BackgroundColor3 = Color3.fromRGB(20, 14, 38)
    closeBtn.BorderSizePixel  = 0
    closeBtn.Text             = "✕"
    closeBtn.TextSize         = 13
    closeBtn.TextColor3       = C.MUTED
    closeBtn.Font              = Enum.Font.GothamBold
    closeBtn.AutoButtonColor   = false
    closeBtn.ZIndex            = 22
    closeBtn.Parent            = modal
    uiCorner(closeBtn, 14)

    table.insert(self._connections, closeBtn.MouseButton1Click:Connect(function()
        self:_closeModal()
    end))

    -- Campo de nome
    local nameLbl = Instance.new("TextLabel")
    nameLbl.Position         = UDim2.new(0, 20, 0, 58)
    nameLbl.Size             = UDim2.new(0.5, 0, 0, 14)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Text             = "NOME DO PERSONAGEM"
    nameLbl.TextSize         = 10
    nameLbl.TextColor3       = C.MUTED
    nameLbl.Font              = Enum.Font.GothamBold
    nameLbl.TextXAlignment    = Enum.TextXAlignment.Left
    nameLbl.ZIndex            = 22
    nameLbl.Parent            = modal

    local nameBox = Instance.new("TextBox")
    nameBox.Position         = UDim2.new(0, 20, 0, 76)
    nameBox.Size             = UDim2.new(1, -40, 0, 38)
    nameBox.BackgroundColor3 = Color3.fromRGB(18, 14, 40)
    nameBox.BorderSizePixel  = 0
    nameBox.Text             = ""
    nameBox.PlaceholderText  = "Digite um nome..."
    nameBox.PlaceholderColor3 = C.HINT
    nameBox.TextSize         = 13
    nameBox.TextColor3       = C.TEXT
    nameBox.Font              = Enum.Font.Gotham
    nameBox.ZIndex            = 22
    nameBox.Parent            = modal
    uiCorner(nameBox, 8)
    stroke(nameBox, C.DIVIDER, 1)
    self._nameBox = nameBox

    -- Seleção de classe
    local classLbl = Instance.new("TextLabel")
    classLbl.Position         = UDim2.new(0, 20, 0, 128)
    classLbl.Size             = UDim2.new(0.5, 0, 0, 14)
    classLbl.BackgroundTransparency = 1
    classLbl.Text             = "CLASSE"
    classLbl.TextSize         = 10
    classLbl.TextColor3       = C.MUTED
    classLbl.Font              = Enum.Font.GothamBold
    classLbl.TextXAlignment    = Enum.TextXAlignment.Left
    classLbl.ZIndex            = 22
    classLbl.Parent            = modal

    local selectedClass = { index = 1 }
    local classBtns = {}

    for i, cls in ipairs(CLASSES) do
        local clsBtn = Instance.new("TextButton")
        clsBtn.Position         = UDim2.new(0, 20 + (i-1) * 84, 0, 148)
        clsBtn.Size             = UDim2.new(0, 76, 0, 68)
        clsBtn.BackgroundColor3 = i == 1 and C.ACCENT or Color3.fromRGB(16, 12, 36)
        clsBtn.BorderSizePixel  = 0
        clsBtn.Text             = ""
        clsBtn.AutoButtonColor   = false
        clsBtn.ZIndex            = 22
        clsBtn.Parent            = modal
        uiCorner(clsBtn, 8)
        classBtns[i] = clsBtn

        local clsIcon = Instance.new("TextLabel")
        clsIcon.Position        = UDim2.new(0.5, -12, 0, 8)
        clsIcon.Size            = UDim2.new(0, 24, 0, 24)
        clsIcon.BackgroundTransparency = 1
        clsIcon.Text            = cls.icon
        clsIcon.TextSize        = 18
        clsIcon.TextColor3      = C.TEXT
        clsIcon.Font             = Enum.Font.Gotham
        clsIcon.ZIndex           = 23
        clsIcon.Parent           = clsBtn

        local clsName = Instance.new("TextLabel")
        clsName.Position        = UDim2.new(0, 0, 0, 34)
        clsName.Size            = UDim2.new(1, 0, 0, 14)
        clsName.BackgroundTransparency = 1
        clsName.Text            = cls.name
        clsName.TextSize        = 9
        clsName.TextColor3      = C.TEXT
        clsName.Font             = Enum.Font.GothamMedium
        clsName.TextXAlignment   = Enum.TextXAlignment.Center
        clsName.ZIndex           = 23
        clsName.Parent           = clsBtn

        table.insert(self._connections, clsBtn.MouseButton1Click:Connect(function()
            selectedClass.index = i
            for j, b in ipairs(classBtns) do
                TweenService:Create(b, TWEEN_FAST, {
                    BackgroundColor3 = j == i and C.ACCENT or Color3.fromRGB(16, 12, 36)
                }):Play()
            end
        end))
    end

    -- Botão confirmar criação
    local confirmBtn = Instance.new("TextButton")
    confirmBtn.AnchorPoint      = Vector2.new(0.5, 1)
    confirmBtn.Position         = UDim2.new(0.5, 0, 1, -20)
    confirmBtn.Size             = UDim2.new(0.7, 0, 0, 44)
    confirmBtn.BackgroundColor3 = C.CREATE_BTN
    confirmBtn.BorderSizePixel  = 0
    confirmBtn.Text             = "✓  Criar Personagem"
    confirmBtn.TextSize         = 14
    confirmBtn.TextColor3       = C.TEXT
    confirmBtn.Font              = Enum.Font.GothamBold
    confirmBtn.AutoButtonColor   = false
    confirmBtn.ZIndex            = 22
    confirmBtn.Parent            = modal
    uiCorner(confirmBtn, 10)

    table.insert(self._connections, confirmBtn.MouseEnter:Connect(function()
        TweenService:Create(confirmBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_H }):Play()
    end))
    table.insert(self._connections, confirmBtn.MouseLeave:Connect(function()
        TweenService:Create(confirmBtn, TWEEN_FAST, { BackgroundColor3 = C.CREATE_BTN }):Play()
    end))
    table.insert(self._connections, confirmBtn.MouseButton1Click:Connect(function()
        local name = self._nameBox and self._nameBox.Text or ""
        if #name < 2 then
            -- Shake o campo de nome
            TweenService:Create(nameBox, TWEEN_FAST, { Position = UDim2.new(0, 28, 0, 76) }):Play()
            task.delay(0.08, function()
                TweenService:Create(nameBox, TWEEN_FAST, { Position = UDim2.new(0, 12, 0, 76) }):Play()
                task.delay(0.08, function()
                    TweenService:Create(nameBox, TWEEN_FAST, { Position = UDim2.new(0, 20, 0, 76) }):Play()
                end)
            end)
            return
        end
        local cls = CLASSES[selectedClass.index]
        self._slots[slotIndex] = {
            name      = name,
            class     = cls.name,
            classIcon = cls.icon,
        }
        self:_closeModal()
        self:_refreshGrid()
        -- Na implementação real, salva no servidor:
        -- game:GetService("ReplicatedStorage").Remotes.CreateSlot:FireServer(slotIndex, name, cls.name)
    end))

    -- Animação de entrada do modal
    modal.Position = UDim2.new(0.5, 0, 0.5, 20)
    modal.BackgroundTransparency = 1
    TweenService:Create(modal, TWEEN_MED, {
        Position = UDim2.new(0.5, 0, 0.5, 0),
        BackgroundTransparency = 0,
    }):Play()
end

function SlotsMenu:_closeModal()
    if self._createModal then
        self._createModal:Destroy()
        self._createModal = nil
    end
    self._nameBox = nil
end

function SlotsMenu:_deleteSlot(index)
    self._slots[index] = nil
    self:_refreshGrid()
end

function SlotsMenu:_refreshGrid()
    -- Limpar e recriar todos os cards
    for _, child in ipairs(self._grid:GetChildren()) do
        if child:IsA("GuiObject") then
            child:Destroy()
        end
    end
    self._slotFrames = {}
    for i = 1, MAX_SLOTS do
        self:_buildSlotCard(self._grid, i)
    end
    -- Atualizar contador
    local used = 0
    for i = 1, MAX_SLOTS do
        if self._slots[i] then used = used + 1 end
    end
    if self._slotCount then
        self._slotCount.Text = used .. " / " .. MAX_SLOTS .. " slots usados"
    end
end

function SlotsMenu:Show()
    self._root.Visible = true
    self._root.BackgroundTransparency = 1
    TweenService:Create(self._root, TweenInfo.new(0.3, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 0
    }):Play()
end

function SlotsMenu:Hide()
    self:_closeModal()
    TweenService:Create(self._root, TweenInfo.new(0.25, Enum.EasingStyle.Quart), {
        BackgroundTransparency = 1
    }):Play()
    task.delay(0.26, function()
        if self._root then self._root.Visible = false end
    end)
end

function SlotsMenu:Destroy()
    self:_closeModal()
    for _, c in ipairs(self._connections) do c:Disconnect() end
    if self._root then self._root:Destroy() end
end

return SlotsMenu
