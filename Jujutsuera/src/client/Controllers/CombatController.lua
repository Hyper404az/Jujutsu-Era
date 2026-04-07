local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")

local CombatController = {}
CombatController.__index = CombatController

local RED_PALETTE = {
    Color3.fromRGB(255, 70, 78),
    Color3.fromRGB(255, 128, 134),
    Color3.fromRGB(255, 235, 238),
}

local BLUE_PALETTE = {
    Color3.fromRGB(72, 194, 255),
    Color3.fromRGB(156, 225, 255),
    Color3.fromRGB(235, 250, 255),
}

local PURPLE_PALETTE = {
    Color3.fromRGB(121, 78, 255),
    Color3.fromRGB(255, 76, 132),
    Color3.fromRGB(248, 228, 255),
}

function CombatController.new(network)
    local self = setmetatable({}, CombatController)
    self._network = network
    self._player = Players.LocalPlayer
    self._castVisuals = {}
    self:_bind()
    return self
end

function CombatController:_tweenAndCleanup(instance, tweenInfo, goal, lifetime)
    TweenService:Create(instance, tweenInfo, goal):Play()
    if lifetime then
        Debris:AddItem(instance, lifetime)
    end
end

function CombatController:_createEffectPart(options)
    local part = Instance.new("Part")
    part.Name = options.Name or "CombatEffect"
    part.Anchored = options.Anchored ~= false
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.CastShadow = false
    part.Massless = true
    part.Material = options.Material or Enum.Material.Neon
    part.Color = options.Color or Color3.new(1, 1, 1)
    part.Transparency = options.Transparency or 0
    part.Size = options.Size or Vector3.new(1, 1, 1)
    if options.Shape then
        part.Shape = options.Shape
    end
    if options.CFrame then
        part.CFrame = options.CFrame
    elseif options.Position then
        part.Position = options.Position
    end
    part.Parent = options.Parent or workspace
    return part
end

function CombatController:_flashLighting(config)
    if config.Origin then
        local character = self._player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - config.Origin).Magnitude > (config.Radius or 120) then
            return
        end
    end

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Brightness = 0
    color.Contrast = 0
    color.Saturation = 0
    color.TintColor = config.TintColor or Color3.fromRGB(255, 255, 255)
    color.Parent = Lighting

    local inTime = config.InTime or 0.08
    local holdTime = config.HoldTime or 0.08
    local outTime = config.OutTime or 0.18

    self:_tweenAndCleanup(blur, TweenInfo.new(inTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = config.BlurSize or 12,
    })
    self:_tweenAndCleanup(color, TweenInfo.new(inTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Brightness = config.Brightness or 0.05,
        Contrast = config.Contrast or 0.2,
        Saturation = config.Saturation or 0.15,
    })

    task.delay(inTime + holdTime, function()
        self:_tweenAndCleanup(blur, TweenInfo.new(outTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = 0,
        }, outTime + 0.05)
        self:_tweenAndCleanup(color, TweenInfo.new(outTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
        }, outTime + 0.05)
    end)
end

function CombatController:_spawnRadialSpokes(position, palette, count, minLength, maxLength, duration, width)
    for index = 1, count do
        local angle = ((index - 1) / count) * (math.pi * 2)
        local heightOffset = ((index % 2 == 0) and 0.35 or -0.12) + (math.random() - 0.5) * 0.35
        local direction = Vector3.new(math.cos(angle), heightOffset, math.sin(angle)).Unit
        local color = palette[((index - 1) % #palette) + 1]
        local length = minLength + (math.random() * (maxLength - minLength))
        local spoke = self:_createEffectPart({
            Name = "GojoBurstSpoke",
            Shape = Enum.PartType.Block,
            Color = color,
            Size = Vector3.new(width, width, 0.4),
            CFrame = CFrame.lookAt(position, position + direction),
        })

        local goalCenter = position + direction * (length * 0.5)
        self:_tweenAndCleanup(spoke, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            CFrame = CFrame.lookAt(goalCenter, goalCenter + direction),
            Size = Vector3.new(width * 0.35, width * 0.35, length),
            Transparency = 1,
        }, duration + 0.05)
    end
end

function CombatController:_spawnConvergingSpokes(position, palette, count, radius, duration, width, innerRadius)
    local targetRadius = innerRadius or 0.6
    for index = 1, count do
        local angle = ((index - 1) / count) * (math.pi * 2)
        local sourceOffset = Vector3.new(
            math.cos(angle) * radius,
            ((index % 3) - 1) * 1.1,
            math.sin(angle) * radius
        )
        local sourcePosition = position + sourceOffset
        local direction = (position - sourcePosition).Unit
        local color = palette[((index - 1) % #palette) + 1]
        local spoke = self:_createEffectPart({
            Name = "GojoConvergingSpoke",
            Shape = Enum.PartType.Block,
            Color = color,
            Size = Vector3.new(width, width, radius * 0.7),
            CFrame = CFrame.lookAt(sourcePosition, position) * CFrame.new(0, 0, -(radius * 0.35)),
        })

        local goalPosition = position - (direction * targetRadius * 0.5)
        self:_tweenAndCleanup(spoke, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
            CFrame = CFrame.lookAt(goalPosition, position),
            Size = Vector3.new(width * 0.35, width * 0.35, targetRadius),
            Transparency = 1,
        }, duration + 0.05)
    end
end

function CombatController:_spawnGroundPulse(position, color, startRadius, endRadius, duration, opacity)
    local pulse = self:_createEffectPart({
        Name = "GojoGroundPulse",
        Shape = Enum.PartType.Cylinder,
        Color = color,
        Transparency = opacity or 0.15,
        Size = Vector3.new(0.18, startRadius, startRadius),
        CFrame = CFrame.new(position + Vector3.new(0, -2.75, 0)) * CFrame.Angles(0, 0, math.rad(90)),
    })

    self:_tweenAndCleanup(pulse, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, endRadius, endRadius),
        Transparency = 1,
    }, duration + 0.05)
