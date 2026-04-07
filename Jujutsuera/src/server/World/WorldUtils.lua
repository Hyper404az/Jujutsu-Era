local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameplayConfig = require(ReplicatedStorage.Shared.Config.GameplayConfig)
local TrainingConfig = require(ReplicatedStorage.Shared.Config.TrainingConfig)
local WorldConfig = require(ReplicatedStorage.Shared.Config.WorldConfig)

local Utils = {}
local PALETTE = WorldConfig.Palette
local RNG = Random.new(78124)

function Utils.clearFolder(folder)
    for _, child in ipairs(folder:GetChildren()) do
        child:Destroy()
    end
end

function Utils.ensureFolder(parent, name)
    local existing = parent:FindFirstChild(name)
    if existing and existing:IsA("Folder") then
        Utils.clearFolder(existing)
        return existing
    end

    if existing then
        existing:Destroy()
    end

    local folder = Instance.new("Folder")
    folder.Name = name
    folder.Parent = parent
    return folder
end

function Utils.make(className, parent, props)
    local inst = Instance.new(className)
    for key, value in pairs(props or {}) do
        inst[key] = value
    end
    inst.Parent = parent
    return inst
end

function Utils.part(parent, props)
    local className = props.ClassName or "Part"
    props.ClassName = nil
    local part = Utils.make(className, parent, props)
    if part:IsA("BasePart") then
        part.TopSurface = Enum.SurfaceType.Smooth
        part.BottomSurface = Enum.SurfaceType.Smooth
    end
    return part
end

function Utils.floor(parent, name, cframe, size, material, color, reflectance)
    return Utils.part(parent, {
        Name = name,
        Anchored = true,
        Material = material,
        Color = color,
        Reflectance = reflectance or 0,
        Size = size,
        CFrame = cframe,
    })
end

function Utils.wall(parent, cframe, size, material, color)
    return Utils.part(parent, {
        Name = "Wall",
        Anchored = true,
        Material = material,
        Color = color,
        Size = size,
        CFrame = cframe,
    })
end

function Utils.window(parent, cframe, size, color)
    local glass = Utils.part(parent, {
        Name = "Window",
        Anchored = true,
        Material = Enum.Material.Glass,
        Color = color or Color3.fromRGB(182, 86, 120),
        Transparency = 0.35,
        Reflectance = 0.05,
        Size = size,
        CFrame = cframe,
    })

    Utils.make("PointLight", glass, {
        Brightness = 0.45,
        Range = 10,
        Color = Color3.fromRGB(255, 188, 214),
    })

    return glass
end

function Utils.surfaceText(part, face, title, subtitle, options)
    options = options or {}
    local gui = Utils.make("SurfaceGui", part, {
        Face = face,
        LightInfluence = 0,
        Brightness = options.Brightness or 2.4,
        SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud,
        PixelsPerStud = options.PixelsPerStud or 28,
        CanvasSize = Vector2.new(1024, 512),
    })

    Utils.make("Frame", gui, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = options.BackgroundColor3 or Color3.fromRGB(18, 14, 24),
        BackgroundTransparency = options.BackgroundTransparency or 0.18,
        BorderSizePixel = 0,
    })

    Utils.make("TextLabel", gui, {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.05, 0.08),
        Size = UDim2.fromScale(0.9, subtitle and 0.5 or 0.76),
        Font = options.TitleFont or Enum.Font.GothamBlack,
        Text = title,
        TextColor3 = options.TitleColor3 or Color3.fromRGB(245, 240, 255),
        TextScaled = true,
        TextWrapped = true,
        TextStrokeTransparency = 0.75,
    })

    if subtitle then
        Utils.make("TextLabel", gui, {
            BackgroundTransparency = 1,
            Position = UDim2.fromScale(0.05, 0.58),
            Size = UDim2.fromScale(0.9, 0.24),
            Font = options.SubtitleFont or Enum.Font.GothamSemibold,
            Text = subtitle,
            TextColor3 = options.SubtitleColor3 or Color3.fromRGB(194, 182, 220),
            TextScaled = true,
            TextWrapped = true,
            TextStrokeTransparency = 0.82,
        })
    end

    return gui
