-- MM2 Script | Rayfield GUI | Delta Executor
-- Мобильная оптимизация | Авто-прицел + Авто-стрельба

local Players         = game:GetService("Players")
local RunService      = game:GetService("RunService")
local UserInputService= game:GetService("UserInputService")
local TweenService    = game:GetService("TweenService")
local Camera          = workspace.CurrentCamera
local LocalPlayer     = Players.LocalPlayer

-- ===================== RAYFIELD =====================
local OK, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not OK then warn("Rayfield error: "..tostring(Rayfield)) return end

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
local ESPObjects  = {}
local ForcedRoles = {}
local MyRole      = "Innocent"

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

local TabESP = Window:CreateTab("ESP",    "eye")
local TabAim = Window:CreateTab("Aimbot", "crosshair")
local TabInfo= Window:CreateTab("Инфо",  "info")

-- ESP вкладка
TabESP:CreateToggle({ Name="ESP Включён",         CurrentValue=S.ESP_Enabled,   Flag="esp_on",   Callback=function(v) S.ESP_Enabled=v end })
TabESP:CreateToggle({ Name="Murderer ESP",         CurrentValue=S.Show_Murderer, Flag="esp_murd", Callback=function(v) S.Show_Murderer=v end })
TabESP:CreateToggle({ Name="Sheriff ESP",          CurrentValue=S.Show_Sheriff,  Flag="esp_sher", Callback=function(v) S.Show_Sheriff=v end })
TabESP:CreateToggle({ Name="Innocent ESP",         CurrentValue=S.Show_Innocent, Flag="esp_inno", Callback=function(v) S.Show_Innocent=v end })

-- Aimbot вкладка
TabAim:CreateToggle({ Name="Aimbot Включён",       CurrentValue=S.Aimbot_Enabled,Flag="aim_on",   Callback=function(v) S.Aimbot_Enabled=v end })
TabAim:CreateToggle({ Name="Авто-Стрельба",        CurrentValue=S.AutoShoot,     Flag="aim_auto", Callback=function(v) S.AutoShoot=v end })
TabAim:CreateToggle({ Name="Wall Check",           CurrentValue=S.WallCheck,     Flag="aim_wall", Callback=function(v) S.WallCheck=v end })
TabAim:CreateToggle({ Name="Team Check",           CurrentValue=S.TeamCheck,     Flag="aim_team", Callback=function(v) S.TeamCheck=v end })
TabAim:CreateToggle({ Name="FOV Круг",             CurrentValue=S.FOV_Visible,   Flag="aim_fov_v",Callback=function(v) S.FOV_Visible=v if FOVCircle then FOVCircle.Visible=v end end })
TabAim:CreateToggle({ Name="AIM Кнопка",           CurrentValue=S.AimBtn_Visible,Flag="aim_btn_v",Callback=function(v) S.AimBtn_Visible=v if AimGui then AimGui.Enabled=v end end })

TabAim:CreateSlider({ Name="FOV Размер", Range={50,600}, Increment=10, Suffix="px", CurrentValue=S.FOV,       Flag="aim_fov",    Callback=function(v) S.FOV=v end })
TabAim:CreateSlider({ Name="Плавность",  Range={1,10},   Increment=1,  Suffix="",   CurrentValue=3,            Flag="aim_smooth", Callback=function(v) S.Smoothness=v/10 end })

TabAim:CreateDropdown({
    Name="Часть тела", Options={"Head","HumanoidRootPart","UpperTorso"},
    CurrentOption={"Head"}, Flag="aim_part",
    Callback=function(v) S.Target_Part=v[1] or "Head" end,
})

-- Инфо вкладка
TabInfo:CreateSection("Информация")
TabInfo:CreateLabel("Кнопку AIM можно перетаскивать")
TabInfo:CreateLabel("Авто-стрельба работает при оружии в руках")
TabInfo:CreateLabel("Красный = Murderer | Синий = Sheriff")
TabInfo:CreateLabel("Зелёный = Innocent")
TabInfo:CreateLabel("Если ты Innocent — не целишься в Sheriff")

