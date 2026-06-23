-- MM2 Script | Rayfield GUI | Delta Executor
-- Телепорт к пистолету + Невидимость + Aimbot + ESP

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ===================== RAYFIELD =====================
local OK, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not OK then warn("Rayfield error: " .. tostring(Rayfield)) return end

-- ===================== НАСТРОЙКИ ===================
local S = {
    ESP_Enabled    = true,
    Show_Murderer  = true,
    Show_Sheriff   = true,
    Show_Innocent  = true,

    Murderer_Color = Color3.fromRGB(255, 60,  60),
    Sheriff_Color  = Color3.fromRGB(60,  150, 255),
    Innocent_Color = Color3.fromRGB(80,  255, 120),

    Aimbot_Enabled = true,
    FOV            = 220,
    Smoothness     = 0.20,
    Target_Part    = "Head",
    WallCheck      = true,
    TeamCheck      = true,

    AutoShoot      = true,
    FOV_Visible    = true,
    FOV_Color      = Color3.fromRGB(255, 255, 255),
    AimBtn_Visible = true,
}

-- ===================== СОСТОЯНИЕ ===================
local ESPObjects    = {}
local ForcedRoles   = {}
local MyRole        = "Innocent"
local SavedPosition = nil   -- для телепорта обратно
local IsInvisible   = false
local VisibleParts  = {}
local InvisConns    = {}

local Roles = {
    Murderer = "Murderer",
    Sheriff  = "Sheriff",
    Innocent = "Innocent",
}

