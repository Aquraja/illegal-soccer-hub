--[[
    ╔══════════════════════════════════════════════════╗
    ║          ILLEGAL SOCCER HUB  v1.4               ║
    ║  loadstring(game:HttpGet("RAW_URL"))()           ║
    ║  Fix v1.4: GUI visual lock + touch drag fix      ║
    ╚══════════════════════════════════════════════════╝
]]

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")

local Config = {
    InfiniteEnergy = false,
    NoCooldown     = false,
    AutoSprint     = false,
    SprintSpeed    = 28,
    NormalSpeed    = 16,
}

local State = {
    HubOpen      = true,
    Dragging     = false,
    DragStart    = Vector2.new(),
    FrameStart   = Vector2.new(),
    sprintConn   = nil,
    energyConn   = nil,
    cooldownConn = nil,
}

-- ══════════════════════════════════════
--  DEBUG LOGGER
-- ══════════════════════════════════════
local logLines = {}
local function log(msg)
    table.insert(logLines, 1, msg)
    if #logLines > 6 then table.remove(logLines) end
end

-- ══════════════════════════════════════
--  SCANNER — cari semua GUI bar di PlayerGui
-- ══════════════════════════════════════
local ENERGY_KEYWORDS = {
    "energy","stamina","sprint","dash","fuel","power",
    "charge","bar","gauge","meter","stam","run","endurance"
}
local COOLDOWN_KEYWORDS = {
    "cooldown","cd","timer","delay","wait","recharge","ability","skill","item"
}

local function matchAny(name, keywords)
    local n = name:lower()
    for _, kw in ipairs(keywords) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

-- Cari Frame/ImageLabel yang merupakan bar (Size.X.Scale berubah saat dipakai)
local function findUIBars(keywords)
    local results = {}
    local seen = {}
    for _, obj in ipairs(PlayerGui:GetDescendants()) do
        local path = obj:GetFullName()
        if not seen[path] then
            seen[path] = true
            -- Cari Frame atau ImageLabel yang namanya cocok keyword
            if (obj:IsA("Frame") or obj:IsA("ImageLabel") or obj:IsA("TextLabel")) then
                if matchAny(obj.Name, keywords) then
                    table.insert(results, obj)
                end
            end
            -- Cari juga parent dengan nama cocok yang punya child bernama "Fill"/"Bar"/"Inner"
            if obj:IsA("Frame") and matchAny(obj.Name, keywords) then
                for _, child in ipairs(obj:GetChildren()) do
                    if child:IsA("Frame") or child:IsA("ImageLabel") then
                        local cn = child.Name:lower()
                        if cn:find("fill") or cn:find("bar") or cn:find("inner") or cn:find("progress") then
                            table.insert(results, child)
                        end
                    end
                end
            end
        end
    end
    return results
end

-- Cari semua NumberValue/IntValue di seluruh game (ValueBase)
local function findValueBases(keywords)
    local results = {}
    local seen = {}
    local searchRoots = {
        Character,
        LocalPlayer,
        PlayerGui,
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("PlayerScripts"),
        workspace,
    }
    for _, root in ipairs(searchRoots) do
        if root then
            local ok, descs = pcall(function() return root:GetDescendants() end)
            if ok then
                for _, v in ipairs(descs) do
                    local path = v:GetFullName()
                    if not seen[path] then
                        seen[path] = true
                        if v:IsA("NumberValue") or v:IsA("IntValue")
                        or v:IsA("DoubleConstrainedValue") or v:IsA("IntConstrainedValue") then
                            if matchAny(v.Name, keywords) then
                                table.insert(results, v)
                            end
                        end
                    end
                end
            end
        end
    end
    return results
end

-- Cari attribute di semua instance
local function findAttributes(keywords)
    local results = {}
    local targets = {Character, LocalPlayer, workspace}
    for _, target in ipairs(targets) do
        if target then
            local ok, attrs = pcall(function() return target:GetAttributes() end)
            if ok and attrs then
                for name, val in pairs(attrs) do
                    if type(val) == "number" and matchAny(name, keywords) then
                        table.insert(results, {obj = target, name = name, val = val})
                    end
                end
            end
        end
    end
    return results
