--[[
    ╔══════════════════════════════════════════════════╗
    ║          ILLEGAL SOCCER HUB  v1.3               ║
    ║  loadstring(game:HttpGet("RAW_URL"))()           ║
    ║  Executor : Synapse X / KRNL / Fluxus / Delta   ║
    ║  Focus    : Infinite Energy + No Cooldown        ║
    ╚══════════════════════════════════════════════════╝
]]

-- ══════════════════════════════════════
--  SERVICES
-- ══════════════════════════════════════
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")
local Character   = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
local Humanoid    = Character:WaitForChild("Humanoid")

-- ══════════════════════════════════════
--  CONFIG
-- ══════════════════════════════════════
local Config = {
    AutoSprint     = false,
    InfiniteEnergy = false,
    NoCooldown     = false,
    SprintSpeed    = 28,
    NormalSpeed    = 16,
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local State = {
    HubOpen      = true,
    Dragging     = false,
    DragOffset   = Vector2.new(),
    sprintConn   = nil,
    energyConn   = nil,
    cooldownConn = nil,
    energyMax    = {},   -- cache: path → max value pernah terdeteksi
}

-- ══════════════════════════════════════
--  SCANNER UTILITY
-- ══════════════════════════════════════

-- Keyword yang mungkin dipakai Illegal Soccer untuk energy/stamina
local ENERGY_KEYWORDS = {
    "energy","stamina","sprint","dash","run","endurance",
    "fuel","power","charge","bar","mana","gauge","meter",
    "sprintbar","runbar","sprintenergy","currentenergy",
    "maxenergy","stambar","stam"
}

-- Keyword cooldown
local COOLDOWN_KEYWORDS = {
    "cooldown","cd","timer","delay","wait","recharge",
    "itemcooldown","skillcooldown","abilitycooldown",
    "lastused","nextuseTime","attackcooldown"
}

local function matchKeyword(name, keywords)
    local n = name:lower()
    for _, kw in ipairs(keywords) do
        if n:find(kw, 1, true) then return true end
    end
    return false
end

-- Kumpulkan semua ValueBase kandidat dari semua tempat
local function scanValueBases(keywords)
    local results = {}
    local seen = {}
    local targets = {
        Character,
        LocalPlayer,
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("Backpack"),
        LocalPlayer:FindFirstChild("PlayerScripts"),
    }
    for _, target in ipairs(targets) do
        if target then
            local ok, descendants = pcall(function() return target:GetDescendants() end)
            if ok then
                for _, v in ipairs(descendants) do
                    local path = v:GetFullName()
                    if not seen[path] then
                        if v:IsA("NumberValue") or v:IsA("IntValue")
                        or v:IsA("DoubleConstrainedValue") or v:IsA("IntConstrainedValue") then
                            if matchKeyword(v.Name, keywords) then
                                seen[path] = true
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

-- Kumpulkan semua attribute kandidat
local function scanAttributes(keywords)
    local results = {}
    local targets = {Character, LocalPlayer}
    for _, target in ipairs(targets) do
        if target then
            local ok, attrs = pcall(function() return target:GetAttributes() end)
            if ok and attrs then
                for attrName, attrVal in pairs(attrs) do
                    if type(attrVal) == "number" and matchKeyword(attrName, keywords) then
                        table.insert(results, {obj = target, name = attrName, val = attrVal})
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
--[[
    Strategy: Brute-lock setiap Heartbeat (~60x/detik).
    - Scan semua NumberValue/IntValue yang namanya cocok keyword energy.
    - Cache nilai MAX yang pernah terlihat per object.
    - Setiap tick, kalau nilai turun dari max → paksa balik ke max.
    - Sama untuk attribute.
    - Juga scan DoubleConstrainedValue.MaxValue untuk tau batas atasnya.
]]

local function enableInfiniteEnergy()
    if State.energyConn then State.energyConn:Disconnect() end
    State.energyMax = {}

    -- Pre-scan untuk seed max cache
    local objs = scanValueBases(ENERGY_KEYWORDS)
    for _, obj in ipairs(objs) do
        local path = obj:GetFullName()
        local maxVal = obj.Value
        -- Kalau DoubleConstrainedValue, pakai MaxValue
        if obj:IsA("DoubleConstrainedValue") or obj:IsA("IntConstrainedValue") then
            maxVal = obj.MaxValue
        end
        State.energyMax[path] = math.max(State.energyMax[path] or 0, maxVal)
    end

    State.energyConn = RunService.Heartbeat:Connect(function()
        -- Lock ValueBase
        local objs2 = scanValueBases(ENERGY_KEYWORDS)
        for _, obj in ipairs(objs2) do
            local path = obj:GetFullName()
            local currentMax = State.energyMax[path] or 0

            -- Update cache kalau ketemu nilai lebih besar
            local trueMax = obj.Value
            if obj:IsA("DoubleConstrainedValue") or obj:IsA("IntConstrainedValue") then
                trueMax = obj.MaxValue
            end
            if trueMax > currentMax then
                currentMax = trueMax
                State.energyMax[path] = currentMax
            end

            -- Paksa nilai = max
            if obj.Value < currentMax and currentMax > 0 then
                pcall(function() obj.Value = currentMax end)
            end
        end

        -- Lock attributes
        local attrs = scanAttributes(ENERGY_KEYWORDS)
        for _, entry in ipairs(attrs) do
            local key = entry.obj:GetFullName() .. "::" .. entry.name
            local currentMax = State.energyMax[key] or 0

            -- Cek apakah ada pasangan "Max" attribute
            local maxAttrVal = entry.obj:GetAttribute("Max" .. entry.name)
                            or entry.obj:GetAttribute(entry.name .. "Max")
                            or entry.obj:GetAttribute("max" .. entry.name)
            if maxAttrVal and type(maxAttrVal) == "number" and maxAttrVal > currentMax then
                currentMax = maxAttrVal
                State.energyMax[key] = currentMax
            end
            if entry.val > currentMax then
                currentMax = entry.val
                State.energyMax[key] = currentMax
            end

            if entry.val < currentMax and currentMax > 0 then
                pcall(function() entry.obj:SetAttribute(entry.name, currentMax) end)
            end
        end
    end)
end

local function disableInfiniteEnergy()
    if State.energyConn then State.energyConn:Disconnect(); State.energyConn = nil end
    State.energyMax = {}
end

-- ══════════════════════════════════════
--  FEATURE: NO COOLDOWN
-- ══════════════════════════════════════
--[[
    Strategy: Brute-lock semua ValueBase + attribute yang namanya cocok
    keyword cooldown → paksa ke 0 setiap Heartbeat.
    Cooldown = 0 berarti item bisa langsung dipakai lagi.
]]

local function enableNoCooldown()
    if State.cooldownConn then State.cooldownConn:Disconnect() end

    State.cooldownConn = RunService.Heartbeat:Connect(function()
        -- Lock ValueBase cooldown → 0
        local objs = scanValueBases(COOLDOWN_KEYWORDS)
        for _, obj in ipairs(objs) do
            if obj.Value ~= 0 then
                pcall(function() obj.Value = 0 end)
            end
        end

        -- Lock attribute cooldown → 0
        local attrs = scanAttributes(COOLDOWN_KEYWORDS)
        for _, entry in ipairs(attrs) do
            if entry.val ~= 0 then
                pcall(function() entry.obj:SetAttribute(entry.name, 0) end)
            end
        end

        -- Extra: scan semua NumberValue di Character yang nilainya
        -- positif kecil (< 10) dan turun — kemungkinan cooldown timer
        local ok, chars = pcall(function() return Character:GetDescendants() end)
        if ok then
            for _, v in ipairs(chars) do
                if (v:IsA("NumberValue") or v:IsA("IntValue")) then
                    -- Nilai antara 0.01 dan 10 kemungkinan timer cooldown
                    if v.Value > 0 and v.Value <= 10 then
                        local n = v.Name:lower()
                        -- Skip energy values
                        if not matchKeyword(n, ENERGY_KEYWORDS) then
                            pcall(function() v.Value = 0 end)
                        end
                    end
                end
            end
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
--  GUI
-- ══════════════════════════════════════
if PlayerGui:FindFirstChild("ISHub") then
    PlayerGui:FindFirstChild("ISHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ISHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 280, 0, 260)
MainFrame.Position         = UDim2.new(0, 60, 0, 80)
MainFrame.BackgroundColor3 = Color3.fromRGB(13, 13, 18)
MainFrame.BorderSizePixel  = 0
MainFrame.ClipsDescendants = true
MainFrame.Parent           = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color        = Color3.fromRGB(70, 165, 255)
Stroke.Thickness    = 1.5
Stroke.Transparency = 0.25

-- Title Bar
local TitleBar = Instance.new("Frame", MainFrame)
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel  = 0
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Text               = "⚽  IS HUB v1.3"
TitleLabel.Size               = UDim2.new(1, -48, 1, 0)
TitleLabel.Position           = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3         = Color3.fromRGB(70, 165, 255)
TitleLabel.TextSize           = 13
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left

local MinBtn = Instance.new("TextButton", TitleBar)
MinBtn.Text             = "─"
MinBtn.Size             = UDim2.new(0, 30, 0, 22)
MinBtn.Position         = UDim2.new(1, -36, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
MinBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
MinBtn.TextSize         = 13
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

-- Status bar — nampilin berapa object ketemu
local StatusBar = Instance.new("TextLabel", MainFrame)
StatusBar.Size            = UDim2.new(1, -16, 0, 16)
StatusBar.Position        = UDim2.new(0, 8, 0, 42)
StatusBar.BackgroundTransparency = 1
StatusBar.TextColor3      = Color3.fromRGB(60, 60, 85)
StatusBar.TextSize        = 10
StatusBar.Font            = Enum.Font.Gotham
StatusBar.Text            = "Scanning..."
StatusBar.TextXAlignment  = Enum.TextXAlignment.Left

-- Update status count
local function updateStatus()
    local eCount = #scanValueBases(ENERGY_KEYWORDS) + #scanAttributes(ENERGY_KEYWORDS)
    local cCount = #scanValueBases(COOLDOWN_KEYWORDS) + #scanAttributes(COOLDOWN_KEYWORDS)
    StatusBar.Text = "Energy objects: " .. eCount .. "  |  Cooldown objects: " .. cCount
end
task.spawn(updateStatus)

-- Content
local Content = Instance.new("Frame", MainFrame)
Content.Size             = UDim2.new(1, -16, 1, -68)
Content.Position         = UDim2.new(0, 8, 0, 62)
Content.BackgroundTransparency = 1
Content.BorderSizePixel  = 0

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 6)

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingTop = UDim.new(0, 4)

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local ACCENT  = Color3.fromRGB(70, 165, 255)
local BG_ROW  = Color3.fromRGB(20, 20, 30)
local TEXT_HI = Color3.fromRGB(215, 215, 215)
local tweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad)

local function makeToggle(labelText, descText, configKey, onEnable, onDisable)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, 0, 0, 50)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Text           = labelText
    Label.Size           = UDim2.new(1, -54, 0, 22)
    Label.Position       = UDim2.new(0, 12, 0, 6)
    Label.BackgroundTransparency = 1
    Label.TextColor3     = TEXT_HI
    Label.TextSize       = 13
    Label.Font           = Enum.Font.GothamBold
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Desc = Instance.new("TextLabel", Row)
    Desc.Text            = descText
    Desc.Size            = UDim2.new(1, -54, 0, 16)
    Desc.Position        = UDim2.new(0, 12, 0, 28)
    Desc.BackgroundTransparency = 1
    Desc.TextColor3      = Color3.fromRGB(90, 90, 110)
    Desc.TextSize        = 10
    Desc.Font            = Enum.Font.Gotham
    Desc.TextXAlignment  = Enum.TextXAlignment.Left

    local Pill = Instance.new("Frame", Row)
    Pill.Size             = UDim2.new(0, 40, 0, 20)
    Pill.Position         = UDim2.new(1, -50, 0.5, -10)
    Pill.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    Pill.BorderSizePixel  = 0
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size             = UDim2.new(0, 14, 0, 14)
    Knob.Position         = UDim2.new(0, 3, 0.5, -7)
    Knob.BackgroundColor3 = Color3.fromRGB(120, 120, 140)
    Knob.BorderSizePixel  = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function setVisual(state)
        TweenService:Create(Pill, tweenInfo, {
            BackgroundColor3 = state and ACCENT or Color3.fromRGB(40,40,55)
        }):Play()
        TweenService:Create(Knob, tweenInfo, {
            BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(120,120,140),
            Position         = state and UDim2.new(0,23,0.5,-7) or UDim2.new(0,3,0.5,-7)
        }):Play()
    end

    setVisual(Config[configKey])

    local Btn = Instance.new("TextButton", Row)
    Btn.Size               = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Text               = ""

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        setVisual(Config[configKey])
        if Config[configKey] then
            if onEnable then onEnable() end
        else
            if onDisable then onDisable() end
        end
        task.spawn(updateStatus)
    end)

    return Row
