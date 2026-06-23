-- ╔══════════════════════════════════════════════════════════╗
-- ║         MM2 Script | Delta Executor | Mobile             ║
-- ║   ESP + Aimbot + Invis + Teleport | Rayfield GUI         ║
-- ╚══════════════════════════════════════════════════════════╝

-- ===================== СЕРВИСЫ ======================
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local ReplicatedStorage= game:GetService("ReplicatedStorage")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- ===================== RAYFIELD =====================
local OK, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not OK then
    warn("[MM2] Rayfield не загружен: " .. tostring(Rayfield))
    return
end

-- ===================== НАСТРОЙКИ ====================
local S = {
    -- ESP
    ESP_Enabled    = true,
    Show_Murderer  = true,
    Show_Sheriff   = true,
    Show_Innocent  = true,
    ESP_BoxColor_M = Color3.fromRGB(255, 60,  60),
    ESP_BoxColor_S = Color3.fromRGB(60,  150, 255),
    ESP_BoxColor_I = Color3.fromRGB(80,  255, 120),
    ESP_Thickness  = 1.5,
    ESP_NameSize   = 13,
    ESP_RoleSize   = 11,

    -- Aimbot
    Aimbot_Enabled = true,
    FOV            = 220,
    Smoothness     = 0.20,
    Target_Part    = "Head",
    WallCheck      = true,
    AutoShoot      = true,
    FOV_Visible    = true,
    FOV_Color      = Color3.fromRGB(255, 255, 255),
    AimBtn_Visible = true,

    -- Невидимость
    Invis_Transparency = 0.5,

    -- Телепорт
    Teleport_Offset    = Vector3.new(0, 3, 0),
}

-- ===================== СОСТОЯНИЕ ====================
local ESPObjects    = {}
local ForcedRoles   = {}
local MyRole        = "Innocent"
local AimActive     = false
local IsInvisible   = false
local VisibleParts  = {}
local InvisHB       = nil
local SavedPosition = nil
local GunPosition   = nil
local lastShot      = 0
local SHOT_CD       = 0.15

local Roles = {
    Murderer = "Murderer",
    Sheriff  = "Sheriff",
    Innocent = "Innocent",
}

-- ╔══════════════════════════════════════════════════════════╗
-- ║                    RAYFIELD GUI                          ║
-- ╚══════════════════════════════════════════════════════════╝

local Window = Rayfield:CreateWindow({
    Name                   = "MM2 Script",
    LoadingTitle           = "MM2 Script",
    LoadingSubtitle        = "Delta Executor | Mobile",
    Theme                  = "Default",
    DisableRayfieldPrompts = true,
    ConfigurationSaving    = { Enabled = false },
    KeySystem              = false,
})

local TabESP   = Window:CreateTab("ESP",      "eye")
local TabAim   = Window:CreateTab("Aimbot",   "crosshair")
local TabUtils = Window:CreateTab("Утилиты",  "star")
local TabInfo  = Window:CreateTab("Инфо",     "info")

-- ─────────────────── ESP Tab ──────────────────────
TabESP:CreateSection("Настройки ESP")

TabESP:CreateToggle({
    Name         = "ESP Включён",
    CurrentValue = S.ESP_Enabled,
    Flag         = "esp_on",
    Callback     = function(v) S.ESP_Enabled = v end,
})

TabESP:CreateToggle({
    Name         = "Murderer ESP",
    CurrentValue = S.Show_Murderer,
    Flag         = "esp_murd",
    Callback     = function(v) S.Show_Murderer = v end,
})

TabESP:CreateToggle({
    Name         = "Sheriff ESP",
    CurrentValue = S.Show_Sheriff,
    Flag         = "esp_sher",
    Callback     = function(v) S.Show_Sheriff = v end,
})

TabESP:CreateToggle({
    Name         = "Innocent ESP",
    CurrentValue = S.Show_Innocent,
    Flag         = "esp_inno",
    Callback     = function(v) S.Show_Innocent = v end,
})

TabESP:CreateSlider({
    Name         = "Толщина бокса",
    Range        = {1, 5},
    Increment    = 1,
    Suffix       = "px",
    CurrentValue = 2,
    Flag         = "esp_thick",
    Callback     = function(v) S.ESP_Thickness = v end,
})

-- ─────────────────── Aimbot Tab ───────────────────
TabAim:CreateSection("Настройки Aimbot")

TabAim:CreateToggle({
    Name         = "Aimbot Включён",
    CurrentValue = S.Aimbot_Enabled,
    Flag         = "aim_on",
    Callback     = function(v) S.Aimbot_Enabled = v end,
})

TabAim:CreateToggle({
    Name         = "Авто-Стрельба",
    CurrentValue = S.AutoShoot,
    Flag         = "aim_auto",
    Callback     = function(v) S.AutoShoot = v end,
})