end

function CombatController:_clearCastVisual(userId)
    local castState = self._castVisuals[userId]
    if not castState then
        return
    end

    if castState.Humanoid and castState.Humanoid.Parent then
        castState.Humanoid.AutoRotate = castState.AutoRotate
    end

    for _, part in ipairs(castState.Parts or {}) do
        if part and part.Parent then
            part:Destroy()
        end
    end

    self._castVisuals[userId] = nil
end

function CombatController:_findMotor(character, names)
    for _, name in ipairs(names) do
        local motor = character:FindFirstChild(name, true)
        if motor and motor:IsA("Motor6D") then
            return motor
        end
    end

    return nil
end

function CombatController:_playGojoPose(character, variant, duration)
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then
        return
    end

    local rightShoulder = self:_findMotor(character, { "Right Shoulder", "RightShoulder" })
    local leftShoulder = self:_findMotor(character, { "Left Shoulder", "LeftShoulder" })
    local neck = self:_findMotor(character, { "Neck" })

    local motors = {}
    for _, motor in ipairs({ rightShoulder, leftShoulder, neck }) do
        if motor then
            motors[motor] = motor.C0
        end
    end

    local goals = {}
    if variant == "Red" then
        if rightShoulder then
            goals[rightShoulder] = rightShoulder.C0 * CFrame.Angles(math.rad(-82), math.rad(14), math.rad(30))
        end
        if leftShoulder then
            goals[leftShoulder] = leftShoulder.C0 * CFrame.Angles(math.rad(8), math.rad(-6), math.rad(-18))
        end
        if neck then
            goals[neck] = neck.C0 * CFrame.Angles(math.rad(10), math.rad(-14), 0)
        end
    elseif variant == "Blue" then
        if rightShoulder then
            goals[rightShoulder] = rightShoulder.C0 * CFrame.Angles(math.rad(-56), math.rad(-22), math.rad(18))
        end
        if leftShoulder then
            goals[leftShoulder] = leftShoulder.C0 * CFrame.Angles(math.rad(-40), math.rad(22), math.rad(-28))
        end
        if neck then
            goals[neck] = neck.C0 * CFrame.Angles(math.rad(6), math.rad(16), 0)
        end
    elseif variant == "Purple" then
        if rightShoulder then
            goals[rightShoulder] = rightShoulder.C0 * CFrame.Angles(math.rad(-94), math.rad(8), math.rad(26))
        end
        if leftShoulder then
            goals[leftShoulder] = leftShoulder.C0 * CFrame.Angles(math.rad(-94), math.rad(-8), math.rad(-26))
        end
        if neck then
            goals[neck] = neck.C0 * CFrame.Angles(math.rad(12), 0, 0)
        end
    end

    for motor, goal in pairs(goals) do
        TweenService:Create(motor, TweenInfo.new(math.min(0.12, duration * 0.45), Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
            C0 = goal,
        }):Play()
    end

    task.delay(duration, function()
        for motor, original in pairs(motors) do
            if motor.Parent then
                TweenService:Create(motor, TweenInfo.new(0.15, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
                    C0 = original,
                }):Play()
            end
        end
    end)
end