end

-- ══════════════════════════════════════
--  FEATURE: INFINITE ENERGY
-- ══════════════════════════════════════
local energyMaxCache = {}

local function enableInfiniteEnergy()
    if State.energyConn then State.energyConn:Disconnect() end
    energyMaxCache = {}
    local foundAnything = false

    State.energyConn = RunService.Heartbeat:Connect(function()
        local touched = 0

        -- 1. Lock ValueBase
        for _, v in ipairs(findValueBases(ENERGY_KEYWORDS)) do
            local path = v:GetFullName()
            local trueMax = v.Value
            if v:IsA("DoubleConstrainedValue") or v:IsA("IntConstrainedValue") then
                trueMax = v.MaxValue
            end
            if trueMax > (energyMaxCache[path] or 0) then
                energyMaxCache[path] = trueMax
            end
            local mx = energyMaxCache[path] or 100
            if v.Value < mx then
                pcall(function() v.Value = mx end)
                touched = touched + 1
            end
        end

        -- 2. Lock attributes
        for _, entry in ipairs(findAttributes(ENERGY_KEYWORDS)) do
            local key = entry.obj:GetFullName() .. "::" .. entry.name
            local mx = entry.obj:GetAttribute("Max"..entry.name)
                    or entry.obj:GetAttribute(entry.name.."Max")
                    or energyMaxCache[key] or entry.val
            if entry.val > (energyMaxCache[key] or 0) then
                energyMaxCache[key] = entry.val
            end
            mx = energyMaxCache[key] or 100
            if entry.val < mx then
                pcall(function() entry.obj:SetAttribute(entry.name, mx) end)
                touched = touched + 1
            end
        end

        -- 3. Lock GUI bar — paksa Size.X.Scale = 1 (bar full)
        for _, bar in ipairs(findUIBars(ENERGY_KEYWORDS)) do
            -- Kalau bar punya Scale X yang bukan 1, paksa ke 1
            if bar:IsA("Frame") or bar:IsA("ImageLabel") then
                if bar.Size.X.Scale < 0.99 and bar.Size.X.Scale > 0 then
                    pcall(function()
                        bar.Size = UDim2.new(1, bar.Size.X.Offset, bar.Size.Y.Scale, bar.Size.Y.Offset)
                    end)
                    touched = touched + 1
                end
            end
        end

        -- 4. Paksa WalkSpeed tetap sprint kalau auto sprint aktif
        if Config.AutoSprint and Humanoid and Humanoid.Parent then
            Humanoid.WalkSpeed = Config.SprintSpeed
        end

        if touched > 0 and not foundAnything then
            foundAnything = true
            log("Energy: locked " .. touched .. " object(s)")
        end
    end)
end

local function disableInfiniteEnergy()
    if State.energyConn then State.energyConn:Disconnect(); State.energyConn = nil end
    energyMaxCache = {}
end