end

function Utils.billboard(part, text, options)
    options = options or {}
    local gui = Utils.make("BillboardGui", part, {
        Size = UDim2.fromOffset(options.Width or 220, options.Height or 70),
        StudsOffset = options.Offset or Vector3.new(0, 4.2, 0),
        AlwaysOnTop = true,
        LightInfluence = 0,
        MaxDistance = options.MaxDistance or 80,
    })

    local frame = Utils.make("Frame", gui, {
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = options.BackgroundColor3 or Color3.fromRGB(20, 16, 28),
        BackgroundTransparency = options.BackgroundTransparency or 0.2,
        BorderSizePixel = 0,
    })
    Utils.make("UICorner", frame, { CornerRadius = UDim.new(0, 14) })
    Utils.make("UIStroke", frame, {
        Color = options.StrokeColor3 or PALETTE.NeonBlue,
        Thickness = 1.4,
        Transparency = 0.36,
    })

    local label = Utils.make("TextLabel", frame, {
        BackgroundTransparency = 1,
        Position = UDim2.fromScale(0.07, 0.12),
        Size = UDim2.fromScale(0.86, 0.76),
        Font = options.Font or Enum.Font.GothamBold,
        Text = text,
        TextColor3 = options.TextColor3 or Color3.fromRGB(244, 238, 255),
        TextScaled = true,
        TextWrapped = true,
        TextStrokeTransparency = 0.8,
    })

    return gui, label
end

function Utils.emitterRig(parent, name, cframe, size, emitters)
    local rig = Utils.part(parent, {
        Name = name,
        Anchored = true,
        Transparency = 1,
        CanCollide = false,
        CanQuery = false,
        CanTouch = false,
        Size = size,
        CFrame = cframe,
    })

    for _, emitterProps in ipairs(emitters) do
        local attachment = Utils.make("Attachment", rig, {})
        Utils.make("ParticleEmitter", attachment, emitterProps)
    end

    return rig
end

function Utils.stairs(parent, baseCFrame, stepCount, stepSize, direction)
    for index = 0, stepCount - 1 do
        Utils.floor(parent, "Step", baseCFrame + (direction * (index * stepSize.Z)) + Vector3.new(0, index * stepSize.Y, 0), stepSize, Enum.Material.Concrete, Color3.fromRGB(112, 106, 104))
    end
end

function Utils.tree(parent, position, trunkHeight, canopySize, canopyColor)
    local model = Utils.make("Model", parent, { Name = "Tree" })
    local trunk = Utils.part(model, {
        Name = "Trunk",
        Anchored = true,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(86, 62, 45),
        Size = Vector3.new(2.6, trunkHeight, 2.6),
        CFrame = CFrame.new(position + Vector3.new(0, trunkHeight * 0.5, 0)),
    })
    local canopy = Utils.part(model, {
        Name = "Canopy",
        Anchored = true,
        Shape = Enum.PartType.Ball,
        Material = Enum.Material.Grass,
        Color = canopyColor or Color3.fromRGB(49, 60, 50),
        Size = canopySize,
        CFrame = trunk.CFrame * CFrame.new(0, (trunkHeight * 0.42) + (canopySize.Y * 0.22), 0),
    })
    local attachment = Utils.make("Attachment", canopy, {})
    Utils.make("ParticleEmitter", attachment, {
        Texture = "rbxasset://textures/particles/sparkles_main.dds",
        Rate = 1.2,
        Lifetime = NumberRange.new(4, 6),
        Speed = NumberRange.new(0.8, 2.1),
        SpreadAngle = Vector2.new(18, 28),
        Acceleration = WorldConfig.GlobalWind * 1.2,
        Color = ColorSequence.new(canopy.Color),
        Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.82),
            NumberSequenceKeypoint.new(1, 1),
        }),
        Size = NumberSequence.new(0.16, 0.05),
    })
    model.PrimaryPart = trunk
    return model
end