function CombatController:_emitChargeFragments(originPart, palette, count, duration, spread)
    for index = 1, count do
        local fragment = Instance.new("Part")
        fragment.Name = "GojoChargeFragment"
        fragment.Shape = Enum.PartType.Ball
        fragment.Anchored = true
        fragment.CanCollide = false
        fragment.CanQuery = false
        fragment.CanTouch = false
        fragment.Material = Enum.Material.Neon
        fragment.Color = palette[((index - 1) % #palette) + 1]
        fragment.Size = Vector3.new(0.2, 0.2, 0.2)
        fragment.CFrame = originPart.CFrame
        fragment.Parent = workspace

        local angle = (math.pi * 2 / count) * index
        local offset = Vector3.new(math.cos(angle) * spread, math.sin(angle * 1.4) * (spread * 0.45), math.sin(angle) * spread)
        local goalPosition = originPart.Position + originPart.CFrame:VectorToWorldSpace(offset)

        TweenService:Create(fragment, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = goalPosition,
            Size = Vector3.new(0.75, 0.75, 0.75),
            Transparency = 1,
        }):Play()

        Debris:AddItem(fragment, duration + 0.05)
    end
end

function CombatController:_pulseCamera(origin, amplitude, duration, radius)
    local camera = workspace.CurrentCamera
    local character = self._player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not camera or not root then
        return
    end

    local distance = (root.Position - origin).Magnitude
    local maxRadius = radius or 120
    if distance > maxRadius then
        return
    end

    local strength = (1 - math.clamp(distance / maxRadius, 0, 1)) * amplitude
    if strength <= 0 then
        return
    end

    local startedAt = os.clock()
    local connection
    local lastOffset = Vector3.zero
    connection = RunService.RenderStepped:Connect(function()
        local elapsed = os.clock() - startedAt
        if elapsed >= duration then
            camera.CFrame = camera.CFrame * CFrame.new(-lastOffset)
            connection:Disconnect()
            return
        end

        camera.CFrame = camera.CFrame * CFrame.new(-lastOffset)

        local fade = 1 - (elapsed / duration)
        lastOffset = Vector3.new(
            (math.random() - 0.5) * strength * fade,
            (math.random() - 0.5) * strength * fade,
            0
        )
        camera.CFrame = camera.CFrame * CFrame.new(lastOffset)
    end)
end

function CombatController:_applyPurpleVacuum(payload, origin)
    local character = self._player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root then
        return
    end

    local distance = (root.Position - origin).Magnitude
    if distance > 140 then
        return
    end

    local blur = Instance.new("BlurEffect")
    blur.Size = 0
    blur.Parent = Lighting

    local color = Instance.new("ColorCorrectionEffect")
    color.Brightness = 0
    color.Contrast = 0
    color.Saturation = 0
    color.TintColor = Color3.fromRGB(210, 188, 255)
    color.Parent = Lighting

    local inTime = math.max(0.08, (payload.Duration or 0.6) * 0.55)
    self:_tweenAndCleanup(blur, TweenInfo.new(inTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = 18,
    })
    self:_tweenAndCleanup(color, TweenInfo.new(inTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Brightness = -0.08,
        Contrast = 0.2,
        Saturation = -0.35,
    })

    task.delay(payload.Duration or 0.6, function()
        self:_tweenAndCleanup(blur, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = 0,
        }, 0.2)
        self:_tweenAndCleanup(color, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Brightness = 0,
            Contrast = 0,
            Saturation = 0,
        }, 0.2)
    end)
end

function CombatController:_spawnRedCharge(payload)
    local caster = Players:GetPlayerByUserId(payload.CasterUserId)
    local character = caster and caster.Character
    local rightHand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not rightHand or not root then
        return
    end

    self:_clearCastVisual(payload.CasterUserId)

    local duration = payload.Duration or 0.4
    local charge = self:_createEffectPart({
        Name = "GojoRedCharge",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = RED_PALETTE[1],
        Size = Vector3.new(0.8, 0.8, 0.8),
    })

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rightHand
    weld.Part1 = charge
    weld.Parent = charge
    charge.CFrame = rightHand.CFrame * CFrame.new(0, -0.15, -0.95)

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(255, 134, 142)
    light.Range = 18
    light.Brightness = 4.5
    light.Parent = charge

    local shell = self:_createEffectPart({
        Name = "GojoRedShell",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = RED_PALETTE[2],
        Transparency = 0.3,
        Size = Vector3.new(1.4, 1.4, 1.4),
    })
    local shellWeld = Instance.new("WeldConstraint")
    shellWeld.Part0 = charge
    shellWeld.Part1 = shell
    shellWeld.Parent = shell
    shell.CFrame = charge.CFrame

    local ring = self:_createEffectPart({
        Name = "GojoRedChargeRing",
        Shape = Enum.PartType.Cylinder,
        Anchored = false,
        Color = RED_PALETTE[3],
        Transparency = 0.18,
        Size = Vector3.new(0.14, 2.4, 2.4),
    })
    local ringWeld = Instance.new("WeldConstraint")
    ringWeld.Part0 = charge
    ringWeld.Part1 = ring
    ringWeld.Parent = ring
    ring.CFrame = charge.CFrame * CFrame.Angles(0, 0, math.rad(90))

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local previousAutoRotate = humanoid and humanoid.AutoRotate
    if humanoid then
        humanoid.AutoRotate = false
    end

    local burstOrigin = root.Position + root.CFrame.LookVector * 2.5 + Vector3.new(0, 1.45, 0)

    self:_playGojoPose(character, "Red", duration)
    self:_emitChargeFragments(charge, RED_PALETTE, 10, duration, 2.1)
    self:_spawnRadialSpokes(burstOrigin, RED_PALETTE, 12, 4.5, 10, duration, 0.42)
    self:_spawnGroundPulse(root.Position, RED_PALETTE[2], 5, 18, duration, 0.22)
    self:_flashLighting({
        Origin = root.Position,
        Radius = 110,
        TintColor = Color3.fromRGB(255, 186, 190),
        BlurSize = 10,
        Brightness = 0.08,
        Contrast = 0.18,
        Saturation = 0.12,
        InTime = 0.06,
        HoldTime = duration * 0.35,
        OutTime = 0.16,
    })

    TweenService:Create(charge, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(1.45, 1.45, 1.45),
    }):Play()

    TweenService:Create(shell, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(2.65, 2.65, 2.65),
        Transparency = 1,
    }):Play()
    TweenService:Create(ring, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 8.5, 8.5),
        Transparency = 1,
    }):Play()
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 24,
    }):Play()

    self._castVisuals[payload.CasterUserId] = {
        Humanoid = humanoid,
        AutoRotate = previousAutoRotate,
        Parts = { charge, shell, ring },
    }

    task.delay(duration, function()
        self:_clearCastVisual(payload.CasterUserId)
    end)