-- ===================== RAYFIELD ОКНО ===============
local Window = Rayfield:CreateWindow({
    Name                   = "MM2 Script",
    LoadingTitle           = "MM2 Script",
    LoadingSubtitle        = "by Delta Executor",
    Theme                  = "Default",
    DisableRayfieldPrompts = true,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

local TabESP   = Window:CreateTab("ESP",       "eye")
local TabAim   = Window:CreateTab("Aimbot",    "crosshair")
local TabUtils = Window:CreateTab("Утилиты",   "star")
local TabInfo  = Window:CreateTab("Инфо",      "info")

-- ── ESP ──────────────────────────────────────────
TabESP:CreateToggle({ Name="ESP Включён",     CurrentValue=S.ESP_Enabled,   Flag="esp_on",   Callback=function(v) S.ESP_Enabled=v    end })
TabESP:CreateToggle({ Name="Murderer ESP",    CurrentValue=S.Show_Murderer, Flag="esp_murd", Callback=function(v) S.Show_Murderer=v  end })
TabESP:CreateToggle({ Name="Sheriff ESP",     CurrentValue=S.Show_Sheriff,  Flag="esp_sher", Callback=function(v) S.Show_Sheriff=v   end })
TabESP:CreateToggle({ Name="Innocent ESP",    CurrentValue=S.Show_Innocent, Flag="esp_inno", Callback=function(v) S.Show_Innocent=v  end })

-- ── Aimbot ────────────────────────────────────────
TabAim:CreateToggle({ Name="Aimbot Включён",  CurrentValue=S.Aimbot_Enabled,Flag="aim_on",    Callback=function(v) S.Aimbot_Enabled=v end })
TabAim:CreateToggle({ Name="Авто-Стрельба",   CurrentValue=S.AutoShoot,     Flag="aim_auto",  Callback=function(v) S.AutoShoot=v      end })
TabAim:CreateToggle({ Name="Wall Check",      CurrentValue=S.WallCheck,     Flag="aim_wall",  Callback=function(v) S.WallCheck=v      end })
TabAim:CreateToggle({ Name="Team Check",      CurrentValue=S.TeamCheck,     Flag="aim_team",  Callback=function(v) S.TeamCheck=v      end })
TabAim:CreateToggle({ Name="FOV Круг",        CurrentValue=S.FOV_Visible,   Flag="aim_fov_v", Callback=function(v)
    S.FOV_Visible = v
    if FOVCircle then FOVCircle.Visible = v end
end })
TabAim:CreateToggle({ Name="AIM Кнопка",      CurrentValue=S.AimBtn_Visible,Flag="aim_btn_v", Callback=function(v)
    S.AimBtn_Visible = v
    if AimGui then AimGui.Enabled = v end
end })
TabAim:CreateSlider({ Name="FOV Размер", Range={50,600}, Increment=10, Suffix="px", CurrentValue=S.FOV,  Flag="aim_fov",    Callback=function(v) S.FOV=v            end })
TabAim:CreateSlider({ Name="Плавность",  Range={1,10},   Increment=1,  Suffix="",   CurrentValue=3,       Flag="aim_smooth", Callback=function(v) S.Smoothness=v/10  end })
TabAim:CreateDropdown({
    Name="Часть тела", Options={"Head","HumanoidRootPart","UpperTorso"},
    CurrentOption={"Head"}, Flag="aim_part",
    Callback=function(v) S.Target_Part = v[1] or "Head" end,
})

-- ── Утилиты ──────────────────────────────────────
TabUtils:CreateSection("Телепорт к пистолету")
TabUtils:CreateButton({
    Name     = "⚡ Телепорт к Gun",
    Callback = function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            Rayfield:Notify({ Title="Ошибка", Content="Персонаж не найден", Duration=3, Image="x" })
            return
        end

        -- Сохраняем текущую позицию
        SavedPosition = root.CFrame
        Rayfield:Notify({ Title="Позиция сохранена", Content="Ищу пистолет...", Duration=2, Image="map-pin" })

        -- Ищем пистолет в workspace
        local gunNames = {"Gun","SuperGun","Revolver","Pistol","gun","pistol","revolver"}
        local foundGun = nil
        local foundPos = nil

        -- Поиск по workspace
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Tool") or obj:IsA("Model") or obj:IsA("Part") or obj:IsA("MeshPart") then
                local low = obj.Name:lower()
                if low:find("gun") or low:find("pistol") or low:find("revolver") then
                    -- Проверяем что это не в персонаже
                    local inChar = false
                    for _, p in ipairs(Players:GetPlayers()) do
                        if p.Character and obj:IsDescendantOf(p.Character) then
                            inChar = true break
                        end
                    end
                    if not inChar then
                        foundGun = obj
                        if obj:IsA("BasePart") or obj:IsA("MeshPart") then
                            foundPos = obj.Position
                        elseif obj:IsA("Model") and obj.PrimaryPart then
                            foundPos = obj.PrimaryPart.Position
                        elseif obj:IsA("Tool") then
                            local handle = obj:FindFirstChild("Handle")
                            if handle then foundPos = handle.Position end
                        end
                        if foundPos then break end
                    end
                end
            end
        end

        if foundPos then
            root.CFrame = CFrame.new(foundPos + Vector3.new(0, 3, 0))
            Rayfield:Notify({
                Title   = "Телепорт",
                Content = "Телепортирован к пистолету!",
                Duration= 3,
                Image   = "zap",
            })
        else
            Rayfield:Notify({
                Title   = "Не найдено",
                Content = "Пистолет не найден на карте",
                Duration= 3,
                Image   = "x",
            })
        end
    end,
})

TabUtils:CreateButton({
    Name     = "↩ Вернуться назад",
    Callback = function()
        local char = LocalPlayer.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root then
            Rayfield:Notify({ Title="Ошибка", Content="Персонаж не найден", Duration=3, Image="x" })
            return
        end
        if not SavedPosition then
            Rayfield:Notify({ Title="Ошибка", Content="Сначала нажми телепорт к Gun!", Duration=3, Image="x" })
            return
        end
        root.CFrame = SavedPosition
        Rayfield:Notify({
            Title   = "Возврат",
            Content = "Вернулся на прежнюю позицию!",
            Duration= 3,
            Image   = "rotate-ccw",
        })
    end,
})

TabUtils:CreateSection("Невидимость (GUI кнопка ниже)")
TabUtils:CreateLabel("Кнопка невидимости — плавающая, перетаскиваемая")
TabUtils:CreateLabel("Ты становишься полупрозрачным (0.5)")

-- ── Инфо ─────────────────────────────────────────
TabInfo:CreateSection("Управление")
TabInfo:CreateLabel("AIM кнопка — тап вкл/выкл, тащи для перемещения")
TabInfo:CreateLabel("INVIS кнопка — тап вкл/выкл, тащи для перемещения")
TabInfo:CreateLabel("Авто-стрельба работает при оружии в руках")
TabInfo:CreateLabel("Красный = Murderer | Синий = Sheriff | Зелёный = Innocent")
TabInfo:CreateLabel("Innocent — не целишься в Sheriff")

-- ===================== FOV КРУГ ===================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius       = S.FOV
FOVCircle.Color        = S.FOV_Color
FOVCircle.Thickness    = 1.5
FOVCircle.Filled       = false
FOVCircle.Transparency = 0.85
FOVCircle.Visible      = S.FOV_Visible

-- ===================== УТИЛИТА: ПЛАВАЮЩАЯ КНОПКА =
-- Универсальная функция создания плавающей кнопки
local function CreateFloatingButton(gui, config)
    --[[
        config = {
            Size      = UDim2,
            Position  = UDim2,
            BgColor   = Color3,
            Text      = string,
            TextColor = Color3,
            CornerR   = UDim,
            StrokeColor = Color3,
            OnTap     = function(),   -- короткое нажатие
        }
    --]]

    local Frame = Instance.new("Frame")
    Frame.Size              = config.Size or UDim2.new(0, 80, 0, 80)
    Frame.Position          = config.Position or UDim2.new(0, 10, 0.5, 0)
    Frame.BackgroundColor3  = config.BgColor or Color3.fromRGB(30, 30, 40)
    Frame.BorderSizePixel   = 0
    Frame.Active            = true
    Frame.Parent            = gui

    local Corner = Instance.new("UICorner")
    Corner.CornerRadius = config.CornerR or UDim.new(1, 0)
    Corner.Parent       = Frame

    local Stroke = Instance.new("UIStroke")
    Stroke.Color     = config.StrokeColor or Color3.fromRGB(200, 200, 200)
    Stroke.Thickness = 2.5
    Stroke.Parent    = Frame

    local Label = Instance.new("TextLabel")
    Label.Size               = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text               = config.Text or "BTN"
    Label.TextColor3         = config.TextColor or Color3.fromRGB(255, 255, 255)
    Label.TextScaled         = true
    Label.Font               = Enum.Font.GothamBold
    Label.Parent             = Frame

    local Btn = Instance.new("TextButton")
    Btn.Size                 = UDim2.new(1, 0, 1, 0)
    Btn.BackgroundTransparency = 1
    Btn.Text                 = ""
    Btn.Parent               = Frame

    -- Drag логика (мобильная)
    local dragging      = false
    local dragStartPos  = Vector2.new(0, 0)
    local frameStart    = Vector2.new(0, 0)
    local tapTime       = 0
    local TAP_MAX       = 0.22

    Btn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging     = true
        tapTime      = tick()
        local pos    = input.Position
        dragStartPos = Vector2.new(pos.X, pos.Y)
        frameStart   = Vector2.new(Frame.Position.X.Offset, Frame.Position.Y.Offset)
    end)

    Btn.InputEnded:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = false
        if tick() - tapTime < TAP_MAX then
            if config.OnTap then config.OnTap(Stroke, Label) end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.Touch then return end
        local pos   = input.Position
        local delta = Vector2.new(pos.X - dragStartPos.X, pos.Y - dragStartPos.Y)
        if delta.Magnitude > 8 then tapTime = 0 end
        local vp   = Camera.ViewportSize
        local newX = math.clamp(frameStart.X + delta.X, 0, vp.X - Frame.AbsoluteSize.X)
        local newY = math.clamp(frameStart.Y + delta.Y, 0, vp.Y - Frame.AbsoluteSize.Y)
        Frame.Position = UDim2.new(0, newX, 0, newY)
    end)

    return Frame, Stroke, Label