function Utils.scatterTrees(parent, center, halfExtents, count, clearRadius, canopyColor)
    for _ = 1, count do
        local x = RNG:NextNumber(-halfExtents.X, halfExtents.X)
        local z = RNG:NextNumber(-halfExtents.Z, halfExtents.Z)
        if Vector3.new(x, 0, z).Magnitude > (clearRadius or 0) then
            Utils.tree(
                parent,
                center + Vector3.new(x, 0, z),
                RNG:NextNumber(14, 22),
                Vector3.new(RNG:NextNumber(10, 15), RNG:NextNumber(10, 15), RNG:NextNumber(10, 15)),
                canopyColor
            )
        end
    end
end

function Utils.spawnRegion(parent, name, cframe, size, attributes)
    local region = Utils.part(parent, {
        Name = name,
        Anchored = true,
        Transparency = 1,
        CanCollide = false,
        CanTouch = false,
        Size = size,
        CFrame = cframe,
    })
    for key, value in pairs(attributes) do
        region:SetAttribute(key, value)
    end
    return region
end

function Utils.trainingDummy(parent, cframe)
    local model = Utils.make("Model", parent, { Name = "TrainingDummy" })
    local root = Utils.part(model, {
        Name = "HumanoidRootPart",
        Anchored = true,
        Transparency = 1,
        CanCollide = false,
        Size = Vector3.new(2, 2, 1),
        CFrame = cframe * CFrame.new(0, 3, 0),
    })
    Utils.part(model, {
        Name = "Torso",
        Anchored = true,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(121, 85, 56),
        Size = Vector3.new(2.2, 3.2, 1.25),
        CFrame = cframe * CFrame.new(0, 4.2, 0),
    })
    Utils.part(model, {
        Name = "Head",
        Anchored = true,
        Shape = Enum.PartType.Ball,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(144, 98, 66),
        Size = Vector3.new(1.65, 1.65, 1.65),
        CFrame = cframe * CFrame.new(0, 6.6, 0),
    })
    Utils.part(model, {
        Name = "Pole",
        Anchored = true,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(88, 60, 37),
        Size = Vector3.new(0.5, 6.6, 0.5),
        CFrame = cframe * CFrame.new(0, 3.25, 0),
    })
    model.PrimaryPart = root
    CollectionService:AddTag(model, TrainingConfig.DummyTag)
    return model
end

function Utils.missionBoard(parent, cframe)
    local model = Utils.make("Model", parent, { Name = "MissionBoard" })
    local board = Utils.part(model, {
        Name = "Board",
        Anchored = true,
        Material = Enum.Material.WoodPlanks,
        Color = Color3.fromRGB(92, 57, 45),
        Size = Vector3.new(14, 10, 1.3),
        CFrame = cframe * CFrame.new(0, 6, 0),
    })
    Utils.part(model, {
        Name = "Frame",
        Anchored = true,
        Material = Enum.Material.Wood,
        Color = Color3.fromRGB(67, 42, 33),
        Size = Vector3.new(16, 13, 1.8),
        CFrame = cframe * CFrame.new(0, 6, 0),
    })
    Utils.surfaceText(board, Enum.NormalId.Front, "Mission Board", "Daily / Side (Lv. 5+)", {
        TitleColor3 = PALETTE.PaperGlow,
        SubtitleColor3 = Color3.fromRGB(255, 188, 160),
        BackgroundColor3 = Color3.fromRGB(39, 27, 24),
        BackgroundTransparency = 0.05,
        Brightness = 3.4,
    })
    Utils.make("PointLight", board, {
        Brightness = 2.2,
        Range = 18,
        Color = Color3.fromRGB(255, 184, 147),
        Shadows = true,
    })
    Utils.make("ProximityPrompt", board, {
        ActionText = "Inspect",
        ObjectText = "Mission Board",
        MaxActivationDistance = 14,
        HoldDuration = 0.25,
        KeyboardKeyCode = Enum.KeyCode.E,
    })
    model.PrimaryPart = board
    CollectionService:AddTag(model, GameplayConfig.MissionNpcTag)
    return model
end

return Utils
