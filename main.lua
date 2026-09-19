--[[
    ╔══════════════════════════════════════════════════╗
    ║          ILLEGAL SOCCER HUB  v1.1               ║
    ║  loadstring(game:HttpGet("RAW_URL"))()           ║
    ║  Executor : Synapse X / KRNL / Fluxus / Delta   ║
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
    -- Movement
    AutoSprint     = false,
    InfiniteEnergy = false,
    SprintSpeed    = 28,
    NormalSpeed    = 16,

    -- Visual
    BallESP        = false,
    PlayerESP      = false,

    -- Auto Item
    AutoJetpack       = false,
    AutoRocketPunch   = false,
    AutoFreezeGun     = false,
    AutoShotgun       = false,
    AutoGrapple       = false,
    ItemScanInterval  = 0.08,   -- detik antar scan (lebih kecil = lebih responsif)

    -- Hub
    HubKey = Enum.KeyCode.RightShift,
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local State = {
    HubOpen      = true,
    Dragging     = false,
    DragOffset   = Vector2.new(),
    Connections  = {},
    ESPBall      = {},
    ESPPlayers   = {},
}

-- ══════════════════════════════════════
--  UTILITY
-- ══════════════════════════════════════
local function push(conn)
    table.insert(State.Connections, conn)
end

local function cleanConnections()
    for _, c in ipairs(State.Connections) do
        if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
    end
    State.Connections = {}
end

local function getEnergyObject()
    local targets = {Character, LocalPlayer:FindFirstChild("PlayerGui")}
    for _, target in ipairs(targets) do
        if target then
            for _, v in ipairs(target:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") then
                    local n = v.Name:lower()
                    if n:find("energy") or n:find("stamina") or n:find("sprint") then
                        return v
                    end
                end
            end
        end
    end
    return nil
end

-- Cari tool di karakter berdasarkan keyword nama
local function findTool(keywords)
    for _, obj in ipairs(Character:GetChildren()) do
        if obj:IsA("Tool") or obj:IsA("LocalScript") or obj:IsA("Script") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then return obj end
            end
        end
    end
    -- Fallback: cari di Backpack
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, obj in ipairs(bp:GetChildren()) do
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then return obj end
            end
        end
    end
    return nil
end

-- Activate tool: equip lalu activate
local function activateTool(tool)
    if not tool then return end
    -- Equip
    if tool.Parent ~= Character then
        local humanoid = Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:EquipTool(tool) end
    end
    task.wait(0.05)
    -- Fire activation
    local activateEvent = tool:FindFirstChild("Activate")
                       or tool:FindFirstChild("OnActivate")
                       or tool:FindFirstChild("UseItem")
    if activateEvent and activateEvent:IsA("RemoteEvent") then
        activateEvent:FireServer()
    else
        -- Fallback: simulate click
        tool:Activate()
    end
end

-- ══════════════════════════════════════
--  GUI BUILD
-- ══════════════════════════════════════
if PlayerGui:FindFirstChild("ISHub") then
    PlayerGui:FindFirstChild("ISHub"):Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name           = "ISHub"
ScreenGui.ResetOnSpawn   = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent         = PlayerGui

-- Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 290, 0, 420)
MainFrame.Position         = UDim2.new(0, 80, 0, 80)
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
local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Text               = "⚽  ILLEGAL SOCCER HUB  v1.1"
TitleLabel.Size               = UDim2.new(1, -48, 1, 0)
TitleLabel.Position           = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3         = Color3.fromRGB(70, 165, 255)
TitleLabel.TextSize           = 12
TitleLabel.Font               = Enum.Font.GothamBold
TitleLabel.TextXAlignment     = Enum.TextXAlignment.Left
TitleLabel.Parent             = TitleBar

local MinBtn = Instance.new("TextButton")
MinBtn.Text             = "─"
MinBtn.Size             = UDim2.new(0, 30, 0, 22)
MinBtn.Position         = UDim2.new(1, -36, 0, 9)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 50)
MinBtn.TextColor3       = Color3.fromRGB(180, 180, 180)
MinBtn.TextSize         = 13
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.BorderSizePixel  = 0
MinBtn.Parent           = TitleBar
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 6)