end

function CombatController:_spawnBlueCharge(payload)
    local caster = Players:GetPlayerByUserId(payload.CasterUserId)
    local character = caster and caster.Character
    local rightHand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not rightHand or not root then
        return
    end

    self:_clearCastVisual(payload.CasterUserId)

    local duration = payload.Duration or 0.42
    local charge = self:_createEffectPart({
        Name = "GojoBlueCharge",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = BLUE_PALETTE[1],
        Size = Vector3.new(0.72, 0.72, 0.72),
    })

    local weld = Instance.new("WeldConstraint")
    weld.Part0 = rightHand
    weld.Part1 = charge
    weld.Parent = charge
    charge.CFrame = rightHand.CFrame * CFrame.new(0, -0.05, -0.95)

    local light = Instance.new("PointLight")
    light.Color = BLUE_PALETTE[3]
    light.Range = 22
    light.Brightness = 4.25
    light.Parent = charge

    local shell = self:_createEffectPart({
        Name = "GojoBlueShell",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = BLUE_PALETTE[2],
        Transparency = 0.38,
        Size = Vector3.new(1.7, 1.7, 1.7),
    })
    local shellWeld = Instance.new("WeldConstraint")
    shellWeld.Part0 = charge
    shellWeld.Part1 = shell
    shellWeld.Parent = shell
    shell.CFrame = charge.CFrame

    local innerRing = self:_createEffectPart({
        Name = "GojoBlueChargeRingA",
        Shape = Enum.PartType.Cylinder,
        Anchored = false,
        Color = BLUE_PALETTE[3],
        Transparency = 0.15,
        Size = Vector3.new(0.12, 2.8, 2.8),
    })
    local innerRingWeld = Instance.new("WeldConstraint")
    innerRingWeld.Part0 = charge
    innerRingWeld.Part1 = innerRing
    innerRingWeld.Parent = innerRing
    innerRing.CFrame = charge.CFrame * CFrame.Angles(0, 0, math.rad(90))

    local outerRing = self:_createEffectPart({
        Name = "GojoBlueChargeRingB",
        Shape = Enum.PartType.Cylinder,
        Anchored = false,
        Color = BLUE_PALETTE[2],
        Transparency = 0.28,
        Size = Vector3.new(0.12, 4.2, 4.2),
    })
    local outerRingWeld = Instance.new("WeldConstraint")
    outerRingWeld.Part0 = charge
    outerRingWeld.Part1 = outerRing
    outerRingWeld.Parent = outerRing
    outerRing.CFrame = charge.CFrame * CFrame.Angles(math.rad(90), 0, 0)

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local previousAutoRotate = humanoid and humanoid.AutoRotate
    if humanoid then
        humanoid.AutoRotate = false
    end

    local chargeOrigin = root.Position + root.CFrame.LookVector * 2.2 + Vector3.new(0, 1.4, 0)

    self:_playGojoPose(character, "Blue", duration)
    self:_emitChargeFragments(charge, BLUE_PALETTE, 12, duration, 2.05)
    self:_spawnConvergingSpokes(chargeOrigin, BLUE_PALETTE, 12, 6.5, duration, 0.28, 0.75)
    self:_spawnGroundPulse(root.Position, BLUE_PALETTE[2], 20, 6, duration, 0.28)
    self:_flashLighting({
        Origin = root.Position,
        Radius = 120,
        TintColor = Color3.fromRGB(164, 230, 255),
        BlurSize = 12,
        Brightness = -0.03,
        Contrast = 0.18,
        Saturation = -0.1,
        InTime = 0.08,
        HoldTime = duration * 0.55,
        OutTime = 0.18,
    })

    TweenService:Create(charge, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(1.55, 1.55, 1.55),
    }):Play()

    TweenService:Create(shell, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(2.8, 2.8, 2.8),
        Transparency = 1,
    }):Play()
    TweenService:Create(innerRing, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 1.1, 1.1),
        Transparency = 1,
    }):Play()
    TweenService:Create(outerRing, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 8.6, 8.6),
        Transparency = 1,
    }):Play()
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 26,
    }):Play()

    self._castVisuals[payload.CasterUserId] = {
        Humanoid = humanoid,
        AutoRotate = previousAutoRotate,
        Parts = { charge, shell, innerRing, outerRing },
    }

    task.delay(duration, function()
        self:_clearCastVisual(payload.CasterUserId)
    end)
end

