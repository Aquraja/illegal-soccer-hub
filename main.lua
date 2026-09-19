cat > /home/claude/illegal-soccer-hub/main.lua << 'ENDOFFILE'
--[[
    ╔══════════════════════════════════════════════════╗
    ║          ILLEGAL SOCCER HUB  v1.2               ║
    ║  loadstring(game:HttpGet("RAW_URL"))()           ║
    ║  Executor : Synapse X / KRNL / Fluxus / Delta   ║
    ║  Fix v1.2 : Energy brute-lock + Android drag    ║
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
    AutoSprint        = false,
    InfiniteEnergy    = false,
    SprintSpeed       = 28,
    NormalSpeed       = 16,
    BallESP           = false,
    PlayerESP         = false,
    AutoJetpack       = false,
    AutoRocketPunch   = false,
    AutoFreezeGun     = false,
    AutoShotgun       = false,
    AutoGrapple       = false,
    ItemScanInterval  = 0.08,
    HubKey            = Enum.KeyCode.RightShift,
}

-- ══════════════════════════════════════
--  STATE
-- ══════════════════════════════════════
local State = {
    HubOpen     = true,
    Dragging    = false,
    DragOffset  = Vector2.new(),
    Connections = {},
    ESPBall     = {},
    ESPPlayers  = {},
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

-- Cari semua ValueBase yang mungkin energy di semua tempat
local function findAllEnergyObjects()
    local found = {}
    local searchTargets = {
        Character,
        LocalPlayer,
        LocalPlayer:FindFirstChild("PlayerGui"),
        LocalPlayer:FindFirstChild("Backpack"),
    }
    local keywords = {
        "energy","stamina","sprint","dash","run",
        "endurance","fuel","power","charge","bar"
    }
    for _, target in ipairs(searchTargets) do
        if target then
            for _, v in ipairs(target:GetDescendants()) do
                if v:IsA("NumberValue") or v:IsA("IntValue") or v:IsA("DoubleConstrainedValue") then
                    local n = v.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if n:find(kw) then
                            table.insert(found, v)
                            break
                        end
                    end
                end
            end
        end
    end
    return found
end

-- Cari semua attribute yang mungkin energy
local function findAllEnergyAttributes()
    local found = {}
    local keywords = {
        "energy","stamina","sprint","dash","run",
        "endurance","fuel","power","charge"
    }
    local targets = {Character, LocalPlayer}
    for _, target in ipairs(targets) do
        if target then
            local ok, attrs = pcall(function() return target:GetAttributes() end)
            if ok and attrs then
                for attrName, attrVal in pairs(attrs) do
                    if type(attrVal) == "number" then
                        local n = attrName:lower()
                        for _, kw in ipairs(keywords) do
                            if n:find(kw) then
                                table.insert(found, {obj = target, name = attrName, val = attrVal})
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return found
end

local function findTool(keywords)
    local searchIn = {Character:GetChildren()}
    local bp = LocalPlayer:FindFirstChild("Backpack")
    if bp then
        for _, v in ipairs(bp:GetChildren()) do
            table.insert(searchIn, v)
        end
    end
    for _, obj in ipairs(searchIn) do
        if obj:IsA("Tool") or obj:IsA("LocalScript") or obj:IsA("Script") then
            local n = obj.Name:lower()
            for _, kw in ipairs(keywords) do
                if n:find(kw) then return obj end
            end
        end
    end
    return nil
end

local function activateTool(tool)
    if not tool then return end
    if tool.Parent ~= Character then
        local h = Character:FindFirstChildOfClass("Humanoid")
        if h then h:EquipTool(tool) end
    end
    task.wait(0.05)
    local ev = tool:FindFirstChild("Activate")
           or tool:FindFirstChild("OnActivate")
           or tool:FindFirstChild("UseItem")
    if ev and ev:IsA("RemoteEvent") then
        ev:FireServer()
    else
        pcall(function() tool:Activate() end)
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

local MainFrame = Instance.new("Frame")
MainFrame.Name             = "MainFrame"
MainFrame.Size             = UDim2.new(0, 290, 0, 420)
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

local TitleBar = Instance.new("Frame")
TitleBar.Name             = "TitleBar"
TitleBar.Size             = UDim2.new(1, 0, 0, 40)
TitleBar.BackgroundColor3 = Color3.fromRGB(18, 18, 28)
TitleBar.BorderSizePixel  = 0
TitleBar.Parent           = MainFrame
Instance.new("UICorner", TitleBar).CornerRadius = UDim.new(0, 10)

local TitleLabel = Instance.new("TextLabel", TitleBar)
TitleLabel.Text               = "⚽  ILLEGAL SOCCER HUB  v1.2"
TitleLabel.Size               = UDim2.new(1, -48, 1, 0)
TitleLabel.Position           = UDim2.new(0, 12, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextColor3         = Color3.fromRGB(70, 165, 255)
TitleLabel.TextSize           = 12
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

local KeyHint = Instance.new("TextLabel", MainFrame)
KeyHint.Text            = "[─] Minimize  •  Drag title bar"
KeyHint.Size            = UDim2.new(1, 0, 0, 16)
KeyHint.Position        = UDim2.new(0, 0, 0, 42)
KeyHint.BackgroundTransparency = 1
KeyHint.TextColor3      = Color3.fromRGB(55, 55, 80)
KeyHint.TextSize        = 10
KeyHint.Font            = Enum.Font.Gotham

local Content = Instance.new("ScrollingFrame", MainFrame)
Content.Name                  = "Content"
Content.Size                  = UDim2.new(1, -16, 1, -68)
Content.Position              = UDim2.new(0, 8, 0, 60)
Content.BackgroundTransparency = 1
Content.ScrollBarThickness    = 3
Content.ScrollBarImageColor3  = Color3.fromRGB(70, 165, 255)
Content.BorderSizePixel       = 0
Content.CanvasSize            = UDim2.new(0, 0, 0, 0)
Content.AutomaticCanvasSize   = Enum.AutomaticSize.Y

local ListLayout = Instance.new("UIListLayout", Content)
ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
ListLayout.Padding   = UDim.new(0, 5)

local ContentPad = Instance.new("UIPadding", Content)
ContentPad.PaddingTop    = UDim.new(0, 4)
ContentPad.PaddingBottom = UDim.new(0, 10)

-- ══════════════════════════════════════
--  COMPONENT BUILDERS
-- ══════════════════════════════════════
local ACCENT   = Color3.fromRGB(70, 165, 255)
local BG_ROW   = Color3.fromRGB(20, 20, 30)
local BG_SEC   = Color3.fromRGB(23, 23, 36)
local TEXT_HI  = Color3.fromRGB(215, 215, 215)
local tweenInfo = TweenInfo.new(0.14, Enum.EasingStyle.Quad)

local function makeSection(title)
    local f = Instance.new("Frame", Content)
    f.Size             = UDim2.new(1, 0, 0, 24)
    f.BackgroundColor3 = BG_SEC
    f.BorderSizePixel  = 0
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

local function makeToggle(labelText, configKey, onEnable, onDisable)
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, 0, 0, 36)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
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
            Position = state and UDim2.new(0,21,0.5,-6) or UDim2.new(0,3,0.5,-6)
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
    local Row = Instance.new("Frame", Content)
    Row.Size             = UDim2.new(1, 0, 0, 52)
    Row.BackgroundColor3 = BG_ROW
    Row.BorderSizePixel  = 0
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

    -- Support mouse + touch di slider
    Track.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1
        or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(i.Position.X)
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
--  FEATURES
-- ══════════════════════════════════════

-- >> SPRINT <<
local sprintConn

local function enableAutoSprint()
    if sprintConn then sprintConn:Disconnect() end
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

-- >> INFINITE ENERGY — BRUTE LOCK via Heartbeat <<
--[[
    Cara kerja:
    Setiap Heartbeat (60fps), scan SEMUA ValueBase + attribute yang mungkin
    energy dan paksa ke nilai max yang pernah terdeteksi.
    Ini lebih reliable dari .Changed karena server bisa update
    energy di tick yang sama sebelum .Changed fire.
]]
local energyConn
local energyMaxCache = {}  -- simpan max value yang pernah terlihat per object path

local function enableInfiniteEnergy()
    if energyConn then energyConn:Disconnect() end

    -- Scan pertama untuk populate cache max value
    local objs = findAllEnergyObjects()
    for _, obj in ipairs(objs) do
        local path = obj:GetFullName()
        energyMaxCache[path] = math.max(energyMaxCache[path] or 0, obj.Value)
    end

    local attrs = findAllEnergyAttributes()
    for _, entry in ipairs(attrs) do
        local key = entry.obj:GetFullName() .. "." .. entry.name
        energyMaxCache[key] = math.max(energyMaxCache[key] or 0, entry.val)
    end

    -- Brute lock setiap Heartbeat
    energyConn = RunService.Heartbeat:Connect(function()
        -- Lock ValueBase objects
        local currentObjs = findAllEnergyObjects()
        for _, obj in ipairs(currentObjs) do
            local path = obj:GetFullName()
            -- Update max cache kalau ketemu nilai lebih besar
            if obj.Value > (energyMaxCache[path] or 0) then
                energyMaxCache[path] = obj.Value
            end
            local maxVal = energyMaxCache[path] or 100
            if obj.Value < maxVal then
                pcall(function() obj.Value = maxVal end)
            end
        end

        -- Lock attributes
        local currentAttrs = findAllEnergyAttributes()
        for _, entry in ipairs(currentAttrs) do
            local key = entry.obj:GetFullName() .. "." .. entry.name
            if entry.val > (energyMaxCache[key] or 0) then
                energyMaxCache[key] = entry.val
            end
            local maxVal = energyMaxCache[key] or 100
            if entry.val < maxVal then
                pcall(function()
                    entry.obj:SetAttribute(entry.name, maxVal)
                end)
            end
        end

        -- Extra: paksa WalkSpeed tetap sprint kalau auto sprint aktif
        -- (beberapa game reset WalkSpeed via energy system)
        if Config.AutoSprint and Humanoid and Humanoid.Parent then
            if Humanoid.WalkSpeed < Config.SprintSpeed then
                Humanoid.WalkSpeed = Config.SprintSpeed
            end
        end
    end)
end

local function disableInfiniteEnergy()
    if energyConn then energyConn:Disconnect(); energyConn = nil end
    energyMaxCache = {}
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
            if n:find("ball") or n:find("soccer") or n:find("bola") or n:find("puck") then
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

                push(RunService.Heartbeat:Connect(function()
                    if root and root.Parent and Character
                    and Character:FindFirstChild("HumanoidRootPart") then
                        local d = math.floor((root.Position - Character.HumanoidRootPart.Position).Magnitude)
                        distL.Text = d .. " studs"
                    end
                end))

                table.insert(State.ESPPlayers, bb)
            end
        end
    end
end

-- >> AUTO ITEM <<
local ITEM_MAP = {
    { keys = {"jetpack","jet"},               configKey = "AutoJetpack"     },
    { keys = {"rocketpunch","rocket","punch"}, configKey = "AutoRocketPunch" },
    { keys = {"freezegun","freeze"},          configKey = "AutoFreezeGun"   },
    { keys = {"shotgun"},                     configKey = "AutoShotgun"     },
    { keys = {"grapple","hook","grappling"},  configKey = "AutoGrapple"     },
}

local itemLastUsed = {}
local itemScanConn

local function scanAndUseItems()
    local now = tick()
    for _, entry in ipairs(ITEM_MAP) do
        if Config[entry.configKey] then
            local tool = findTool(entry.keys)
            if tool then
                local lastUse = itemLastUsed[entry.configKey] or 0
                if now - lastUse >= 0.5 then
                    itemLastUsed[entry.configKey] = now
                    task.spawn(function() activateTool(tool) end)
                end
            end
        end
    end
end

local function startItemScan()
    if itemScanConn then return end
    local lastScan = 0
    itemScanConn = RunService.Heartbeat:Connect(function()
        local now = tick()
        if now - lastScan >= Config.ItemScanInterval then
            lastScan = now
            scanAndUseItems()
        end
    end)
end

local function stopItemScan()
    if itemScanConn then itemScanConn:Disconnect(); itemScanConn = nil end
end

local function anyItemAutoEnabled()
    return Config.AutoJetpack or Config.AutoRocketPunch
        or Config.AutoFreezeGun or Config.AutoShotgun
        or Config.AutoGrapple
end

-- ══════════════════════════════════════
--  BUILD PANEL CONTENT
-- ══════════════════════════════════════

makeSection("Movement")

makeToggle("Auto Sprint", "AutoSprint", enableAutoSprint, disableAutoSprint)

makeToggle("Infinite Energy", "InfiniteEnergy", enableInfiniteEnergy, disableInfiniteEnergy)

makeSlider("Sprint Speed", "SprintSpeed", 16, 60, function(val)
    if Config.AutoSprint and Humanoid and Humanoid.Parent then
        Humanoid.WalkSpeed = val
    end
end)

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

makeSection("Auto Item Use")

local function makeItemToggle(label, configKey)
    makeToggle(label, configKey,
        function() if anyItemAutoEnabled() then startItemScan() end end,
        function() if not anyItemAutoEnabled() then stopItemScan() end end
    )
end

makeItemToggle("Auto Jetpack",      "AutoJetpack")
makeItemToggle("Auto Rocket Punch", "AutoRocketPunch")
makeItemToggle("Auto Freeze Gun",   "AutoFreezeGun")
makeItemToggle("Auto Shotgun",      "AutoShotgun")
makeItemToggle("Auto Grapple Hook", "AutoGrapple")

-- ══════════════════════════════════════
--  DRAG — PC + ANDROID TOUCH
-- ══════════════════════════════════════
--[[
    Fix Android:
    - Touch mulai   → TouchTap / Touch InputBegan di TitleBar
    - Touch gerak   → Touch InputChanged (bukan MouseMove)
    - Touch lepas   → Touch InputEnded
    Support keduanya sekaligus, deteksi otomatis.
]]

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
        local screenSize = workspace.CurrentCamera.ViewportSize
        local newX = math.clamp(i.Position.X - State.DragOffset.X, 0, screenSize.X - MainFrame.AbsoluteSize.X)
        local newY = math.clamp(i.Position.Y - State.DragOffset.Y, 0, screenSize.Y - MainFrame.AbsoluteSize.Y)
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
--  TOGGLE HUB
-- ══════════════════════════════════════
local FULL_H = 420
local MINI_H = 40

local function toggleHub()
    State.HubOpen   = not State.HubOpen
    Content.Visible = State.HubOpen
    KeyHint.Visible = State.HubOpen
    TweenService:Create(MainFrame, TweenInfo.new(0.18, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 290, 0, State.HubOpen and FULL_H or MINI_H)
    }):Play()
end

MinBtn.MouseButton1Click:Connect(toggleHub)

UserInputService.InputBegan:Connect(function(i, gp)
    if not gp and i.KeyCode == Config.HubKey then toggleHub() end
end)

-- ══════════════════════════════════════
--  RESPAWN HANDLER
-- ══════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function(newChar)
    Character = newChar
    Humanoid  = newChar:WaitForChild("Humanoid")
    energyMaxCache = {}  -- reset cache pas respawn

    if Config.AutoSprint     then enableAutoSprint() end
    if Config.InfiniteEnergy then task.wait(0.5); enableInfiniteEnergy() end
    if Config.BallESP        then task.wait(0.3); applyBallESP() end
    if Config.PlayerESP      then task.wait(1);   applyPlayerESP() end
    if anyItemAutoEnabled()  then startItemScan() end
end)

-- ══════════════════════════════════════
--  DONE
-- ══════════════════════════════════════
print("[ IS Hub v1.2 ] Loaded — Energy brute-lock ON | Touch drag fixed")
ENDOFFILE