-- ===================== FOV КРУГ ===================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius       = S.FOV
FOVCircle.Color        = S.FOV_Color
FOVCircle.Thickness    = 1.5
FOVCircle.Filled       = false
FOVCircle.Transparency = 0.85
FOVCircle.Visible      = S.FOV_Visible

-- ===================== AIM КНОПКА (плавающая) ====
local AimGui = Instance.new("ScreenGui")
AimGui.Name            = "AimButtonGui"
AimGui.ResetOnSpawn    = false
AimGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
AimGui.IgnoreGuiInset  = true
AimGui.Enabled         = S.AimBtn_Visible
AimGui.Parent          = LocalPlayer.PlayerGui

-- Контейнер кнопки
local AimFrame = Instance.new("Frame")
AimFrame.Size            = UDim2.new(0, 85, 0, 85)
AimFrame.Position        = UDim2.new(1, -110, 1, -200)
AimFrame.BackgroundColor3= Color3.fromRGB(20, 20, 30)
AimFrame.BorderSizePixel = 0
AimFrame.Active          = true
AimFrame.Parent          = AimGui

local AimCorner = Instance.new("UICorner")
AimCorner.CornerRadius   = UDim.new(1, 0)
AimCorner.Parent         = AimFrame

-- Внешнее кольцо
local AimRing = Instance.new("UIStroke")
AimRing.Color            = Color3.fromRGB(200, 50, 50)
AimRing.Thickness        = 3
AimRing.Parent           = AimFrame

-- Иконка/текст кнопки
local AimLabel = Instance.new("TextLabel")
AimLabel.Size            = UDim2.new(1, 0, 0.55, 0)
AimLabel.Position        = UDim2.new(0, 0, 0.1, 0)
AimLabel.BackgroundTransparency = 1
AimLabel.Text            = "⊕"
AimLabel.TextColor3      = Color3.fromRGB(255, 80, 80)
AimLabel.TextScaled      = true
AimLabel.Font            = Enum.Font.GothamBold
AimLabel.Parent          = AimFrame

local AimSubLabel = Instance.new("TextLabel")
AimSubLabel.Size         = UDim2.new(1, 0, 0.3, 0)
AimSubLabel.Position     = UDim2.new(0, 0, 0.65, 0)
AimSubLabel.BackgroundTransparency = 1
AimSubLabel.Text         = "AIM"
AimSubLabel.TextColor3   = Color3.fromRGB(200, 200, 200)
AimSubLabel.TextScaled   = true
AimSubLabel.Font         = Enum.Font.GothamBold
AimSubLabel.Parent       = AimFrame

-- Кнопка (прозрачная поверх фрейма)
local AimButton = Instance.new("TextButton")
AimButton.Size           = UDim2.new(1, 0, 1, 0)
AimButton.BackgroundTransparency = 1
AimButton.Text           = ""
AimButton.Parent         = AimFrame

-- ====== ЛОГИКА ПЕРЕТАСКИВАНИЯ КНОПКИ ======
local dragging     = false
local dragStartPos = Vector2.new(0, 0)
local frameStartPos= Vector2.new(0, 0)
local tapTime      = 0
local TAP_THRESHOLD= 0.2  -- секунды — меньше = тап, больше = drag

local AimActive = false  -- ручной aim (тап по кнопке)

AimButton.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging      = true
    tapTime       = tick()
    local pos     = input.Position
    dragStartPos  = Vector2.new(pos.X, pos.Y)
    frameStartPos = Vector2.new(
        AimFrame.Position.X.Offset,
        AimFrame.Position.Y.Offset
    )
end)