function CombatController:_spawnPurpleCharge(payload)
    local caster = Players:GetPlayerByUserId(payload.CasterUserId)
    local character = caster and caster.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local rightHand = character and (character:FindFirstChild("RightHand") or character:FindFirstChild("Right Arm"))
    local leftHand = character and (character:FindFirstChild("LeftHand") or character:FindFirstChild("Left Arm"))
    if not root or not rightHand or not leftHand then
        return
    end

    self:_clearCastVisual(payload.CasterUserId)

    local duration = payload.Duration or 1
    local corePosition = root.Position + root.CFrame.LookVector * 2.8 + Vector3.new(0, 1.8, 0)

    local blueHand = self:_createEffectPart({
        Name = "GojoPurpleBlueHand",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = BLUE_PALETTE[1],
        Size = Vector3.new(0.9, 0.9, 0.9),
    })
    local blueWeld = Instance.new("WeldConstraint")
    blueWeld.Part0 = leftHand
    blueWeld.Part1 = blueHand
    blueWeld.Parent = blueHand
    blueHand.CFrame = leftHand.CFrame * CFrame.new(0, -0.05, -0.75)

    local redHand = self:_createEffectPart({
        Name = "GojoPurpleRedHand",
        Shape = Enum.PartType.Ball,
        Anchored = false,
        Color = RED_PALETTE[1],
        Size = Vector3.new(0.9, 0.9, 0.9),
    })
    local redWeld = Instance.new("WeldConstraint")
    redWeld.Part0 = rightHand
    redWeld.Part1 = redHand
    redWeld.Parent = redHand
    redHand.CFrame = rightHand.CFrame * CFrame.new(0, -0.05, -0.75)

    local core = self:_createEffectPart({
        Name = "GojoPurpleCharge",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(225, 110, 255),
        Transparency = 0.08,
        Size = Vector3.new(1.9, 1.9, 1.9),
        Position = corePosition,
    })

    local light = Instance.new("PointLight")
    light.Color = Color3.fromRGB(220, 160, 255)
    light.Range = 40
    light.Brightness = 6
    light.Parent = core

    local voidShell = self:_createEffectPart({
        Name = "GojoPurpleVoid",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(24, 16, 34),
        Transparency = 0.24,
        Size = Vector3.new(2.4, 2.4, 2.4),
        Position = corePosition,
    })

    local ringA = self:_createEffectPart({
        Name = "GojoPurpleRingA",
        Shape = Enum.PartType.Cylinder,
        Color = Color3.fromRGB(234, 197, 255),
        Transparency = 0.22,
        Size = Vector3.new(0.18, 5.2, 5.2),
        CFrame = core.CFrame * CFrame.Angles(0, 0, math.rad(90)),
    })

    local ringB = self:_createEffectPart({
        Name = "GojoPurpleRingB",
        Shape = Enum.PartType.Cylinder,
        Color = Color3.fromRGB(255, 132, 183),
        Transparency = 0.28,
        Size = Vector3.new(0.18, 6.4, 6.4),
        CFrame = core.CFrame * CFrame.Angles(math.rad(90), 0, 0),
    })

    local portal = self:_createEffectPart({
        Name = "GojoPurplePortal",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(183, 86, 255),
        Transparency = 0.3,
        Size = Vector3.new(6, 9, 2.8),
        CFrame = CFrame.lookAt(
            root.Position - root.CFrame.LookVector * 4 + Vector3.new(0, 3.4, 0),
            root.Position + Vector3.new(0, 3.4, 0)
        ),
    })

    local portalCore = self:_createEffectPart({
        Name = "GojoPurplePortalCore",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(255, 121, 205),
        Transparency = 0.48,
        Size = Vector3.new(4.2, 7.2, 1.4),
        CFrame = portal.CFrame,
    })

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local previousAutoRotate = humanoid and humanoid.AutoRotate
    if humanoid then
        humanoid.AutoRotate = false
    end

    self:_playGojoPose(character, "Purple", duration)
    self:_emitChargeFragments(core, PURPLE_PALETTE, 16, duration, 4.4)
    self:_spawnConvergingSpokes(corePosition, PURPLE_PALETTE, 18, 9.5, duration, 0.35, 0.8)
    self:_spawnGroundPulse(root.Position, Color3.fromRGB(244, 175, 255), 28, 8, duration, 0.32)
    self:_flashLighting({
        Origin = corePosition,
        Radius = 160,
        TintColor = Color3.fromRGB(225, 166, 255),
        BlurSize = 20,
        Brightness = -0.08,
        Contrast = 0.28,
        Saturation = -0.18,
        InTime = 0.12,
        HoldTime = duration * 0.52,
        OutTime = 0.22,
    })

    self:_applyPurpleVacuum(payload, core.Position)
    self:_pulseCamera(core.Position, 0.26, duration, 160)

    self:_tweenAndCleanup(core, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(4.8, 4.8, 4.8),
        Transparency = 0.22,
    }, duration + 0.05)
    self:_tweenAndCleanup(voidShell, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(2.2, 2.2, 2.2),
        Transparency = 0.68,
    }, duration + 0.05)
    self:_tweenAndCleanup(ringA, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 10.5, 10.5),
        Transparency = 1,
        CFrame = ringA.CFrame * CFrame.Angles(0, 0, math.rad(160)),
    }, duration + 0.05)
    self:_tweenAndCleanup(ringB, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 12.8, 12.8),
        Transparency = 1,
        CFrame = ringB.CFrame * CFrame.Angles(math.rad(160), 0, 0),
    }, duration + 0.05)
    self:_tweenAndCleanup(portal, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(13, 17, 4.2),
        Transparency = 0.75,
    }, duration + 0.08)
    self:_tweenAndCleanup(portalCore, TweenInfo.new(duration, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(9.8, 13.8, 2.2),
        Transparency = 1,
    }, duration + 0.08)
    self:_tweenAndCleanup(blueHand, TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(1.9, 1.9, 1.9),
        Transparency = 1,
    }, duration * 0.75 + 0.05)
    self:_tweenAndCleanup(redHand, TweenInfo.new(duration * 0.7, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(1.9, 1.9, 1.9),
        Transparency = 1,
    }, duration * 0.75 + 0.05)
    TweenService:Create(light, TweenInfo.new(duration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
        Brightness = 0,
        Range = 60,
    }):Play()

    self._castVisuals[payload.CasterUserId] = {
        Humanoid = humanoid,
        AutoRotate = previousAutoRotate,
        Parts = { blueHand, redHand, core, voidShell, ringA, ringB, portal, portalCore },
    }

    task.delay(duration, function()
        self:_clearCastVisual(payload.CasterUserId)
    end)