end

-- ===================== GUI КОНТЕЙНЕР =============
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name           = "MM2_FloatButtons"
FloatGui.ResetOnSpawn   = false
FloatGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
FloatGui.IgnoreGuiInset = true
FloatGui.Parent         = LocalPlayer.PlayerGui

-- ===================== AIM КНОПКА ================
local AimGui = FloatGui  -- используем один gui
local AimActive = false
local AimFrame, AimStroke, AimLabel

AimFrame, AimStroke, AimLabel = CreateFloatingButton(FloatGui, {
    Size        = UDim2.new(0, 82, 0, 82),
    Position    = UDim2.new(1, -100, 1, -200),
    BgColor     = Color3.fromRGB(18, 18, 28),
    Text        = "⊕\nAIM",
    TextColor   = Color3.fromRGB(255, 80,  80),
    StrokeColor = Color3.fromRGB(200, 50,  50),
    OnTap       = function(stroke, label)
        AimActive = not AimActive
        if AimActive then
            stroke.Color  = Color3.fromRGB(50, 255, 100)
            label.TextColor3 = Color3.fromRGB(50, 255, 100)
        else
            stroke.Color  = Color3.fromRGB(200, 50, 50)
            label.TextColor3 = Color3.fromRGB(255, 80, 80)
        end
    end,
})