AimButton.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end
    dragging = false
    -- Если нажали быстро (тап) — toggle ручного aim
    if tick() - tapTime < TAP_THRESHOLD then
        AimActive = not AimActive
        AimRing.Color    = AimActive and Color3.fromRGB(50, 255, 100) or Color3.fromRGB(200, 50, 50)
        AimLabel.TextColor3 = AimActive and Color3.fromRGB(50, 255, 100) or Color3.fromRGB(255, 80, 80)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not dragging then return end
    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    -- Проверяем что это тот же палец (первый тач)
    local pos  = input.Position
    local delta= Vector2.new(pos.X - dragStartPos.X, pos.Y - dragStartPos.Y)

    -- Если двигаем — это drag, отменяем тап
    if delta.Magnitude > 10 then
        tapTime = 0
    end

    local vp = Camera.ViewportSize
    local newX = math.clamp(frameStartPos.X + delta.X, 0, vp.X - AimFrame.AbsoluteSize.X)
    local newY = math.clamp(frameStartPos.Y + delta.Y, 0, vp.Y - AimFrame.AbsoluteSize.Y)

    AimFrame.Position = UDim2.new(0, newX, 0, newY)
end)

-- ===================== РОЛЬ МЕСТНОГО ИГРОКА ======
local function UpdateMyRole()
    local char = LocalPlayer.Character
    if not char then MyRole = Roles.Innocent return end

    local function hasItem(name)
        return char:FindFirstChild(name) ~= nil
    end

    local murdererItems = {"Knife","AK47","AK-47","Bat","Sword","Scythe","Bokken"}
    for _, n in ipairs(murdererItems) do
        if hasItem(n) then MyRole = Roles.Murderer return end
    end

    -- Проверяем через Tool
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

    local murdererItems = {"Knife","AK47","AK-47","Bat","Sword","Scythe","Bokken"}
    for _, n in ipairs(murdererItems) do
        if char:FindFirstChild(n) then
            ForcedRoles[player] = Roles.Murderer
            return Roles.Murderer
        end
    end

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

-- ===================== ПРОВЕРКА ЦЕЛИ ПО РОЛИ =====
-- Возвращает true если LocalPlayer должен целиться в target
local function ShouldTarget(targetRole)
    -- Мардер целится во всех (sheriff + innocent)
    if MyRole == Roles.Murderer then
        return targetRole == Roles.Sheriff or targetRole == Roles.Innocent
    end
    -- Шериф целится только в мардера
    if MyRole == Roles.Sheriff then
        return targetRole == Roles.Murderer
    end
    -- Мирный НЕ целится в шерифа, только в мардера
    if MyRole == Roles.Innocent then
        return targetRole == Roles.Murderer
    end
    return false
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

-- ===================== ОРУЖИЕ В РУКАХ ===========
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

-- ===================== АВТО-СТРЕЛЬБА ============
local lastShot = 0
local SHOT_COOLDOWN = 0.15