TabAim:CreateToggle({
    Name         = "Wall Check",
    CurrentValue = S.WallCheck,
    Flag         = "aim_wall",
    Callback     = function(v) S.WallCheck = v end,
})

TabAim:CreateToggle({
    Name         = "FOV Круг",
    CurrentValue = S.FOV_Visible,
    Flag         = "aim_fov_v",
    Callback     = function(v)
        S.FOV_Visible = v
        if FOVCircle then FOVCircle.Visible = v end
    end,
})

TabAim:CreateToggle({
    Name         = "AIM Кнопка видна",
    CurrentValue = S.AimBtn_Visible,
    Flag         = "aim_btn_v",
    Callback     = function(v)
        S.AimBtn_Visible = v
        if _AimFrame then _AimFrame.Visible = v end
    end,
})

TabAim:CreateSlider({
    Name         = "FOV Размер",
    Range        = {50, 600},
    Increment    = 10,
    Suffix       = "px",
    CurrentValue = S.FOV,
    Flag         = "aim_fov",
    Callback     = function(v) S.FOV = v end,
})

TabAim:CreateSlider({
    Name         = "Плавность (1=резко, 10=плавно)",
    Range        = {1, 10},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 2,
    Flag         = "aim_smooth",
    Callback     = function(v) S.Smoothness = v / 10 end,
})

TabAim:CreateDropdown({
    Name          = "Цель (часть тела)",
    Options       = {"Head", "HumanoidRootPart", "UpperTorso"},
    CurrentOption = {"Head"},
    Flag          = "aim_part",
    Callback      = function(v)
        S.Target_Part = v[1] or "Head"
    end,
})

-- ─────────────────── Utilities Tab ────────────────
TabUtils:CreateSection("Телепорт к пистолету")

TabUtils:CreateLabel("Кнопка TELEPORT (плавающая) внизу справа")
TabUtils:CreateLabel("Тап 1 = сохранить позицию и телепорт к Gun")
TabUtils:CreateLabel("Тап 2 = вернуться обратно")

TabUtils:CreateSection("Невидимость")
TabUtils:CreateLabel("Кнопка INVIS (плавающая) внизу справа")
TabUtils:CreateLabel("Ты становишься полупрозрачным для других")

TabUtils:CreateSlider({
    Name         = "Прозрачность при инвизе",
    Range        = {1, 9},
    Increment    = 1,
    Suffix       = "",
    CurrentValue = 5,
    Flag         = "invis_tr",
    Callback     = function(v)
        S.Invis_Transparency = v / 10
        if IsInvisible then
            for _, part in ipairs(VisibleParts) do
                pcall(function() part.Transparency = S.Invis_Transparency end)
            end
        end
    end,
})

-- ─────────────────── Info Tab ─────────────────────
TabInfo:CreateSection("Кнопки управления")
TabInfo:CreateLabel("⊕ AIM  — тап вкл/выкл, тащи чтобы переместить")
TabInfo:CreateLabel("👁 INVIS — тап вкл/выкл, тащи чтобы переместить")
TabInfo:CreateLabel("⚡ TELE — тап 1 = к пистолету, тап 2 = назад")
TabInfo:CreateSection("Роли и цели")
TabInfo:CreateLabel("Innocent → целится только в Murderer")
TabInfo:CreateLabel("Sheriff  → целится только в Murderer")
TabInfo:CreateLabel("Murderer → целится в Sheriff + Innocent")
TabInfo:CreateSection("ESP Цвета")
TabInfo:CreateLabel("Красный  = Murderer")
TabInfo:CreateLabel("Синий    = Sheriff")
TabInfo:CreateLabel("Зелёный  = Innocent")

-- ╔══════════════════════════════════════════════════════════╗
-- ║              FOV CIRCLE (Drawing)                        ║
-- ╚══════════════════════════════════════════════════════════╝

local FOVCircle = Drawing.new("Circle")
FOVCircle.Radius       = S.FOV
FOVCircle.Color        = S.FOV_Color
FOVCircle.Thickness    = 1.5
FOVCircle.Filled       = false
FOVCircle.Transparency = 0.85
FOVCircle.Visible      = S.FOV_Visible

-- ╔══════════════════════════════════════════════════════════╗
-- ║           ПЛАВАЮЩИЕ КНОПКИ — ИСПРАВЛЕННАЯ ЛОГИКА         ║
-- ╚══════════════════════════════════════════════════════════╝

-- Главный ScreenGui для кнопок
local FloatGui = Instance.new("ScreenGui")
FloatGui.Name            = "MM2_Floats"
FloatGui.ResetOnSpawn    = false
FloatGui.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
FloatGui.IgnoreGuiInset  = true
FloatGui.DisplayOrder    = 999
FloatGui.Parent          = LocalPlayer.PlayerGui