-- ══════════════════════════════════════
--  FEATURE: NO COOLDOWN
-- ══════════════════════════════════════
local function enableNoCooldown()
    if State.cooldownConn then State.cooldownConn:Disconnect() end

    State.cooldownConn = RunService.Heartbeat:Connect(function()
        local touched = 0

        -- 1. Lock ValueBase cooldown → 0
        for _, v in ipairs(findValueBases(COOLDOWN_KEYWORDS)) do
            if v.Value > 0 then
                pcall(function() v.Value = 0 end)
                touched = touched + 1
            end
        end

        -- 2. Lock attribute cooldown → 0
        for _, entry in ipairs(findAttributes(COOLDOWN_KEYWORDS)) do
            if entry.val > 0 then
                pcall(function() entry.obj:SetAttribute(entry.name, 0) end)
                touched = touched + 1
            end
        end

        -- 3. Sweep semua NumberValue di Character yang nilainya 0 < v <= 15
        --    dan bukan energy keyword — kemungkinan cooldown timer
        if Character then
            local ok, descs = pcall(function() return Character:GetDescendants() end)
            if ok then
                for _, v in ipairs(descs) do
                    if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                        if v.Value > 0 and v.Value <= 15 then
                            if not matchAny(v.Name, ENERGY_KEYWORDS) then
                                pcall(function() v.Value = 0 end)
                                touched = touched + 1
                            end
                        end
                    end
                end
            end
        end

        -- 4. GUI cooldown overlay — cari Frame cooldown yang nutup tombol item
        --    biasanya punya BackgroundTransparency < 1 saat cooldown aktif
        for _, bar in ipairs(findUIBars(COOLDOWN_KEYWORDS)) do
            if bar:IsA("Frame") then
                -- Paksa transparency = 1 (invisible = cooldown keliatan habis)
                if bar.BackgroundTransparency < 0.95 then
                    pcall(function() bar.BackgroundTransparency = 1 end)
                    touched = touched + 1
                end
                -- Kalau size-based cooldown (bar menyusut), paksa ke 0
                if bar.Size.Y.Scale > 0.01 and bar.Size.Y.Scale < 1 then
                    pcall(function()
                        bar.Size = UDim2.new(bar.Size.X.Scale, bar.Size.X.Offset, 0, bar.Size.Y.Offset)
                    end)
                    touched = touched + 1
                end
            end
        end

        if touched > 0 then
            log("Cooldown: nulled " .. touched .. " object(s)")
        end
    end)
end

local function disableNoCooldown()
    if State.cooldownConn then State.cooldownConn:Disconnect(); State.cooldownConn = nil end
end

-- ══════════════════════════════════════
--  FEATURE: AUTO SPRINT
-- ══════════════════════════════════════
local function enableAutoSprint()
    if State.sprintConn then State.sprintConn:Disconnect() end
    State.sprintConn = RunService.Heartbeat:Connect(function()
        if Humanoid and Humanoid.Parent then
            Humanoid.WalkSpeed = Config.SprintSpeed
        end
    end)
end

local function disableAutoSprint()
    if State.sprintConn then State.sprintConn:Disconnect(); State.sprintConn = nil end
    if Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = Config.NormalSpeed
    end
end