local KeyHint = Instance.new("TextLabel")
KeyHint.Text            = "[RShift] Toggle Panel"
KeyHint.Size            = UDim2.new(1, 0, 0, 16)
KeyHint.Position        = UDim2.new(0, 0, 0, 42)
KeyHint.BackgroundTransparency = 1
KeyHint.TextColor3      = Color3.fromRGB(60, 60, 85)
KeyHint.TextSize        = 10
KeyHint.Font            = Enum.Font.Gotham
KeyHint.Parent          = MainFrame

-- Scrollable Content
local Content = Instance.new("ScrollingFrame")
Content.Name                  = "Content"
Content.Size                  = UDim2.new(1, -16, 1, -68)
Content.Position              = UDim2.new(0, 8, 0, 60)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness    = 3
Content.ScrollBarImageColor3  = Color3.fromRGB(70, 165, 255)
Content.BorderSizePixel       = 0
Content.CanvasSize            = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize   = Enum.AutomaticSize.Y
Content.Parent                = MainFrame

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 5)

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingTop    = UDim.new(0, 4)
ContentPad.PaddingBottom = UDim.new(0, 10)

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local ACCENT  = Color3.fromRGB(70, 165, 255)
local BG_ROW  = Color3.fromRGB(20, 20, 30)
local BG_SEC  = Color3.fromRGB(23, 23, 36)
local TEXT_HI = Color3.fromRGB(215, 215, 215)
local TEXT_DIM = Color3.fromRGB(70, 70, 95)

local function makeSection(title)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 24)
    f.BackgroundColor3 = BG_SEC
    f.BorderSizePixel  = 0
    f.Parent           = Content
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 6)

    local lbl = Instance.new("TextLabel", f)
    lbl.Text           = "  ▸  " .. title:upper()
    lbl.Size           = UDim2.new(1, 0, 1, 0)
    lbl.BackgroundTransparency = 1
    lbl.TextColor3     = ACCENT
    lbl.TextSize       = 10
    lbl.Font           = Enum.Font.GothamBold
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return f
end

local tweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad)