-- ─────────────────────────────────────────────────
-- Ключевое исправление: используем ОДИН глобальный
-- InputChanged на FloatGui, а не на кнопке.
-- Это исключает потерю трека пальца при мультитаче.
-- ─────────────────────────────────────────────────

-- Трекер всех активных drag-сессий
-- dragSessions[inputObject] = { frame, startInput, startFramePos }
local dragSessions = {}

-- Реестр кнопок для tap-логики
-- tapRegistry[inputObject] = { frame, tapTime, onTap, stroke, label }
local tapRegistry  = {}

local function ClampFrameToScreen(frame, x, y)
    local vp  = Camera.ViewportSize
    local sz  = frame.AbsoluteSize
    -- Гарантируем что кнопка ВСЕГДА остаётся на экране
    local cx  = math.clamp(x, 0, math.max(0, vp.X - sz.X))
    local cy  = math.clamp(y, 0, math.max(0, vp.Y - sz.Y))
    return cx, cy
end

-- Глобальный обработчик движения (один на всё)
UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    local session = dragSessions[input]
    if not session then return end

    local frame     = session.frame
    local startPos  = session.startInput
    local startFP   = session.startFramePos

    local cur   = input.Position
    local dx    = cur.X - startPos.X
    local dy    = cur.Y - startPos.Y

    -- Если сдвиг больше 12px — считаем drag, отменяем tap
    if math.sqrt(dx*dx + dy*dy) > 12 then
        local tr = tapRegistry[input]
        if tr then tr.isTap = false end
    end

    local nx, ny = ClampFrameToScreen(
        frame,
        startFP.X + dx,
        startFP.Y + dy
    )
    frame.Position = UDim2.new(0, nx, 0, ny)
end)

-- Глобальный обработчик окончания касания
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.Touch then return end

    local session = dragSessions[input]
    if session then
        dragSessions[input] = nil
    end

    local tr = tapRegistry[input]
    if tr then
        if tr.isTap and tr.onTap then
            tr.onTap()
        end
        tapRegistry[input] = nil
    end
end)

-- Создание плавающей кнопки
-- cfg:
--   size     UDim2
--   pos      UDim2
--   bg       Color3
--   stroke   Color3
--   text     string
--   subtext  string   (маленький текст снизу)
--   textClr  Color3
--   onTap    function
local function MakeFloatButton(cfg)
    local TAP_MAX = 0.25  -- секунд

    -- Вычисляем абсолютную начальную позицию
    local vp = Camera.ViewportSize
    local sw = cfg.size and cfg.size.X.Offset or 65
    local sh = cfg.size and cfg.size.Y.Offset or 65
    local startX = cfg.pos and cfg.pos.X.Offset or (vp.X - sw - 15)
    local startY = cfg.pos and cfg.pos.Y.Offset or (vp.Y - sh - 15)

    -- Корневой фрейм
    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(0, sw, 0, sh)
    frame.Position          = UDim2.new(0, startX, 0, startY)
    frame.BackgroundColor3  = cfg.bg or Color3.fromRGB(18, 18, 28)
    frame.BorderSizePixel   = 0
    frame.ClipsDescendants  = false
    frame.Parent            = FloatGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent       = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color     = cfg.stroke or Color3.fromRGB(200, 200, 200)
    stroke.Thickness = 2.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent    = frame

    -- Иконка / главный текст
    local mainLabel = Instance.new("TextLabel")
    mainLabel.Size               = UDim2.new(1, 0, 0.55, 0)
    mainLabel.Position           = UDim2.new(0, 0, 0.05, 0)
    mainLabel.BackgroundTransparency = 1
    mainLabel.Text               = cfg.text or "BTN"
    mainLabel.TextColor3         = cfg.textClr or Color3.fromRGB(255, 255, 255)
    mainLabel.TextScaled         = true
    mainLabel.Font               = Enum.Font.GothamBold
    mainLabel.Parent             = frame

    -- Подпись снизу
    local subLabel = Instance.new("TextLabel")
    subLabel.Size                = UDim2.new(1, 0, 0.35, 0)
    subLabel.Position            = UDim2.new(0, 0, 0.62, 0)
    subLabel.BackgroundTransparency = 1
    subLabel.Text                = cfg.subtext or ""
    subLabel.TextColor3          = Color3.fromRGB(200, 200, 200)
    subLabel.TextScaled          = true
    subLabel.Font                = Enum.Font.GothamBold
    subLabel.Parent              = frame

    -- Прозрачная кнопка поверх
    local btn = Instance.new("TextButton")
    btn.Size                 = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                 = ""
    btn.ZIndex               = 10
    btn.Parent               = frame

    -- Обработка касания на кнопке
    btn.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.Touch then return end

        -- Абсолютная позиция фрейма в момент начала
        local absPos = frame.AbsolutePosition

        dragSessions[input] = {
            frame        = frame,
            startInput   = Vector2.new(input.Position.X, input.Position.Y),
            startFramePos= Vector2.new(absPos.X, absPos.Y),
        }

        tapRegistry[input] = {
            isTap  = true,
            onTap  = cfg.onTap,
            stroke = stroke,
            label  = mainLabel,
        }
    end)

    return {
        frame    = frame,
        stroke   = stroke,
        mainLbl  = mainLabel,
        subLbl   = subLabel,
    }
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  КНОПКА AIM                              ║
-- ╚══════════════════════════════════════════════════════════╝