-- ══════════════════════════════════════
--  GUI BUILD
-- ══════════════════════════════════════
if PlayerGui:FindFirstChild("ISHub") then
    PlayerGui:FindFirstChild("ISHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name              = "ISHub"
ScreenGui.ResetOnSpawn      = false
ScreenGui.ZIndexBehavior    = Enum.ZIndexBehavior.Sibling
ScreenGui.DisplayOrder      = 999
ScreenGui.IgnoreGuiInset    = true
ScreenGui.Parent            = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name              = "MainFrame"
MainFrame.Size              = UDim2.new(0, 280, 0, 290)
MainFrame.Position          = UDim2.new(0, 60, 0, 100)
MainFrame.BackgroundColor3  = Color3.fromRGB(13, 13, 18)
MainFrame.BorderSizePixel   = 0
MainFrame.ClipsDescendants  = true
MainFrame.ZIndex            = 100
MainFrame.Parent            = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color        = Color3.fromRGB(70, 165, 255)
Stroke.Thickness    = 1.5
Stroke.Transparency = 0.2

-- Title Bar — ini yang di-drag
local TitleBar = Instance.new("TextButton", MainFrame)
TitleBar.Name               = "TitleBar"
TitleBar.Size               = UDim2.new(1, 0, 0, 42)
TitleBar.Position           = UDim2.new(0, 0, 0, 0)
TitleBar.BackgroundColor3   = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel    = 0
TitleBar.Text               = ""
TitleBar.ZIndex             = 101
TitleBar.AutoButtonColor    = false
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Text              = "⚽  IS HUB v1.4"
TitleLabel.Size              = UDim2.new(1, -50, 1, 0)
TitleLabel.Position          = UDim2.new(0, 14, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3        = Color3.fromRGB(70, 165, 255)
TitleLabel.TextSize          = 13
TitleLabel.Font              = Enum.Font.GothamBold
TitleLabel.TextXAlignment    = Enum.TextXAlignment.Left
TitleLabel.ZIndex            = 102

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Text              = "─"
MinBtn.Size              = UDim2.new(0, 32, 0, 24)
MinBtn.Position          = UDim2.new(1, -38, 0.5, -12)
MinBtn.BackgroundColor3  = Color3.fromRGB(35, 35, 50)
MinBtn.TextColor3        = Color3.fromRGB(180, 180, 180)
MinBtn.TextSize          = 13
MinBtn.Font              = Enum.Font.GothamBold
MinBtn.BorderSizePixel   = 0
MinBtn.ZIndex            = 103
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Status
local StatusBar = Instance.new("TextLabel", MainFrame)
StatusBar.Size              = UDim2.new(1, -16, 0, 14)
StatusBar.Position          = UDim2.new(0, 8, 0, 44)
StatusBar.BackgroundTransparency = 1
StatusBar.TextColor3        = Color3.fromRGB(55, 55, 80)
StatusBar.TextSize          = 9
StatusBar.Font              = Enum.Font.Gotham
StatusBar.Text              = "Waiting for match..."
StatusBar.TextXAlignment    = Enum.TextXAlignment.Left
StatusBar.ZIndex            = 101

-- Content
local Content = Instance.new("Frame", MainFrame)
Content.Size                = UDim2.new(1, -16, 1, -70)
Content.Position            = UDim2.new(0, 8, 0, 62)
Content.BackgroundTransparency = 1
Content.ZIndex              = 101

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.SortOrder        = Enum.SortOrder.LayoutOrder
ListLayout.Padding          = UDim.new(0, 6)

Instance.new("UIPadding", Content).PaddingTop = UDim.new(0, 2)

-- Log label di bawah
local LogLabel = Instance.new("TextLabel", MainFrame)
LogLabel.Size               = UDim2.new(1, -16, 0, 30)
LogLabel.Position           = UDim2.new(0, 8, 1, -34)
LogLabel.BackgroundTransparency = 1
LogLabel.TextColor3         = Color3.fromRGB(50, 50, 70)
LogLabel.TextSize           = 9
LogLabel.Font               = Enum.Font.Gotham
LogLabel.Text               = ""
LogLabel.TextXAlignment     = Enum.TextXAlignment.Left
LogLabel.TextYAlignment     = Enum.TextYAlignment.Top
LogLabel.TextWrapped        = true
LogLabel.ZIndex             = 101

-- Update log setiap 0.5 detik
RunService.Heartbeat:Connect(function()
    if #logLines > 0 then
        LogLabel.Text = table.concat(logLines, "\n")
    end
end)

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local ACCENT   = Color3.fromRGB(70, 165, 255)
local BG_ROW   = Color3.fromRGB(20, 20, 30)
local TEXT_HI  = Color3.fromRGB(215, 215, 215)
local TI       = TweenInfo.new(0.14, Enum.EasingStyle.Quad)

local function makeToggle(label, desc, configKey, onEnable, onDisable)
    local Row = Instance.new("Frame", Content)
    Row.Size              = UDim2.new(1, 0, 0, 50)
    Row.BackgroundColor3  = BG_ROW
    Row.BorderSizePixel   = 0
    Row.ZIndex            = 102
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text              = label
    Lbl.Size              = UDim2.new(1, -60, 0, 22)
    Lbl.Position          = UDim2.new(0, 12, 0, 6)
    Lbl.BackgroundTransparency = 1
    Lbl.TextColor3        = TEXT_HI
    Lbl.TextSize          = 13
    Lbl.Font              = Enum.Font.GothamBold
    Lbl.TextXAlignment    = Enum.TextXAlignment.Left
    Lbl.ZIndex            = 103

    local Sub = Instance.new("TextLabel", Row)
    Sub.Text              = desc
    Sub.Size              = UDim2.new(1, -60, 0, 16)
    Sub.Position          = UDim2.new(0, 12, 0, 28)
    Sub.BackgroundTransparency = 1
    Sub.TextColor3        = Color3.fromRGB(80, 80, 105)
    Sub.TextSize          = 10
    Sub.Font              = Enum.Font.Gotham
    Sub.TextXAlignment    = Enum.TextXAlignment.Left
    Sub.ZIndex            = 103

    local Pill = Instance.new("Frame", Row)
    Pill.Size             = UDim2.new(0, 40, 0, 20)
    Pill.Position         = UDim2.new(1, -50, 0.5, -10)
    Pill.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Pill.BorderSizePixel  = 0
    Pill.ZIndex           = 103
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size             = UDim2.new(0, 14, 0, 14)
    Knob.Position         = UDim2.new(0, 3, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(110, 110, 130)
    Knob.BorderSizePixel  = 0
    Knob.ZIndex           = 104
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function setVisual(s)
        TweenService:Create(Pill, TI, {BackgroundColor3 = s and ACCENT or Color3.fromRGB(40,40,55)}):Play()
        TweenService:Create(Knob, TI, {
            BackgroundColor3 = s and Color3.fromRGB(255,255,255) or Color3.fromRGB(110,110,130),
            Position         = s and UDim2.new(0,23,0.5,-7) or UDim2.new(0,3,0.5,-7)
        }):Play()
    end

    setVisual(Config[configKey])

    -- Tombol transparan full row supaya mudah di-tap di Android
    local Btn = Instance.new("TextButton", Row)
    Btn.Size              = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Text              = ""
    Btn.ZIndex            = 105

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        setVisual(Config[configKey])
        if Config[configKey] then
            if onEnable then onEnable() end
        else
            if onDisable then onDisable() end
        end
    end)
end

local function makeSlider(label, configKey, minVal, maxVal, callback)
    local Row = Instance.new("Frame", Content)
    Row.Size              = UDim2.new(1, 0, 0, 52)
    Row.BackgroundColor3  = BG_ROW
    Row.BorderSizePixel   = 0
    Row.ZIndex            = 102
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Lbl = Instance.new("TextLabel", Row)
    Lbl.Text              = label
    Lbl.Size              = UDim2.new(0.7, 0, 0, 22)
    Lbl.Position          = UDim2.new(0, 12, 0, 4)
    Lbl.BackgroundTransparency = 1
    Lbl.TextColor3        = TEXT_HI
    Lbl.TextSize          = 12
    Lbl.Font              = Enum.Font.Gotham
    Lbl.TextXAlignment    = Enum.TextXAlignment.Left
    Lbl.ZIndex            = 103

    local Val = Instance.new("TextLabel", Row)
    Val.Text              = tostring(Config[configKey])
    Val.Size              = UDim2.new(0.3, -12, 0, 22)
    Val.Position          = UDim2.new(0.7, 0, 0, 4)
    Val.BackgroundTransparency = 1
    Val.TextColor3        = ACCENT
    Val.TextSize          = 12
    Val.Font              = Enum.Font.GothamBold
    Val.TextXAlignment    = Enum.TextXAlignment.Right
    Val.ZIndex            = 103

    local Track = Instance.new("Frame", Row)
    Track.Size            = UDim2.new(1, -24, 0, 6)
    Track.Position        = UDim2.new(0, 12, 0, 34)
    Track.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Track.BorderSizePixel = 0
    Track.ZIndex          = 103
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local sc = math.clamp((Config[configKey]-minVal)/(maxVal-minVal),0,1)

    local Fill = Instance.new("Frame", Track)
    Fill.Size             = UDim2.new(sc, 0, 1, 0)
    Fill.BackgroundColor3 = ACCENT
    Fill.BorderSizePixel  = 0
    Fill.ZIndex           = 104
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Track)
    Knob.Size             = UDim2.new(0, 16, 0, 16)
    Knob.AnchorPoint      = Vector2.new(0.5, 0.5)
    Knob.Position         = UDim2.new(sc, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240,240,255)
    Knob.BorderSizePixel  = 0
    Knob.ZIndex           = 105
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function update(x)
        local rel = math.clamp((x - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X,1), 0, 1)
        local val = math.floor(minVal + rel*(maxVal-minVal))
        Config[configKey] = val
        Val.Text          = tostring(val)
        Fill.Size         = UDim2.new(rel, 0, 1, 0)
        Knob.Position     = UDim2.new(rel, 0, 0.5, 0)
        if callback then callback(val) end
    end

    Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if not dragging then return end
        if i.UserInputType == Enum.UserInputType.MouseMove
        or i.UserInputType == Enum.UserInputType.Touch then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ══════════════════════════════════════
--  BUILD PANEL
-- ══════════════════════════════════════
makeToggle("Infinite Energy", "Lock energy bar visual + value", "InfiniteEnergy",
    enableInfiniteEnergy, disableInfiniteEnergy)

makeToggle("No Cooldown", "Reset semua cooldown ke 0", "NoCooldown",
    enableNoCooldown, disableNoCooldown)

makeToggle("Auto Sprint", "WalkSpeed dikunci ke slider", "AutoSprint",
    enableAutoSprint, disableAutoSprint)

makeSlider("Sprint Speed", "SprintSpeed", 16, 60, function(val)
    if Config.AutoSprint and Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = val
    end
end)

-- ══════════════════════════════════════
--  DRAG — ANDROID TOUCH FIX
--  Pakai TitleBar sebagai TextButton,
--  track posisi touch langsung di InputChanged
-- ══════════════════════════════════════
TitleBar.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        -- Cek bukan tap di MinBtn
        local minBtnPos = MinBtn.AbsolutePosition
        local minBtnSize = MinBtn.AbsoluteSize
        local ix, iy = input.Position.X, input.Position.Y
        local inMin = ix >= minBtnPos.X and ix <= minBtnPos.X + minBtnSize.X
                   and iy >= minBtnPos.Y and iy <= minBtnPos.Y + minBtnSize.Y
        if not inMin then
            State.Dragging   = true
            State.DragStart  = Vector2.new(input.Position.X, input.Position.Y)
            State.FrameStart = Vector2.new(MainFrame.Position.X.Offset, MainFrame.Position.Y.Offset)
        end
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if not State.Dragging then return end
    if input.UserInputType == Enum.UserInputType.MouseMove
    or input.UserInputType == Enum.UserInputType.Touch then
        local delta  = Vector2.new(input.Position.X, input.Position.Y) - State.DragStart
        local vp     = workspace.CurrentCamera.ViewportSize
        local newX   = math.clamp(State.FrameStart.X + delta.X, 0, vp.X - MainFrame.AbsoluteSize.X)
        local newY   = math.clamp(State.FrameStart.Y + delta.Y, 0, vp.Y - MainFrame.AbsoluteSize.Y)
        MainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        State.Dragging = false
    end
end)