-- ===================== INVIS КНОПКА ==============
local InvisActive = false

-- Настройка невидимости
local function SetupInvisChar()
    local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
    VisibleParts = {}
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency == 0 then
            table.insert(VisibleParts, d)
        end
    end
end

local function ApplyInvis(state)
    local char = LocalPlayer.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not char or not hum or not root then return end

    IsInvisible = state
    local tr = state and 0.5 or 0
    for _, part in ipairs(VisibleParts) do
        pcall(function() part.Transparency = tr end)
    end
end

-- Heartbeat для невидимости (телепорт вниз)
local invisHB = nil

local function StartInvisLoop()
    if invisHB then invisHB:Disconnect() end
    invisHB = RunService.Heartbeat:Connect(function()
        if not IsInvisible then return end
        local char = LocalPlayer.Character
        local hum  = char and char:FindFirstChildOfClass("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if not root or not hum then return end

        local origCF     = root.CFrame
        local origOffset = hum.CameraOffset
        local downCF     = origCF * CFrame.new(0, -200000, 0)
        root.CFrame      = downCF
        hum.CameraOffset = downCF:ToObjectSpace(CFrame.new(origCF.Position)).Position
        RunService.RenderStepped:Wait()
        root.CFrame      = origCF
        hum.CameraOffset = origOffset
    end)
    table.insert(InvisConns, invisHB)
end

SetupInvisChar()
StartInvisLoop()

local InvisFrame, InvisStroke, InvisLabel
InvisFrame, InvisStroke, InvisLabel = CreateFloatingButton(FloatGui, {
    Size        = UDim2.new(0, 75, 0, 75),
    Position    = UDim2.new(1, -100, 1, -300),
    BgColor     = Color3.fromRGB(18, 18, 28),
    Text        = "👁\nINVIS",
    TextColor   = Color3.fromRGB(180, 180, 255),
    StrokeColor = Color3.fromRGB(100, 100, 200),
    OnTap       = function(stroke, label)
        InvisActive = not InvisActive
        ApplyInvis(InvisActive)
        if InvisActive then
            stroke.Color     = Color3.fromRGB(50, 200, 255)
            label.TextColor3 = Color3.fromRGB(50, 200, 255)
        else
            stroke.Color     = Color3.fromRGB(100, 100, 200)
            label.TextColor3 = Color3.fromRGB(180, 180, 255)
        end
        Rayfield:Notify({
            Title   = "Невидимость",
            Content = InvisActive and "Включена!" or "Выключена!",
            Duration= 2,
            Image   = InvisActive and "eye-off" or "eye",
        })
    end,
})

-- ===================== РОЛЬ МЕСТНОГО ИГРОКА ======
local function UpdateMyRole()
    local char = LocalPlayer.Character
    if not char then MyRole = Roles.Innocent return end

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local low = item.Name:lower()
            if low:find("knife") or low:find("ak") or low:find("bat") or
               low:find("sword") or low:find("scythe") then
                MyRole = Roles.Murderer return
            end
            if low:find("gun") or low:find("revolver") or low:find("pistol") then
                MyRole = Roles.Sheriff return
            end
        end
    end

    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            local low = item.Name:lower()
            if low:find("knife") or low:find("ak") or low:find("bat") or
               low:find("sword") or low:find("scythe") then
                MyRole = Roles.Murderer return
            end
            if low:find("gun") or low:find("revolver") or low:find("pistol") then
                MyRole = Roles.Sheriff return
            end
        end
    end

    MyRole = Roles.Innocent
end

-- ===================== РОЛЬ ПРОТИВНИКА ===========
local function GetRole(player)
    if ForcedRoles[player] then return ForcedRoles[player] end

    local char = player.Character
    if not char then return Roles.Innocent end

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local low = item.Name:lower()
            if low:find("knife") or low:find("ak") or low:find("bat") or
               low:find("sword") or low:find("scythe") then
                ForcedRoles[player] = Roles.Murderer
                return Roles.Murderer
            end
            if low:find("gun") or low:find("revolver") or low:find("pistol") then
                ForcedRoles[player] = Roles.Sheriff
                return Roles.Sheriff
            end
        end
    end

    local bp = player:FindFirstChild("Backpack")
    if bp then
        for _, item in ipairs(bp:GetChildren()) do
            local low = item.Name:lower()
            if low:find("knife") or low:find("ak") or low:find("bat") or
               low:find("sword") or low:find("scythe") then
                ForcedRoles[player] = Roles.Murderer
                return Roles.Murderer
            end
            if low:find("gun") or low:find("revolver") or low:find("pistol") then
                ForcedRoles[player] = Roles.Sheriff
                return Roles.Sheriff
            end
        end
    end

    return Roles.Innocent
end

-- ===================== ДОЛЖЕН ЛИ ЦЕЛИТЬСЯ ========
local function ShouldTarget(targetRole)
    if MyRole == Roles.Murderer then
        return targetRole == Roles.Sheriff or targetRole == Roles.Innocent
    end
    if MyRole == Roles.Sheriff then
        return targetRole == Roles.Murderer
    end
    -- Innocent: только в Murderer
    return targetRole == Roles.Murderer
end

-- ===================== WALL CHECK ================
local function IsVisible(targetPart)
    if not S.WallCheck then return true end
    local lc = LocalPlayer.Character
    if not lc then return false end
    local lr = lc:FindFirstChild("HumanoidRootPart")
    if not lr then return false end

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {lc, targetPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(lr.Position, targetPart.Position - lr.Position, params)
    return result == nil
end

-- ===================== ОРУЖИЕ В РУКАХ ============
local function GetHeldWeapon()
    local char = LocalPlayer.Character
    if not char then return nil, "none" end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            local low = item.Name:lower()
            if low:find("gun") or low:find("revolver") or low:find("pistol") then
                return item, "gun"
            end
            if low:find("knife") or low:find("ak") or low:find("bat") or
               low:find("sword") or low:find("scythe") then
                return item, "melee"
            end
        end
    end
    return nil, "none"
end

-- ===================== АВТО-СТРЕЛЬБА =============
local lastShot = 0
local SHOT_CD  = 0.15

local function TryAutoShoot(targetPlayer)
    if not S.AutoShoot then return end
    if tick() - lastShot < SHOT_CD then return end

    local weapon, wType = GetHeldWeapon()
    if not weapon or wType == "none" then return end

    local char     = targetPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local targetPart = char:FindFirstChild(S.Target_Part) or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if not IsVisible(targetPart) then return end

    lastShot = tick()

    pcall(function()
        local rs = game:GetService("ReplicatedStorage")
        if wType == "gun" then
            for _, v in ipairs(rs:GetDescendants()) do
                if v:IsA("RemoteEvent") then
                    local low = v.Name:lower()
                    if low:find("shoot") or low:find("fire") or
                       low:find("gun")   or low:find("bullet") then
                        pcall(function()
                            v:FireServer(CFrame.new(targetPart.Position), targetPart.Position)
                        end)
                        break
                    end
                end
            end
        end
    end)
end

-- ===================== БЛИЖАЙШИЙ ВРАГ ============
local function GetClosestTarget()
    local best     = nil
    local bestDist = S.FOV
    local center   = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    UpdateMyRole()

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        local char     = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        if not humanoid or humanoid.Health <= 0 then continue end

        local role = GetRole(player)
        if not ShouldTarget(role) then continue end

        local targetPart = char:FindFirstChild(S.Target_Part)
                        or char:FindFirstChild("HumanoidRootPart")
        if not targetPart then continue end

        local sp, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
        if not onScreen or sp.Z < 0 then continue end

        local dist = (Vector2.new(sp.X, sp.Y) - center).Magnitude
        if dist < bestDist and IsVisible(targetPart) then
            bestDist = dist
            best     = player
        end
    end

    return best
end

-- ===================== AIMBOT ОБНОВЛЕНИЕ =========
local function UpdateAimbot()
    FOVCircle.Radius   = S.FOV
    FOVCircle.Visible  = S.FOV_Visible
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if not S.Aimbot_Enabled then return end

    local _, wType  = GetHeldWeapon()
    local hasWeapon = wType ~= "none"

    if not hasWeapon and not AimActive then return end

    local target = GetClosestTarget()
    if not target then return end

    local char = target.Character
    if not char then return end

    local targetPart = char:FindFirstChild(S.Target_Part)
                    or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    local _, onScreen = Camera:WorldToViewportPoint(targetPart.Position)
    if not onScreen then return end

    local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, S.Smoothness)

    if hasWeapon then TryAutoShoot(target) end
end

-- ===================== ESP: Drawing ==============
local function CreateESP(player)
    local data = { lines = {} }
    for i = 1, 4 do
        local line = Drawing.new("Line")
        line.Thickness    = 1.5
        line.Color        = Color3.fromRGB(255, 255, 255)
        line.Visible      = false
        line.Transparency = 1
        data.lines[i]     = line
    end

    data.nameText = Drawing.new("Text")
    data.nameText.Size         = 14
    data.nameText.Center       = true
    data.nameText.Outline      = true
    data.nameText.OutlineColor = Color3.fromRGB(0, 0, 0)
    data.nameText.Visible      = false
    data.nameText.Font         = Drawing.Fonts.UI

    data.roleText = Drawing.new("Text")
    data.roleText.Size         = 11
    data.roleText.Center       = true
    data.roleText.Outline      = true
    data.roleText.OutlineColor = Color3.fromRGB(0, 0, 0)
    data.roleText.Visible      = false
    data.roleText.Font         = Drawing.Fonts.UI

    ESPObjects[player] = data
end

local function RemoveESP(player)
    if not ESPObjects[player] then return end
    local d = ESPObjects[player]
    for _, line in ipairs(d.lines) do line:Remove() end
    d.nameText:Remove()
    d.roleText:Remove()
    ESPObjects[player] = nil
end

local function SetESPVisible(data, v)
    for _, l in ipairs(data.lines) do l.Visible = v end
    data.nameText.Visible = v
    data.roleText.Visible = v
end

local function GetBoundingBox(char)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return nil end

    local topSP, on1 = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.7, 0))
    local botSP      = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3,   0))

    if not on1 or topSP.Z < 0 then return nil end

    local h  = math.abs(botSP.Y - topSP.Y)
    local w  = h * 0.55
    local cx = topSP.X

    return {
        TL      = Vector2.new(cx - w/2, topSP.Y),
        TR      = Vector2.new(cx + w/2, topSP.Y),
        BL      = Vector2.new(cx - w/2, botSP.Y),
        BR      = Vector2.new(cx + w/2, botSP.Y),
        namePos = Vector2.new(cx, topSP.Y - 17),
        rolePos = Vector2.new(cx, botSP.Y + 2),
    }