local _AimBtn   = nil
local _AimFrame = nil

local function OnAimTap()
    AimActive = not AimActive
    if AimActive then
        _AimBtn.stroke.Color       = Color3.fromRGB(50, 255, 100)
        _AimBtn.mainLbl.TextColor3 = Color3.fromRGB(50, 255, 100)
        _AimBtn.subLbl.Text        = "ON"
        _AimBtn.subLbl.TextColor3  = Color3.fromRGB(50, 255, 100)
    else
        _AimBtn.stroke.Color       = Color3.fromRGB(200, 50, 50)
        _AimBtn.mainLbl.TextColor3 = Color3.fromRGB(255, 80, 80)
        _AimBtn.subLbl.Text        = "OFF"
        _AimBtn.subLbl.TextColor3  = Color3.fromRGB(180, 180, 180)
    end
end

local vp0 = Camera.ViewportSize
_AimBtn = MakeFloatButton({
    size    = UDim2.new(0, 62, 0, 62),
    pos     = UDim2.new(0, vp0.X - 82, 0, vp0.Y - 220),
    bg      = Color3.fromRGB(15, 15, 25),
    stroke  = Color3.fromRGB(200, 50, 50),
    text    = "⊕",
    subtext = "AIM",
    textClr = Color3.fromRGB(255, 80, 80),
    onTap   = OnAimTap,
})
_AimFrame = _AimBtn.frame

-- ╔══════════════════════════════════════════════════════════╗
-- ║                 КНОПКА INVIS                             ║
-- ╚══════════════════════════════════════════════════════════╝

local _InvisBtn = nil

-- Настройка VisibleParts
local function SetupVisibleParts()
    VisibleParts = {}
    local char = LocalPlayer.Character
    if not char then return end
    for _, d in ipairs(char:GetDescendants()) do
        if d:IsA("BasePart") and d.Transparency == 0 then
            table.insert(VisibleParts, d)
        end
    end
end

local function ApplyInvis(state)
    IsInvisible = state
    local tr = state and S.Invis_Transparency or 0
    for _, part in ipairs(VisibleParts) do
        pcall(function() part.Transparency = tr end)
    end
end

-- Heartbeat невидимости (телепорт под карту и обратно)
local function StartInvisHeartbeat()
    if InvisHB then
        pcall(function() InvisHB:Disconnect() end)
        InvisHB = nil
    end
    InvisHB = RunService.Heartbeat:Connect(function()
        if not IsInvisible then return end
        local char = LocalPlayer.Character
        if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not hum or not root then return end

        local origCF     = root.CFrame
        local origOffset = hum.CameraOffset
        root.CFrame      = origCF * CFrame.new(0, -200000, 0)
        hum.CameraOffset = (origCF * CFrame.new(0, -200000, 0)):ToObjectSpace(
                               CFrame.new(origCF.Position)
                           ).Position
        RunService.RenderStepped:Wait()
        if root and root.Parent then
            root.CFrame      = origCF
            hum.CameraOffset = origOffset
        end
    end)
end

local function OnInvisTap()
    local newState = not IsInvisible
    ApplyInvis(newState)
    if newState then
        _InvisBtn.stroke.Color       = Color3.fromRGB(50, 200, 255)
        _InvisBtn.mainLbl.TextColor3 = Color3.fromRGB(50, 200, 255)
        _InvisBtn.subLbl.Text        = "ON"
        _InvisBtn.subLbl.TextColor3  = Color3.fromRGB(50, 200, 255)
    else
        _InvisBtn.stroke.Color       = Color3.fromRGB(100, 100, 200)
        _InvisBtn.mainLbl.TextColor3 = Color3.fromRGB(180, 180, 255)
        _InvisBtn.subLbl.Text        = "OFF"
        _InvisBtn.subLbl.TextColor3  = Color3.fromRGB(180, 180, 180)
    end
end