end

function CombatController:_spawnImpact(position, payload)
    if payload.AbilityName == "Red" or payload.Effect == "RepulseBurst" then
        self:_spawnRedImpact(position, payload)
        return
    elseif payload.AbilityName == "Blue" or payload.Effect == "AttractionBurst" then
        self:_spawnBlueImpact(position, payload)
        return
    elseif payload.AbilityName == "Hollow Purple" or payload.Effect == "EraseBeam" then
        self:_spawnPurpleImpact(position, payload)
        return
    end

    local part = Instance.new("Part")
    part.Name = "CombatFeedback"
    part.Shape = Enum.PartType.Ball
    part.Anchored = true
    part.CanCollide = false
    part.CanQuery = false
    part.CanTouch = false
    part.Material = Enum.Material.Neon
    part.Size = Vector3.new(1.2, 1.2, 1.2)
    part.Position = position
    part.Color = payload.Type == "Domain" and Color3.fromRGB(120, 86, 255)
        or payload.Type == "Special" and Color3.fromRGB(255, 193, 73)
        or payload.Type == "Physical" and Color3.fromRGB(255, 84, 84)
        or Color3.fromRGB(78, 158, 255)
    part.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 110, 0, 44)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = part

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("-%d", payload.Damage or 0)
    label.TextColor3 = Color3.fromRGB(255, 247, 242)
    label.TextStrokeTransparency = 0.35
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = billboard

    TweenService:Create(part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(4.5, 4.5, 4.5),
        Transparency = 1,
    }):Play()

    TweenService:Create(billboard, TweenInfo.new(0.45, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        StudsOffset = Vector3.new(0, 5.5, 0),
    }):Play()

    Debris:AddItem(part, 0.5)
end