local function TryAutoShoot(targetPlayer)
    if not S.AutoShoot then return end
    if tick() - lastShot < SHOT_COOLDOWN then return end

    local weapon, wType = GetHeldWeapon()
    if not weapon or wType == "none" then return end

    local char      = targetPlayer.Character
    local humanoid  = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local targetPart = char:FindFirstChild(S.Target_Part) or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end

    -- Только если цель видна
    if not IsVisible(targetPart) then return end

    lastShot = tick()

    -- Стреляем через FireServer / RemoteEvent (универсально для MM2)
    pcall(function()
        -- Пробуем через mouse click симуляцию инструмента
        if weapon and weapon:FindFirstChild("Handle") then
            -- Активируем оружие
            local mouse = LocalPlayer:GetMouse()
            -- Наводим mouse.Hit на цель
            local cf = CFrame.new(targetPart.Position)
            -- Стрельба через RemoteEvent MM2
            local remotes = game:GetService("ReplicatedStorage")
            -- Пробуем стандартный выстрел
            if wType == "gun" then
                -- Симулируем нажатие на экран (активация Tool)
                local activate = weapon:FindFirstChild("Activate") or
                                 weapon:FindFirstChild("Fire")     or
                                 weapon:FindFirstChild("Shoot")
                if activate and activate:IsA("RemoteEvent") then
                    activate:FireServer(cf)
                else
                    -- Fallback: симулируем InputBegan на инструменте
                    fireproximityprompt = fireproximityprompt or function() end
                    -- Используем Tool.Activated через коннект
                    local act = weapon.Activated
                    if act then
                        -- Создаём фейковый InputObject
                        local fakeInput = {
                            UserInputType = Enum.UserInputType.MouseButton1,
                            UserInputState = Enum.UserInputState.Begin,
                            Position = Vector3.new(0,0,0),
                        }
                        -- Стреляем через внутренний remote MM2
                        for _, v in ipairs(remotes:GetDescendants()) do
                            if v:IsA("RemoteEvent") and
                               (v.Name:lower():find("shoot") or
                                v.Name:lower():find("fire")  or
                                v.Name:lower():find("gun")   or
                                v.Name:lower():find("bullet")) then
                                pcall(function() v:FireServer(cf, targetPart.Position) end)
                                break
                            end
                        end
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

    -- Авто-aim когда есть оружие в руках ИЛИ ручной aim (AimActive)
    local _, wType = GetHeldWeapon()
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

    -- Плавный поворот камеры
    local targetCF = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(targetCF, S.Smoothness)

    -- Авто-стрельба
    if hasWeapon then
        TryAutoShoot(target)
    end
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
    data.nameText.Size        = 14
    data.nameText.Center      = true
    data.nameText.Outline     = true
    data.nameText.OutlineColor= Color3.fromRGB(0, 0, 0)
    data.nameText.Visible     = false
    data.nameText.Font        = Drawing.Fonts.UI

    data.roleText = Drawing.new("Text")
    data.roleText.Size        = 11
    data.roleText.Center      = true
    data.roleText.Outline     = true
    data.roleText.OutlineColor= Color3.fromRGB(0, 0, 0)
    data.roleText.Visible     = false
    data.roleText.Font        = Drawing.Fonts.UI

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
    local botSP, on2 = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3,   0))

    if (not on1 and not on2) or topSP.Z < 0 then return nil end

    local h = math.abs(botSP.Y - topSP.Y)
    local w = h * 0.55
    local cx= topSP.X

    return {
        TL = Vector2.new(cx - w/2, topSP.Y),
        TR = Vector2.new(cx + w/2, topSP.Y),
        BL = Vector2.new(cx - w/2, botSP.Y),
        BR = Vector2.new(cx + w/2, botSP.Y),
        namePos = Vector2.new(cx, topSP.Y - 17),
        rolePos = Vector2.new(cx, botSP.Y + 2),
    }
end

local function DrawBox(data, box, color)
    local L = data.lines
    L[1].From=box.TL L[1].To=box.TR L[1].Color=color -- top
    L[2].From=box.BL L[2].To=box.BR L[2].Color=color -- bottom
    L[3].From=box.TL L[3].To=box.BL L[3].Color=color -- left
    L[4].From=box.TR L[4].To=box.BR L[4].Color=color -- right
end

-- ===================== ESP ОБНОВЛЕНИЕ ============
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        if not ESPObjects[player] then CreateESP(player) end
        local data = ESPObjects[player]
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
            rtext = ""
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
    MyRole = Roles.Innocent
    ForcedRoles = {}
end)

-- ===================== ГЛАВНЫЙ ЦИКЛ ==============
RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAimbot()
end)

-- ===================== УВЕДОМЛЕНИЕ ===============
Rayfield:Notify({
    Title    = "MM2 Script",
    Content  = "Загружен! Нажми AIM кнопку или возьми оружие",
    Duration = 5,
    Image    = "check",
})

print("[MM2] OK | AimActive="..tostring(AimActive))