_InvisBtn = MakeFloatButton({
    size    = UDim2.new(0, 62, 0, 62),
    pos     = UDim2.new(0, vp0.X - 82, 0, vp0.Y - 295),
    bg      = Color3.fromRGB(15, 15, 25),
    stroke  = Color3.fromRGB(100, 100, 200),
    text    = "👁",
    subtext = "INVIS",
    textClr = Color3.fromRGB(180, 180, 255),
    onTap   = OnInvisTap,
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║              КНОПКА TELEPORT (1 кнопка, 2 режима)        ║
-- ╚══════════════════════════════════════════════════════════╝

local _TeleBtn     = nil
local TeleMode     = 1  -- 1 = "к пистолету", 2 = "назад"

-- Поиск пистолета в workspace
local function FindGunInWorld()
    local gunKeywords = {
        "gun", "pistol", "revolver", "supergun",
        "sheriff", "colt", "glock", "weapon"
    }
    local localChar = LocalPlayer.Character

    for _, obj in ipairs(workspace:GetDescendants()) do
        -- Пропускаем объекты внутри персонажей
        local inAnyChar = false
        for _, p in ipairs(Players:GetPlayers()) do
            if p.Character and obj:IsDescendantOf(p.Character) then
                inAnyChar = true break
            end
        end
        if inAnyChar then continue end

        local low = obj.Name:lower()
        local match = false
        for _, kw in ipairs(gunKeywords) do
            if low:find(kw) then match = true break end
        end

        if match then
            if obj:IsA("BasePart") or obj:IsA("MeshPart") or obj:IsA("UnionOperation") then
                return obj.Position
            elseif obj:IsA("Tool") then
                local handle = obj:FindFirstChild("Handle")
                if handle then return handle.Position end
            elseif obj:IsA("Model") then
                if obj.PrimaryPart then
                    return obj.PrimaryPart.Position
                end
                -- Ищем Handle внутри модели
                for _, child in ipairs(obj:GetDescendants()) do
                    if child:IsA("BasePart") and child.Name:lower():find("handle") then
                        return child.Position
                    end
                end
            end
        end
    end
    return nil
end

local function OnTeleTap()
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then
        Rayfield:Notify({
            Title   = "Ошибка",
            Content = "Персонаж не найден!",
            Duration= 3,
            Image   = "x",
        })
        return
    end

    if TeleMode == 1 then
        -- Режим 1: сохранить позицию → телепорт к пистолету
        SavedPosition = root.CFrame

        local gunPos = FindGunInWorld()
        if gunPos then
            GunPosition = gunPos
            root.CFrame = CFrame.new(gunPos + S.Teleport_Offset)
            TeleMode = 2

            -- Обновляем вид кнопки
            _TeleBtn.stroke.Color       = Color3.fromRGB(50, 255, 100)
            _TeleBtn.mainLbl.TextColor3 = Color3.fromRGB(50, 255, 100)
            _TeleBtn.mainLbl.Text       = "↩"
            _TeleBtn.subLbl.Text        = "BACK"
            _TeleBtn.subLbl.TextColor3  = Color3.fromRGB(50, 255, 100)

            Rayfield:Notify({
                Title   = "Телепорт",
                Content = "Перемещён к пистолету! Нажми снова для возврата.",
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
    elseif TeleMode == 2 then
        -- Режим 2: вернуться на старую позицию
        if SavedPosition then
            root.CFrame = SavedPosition
        end
        TeleMode = 1

        -- Сброс вида кнопки
        _TeleBtn.stroke.Color       = Color3.fromRGB(255, 200, 50)
        _TeleBtn.mainLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
        _TeleBtn.mainLbl.Text       = "⚡"
        _TeleBtn.subLbl.Text        = "TELE"
        _TeleBtn.subLbl.TextColor3  = Color3.fromRGB(200, 200, 200)

        Rayfield:Notify({
            Title   = "Возврат",
            Content = "Вернулся на прежнюю позицию!",
            Duration= 3,
            Image   = "rotate-ccw",
        })
    end
end

_TeleBtn = MakeFloatButton({
    size    = UDim2.new(0, 62, 0, 62),
    pos     = UDim2.new(0, vp0.X - 82, 0, vp0.Y - 370),
    bg      = Color3.fromRGB(15, 15, 25),
    stroke  = Color3.fromRGB(255, 200, 50),
    text    = "⚡",
    subtext = "TELE",
    textClr = Color3.fromRGB(255, 200, 50),
    onTap   = OnTeleTap,
})

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  ЛОГИКА РОЛЕЙ                            ║
-- ╚══════════════════════════════════════════════════════════╝

-- Ключевые слова для оружий
local MURD_WORDS = {"knife","ak47","ak-47","bat","sword","scythe","bokken","blade"}
local SHER_WORDS = {"gun","supergun","revolver","pistol","colt","glock"}

local function MatchWords(str, list)
    local low = str:lower()
    for _, w in ipairs(list) do
        if low:find(w) then return true end
    end
    return false
end

local function ScanContainerForRole(container)
    if not container then return nil end
    for _, item in ipairs(container:GetChildren()) do
        if item:IsA("Tool") or item:IsA("BasePart") or item:IsA("Model") then
            if MatchWords(item.Name, MURD_WORDS) then return Roles.Murderer end
            if MatchWords(item.Name, SHER_WORDS) then return Roles.Sheriff  end
        end
    end
    return nil
end

local function UpdateMyRole()
    local char = LocalPlayer.Character
    if not char then MyRole = Roles.Innocent return end

    -- Проверяем персонаж
    local r = ScanContainerForRole(char)
    if r then MyRole = r return end

    -- Проверяем backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    r = ScanContainerForRole(bp)
    if r then MyRole = r return end

    MyRole = Roles.Innocent
end

local function GetRole(player)
    if ForcedRoles[player] then return ForcedRoles[player] end

    local char = player.Character
    if not char then return Roles.Innocent end

    local r = ScanContainerForRole(char)
    if r then
        ForcedRoles[player] = r
        return r
    end

    local bp = player:FindFirstChild("Backpack")
    r = ScanContainerForRole(bp)
    if r then
        ForcedRoles[player] = r
        return r
    end

    return Roles.Innocent
end

local function ShouldTarget(targetRole)
    if MyRole == Roles.Murderer then
        return targetRole == Roles.Sheriff or targetRole == Roles.Innocent
    end
    if MyRole == Roles.Sheriff then
        return targetRole == Roles.Murderer
    end
    -- Innocent
    return targetRole == Roles.Murderer
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                   WALL CHECK                             ║
-- ╚══════════════════════════════════════════════════════════╝

local function IsVisible(targetPart)
    if not S.WallCheck then return true end
    local lc = LocalPlayer.Character
    if not lc then return false end
    local lr = lc:FindFirstChild("HumanoidRootPart")
    if not lr then return false end

    local origin    = lr.Position
    local direction = targetPart.Position - origin

    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {lc, targetPart.Parent}
    params.FilterType = Enum.RaycastFilterType.Exclude

    local result = workspace:Raycast(origin, direction, params)
    return result == nil
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║              ОРУЖИЕ В РУКАХ LocalPlayer                  ║
-- ╚══════════════════════════════════════════════════════════╝

local function GetHeldWeapon()
    local char = LocalPlayer.Character
    if not char then return nil, "none" end
    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Tool") then
            if MatchWords(item.Name, SHER_WORDS) then return item, "gun"   end
            if MatchWords(item.Name, MURD_WORDS) then return item, "melee" end
        end
    end
    return nil, "none"
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  АВТО-СТРЕЛЬБА                           ║
-- ╚══════════════════════════════════════════════════════════╝

local function TryAutoShoot(targetPlayer)
    if not S.AutoShoot then return end
    if tick() - lastShot < SHOT_CD then return end

    local weapon, wType = GetHeldWeapon()
    if not weapon or wType ~= "gun" then return end

    local char     = targetPlayer.Character
    local humanoid = char and char:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return end

    local targetPart = char:FindFirstChild(S.Target_Part)
                    or char:FindFirstChild("HumanoidRootPart")
    if not targetPart then return end
    if not IsVisible(targetPart) then return end

    lastShot = tick()

    pcall(function()
        local targetCF  = CFrame.new(targetPart.Position)
        local targetPos = targetPart.Position

        -- Попытка 1: найти RemoteEvent стрельбы
        for _, v in ipairs(ReplicatedStorage:GetDescendants()) do
            if v:IsA("RemoteEvent") then
                local low = v.Name:lower()
                if low:find("shoot") or low:find("fire") or
                   low:find("bullet") or low:find("gun") then
                    pcall(function()
                        v:FireServer(targetCF, targetPos)
                    end)
                    break
                end
            end
        end
    end)
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║              ПОИСК БЛИЖАЙШЕЙ ЦЕЛИ                        ║
-- ╚══════════════════════════════════════════════════════════╝

local function GetClosestTarget()
    local best     = nil
    local bestDist = S.FOV
    local center   = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

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
        if dist < bestDist then
            if IsVisible(targetPart) then
                bestDist = dist
                best     = player
            end
        end
    end

    return best
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                 AIMBOT ОБНОВЛЕНИЕ                        ║
-- ╚══════════════════════════════════════════════════════════╝

local function UpdateAimbot()
    -- Обновляем FOV круг
    FOVCircle.Radius   = S.FOV
    FOVCircle.Visible  = S.FOV_Visible
    FOVCircle.Position = Vector2.new(
        Camera.ViewportSize.X / 2,
        Camera.ViewportSize.Y / 2
    )

    if not S.Aimbot_Enabled then return end

    local _, wType  = GetHeldWeapon()
    local hasWeapon = wType ~= "none"

    -- Aim работает если: есть оружие в руках ИЛИ кнопка AIM активна
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

    -- Плавный поворот камеры к цели
    local lookCF   = CFrame.lookAt(Camera.CFrame.Position, targetPart.Position)
    Camera.CFrame  = Camera.CFrame:Lerp(lookCF, S.Smoothness)

    -- Авто-стрельба
    if hasWeapon then
        TryAutoShoot(target)
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                   ESP СИСТЕМА                            ║
-- ╚══════════════════════════════════════════════════════════╝

local function CreateESPData(player)
    local data = { lines = {} }

    -- 4 линии бокса
    for i = 1, 4 do
        local line        = Drawing.new("Line")
        line.Thickness    = S.ESP_Thickness
        line.Color        = Color3.fromRGB(255, 255, 255)
        line.Visible      = false
        line.Transparency = 1
        data.lines[i]     = line
    end

    -- Имя игрока
    data.nameTxt               = Drawing.new("Text")
    data.nameTxt.Size          = S.ESP_NameSize
    data.nameTxt.Center        = true
    data.nameTxt.Outline       = true
    data.nameTxt.OutlineColor  = Color3.fromRGB(0, 0, 0)
    data.nameTxt.Visible       = false
    data.nameTxt.Font          = Drawing.Fonts.UI

    -- Роль
    data.roleTxt               = Drawing.new("Text")
    data.roleTxt.Size          = S.ESP_RoleSize
    data.roleTxt.Center        = true
    data.roleTxt.Outline       = true
    data.roleTxt.OutlineColor  = Color3.fromRGB(0, 0, 0)
    data.roleTxt.Visible       = false
    data.roleTxt.Font          = Drawing.Fonts.UI

    ESPObjects[player] = data
    return data
end

local function DestroyESPData(player)
    local d = ESPObjects[player]
    if not d then return end
    for _, line in ipairs(d.lines) do
        pcall(function() line:Remove() end)
    end
    pcall(function() d.nameTxt:Remove() end)
    pcall(function() d.roleTxt:Remove() end)
    ESPObjects[player] = nil
end

local function SetESPVisibility(data, visible)
    for _, l in ipairs(data.lines) do l.Visible = visible end
    data.nameTxt.Visible = visible
    data.roleTxt.Visible = visible
end

local function CalcBoundingBox(char)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not head or not root then return nil end

    local topWorld    = head.Position + Vector3.new(0, 0.75, 0)
    local bottomWorld = root.Position - Vector3.new(0, 3.2, 0)

    local topSP, onTop       = Camera:WorldToViewportPoint(topWorld)
    local botSP, onBot       = Camera:WorldToViewportPoint(bottomWorld)

    if (not onTop and not onBot) then return nil end
    if topSP.Z < 0 then return nil end

    local height = math.abs(botSP.Y - topSP.Y)
    if height < 5 then return nil end  -- слишком маленький — игнорируем

    local width  = height * 0.55
    local cx     = topSP.X

    return {
        TL      = Vector2.new(cx - width/2, topSP.Y),
        TR      = Vector2.new(cx + width/2, topSP.Y),
        BL      = Vector2.new(cx - width/2, botSP.Y),
        BR      = Vector2.new(cx + width/2, botSP.Y),
        namePos = Vector2.new(cx, topSP.Y - 18),
        rolePos = Vector2.new(cx, botSP.Y + 3),
    }
end

local function RenderBox(data, box, color, thickness)
    local L = data.lines
    -- Верхняя линия
    L[1].From = box.TL; L[1].To = box.TR
    L[1].Color = color; L[1].Thickness = thickness
    -- Нижняя линия
    L[2].From = box.BL; L[2].To = box.BR
    L[2].Color = color; L[2].Thickness = thickness
    -- Левая линия
    L[3].From = box.TL; L[3].To = box.BL
    L[3].Color = color; L[3].Thickness = thickness
    -- Правая линия
    L[4].From = box.TR; L[4].To = box.BR
    L[4].Color = color; L[4].Thickness = thickness
end

-- ─────────────────────────────────────────────────
-- Главное обновление ESP
-- ─────────────────────────────────────────────────
local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end

        -- Создаём ESP если нет
        if not ESPObjects[player] then
            CreateESPData(player)
        end

        local data = ESPObjects[player]
        if not data then continue end

        local char     = player.Character
        local humanoid = char and char:FindFirstChildOfClass("Humanoid")
        local alive    = humanoid and humanoid.Health > 0

        -- Скрываем если не нужен
        if not S.ESP_Enabled or not char or not alive then
            SetESPVisibility(data, false)
            continue
        end

        local role  = GetRole(player)
        local show  = false
        local color = S.ESP_BoxColor_I
        local rText = ""

        if role == Roles.Murderer then
            show  = S.Show_Murderer
            color = S.ESP_BoxColor_M
            rText = "[ MURDERER ]"
        elseif role == Roles.Sheriff then
            show  = S.Show_Sheriff
            color = S.ESP_BoxColor_S
            rText = "[ SHERIFF ]"
        else
            show  = S.Show_Innocent
            color = S.ESP_BoxColor_I
            rText = ""
        end

        if not show then
            SetESPVisibility(data, false)
            continue
        end

        local box = CalcBoundingBox(char)
        if not box then
            SetESPVisibility(data, false)
            continue
        end

        -- Рендерим бокс
        RenderBox(data, box, color, S.ESP_Thickness)
        for _, l in ipairs(data.lines) do l.Visible = true end

        -- Имя
        data.nameTxt.Text     = player.Name
        data.nameTxt.Color    = color
        data.nameTxt.Position = box.namePos
        data.nameTxt.Visible  = true

        -- Роль (только для Murderer / Sheriff)
        if rText ~= "" then
            data.roleTxt.Text     = rText
            data.roleTxt.Color    = color
            data.roleTxt.Position = box.rolePos
            data.roleTxt.Visible  = true
        else
            data.roleTxt.Visible = false
        end
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║             СЛЕЖЕНИЕ ЗА ОРУЖИЕМ ИГРОКОВ                  ║
-- ╚══════════════════════════════════════════════════════════╝

local function WatchPlayerWeapon(player)
    local char = player.Character
    if not char then return end

    -- Сброс принудительной роли при новом персонаже
    ForcedRoles[player] = nil

    -- Когда достают оружие
    char.ChildAdded:Connect(function(child)
        if not child:IsA("Tool") then return end
        local low = child.Name:lower()
        if MatchWords(low, MURD_WORDS) then
            ForcedRoles[player] = Roles.Murderer
        elseif MatchWords(low, SHER_WORDS) then
            ForcedRoles[player] = Roles.Sheriff
        end
    end)

    -- Когда убирают в backpack — роль остаётся (уже записана в ForcedRoles)
    local bp = player:FindFirstChild("Backpack")
    if bp then
        bp.ChildAdded:Connect(function(child)
            if ForcedRoles[player] then return end  -- уже знаем
            if not child:IsA("Tool") then return end
            local low = child.Name:lower()
            if MatchWords(low, MURD_WORDS) then
                ForcedRoles[player] = Roles.Murderer
            elseif MatchWords(low, SHER_WORDS) then
                ForcedRoles[player] = Roles.Sheriff
            end
        end)
    end
end

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  ИНИЦИАЛИЗАЦИЯ                           ║
-- ╚══════════════════════════════════════════════════════════╝

-- Инвис setup
SetupVisibleParts()
StartInvisHeartbeat()

-- Существующие игроки
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LocalPlayer then
        CreateESPData(p)
        WatchPlayerWeapon(p)
        p.CharacterAdded:Connect(function()
            task.wait(0.5)
            WatchPlayerWeapon(p)
        end)
    end
end

-- Новые игроки
Players.PlayerAdded:Connect(function(p)
    CreateESPData(p)
    WatchPlayerWeapon(p)
    p.CharacterAdded:Connect(function()
        task.wait(0.5)
        DestroyESPData(p)
        CreateESPData(p)
        WatchPlayerWeapon(p)
    end)
end)

-- Уход игрока
Players.PlayerRemoving:Connect(function(p)
    DestroyESPData(p)
    ForcedRoles[p] = nil
end)

-- Respawn LocalPlayer
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.5)
    MyRole      = Roles.Innocent
    ForcedRoles = {}
    IsInvisible = false

    -- Сброс кнопки INVIS
    if _InvisBtn then
        _InvisBtn.stroke.Color       = Color3.fromRGB(100, 100, 200)
        _InvisBtn.mainLbl.TextColor3 = Color3.fromRGB(180, 180, 255)
        _InvisBtn.subLbl.Text        = "OFF"
    end

    -- Сброс кнопки TELE
    TeleMode = 1
    if _TeleBtn then
        _TeleBtn.stroke.Color       = Color3.fromRGB(255, 200, 50)
        _TeleBtn.mainLbl.TextColor3 = Color3.fromRGB(255, 200, 50)
        _TeleBtn.mainLbl.Text       = "⚡"
        _TeleBtn.subLbl.Text        = "TELE"
    end

    SetupVisibleParts()
    StartInvisHeartbeat()
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  ГЛАВНЫЙ ЦИКЛ                            ║
-- ╚══════════════════════════════════════════════════════════╝

RunService.RenderStepped:Connect(function()
    UpdateESP()
    UpdateAimbot()
end)

-- ╔══════════════════════════════════════════════════════════╗
-- ║                  УВЕДОМЛЕНИЕ                             ║
-- ╚══════════════════════════════════════════════════════════╝

task.wait(0.5)
Rayfield:Notify({
    Title   = "MM2 Script",
    Content = "Загружен! ⊕AIM  👁INVIS  ⚡TELE — кнопки справа",
    Duration= 6,
    Image   = "check",
})

print("[MM2] ✓ Скрипт запущен | AimActive=" .. tostring(AimActive))