function CombatController:_spawnPurpleImpact(position, payload)
    local sourcePosition = typeof(payload.SourcePosition) == "Vector3" and payload.SourcePosition or position
    local beamLength = (position - sourcePosition).Magnitude
    local midpoint = sourcePosition:Lerp(position, 0.5)

    local beam = self:_createEffectPart({
        Name = "GojoPurpleBeam",
        Color = Color3.fromRGB(214, 110, 255),
        Transparency = 0.04,
        Size = Vector3.new(11.5, 11.5, beamLength),
        CFrame = CFrame.lookAt(sourcePosition, position) * CFrame.new(0, 0, -beamLength * 0.5),
    })

    local core = self:_createEffectPart({
        Name = "GojoPurpleCore",
        Color = Color3.fromRGB(255, 245, 255),
        Transparency = 0.02,
        Size = Vector3.new(4.2, 4.2, beamLength),
        CFrame = beam.CFrame,
    })

    local voidCore = self:_createEffectPart({
        Name = "GojoPurpleVoidCore",
        Color = Color3.fromRGB(18, 12, 30),
        Transparency = 0.16,
        Size = Vector3.new(2.6, 2.6, beamLength),
        CFrame = beam.CFrame,
    })

    local slashA = self:_createEffectPart({
        Name = "GojoPurpleSlashA",
        Color = Color3.fromRGB(255, 176, 240),
        Transparency = 0.12,
        Size = Vector3.new(0.6, 16, beamLength * 0.95),
        CFrame = beam.CFrame * CFrame.Angles(0, 0, math.rad(42)),
    })
    local slashB = self:_createEffectPart({
        Name = "GojoPurpleSlashB",
        Color = Color3.fromRGB(178, 120, 255),
        Transparency = 0.18,
        Size = Vector3.new(0.6, 16, beamLength * 0.95),
        CFrame = beam.CFrame * CFrame.Angles(0, 0, math.rad(-42)),
    })

    local eraseRing = self:_createEffectPart({
        Name = "GojoPurpleEraseRing",
        Shape = Enum.PartType.Cylinder,
        Color = Color3.fromRGB(255, 225, 246),
        Transparency = 0.08,
        Size = Vector3.new(0.28, 14, 14),
        CFrame = CFrame.lookAt(midpoint, position) * CFrame.Angles(0, 0, math.rad(90)),
    })

    local endVoid = self:_createEffectPart({
        Name = "GojoPurpleEndVoid",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(20, 16, 34),
        Transparency = 0.05,
        Size = Vector3.new(4.8, 4.8, 4.8),
        Position = position,
    })
    local endCorona = self:_createEffectPart({
        Name = "GojoPurpleEndCorona",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(213, 168, 255),
        Transparency = 0.3,
        Size = Vector3.new(8.5, 8.5, 8.5),
        Position = position,
    })

    self:_flashLighting({
        Origin = midpoint,
        Radius = 170,
        TintColor = Color3.fromRGB(245, 214, 255),
        BlurSize = 18,
        Brightness = 0.12,
        Contrast = 0.35,
        Saturation = 0.08,
        InTime = 0.05,
        HoldTime = 0.04,
        OutTime = 0.16,
    })
    self:_spawnGroundPulse(position, Color3.fromRGB(232, 186, 255), 10, 32, 0.26, 0.18)
    self:_pulseCamera(midpoint, 0.62, 0.24, 170)

    TweenService:Create(beam, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(19, 19, beamLength),
    }):Play()
    TweenService:Create(core, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.7, 0.7, beamLength),
    }):Play()
    TweenService:Create(voidCore, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.3, 0.3, beamLength),
    }):Play()
    TweenService:Create(slashA, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.2, 28, beamLength),
    }):Play()
    TweenService:Create(slashB, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.2, 28, beamLength),
    }):Play()
    TweenService:Create(eraseRing, TweenInfo.new(0.22, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(0.08, 26, 26),
    }):Play()
    TweenService:Create(endVoid, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(15, 15, 15),
    }):Play()
    TweenService:Create(endCorona, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Transparency = 1,
        Size = Vector3.new(24, 24, 24),
    }):Play()

    Debris:AddItem(beam, 0.25)
    Debris:AddItem(core, 0.25)
    Debris:AddItem(voidCore, 0.25)
    Debris:AddItem(slashA, 0.25)
    Debris:AddItem(slashB, 0.25)
    Debris:AddItem(eraseRing, 0.25)
    Debris:AddItem(endVoid, 0.28)
    Debris:AddItem(endCorona, 0.28)
end

function CombatController:_spawnBlueImpact(position, payload)
    local sourcePosition = typeof(payload.SourcePosition) == "Vector3" and payload.SourcePosition or position

    local core = self:_createEffectPart({
        Name = "GojoBlueCore",
        Shape = Enum.PartType.Ball,
        Color = BLUE_PALETTE[1],
        Size = Vector3.new(2.2, 2.2, 2.2),
        Position = position,
    })

    local light = Instance.new("PointLight")
    light.Color = BLUE_PALETTE[3]
    light.Range = 22
    light.Brightness = 4.2
    light.Parent = core

    local darkShell = self:_createEffectPart({
        Name = "GojoBlueDarkShell",
        Shape = Enum.PartType.Ball,
        Color = Color3.fromRGB(15, 32, 68),
        Transparency = 0.18,
        Size = Vector3.new(5.5, 5.5, 5.5),
        Position = position,
    })

    local outerShell = self:_createEffectPart({
        Name = "GojoBlueOuterShell",
        Shape = Enum.PartType.Ball,
        Color = BLUE_PALETTE[2],
        Transparency = 0.35,
        Size = Vector3.new(8.5, 8.5, 8.5),
        Position = position,
    })

    local pullRing = self:_createEffectPart({
        Name = "GojoBlueRing",
        Shape = Enum.PartType.Cylinder,
        Color = BLUE_PALETTE[3],
        Transparency = 0.15,
        Size = Vector3.new(0.16, 22, 22),
        CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
    })

    local beam = self:_createEffectPart({
        Name = "GojoBlueBeam",
        Color = BLUE_PALETTE[2],
        Size = Vector3.new(0.55, 0.55, (sourcePosition - position).Magnitude),
        CFrame = CFrame.lookAt(sourcePosition, position) * CFrame.new(0, 0, -((sourcePosition - position).Magnitude * 0.5)),
    })

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 118, 0, 44)
    billboard.StudsOffset = Vector3.new(0, 3, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = core

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("-%d", payload.Damage or 0)
    label.TextColor3 = Color3.fromRGB(243, 251, 255)
    label.TextStrokeTransparency = 0.28
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = billboard

    self:_spawnConvergingSpokes(position, BLUE_PALETTE, 16, 11, 0.28, 0.32, 0.75)
    self:_spawnGroundPulse(position, BLUE_PALETTE[2], 24, 4, 0.28, 0.22)
    self:_flashLighting({
        Origin = position,
        Radius = 140,
        TintColor = Color3.fromRGB(190, 239, 255),
        BlurSize = 12,
        Brightness = -0.02,
        Contrast = 0.16,
        Saturation = -0.06,
        InTime = 0.05,
        HoldTime = 0.05,
        OutTime = 0.16,
    })
    self:_pulseCamera(position, 0.32, 0.18, 140)

    TweenService:Create(core, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.5, 0.5, 0.5),
        Transparency = 1,
    }):Play()
    TweenService:Create(darkShell, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(1.6, 1.6, 1.6),
        Transparency = 1,
    }):Play()
    TweenService:Create(outerShell, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(2.5, 2.5, 2.5),
        Transparency = 1,
    }):Play()

    TweenService:Create(pullRing, TweenInfo.new(0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 2.8, 2.8),
        Transparency = 1,
    }):Play()

    TweenService:Create(beam, TweenInfo.new(0.16, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
        Transparency = 1,
    }):Play()

    TweenService:Create(billboard, TweenInfo.new(0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        StudsOffset = Vector3.new(0, 4.6, 0),
    }):Play()

    Debris:AddItem(core, 0.35)
    Debris:AddItem(darkShell, 0.35)
    Debris:AddItem(outerShell, 0.35)
    Debris:AddItem(pullRing, 0.3)
    Debris:AddItem(beam, 0.2)