end

local function DrawBox(data, box, color)
    local L = data.lines
    L[1].From=box.TL  L[1].To=box.TR  L[1].Color=color
    L[2].From=box.BL  L[2].To=box.BR  L[2].Color=color
    L[3].From=box.TL  L[3].To=box.BL  L[3].Color=color
    L[4].From=box.TR  L[4].To=box.BR  L[4].Color=color
end

-- ===================== ESP ОБНОВЛЕНИЕ ============
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not ESPObjects[player] then CreateESP(player) end

        local data     = ESPObjects[player]
        if not data then continue end

        local char     = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local alive    = humanoid and humanoid.Health > 0

        if not S.ESP_Enabled or not char or not alive then
            SetESPVisible(data, false) continue
        end

        local role  = GetRole(player)
        local show  = false
        local color = S.Innocent_Color
        local rtext = ""

        if role == Roles.Murderer then
            show  = S.Show_Murderer
            color = S.Murderer_Color
            rtext = "[ MURDERER ]"
        elseif role == Roles.Sheriff then
            show  = S.Show_Sheriff
            color = S.Sheriff_Color
            rtext = "[ SHERIFF ]"
        else
            show  = S.Show_Innocent
            color = S.Innocent_Color
        end

        if not show then SetESPVisible(data, false) continue end

        local box = GetBoundingBox(char)
        if not box then SetESPVisible(data, false) continue end

        DrawBox(data, box, color)
        for _, l in ipairs(data.lines) do l.Visible = true end

        data.nameText.Text     = player.Name
        data.nameText.Color    = color
        data.nameText.Position = box.namePos
        data.nameText.Visible  = true

        if rtext ~= "" then
            data.roleText.Text     = rtext
            data.roleText.Color    = color
            data.roleText.Position = box.rolePos
            data.roleText.Visible  = true
        else
            data.roleText.Visible = false
        end
    end