-- ══════════════════════════════════════
--  MINIMIZE
-- ══════════════════════════════════════
local FULL_H = 290
local MINI_H = 42

local function toggleHub()
    State.HubOpen    = not State.HubOpen
    Content.Visible  = State.HubOpen
    StatusBar.Visible = State.HubOpen
    LogLabel.Visible = State.HubOpen
    TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 280, 0, State.HubOpen and FULL_H or MINI_H)
    }):Play()
end

MinBtn.MouseButton1Click:Connect(toggleHub)

-- ══════════════════════════════════════
--  RESPAWN
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = newChar:WaitForChild("Humanoid")
    energyMaxCache = {}
    task.wait(1)
    if Config.AutoSprint     then enableAutoSprint() end
    if Config.InfiniteEnergy then enableInfiniteEnergy() end
    if Config.NoCooldown     then enableNoCooldown() end
    log("Respawned — features reattached")
end)

-- ══════════════════════════════════════
--  STATUS UPDATE LOOP
-- ══════════════════════════════════════
task.spawn(function()
    while true do
        task.wait(2)
        local eCount = #findValueBases(ENERGY_KEYWORDS) + #findAttributes(ENERGY_KEYWORDS) + #findUIBars(ENERGY_KEYWORDS)
        local cCount = #findValueBases(COOLDOWN_KEYWORDS) + #findAttributes(COOLDOWN_KEYWORDS) + #findUIBars(COOLDOWN_KEYWORDS)
        StatusBar.Text = "Energy hooks: " .. eCount .. "  |  Cooldown hooks: " .. cCount
    end
end)

print("[ IS Hub v1.4 ] Touch drag fixed | GUI bar lock added | DisplayOrder 999")