end

local function makeSlider(labelText, configKey, minVal, maxVal, callback)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, 0, 0, 52)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Text           = labelText
    Label.Size           = UDim2.new(0.7, 0, 0, 22)
    Label.Position       = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.TextColor3     = TEXT_HI
    Label.TextSize       = 12
    Label.Font           = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Text          = tostring(Config[configKey])
    ValLbl.Size          = UDim2.new(0.3, -12, 0, 22)
    ValLbl.Position      = UDim2.new(0.7, 0, 0, 4)
    ValLbl.BackgroundTransparency = 1
    ValLbl.TextColor3    = ACCENT
    ValLbl.TextSize      = 12
    ValLbl.Font          = Enum.Font.GothamBold
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame", Row)
    Track.Size           = UDim2.new(1, -24, 0, 4)
    Track.Position       = UDim2.new(0, 12, 0, 34)
    Track.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
    Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local initScale = math.clamp((Config[configKey] - minVal) / (maxVal - minVal), 0, 1)

    local Fill = Instance.new("Frame", Track)
    Fill.Size            = UDim2.new(initScale, 0, 1, 0)
    Fill.BackgroundColor3 = ACCENT
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Track)
    Knob.Size            = UDim2.new(0, 14, 0, 14)
    Knob.AnchorPoint     = Vector2.new(0.5, 0.5)
    Knob.Position        = UDim2.new(initScale, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex          = 4
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function update(inputX)
        local rel = math.clamp(
            (inputX - Track.AbsolutePosition.X) / math.max(Track.AbsoluteSize.X, 1),
            0, 1
        )
        local val = math.floor(minVal + rel * (maxVal - minVal))
        Config[configKey] = val
        ValLbl.Text      = tostring(val)
        Fill.Size        = UDim2.new(rel, 0, 1, 0)
        Knob.Position    = UDim2.new(rel, 0, 0.5, 0)
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

    return Row
end

-- ══════════════════════════════════════
--  BUILD PANEL
-- ══════════════════════════════════════

makeToggle(
    "Infinite Energy",
    "Lock energy bar ke max setiap frame",
    "InfiniteEnergy",
    enableInfiniteEnergy,
    disableInfiniteEnergy
)

makeToggle(
    "No Cooldown",
    "Reset semua cooldown item ke 0",
    "NoCooldown",
    enableNoCooldown,
    disableNoCooldown
)

makeToggle(
    "Auto Sprint",
    "WalkSpeed dikunci ke nilai slider",
    "AutoSprint",
    enableAutoSprint,
    disableAutoSprint
)

makeSlider("Sprint Speed", "SprintSpeed", 16, 60, function(val)
    if Config.AutoSprint and Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = val
    end
end)

-- ══════════════════════════════════════
--  DRAG — PC + ANDROID TOUCH
-- ══════════════════════════════════════
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        State.Dragging  = true
        State.DragOffset = Vector2.new(
            i.Position.X - MainFrame.AbsolutePosition.X,
            i.Position.Y - MainFrame.AbsolutePosition.Y
        )
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if not State.Dragging then return end
    if i.UserInputType == Enum.UserInputType.MouseMove
    or i.UserInputType == Enum.UserInputType.Touch then
        local vp  = workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(i.Position.X - State.DragOffset.X, 0, vp.X - MainFrame.AbsoluteSize.X)
        local newY = math.clamp(i.Position.Y - State.DragOffset.Y, 0, vp.Y - MainFrame.AbsoluteSize.Y)
        MainFrame.Position = UDim2.new(0, newX, 0, newY)
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1
    or i.UserInputType == Enum.UserInputType.Touch then
        State.Dragging = false
    end
end)

-- ══════════════════════════════════════
--  MINIMIZE
-- ══════════════════════════════════════
local FULL_H = 260
local MINI_H = 40

local function toggleHub()
    State.HubOpen   = not State.HubOpen
    Content.Visible  = State.HubOpen
    StatusBar.Visible = State.HubOpen
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
    State.energyMax = {}

    task.wait(0.5)
    if Config.AutoSprint     then enableAutoSprint() end
    if Config.InfiniteEnergy then enableInfiniteEnergy() end
    if Config.NoCooldown     then enableNoCooldown() end
    task.spawn(updateStatus)
end)

-- ══════════════════════════════════════
--  DONE
-- ══════════════════════════════════════
print("[ IS Hub v1.3 ] Loaded — Infinite Energy + No Cooldown | Touch drag ON")