end

-- ===================== СЛЕЖЕНИЕ ЗА ОРУЖИЕМ =======
local function WatchPlayer(player)
    local char = player.Character
    if not char then return end
    ForcedRoles[player] = nil
    char.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        local low = child.Name:lower()
        if low:find("knife") or low:find("ak") or low:find("bat") or
           low:find("sword") or low:find("scythe") then
            ForcedRoles[player] = Roles.Murderer
        elseif low:find("gun") or low:find("revolver") or low:find("pistol") then
            ForcedRoles[player] = Roles.Sheriff
        end
    end)
end

-- ===================== ИНИЦИАЛИЗАЦИЯ =============
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESP(p)
        WatchPlayer(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            WatchPlayer(p)
        end)
    end
end

Players.PlayerAdded:Connect(function(p)
    CreateESP(p)
    WatchPlayer(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        RemoveESP(p)
        CreateESP(p)
        WatchPlayer(p)
    end)
end)

Players.PlayerRemoving:Connect(function(p)
    RemoveESP(p)
    ForcedRoles[p] = nil
end)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    MyRole      = Roles.Innocent
    ForcedRoles = {}
    IsInvisible = false
    InvisActive = false
    if InvisStroke then InvisStroke.Color     = Color3.fromRGB(100, 100, 200) end
    if InvisLabel  then InvisLabel.TextColor3 = Color3.fromRGB(180, 180, 255) end
    SetupInvisChar()
    StartInvisLoop()
end)

-- ===================== ГЛАВНЫЙ ЦИКЛ ==============
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAimbot()
end)

-- ===================== УВЕДОМЛЕНИЕ ===============
Rayfield:Notify({
    Title   = "MM2 Script",
    Content = "Загружен! AIM + INVIS кнопки снизу справа",
    Duration= 5,
    Image   = "check",
})

print("[MM2] Скрипт запущен успешно!")