end

function CombatController:_spawnRedImpact(position, payload)
    local sourcePosition = typeof(payload.SourcePosition) == "Vector3" and payload.SourcePosition or position

    local core = self:_createEffectPart({
        Name = "GojoRedCore",
        Shape = Enum.PartType.Ball,
        Color = RED_PALETTE[1],
        Size = Vector3.new(1.8, 1.8, 1.8),
        Position = sourcePosition,
    })

    local coreLight = Instance.new("PointLight")
    coreLight.Color = RED_PALETTE[2]
    coreLight.Range = 20
    coreLight.Brightness = 4
    coreLight.Parent = core

    local ring = self:_createEffectPart({
        Name = "GojoRedRing",
        Shape = Enum.PartType.Cylinder,
        Color = RED_PALETTE[3],
        Transparency = 0.08,
        Size = Vector3.new(0.2, 2.6, 2.6),
        CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
    })

    local impact = self:_createEffectPart({
        Name = "GojoRedImpact",
        Shape = Enum.PartType.Ball,
        Color = RED_PALETTE[3],
        Transparency = 0.05,
        Size = Vector3.new(2.8, 2.8, 2.8),
        Position = position,
    })

    local outerImpact = self:_createEffectPart({
        Name = "GojoRedOuterImpact",
        Shape = Enum.PartType.Ball,
        Color = RED_PALETTE[2],
        Transparency = 0.28,
        Size = Vector3.new(6, 6, 6),
        Position = position,
    })

    local billboard = Instance.new("BillboardGui")
    billboard.Size = UDim2.new(0, 130, 0, 48)
    billboard.StudsOffset = Vector3.new(0, 3.5, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = impact

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = string.format("-%d", payload.Damage or 0)
    label.TextColor3 = Color3.fromRGB(255, 241, 242)
    label.TextStrokeTransparency = 0.2
    label.Font = Enum.Font.GothamBlack
    label.TextScaled = true
    label.Parent = billboard

    self:_spawnRadialSpokes(position, RED_PALETTE, 14, 6, 16, 0.26, 0.55)
    self:_spawnGroundPulse(position, RED_PALETTE[2], 4, 30, 0.26, 0.14)
    self:_flashLighting({
        Origin = position,
        Radius = 135,
        TintColor = Color3.fromRGB(255, 204, 208),
        BlurSize = 11,
        Brightness = 0.06,
        Contrast = 0.14,
        Saturation = 0.08,
        InTime = 0.04,
        HoldTime = 0.04,
        OutTime = 0.14,
    })
    self:_pulseCamera(position, 0.36, 0.16, 135)

    TweenService:Create(core, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = position,
        Size = Vector3.new(2.8, 2.8, 2.8),
        Transparency = 0.4,
    }):Play()

    TweenService:Create(impact, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(18, 18, 18),
        Transparency = 1,
    }):Play()
    TweenService:Create(outerImpact, TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(26, 26, 26),
        Transparency = 1,
    }):Play()

    TweenService:Create(ring, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
        Size = Vector3.new(0.08, 28, 28),
        Transparency = 1,
    }):Play()

    TweenService:Create(billboard, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        StudsOffset = Vector3.new(0, 5.8, 0),
    }):Play()

    Debris:AddItem(core, 0.35)
    Debris:AddItem(ring, 0.3)
    Debris:AddItem(impact, 0.4)
    Debris:AddItem(outerImpact, 0.4)
end

function CombatController:_bind()
    self._network:GetEvent("AbilityCast").OnClientEvent:Connect(function(payload)
        if not payload then
            return
        end

        if payload.AbilityName == "Red" or payload.Effect == "RepulseBurst" then
            self:_spawnRedCharge(payload)
        elseif payload.AbilityName == "Blue" or payload.Effect == "AttractionBurst" then
            self:_spawnBlueCharge(payload)
        elseif payload.AbilityName == "Hollow Purple" or payload.Effect == "EraseBeam" then
            self:_spawnPurpleCharge(payload)
        end
    end)

    self._network:GetEvent("CombatFeedback").OnClientEvent:Connect(function(payload)
        if payload and typeof(payload.Position) == "Vector3" then
            self:_spawnImpact(payload.Position, payload)
        end
    end)
end

return CombatController
