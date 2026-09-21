cat > /home/claude/illegal-soccer-hub/main.lua << 'ENDOFFILE'
--[[
    ╔══════════════════════════════════════════════════╗
    ║          ILLEGAL SOCCER HUB  v2.0               ║
    ║  loadstring(game:HttpGet("RAW_URL"))()           ║
    ║  Infinite Stamina: rainbow bar + size lock       ║
    ╚══════════════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LP    = Players.LocalPlayer
local PGui  = LP:WaitForChild("PlayerGui")
local Char  = LP.Character or LP.CharacterAdded:Wait()
local Hum   = Char:WaitForChild("Humanoid")

local Config = {
    InfiniteStamina = false,
    AutoSprint      = false,
    SprintSpeed     = 28,
}

-- ══════════════════════════════════════
--  RAINBOW COLORS — sama persis kayak
--  bar normal Illegal Soccer
-- ══════════════════════════════════════
local RAINBOW = {
    Color3.fromRGB(255, 80,  80),   -- merah
    Color3.fromRGB(255, 165, 0),    -- orange
    Color3.fromRGB(255, 255, 80),   -- kuning
    Color3.fromRGB(80,  255, 80),   -- hijau
    Color3.fromRGB(80,  200, 255),  -- biru muda
    Color3.fromRGB(160, 80,  255),  -- ungu
    Color3.fromRGB(255, 80,  200),  -- pink
}

-- ══════════════════════════════════════
--  FIND STAMINA BARS
--  Cari semua Frame di PlayerGui yang
--  merupakan bar stamina game ini
-- ══════════════════════════════════════
local function findStaminaBars()
    local bars = {}
    local keywords = {
        "stamina","energy","sprint","dash","bar","gauge",
        "sprintbar","staminabar","energybar","runbar","fill",
        "inner","progress","charge"
    }
    local ok, descs = pcall(function() return PGui:GetDescendants() end)
    if not ok then return bars end

    for _, v in ipairs(descs) do
        if v:IsA("Frame") or v:IsA("ImageLabel") then
            local n = v.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw, 1, true) then
                    -- Pastikan ini bar yang punya size scale (bukan container)
                    if v.Size.X.Scale > 0 or v.Size.Y.Scale > 0 then
                        table.insert(bars, v)
                        break
                    end
                end
            end
        end
    end

    -- Fallback: cari semua Frame kecil yang kemungkinan bar
    -- (size scale X antara 0.1-1.0, height kecil)
    if #bars == 0 then
        for _, v in ipairs(PGui:GetDescendants()) do
            if v:IsA("Frame") then
                local sx = v.Size.X.Scale
                local sy = v.Size.Y.Scale
                local ay = v.AbsoluteSize.Y
                -- Bar biasanya tipis (height < 20px) dan punya scale X
                if sx > 0.05 and sx <= 1.0 and ay > 2 and ay < 25 then
                    table.insert(bars, v)
                end
            end
        end
    end

    return bars
end

-- ══════════════════════════════════════
--  INFINITE STAMINA
--  1. Lock size bar ke penuh (Scale X = 1)
--  2. Animasi warna rainbow seperti KaliHub
--  3. Lock semua ValueBase/attribute stamina
-- ══════════════════════════════════════
local staminaConn
local colorConn
local rainbowIndex = 1
local rainbowT     = 0

local function enableInfiniteStamina()
    if staminaConn then staminaConn:Disconnect() end
    if colorConn   then colorConn:Disconnect()   end

    -- Scan bar sekali
    task.wait(0.2) -- tunggu sebentar supaya GUI fully loaded
    local bars = findStaminaBars()

    -- Juga scan ValueBase
    local valueBases = {}
    local roots = {Char, LP, LP:FindFirstChild("Backpack"), LP:FindFirstChild("PlayerScripts")}
    for _, root in ipairs(roots) do
        if root then
            local ok, descs = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, v in ipairs(descs) do
                    if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("DoubleConstrainedValue") then
                        local n = v.Name:lower()
                        if n:find("stamina") or n:find("energy") or n:find("sprint")
                        or n:find("dash") or n:find("fuel") or n:find("charge") then
                            table.insert(valueBases, {obj = v, max = v.Value > 0 and v.Value or 100})
                        end
                    end
                end
            end
        end
    end

    -- Attributes
    local attrTargets = {Char, LP}

    -- Rainbow color loop
    colorConn = RunService.Heartbeat:Connect(function(dt)
        rainbowT = rainbowT + dt * 2.5  -- kecepatan animasi rainbow

        local idx1 = math.floor(rainbowT % #RAINBOW) + 1
        local idx2 = (idx1 % #RAINBOW) + 1
        local alpha = rainbowT % 1
        local col = RAINBOW[idx1]:Lerp(RAINBOW[idx2], alpha)

        -- Apply ke semua bar yang ketemu
        for _, bar in ipairs(bars) do
            if bar and bar.Parent then
                pcall(function()
                    -- Lock ukuran ke penuh
                    bar.Size = UDim2.new(
                        1, bar.Size.X.Offset,
                        bar.Size.Y.Scale, bar.Size.Y.Offset
                    )
                    -- Warna rainbow
                    bar.BackgroundColor3 = col
                    bar.BackgroundTransparency = 0
                end)

                -- Lock UIGradient kalau ada
                local grad = bar:FindFirstChildOfClass("UIGradient")
                if grad then
                    pcall(function()
                        grad.Color = ColorSequence.new({
                            ColorSequenceKeypoint.new(0, col),
                            ColorSequenceKeypoint.new(0.5, col:Lerp(RAINBOW[idx2], 0.5)),
                            ColorSequenceKeypoint.new(1, RAINBOW[idx2]),
                        })
                    end)
                end
            end
        end
    end)

    -- Value lock Heartbeat terpisah (lebih jarang, hemat CPU)
    local lastValueCheck = 0
    staminaConn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastValueCheck < 0.05 then return end -- check 20x/detik
        lastValueCheck = now

        for _, entry in ipairs(valueBases) do
            if entry.obj and entry.obj.Parent then
                if entry.obj.Value > entry.max then entry.max = entry.obj.Value end
                if entry.obj.Value < entry.max then
                    pcall(function() entry.obj.Value = entry.max end)
                end
            end
        end

        for _, target in ipairs(attrTargets) do
            if target and target.Parent then
                local ok, attrs = pcall(function() return target:GetAttributes() end)
                if ok then
                    for name, val in pairs(attrs) do
                        if type(val) == "number" then
                            local n = name:lower()
                            if n:find("stamina") or n:find("energy") or n:find("sprint") then
                                local mx = target:GetAttribute("Max"..name)
                                        or target:GetAttribute(name.."Max") or val
                                if val < mx then
                                    pcall(function() target:SetAttribute(name, mx) end)
                                end
                            end
                        end
                    end
                end
            end
        end

        -- WalkSpeed guard
        if Config.AutoSprint and Hum and Hum.Parent then
            Hum.WalkSpeed = Config.SprintSpeed
        end
    end)
end

local function disableInfiniteStamina()
    if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
    if colorConn   then colorConn:Disconnect();   colorConn   = nil end
    rainbowT = 0
end

-- ══════════════════════════════════════
--  AUTO SPRINT
-- ══════════════════════════════════════
local sprintConn

local function enableAutoSprint()
    if sprintConn then sprintConn:Disconnect() end
    sprintConn = RunService.Heartbeat:Connect(function()
        if Hum and Hum.Parent then Hum.WalkSpeed = Config.SprintSpeed end
    end)
end

local function disableAutoSprint()
    if sprintConn then sprintConn:Disconnect(); sprintConn = nil end
    if Hum and Hum.Parent then Hum.WalkSpeed = 16 end
end

-- ══════════════════════════════════════
--  GUI
-- ══════════════════════════════════════
if PGui:FindFirstChild("ISHub") then PGui.ISHub:Destroy() end

local SG = Instance.new("ScreenGui")
SG.Name = "ISHub"; SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.DisplayOrder = 999; SG.IgnoreGuiInset = true
SG.Parent = PGui

local MF = Instance.new("Frame", SG)
MF.Size = UDim2.new(0, 272, 0, 220)
MF.Position = UDim2.new(0, 60, 0, 110)
MF.BackgroundColor3 = Color3.fromRGB(13,13,18)
MF.BorderSizePixel = 0; MF.ClipsDescendants = true; MF.ZIndex = 10
Instance.new("UICorner", MF).CornerRadius = UDim.new(0,10)

local STR = Instance.new("UIStroke", MF)
STR.Color = Color3.fromRGB(70,165,255); STR.Thickness = 1.5; STR.Transparency = 0.2

-- Rainbow accent line di bawah title
local AccentLine = Instance.new("Frame", MF)
AccentLine.Size = UDim2.new(1,0,0,2)
AccentLine.Position = UDim2.new(0,0,0,42)
AccentLine.BorderSizePixel = 0; AccentLine.ZIndex = 12

-- Animasi accent line rainbow
local accentT = 0
RunService.Heartbeat:Connect(function(dt)
    if not Config.InfiniteStamina then
        AccentLine.BackgroundColor3 = Color3.fromRGB(70,165,255)
        return
    end
    accentT = accentT + dt * 2.5
    local i1 = math.floor(accentT % #RAINBOW) + 1
    local i2 = (i1 % #RAINBOW) + 1
    AccentLine.BackgroundColor3 = RAINBOW[i1]:Lerp(RAINBOW[i2], accentT % 1)
end)

-- TitleBar
local TB = Instance.new("TextButton", MF)
TB.Size = UDim2.new(1,0,0,42)
TB.BackgroundColor3 = Color3.fromRGB(18,18,28)
TB.BorderSizePixel = 0; TB.Text = ""; TB.AutoButtonColor = false; TB.ZIndex = 11
Instance.new("UICorner", TB).CornerRadius = UDim.new(0,10)

local TL = Instance.new("TextLabel", TB)
TL.Text = "⚽  IS HUB v2.0"
TL.Size = UDim2.new(1,-50,1,0); TL.Position = UDim2.new(0,14,0,0)
TL.BackgroundTransparency = 1; TL.TextColor3 = Color3.fromRGB(70,165,255)
TL.TextSize = 13; TL.Font = Enum.Font.GothamBold
TL.TextXAlignment = Enum.TextXAlignment.Left; TL.ZIndex = 12

local MB = Instance.new("TextButton", TB)
MB.Text = "─"; MB.Size = UDim2.new(0,32,0,24)
MB.Position = UDim2.new(1,-38,0.5,-12)
MB.BackgroundColor3 = Color3.fromRGB(35,35,50)
MB.TextColor3 = Color3.fromRGB(180,180,180)
MB.TextSize = 13; MB.Font = Enum.Font.GothamBold
MB.BorderSizePixel = 0; MB.ZIndex = 13
Instance.new("UICorner", MB).CornerRadius = UDim.new(0,6)

-- Content
local CT = Instance.new("Frame", MF)
CT.Size = UDim2.new(1,-16,1,-50); CT.Position = UDim2.new(0,8,0,48)
CT.BackgroundTransparency = 1; CT.ZIndex = 11
local LL = Instance.new("UIListLayout", CT)
LL.SortOrder = Enum.SortOrder.LayoutOrder; LL.Padding = UDim.new(0,6)
Instance.new("UIPadding", CT).PaddingTop = UDim.new(0,4)

-- ══════════════════════════════════════
--  COMPONENTS
-- ══════════════════════════════════════
local AC  = Color3.fromRGB(70,165,255)
local BR  = Color3.fromRGB(20,20,30)
local TI  = TweenInfo.new(0.14, Enum.EasingStyle.Quad)

local function toggle(lbl, sub, key, onOn, onOff)
    local R = Instance.new("Frame", CT)
    R.Size = UDim2.new(1,0,0,50)
    R.BackgroundColor3 = BR; R.BorderSizePixel = 0; R.ZIndex = 12
    Instance.new("UICorner", R).CornerRadius = UDim.new(0,8)

    -- Rainbow border saat aktif
    local RS = Instance.new("UIStroke", R)
    RS.Thickness = 1.2; RS.Transparency = 1

    local L = Instance.new("TextLabel", R)
    L.Text = lbl; L.Size = UDim2.new(1,-58,0,22); L.Position = UDim2.new(0,12,0,6)
    L.BackgroundTransparency = 1; L.TextColor3 = Color3.fromRGB(215,215,215)
    L.TextSize = 13; L.Font = Enum.Font.GothamBold
    L.TextXAlignment = Enum.TextXAlignment.Left; L.ZIndex = 13

    local S = Instance.new("TextLabel", R)
    S.Text = sub; S.Size = UDim2.new(1,-58,0,16); S.Position = UDim2.new(0,12,0,28)
    S.BackgroundTransparency = 1; S.TextColor3 = Color3.fromRGB(75,75,100)
    S.TextSize = 10; S.Font = Enum.Font.Gotham
    S.TextXAlignment = Enum.TextXAlignment.Left; S.ZIndex = 13

    local P = Instance.new("Frame", R)
    P.Size = UDim2.new(0,40,0,20); P.Position = UDim2.new(1,-50,0.5,-10)
    P.BackgroundColor3 = Color3.fromRGB(40,40,55); P.BorderSizePixel = 0; P.ZIndex = 13
    Instance.new("UICorner", P).CornerRadius = UDim.new(1,0)

    local K = Instance.new("Frame", P)
    K.Size = UDim2.new(0,14,0,14); K.Position = UDim2.new(0,3,0.5,-7)
    K.BackgroundColor3 = Color3.fromRGB(110,110,130); K.BorderSizePixel = 0; K.ZIndex = 14
    Instance.new("UICorner", K).CornerRadius = UDim.new(1,0)

    -- Rainbow animasi di toggle pill saat stamina aktif
    if key == "InfiniteStamina" then
        local pillT = 0
        RunService.Heartbeat:Connect(function(dt)
            if not Config[key] then return end
            pillT = pillT + dt * 2.5
            local i1 = math.floor(pillT % #RAINBOW) + 1
            local i2 = (i1 % #RAINBOW) + 1
            local col = RAINBOW[i1]:Lerp(RAINBOW[i2], pillT % 1)
            P.BackgroundColor3 = col
            RS.Color = col; RS.Transparency = 0.3
        end)
    end

    local function vis(s)
        if key ~= "InfiniteStamina" or not s then
            TweenService:Create(P, TI, {BackgroundColor3 = s and AC or Color3.fromRGB(40,40,55)}):Play()
        end
        TweenService:Create(K, TI, {
            BackgroundColor3 = s and Color3.fromRGB(255,255,255) or Color3.fromRGB(110,110,130),
            Position = s and UDim2.new(0,23,0.5,-7) or UDim2.new(0,3,0.5,-7)
        }):Play()
        if not s then RS.Transparency = 1; P.BackgroundColor3 = Color3.fromRGB(40,40,55) end
    end
    vis(Config[key])

    local B = Instance.new("TextButton", R)
    B.Size = UDim2.new(1,0,1,0); B.BackgroundTransparency = 1
    B.Text = ""; B.ZIndex = 15
    B.MouseButton1Click:Connect(function()
        Config[key] = not Config[key]; vis(Config[key])
        if Config[key] then if onOn  then onOn()  end
        else                 if onOff then onOff() end end
    end)
end

local function slider(lbl, key, mn, mx, cb)
    local R = Instance.new("Frame", CT)
    R.Size = UDim2.new(1,0,0,50)
    R.BackgroundColor3 = BR; R.BorderSizePixel = 0; R.ZIndex = 12
    Instance.new("UICorner", R).CornerRadius = UDim.new(0,8)

    local L = Instance.new("TextLabel", R)
    L.Text = lbl; L.Size = UDim2.new(0.7,0,0,22); L.Position = UDim2.new(0,12,0,4)
    L.BackgroundTransparency = 1; L.TextColor3 = Color3.fromRGB(215,215,215)
    L.TextSize = 12; L.Font = Enum.Font.Gotham
    L.TextXAlignment = Enum.TextXAlignment.Left; L.ZIndex = 13

    local V = Instance.new("TextLabel", R)
    V.Text = tostring(Config[key])
    V.Size = UDim2.new(0.3,-12,0,22); V.Position = UDim2.new(0.7,0,0,4)
    V.BackgroundTransparency = 1; V.TextColor3 = AC
    V.TextSize = 12; V.Font = Enum.Font.GothamBold
    V.TextXAlignment = Enum.TextXAlignment.Right; V.ZIndex = 13

    local TR = Instance.new("Frame", R)
    TR.Size = UDim2.new(1,-24,0,6); TR.Position = UDim2.new(0,12,0,34)
    TR.BackgroundColor3 = Color3.fromRGB(35,35,50); TR.BorderSizePixel = 0; TR.ZIndex = 13
    Instance.new("UICorner", TR).CornerRadius = UDim.new(1,0)

    local sc = math.clamp((Config[key]-mn)/(mx-mn),0,1)
    local F = Instance.new("Frame", TR)
    F.Size = UDim2.new(sc,0,1,0); F.BackgroundColor3 = AC
    F.BorderSizePixel = 0; F.ZIndex = 14
    Instance.new("UICorner", F).CornerRadius = UDim.new(1,0)

    local KN = Instance.new("Frame", TR)
    KN.Size = UDim2.new(0,16,0,16); KN.AnchorPoint = Vector2.new(0.5,0.5)
    KN.Position = UDim2.new(sc,0,0.5,0)
    KN.BackgroundColor3 = Color3.fromRGB(240,240,255)
    KN.BorderSizePixel = 0; KN.ZIndex = 15
    Instance.new("UICorner", KN).CornerRadius = UDim.new(1,0)

    local drag = false
    local function upd(x)
        local rel = math.clamp((x-TR.AbsolutePosition.X)/math.max(TR.AbsoluteSize.X,1),0,1)
        local val = math.floor(mn+rel*(mx-mn))
        Config[key] = val; V.Text = tostring(val)
        F.Size = UDim2.new(rel,0,1,0); KN.Position = UDim2.new(rel,0,0.5,0)
        if cb then cb(val) end
    end
    TR.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = true; upd(i.Position.X) end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not drag then return end
        if i.UserInputType == Enum.UserInputType.MouseMove
        or i.UserInputType == Enum.UserInputType.Touch then upd(i.Position.X) end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then drag = false end
    end)
end

-- ══════════════════════════════════════
--  BUILD PANEL
-- ══════════════════════════════════════
toggle("Infinite Stamina", "Rainbow bar + lock penuh",
    "InfiniteStamina", enableInfiniteStamina, disableInfiniteStamina)

toggle("Auto Sprint", "WalkSpeed dikunci ke slider",
    "AutoSprint", enableAutoSprint, disableAutoSprint)

slider("Sprint Speed", "SprintSpeed", 16, 60, function(v)
    if Config.AutoSprint and Hum and Hum.Parent then Hum.WalkSpeed = v end
end)

-- ══════════════════════════════════════
--  DRAG — DELTA BASED, PC + ANDROID
-- ══════════════════════════════════════
local dragStart   = Vector2.new()
local frameOrigin = Vector2.new()
local dragging    = false

TB.InputBegan:Connect(function(i)
    if i.UserInputType ~= Enum.UserInputType.MouseButton1
    and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local mp = MB.AbsolutePosition; local ms = MB.AbsoluteSize
    if i.Position.X >= mp.X and i.Position.X <= mp.X+ms.X
    and i.Position.Y >= mp.Y and i.Position.Y <= mp.Y+ms.Y then return end
    dragging    = true
    dragStart   = Vector2.new(i.Position.X, i.Position.Y)
    frameOrigin = Vector2.new(MF.Position.X.Offset, MF.Position.Y.Offset)
end)

UserInputService.InputChanged:Connect(function(i)
    if not dragging then return end
    if i.UserInputType ~= Enum.UserInputType.MouseMove
    and i.UserInputType ~= Enum.UserInputType.Touch then return end
    local d  = Vector2.new(i.Position.X, i.Position.Y) - dragStart
    local vp = workspace.CurrentCamera.ViewportSize
    MF.Position = UDim2.new(0,
        math.clamp(frameOrigin.X+d.X, 0, vp.X-MF.AbsoluteSize.X), 0,
        math.clamp(frameOrigin.Y+d.Y, 0, vp.Y-MF.AbsoluteSize.Y))
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)

-- ══════════════════════════════════════
--  MINIMIZE
-- ══════════════════════════════════════
local FH, MH = 220, 42
local open = true

MB.MouseButton1Click:Connect(function()
    open = not open; CT.Visible = open
    TweenService:Create(MF, TweenInfo.new(0.16, Enum.EasingStyle.Quad),
        {Size = UDim2.new(0,272,0, open and FH or MH)}):Play()
end)

-- ══════════════════════════════════════
--  RESPAWN
-- ══════════════════════════════════════
LP.CharacterAdded:Connect(function(nc)
    Char = nc; Hum = nc:WaitForChild("Humanoid")
    task.wait(1)
    if Config.InfiniteStamina then enableInfiniteStamina() end
    if Config.AutoSprint      then enableAutoSprint()      end
end)

print("[ IS Hub v2.0 ] Rainbow stamina bar | Delta drag | No lag")
ENDOFFILE