local function makeToggle(labelText, configKey, onEnable, onDisable)
    local Row = Instance.new("Frame")
    Row.Size             = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
    Row.Parent           = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Text           = labelText
    Label.Size           = UDim2.new(1, -54, 1, 0)
    Label.Position       = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.TextColor3     = TEXT_HI
    Label.TextSize       = 12
    Label.Font           = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Pill = Instance.new("Frame", Row)
    Pill.Size             = UDim2.new(0, 36, 0, 18)
    Pill.Position         = UDim2.new(1, -46, 0.5, -9)
    Pill.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
    Pill.BorderSizePixel  = 0
    Instance.new("UICorner", Pill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Pill)
    Knob.Size             = UDim2.new(0, 12, 0, 12)
    Knob.Position         = UDim2.new(0, 3, 0.5, -6)
    Knob.BackgroundColor3 = Color3.fromRGB(130, 130, 150)
    Knob.BorderSizePixel  = 0
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local function setVisual(state)
        TweenService:Create(Pill, tweenInfo, {
            BackgroundColor3 = state and ACCENT or Color3.fromRGB(45,45,60)
        }):Play()
        TweenService:Create(Knob, tweenInfo, {
            BackgroundColor3 = state and Color3.fromRGB(255,255,255) or Color3.fromRGB(130,130,150),
            Position         = state and UDim2.new(0,21,0.5,-6) or UDim2.new(0,3,0.5,-6)
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
    end)

    return Row
end

local function makeSlider(labelText, configKey, minVal, maxVal, callback)
    local Row = Instance.new("Frame")
    Row.Size             = UDim2.new(1, 0, 0, 52)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
    Row.Parent           = Content
    Instance.new("UICorner", Row).CornerRadius = UDim.new(0, 8)

    local Label = Instance.new("TextLabel", Row)
    Label.Text           = labelText
    Label.Size           = UDim2.new(0.72, 0, 0, 22)
    Label.Position       = UDim2.new(0, 12, 0, 4)
    Label.BackgroundTransparency = 1
    Label.TextColor3     = TEXT_HI
    Label.TextSize       = 12
    Label.Font           = Enum.Font.Gotham
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local ValLbl = Instance.new("TextLabel", Row)
    ValLbl.Text          = tostring(Config[configKey])
    ValLbl.Size          = UDim2.new(0.28, -12, 0, 22)
    ValLbl.Position      = UDim2.new(0.72, 0, 0, 4)
    ValLbl.BackgroundTransparency = 1
    ValLbl.TextColor3    = ACCENT
    ValLbl.TextSize      = 12
    ValLbl.Font          = Enum.Font.GothamBold
    ValLbl.TextXAlignment = Enum.TextXAlignment.Right

    local Track = Instance.new("Frame", Row)
    Track.Size           = UDim2.new(1, -24, 0, 4)
    Track.Position       = UDim2.new(0, 12, 0, 34)
    Track.BackgroundColor3 = Color3.fromRGB(38, 38, 52)
    Track.BorderSizePixel = 0
    Instance.new("UICorner", Track).CornerRadius = UDim.new(1, 0)

    local initScale = (Config[configKey] - minVal) / (maxVal - minVal)

    local Fill = Instance.new("Frame", Track)
    Fill.Size            = UDim2.new(initScale, 0, 1, 0)
    Fill.BackgroundColor3 = ACCENT
    Fill.BorderSizePixel = 0
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Knob = Instance.new("Frame", Track)
    Knob.Size            = UDim2.new(0, 12, 0, 12)
    Knob.AnchorPoint     = Vector2.new(0.5, 0.5)
    Knob.Position        = UDim2.new(initScale, 0, 0.5, 0)
    Knob.BackgroundColor3 = Color3.fromRGB(240, 240, 255)
    Knob.BorderSizePixel = 0
    Knob.ZIndex          = 4
    Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

    local dragging = false

    local function update(inputX)
        local rel = math.clamp((inputX - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
        local val = math.floor(minVal + rel * (maxVal - minVal))
        Config[configKey] = val
        ValLbl.Text      = tostring(val)
        Fill.Size        = UDim2.new(rel, 0, 1, 0)
        Knob.Position    = UDim2.new(rel, 0, 0.5, 0)
        if callback then callback(val) end
    end

    Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true; update(i.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMove then
            update(i.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    return Row
end

-- ══════════════════════════════════════
--  FEATURE IMPLEMENTATIONS
-- ══════════════════════════════════════

-- >> MOVEMENT <<
local sprintConn

local function enableAutoSprint()
    sprintConn = RunService.Heartbeat:Connect(function()
        if Humanoid and Humanoid.Parent then
            Humanoid.WalkSpeed = Config.SprintSpeed
        end
    end)
end

local function disableAutoSprint()
    if sprintConn then sprintConn:Disconnect(); sprintConn = nil end
    if Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = Config.NormalSpeed
    end
end

local energyConn

local function enableInfiniteEnergy()
    local obj = getEnergyObject()
    if obj then
        local mx = obj.Value
        energyConn = obj.Changed:Connect(function(v)
            if v < mx then obj.Value = mx end
        end)
    else
        energyConn = RunService.Heartbeat:Connect(function()
            for _, name in ipairs({"Energy","Stamina","SprintEnergy","CurrentEnergy","StaminaValue"}) do
                for _, target in ipairs({Character, LocalPlayer}) do
                    if target:GetAttribute(name) ~= nil then
                        local mx = target:GetAttribute("Max"..name)
                                or target:GetAttribute(name.."Max") or 100
                        target:SetAttribute(name, mx)
                    end
                end
            end
        end)
    end
end

local function disableInfiniteEnergy()
    if energyConn then energyConn:Disconnect(); energyConn = nil end
end

-- >> ESP <<
local function clearESP(tbl)
    for _, obj in ipairs(tbl) do
        if obj and obj.Parent then obj:Destroy() end
    end
    for k in pairs(tbl) do tbl[k] = nil end
end

local function applyBallESP()
    clearESP(State.ESPBall)
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local n = obj.Name:lower()
            if n:find("ball") or n:find("soccer") or n:find("bola") then
                local sel = Instance.new("SelectionBox")
                sel.Adornee            = obj
                sel.Color3             = Color3.fromRGB(255, 215, 0)
                sel.LineThickness      = 0.05
                sel.SurfaceTransparency = 0.85
                sel.SurfaceColor3      = Color3.fromRGB(255, 215, 0)
                sel.Parent             = workspace

                local bb = Instance.new("BillboardGui")
                bb.Size        = UDim2.new(0, 60, 0, 20)
                bb.StudsOffset = Vector3.new(0, 3.2, 0)
                bb.AlwaysOnTop = true
                bb.Adornee     = obj
                bb.Parent      = workspace

                local lbl = Instance.new("TextLabel", bb)
                lbl.Size               = UDim2.new(1,0,1,0)
                lbl.BackgroundTransparency = 1
                lbl.Text               = "⚽ BALL"
                lbl.TextColor3         = Color3.fromRGB(255, 215, 0)
                lbl.TextSize           = 13
                lbl.Font               = Enum.Font.GothamBold

                table.insert(State.ESPBall, sel)
                table.insert(State.ESPBall, bb)
            end
        end
    end
end

local function applyPlayerESP()
    clearESP(State.ESPPlayers)
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local root = plr.Character:FindFirstChild("HumanoidRootPart")
            if root then
                local bb = Instance.new("BillboardGui")
                bb.Size        = UDim2.new(0, 90, 0, 44)
                bb.StudsOffset = Vector3.new(0, 3.5, 0)
                bb.AlwaysOnTop = true
                bb.Adornee     = root
                bb.Parent      = workspace

                local nameL = Instance.new("TextLabel", bb)
                nameL.Size             = UDim2.new(1,0,0.5,0)
                nameL.BackgroundTransparency = 1
                nameL.Text             = plr.DisplayName
                nameL.TextColor3       = Color3.fromRGB(255, 80, 80)
                nameL.TextSize         = 12
                nameL.Font             = Enum.Font.GothamBold

                local distL = Instance.new("TextLabel", bb)
                distL.Size             = UDim2.new(1,0,0.5,0)
                distL.Position         = UDim2.new(0,0,0.5,0)
                distL.BackgroundTransparency = 1
                distL.TextColor3       = Color3.fromRGB(190,190,190)
                distL.TextSize         = 10
                distL.Font             = Enum.Font.Gotham

                local distConn = RunService.Heartbeat:Connect(function()
                    if root and root.Parent and Character and Character:FindFirstChild("HumanoidRootPart") then
                        local d = math.floor((root.Position - Character.HumanoidRootPart.Position).Magnitude)
                        distL.Text = d .. " studs"
                    end
                end)
                push(distConn)
                table.insert(State.ESPPlayers, bb)
            end
        end
    end
end

-- >> AUTO ITEM USE <<
--[[
    Illegal Soccer items dikenali dari nama Tool/LocalScript di Character.
    Script scan setiap ItemScanInterval detik.
    Mapping keyword → Config key yang mengontrolnya.
]]
local ITEM_MAP = {
    { keys = {"jetpack","jet"},              configKey = "AutoJetpack"     },
    { keys = {"rocketpunch","rocket","punch"}, configKey = "AutoRocketPunch" },
    { keys = {"freezegun","freeze"},         configKey = "AutoFreezeGun"   },
    { keys = {"shotgun"},                    configKey = "AutoShotgun"     },
    { keys = {"grapple","hook","grappling"}, configKey = "AutoGrapple"     },
}

-- Cooldown tracker biar ga spam activate setiap frame
local itemLastUsed = {}

local function scanAndUseItems()
    local now = tick()
    for _, entry in ipairs(ITEM_MAP) do
        if Config[entry.configKey] then
            local tool = findTool(entry.keys)
            if tool then
                local lastUse = itemLastUsed[entry.configKey] or 0
                -- 0.5 detik cooldown antar aktivasi untuk avoid spam flag
                if now - lastUse >= 0.5 then
                    itemLastUsed[entry.configKey] = now
                    task.spawn(function()
                        activateTool(tool)
                    end)
                end
            end
        end
    end
end

local itemScanConn

local function startItemScan()
    if itemScanConn then return end
    itemScanConn = RunService.Heartbeat:Connect(function()
        -- Throttle pakai tick biar ga tiap frame
        if tick() % Config.ItemScanInterval < 0.016 then
            scanAndUseItems()
        end
    end)
end

local function stopItemScan()
    if itemScanConn then
        itemScanConn:Disconnect()
        itemScanConn = nil
    end
end

local function anyItemAutoEnabled()
    return Config.AutoJetpack or Config.AutoRocketPunch
        or Config.AutoFreezeGun or Config.AutoShotgun
        or Config.AutoGrapple
end

-- ══════════════════════════════════════
--  BUILD PANEL CONTENT
-- ══════════════════════════════════════

-- ── MOVEMENT ──
makeSection("Movement")

makeToggle("Auto Sprint", "AutoSprint",
    enableAutoSprint,
    disableAutoSprint
)

makeToggle("Infinite Energy", "InfiniteEnergy",
    enableInfiniteEnergy,
    disableInfiniteEnergy
)

makeSlider("Sprint Speed", "SprintSpeed", 16, 60, function(val)
    if Config.AutoSprint and Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = val
    end
end)

-- ── VISUAL ──
makeSection("Visual / ESP")

makeToggle("Ball ESP", "BallESP",
    function()
        applyBallESP()
        push(workspace.DescendantAdded:Connect(function()
            if Config.BallESP then task.wait(0.1); applyBallESP() end
        end))
    end,
    function() clearESP(State.ESPBall) end
)

makeToggle("Player ESP", "PlayerESP",
    function()
        applyPlayerESP()
        push(Players.PlayerAdded:Connect(function()
            if Config.PlayerESP then task.wait(1); applyPlayerESP() end
        end))
    end,
    function() clearESP(State.ESPPlayers); cleanConnections() end
)

-- ── AUTO ITEM ──
makeSection("Auto Item Use")

-- Helper toggle factory biar ga repeat code
local function makeItemToggle(label, configKey)
    makeToggle(label, configKey,
        function()
            if anyItemAutoEnabled() then startItemScan() end
        end,
        function()
            if not anyItemAutoEnabled() then stopItemScan() end
        end
    )
end

makeItemToggle("Auto Jetpack",      "AutoJetpack")
makeItemToggle("Auto Rocket Punch", "AutoRocketPunch")
makeItemToggle("Auto Freeze Gun",   "AutoFreezeGun")
makeItemToggle("Auto Shotgun",      "AutoShotgun")
makeItemToggle("Auto Grapple Hook", "AutoGrapple")

makeSlider("Item Scan Speed (ms)", "ItemScanInterval", 0.05, 0.5, function(val)
    -- slider dalam 0.05-0.5 detik; label tampil sebagai ms
    Config.ItemScanInterval = val
end)

-- ══════════════════════════════════════
--  DRAG
-- ══════════════════════════════════════
TitleBar.InputBegan:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        State.Dragging  = true
        State.DragOffset = Vector2.new(
            i.Position.X - MainFrame.AbsolutePosition.X,
            i.Position.Y - MainFrame.AbsolutePosition.Y
        )
    end
end)

UserInputService.InputChanged:Connect(function(i)
    if State.Dragging and i.UserInputType == Enum.UserInputType.MouseMove then
        MainFrame.Position = UDim2.new(
            0, i.Position.X - State.DragOffset.X,
            0, i.Position.Y - State.DragOffset.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(i)
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        State.Dragging = false
    end
end)

-- ══════════════════════════════════════
--  TOGGLE HUB
-- ══════════════════════════════════════
local FULL_HEIGHT = 420
local MINI_HEIGHT = 40

local function toggleHub()
    State.HubOpen    = not State.HubOpen
    Content.Visible  = State.HubOpen
    KeyHint.Visible  = State.HubOpen
    TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 290, 0, State.HubOpen and FULL_HEIGHT or MINI_HEIGHT)
    }):Play()
end

MinBtn.MouseButton1Click:Connect(toggleHub)

UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Config.HubKey then toggleHub() end
end)

-- ══════════════════════════════════════
--  RESPAWN
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = newChar:WaitForChild("Humanoid")

    if Config.AutoSprint then enableAutoSprint() end
    if Config.InfiniteEnergy then task.wait(0.5); enableInfiniteEnergy() end
    if Config.BallESP   then task.wait(0.3); applyBallESP() end
    if Config.PlayerESP then task.wait(1);   applyPlayerESP() end
    if anyItemAutoEnabled() then startItemScan() end
end)

-- ══════════════════════════════════════
--  DONE
-- ══════════════════════════════════════
print("[ IS Hub v1.1 ] Loaded — RShift toggle | "
    .. #ITEM_MAP .. " items mapped")
