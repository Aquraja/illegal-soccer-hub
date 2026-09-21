local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 10)

-- ============================================================
-- HOOK INFINITE STAMINA (dipasang sekali)
-- ============================================================
getgenv().infstamina = false
if not getgenv()._stamInstalled then
    getgenv()._stamInstalled = true
    local ok, err = pcall(function()
        local Sprint = require(ReplicatedStorage.Modules.Actions.Sprint)
        local BallHit = require(ReplicatedStorage.Modules.Actions.BallHitStamina)

        local OldDrain
        OldDrain = hookfunction(Sprint.GetDrainAmount, function(...)
            if getgenv().infstamina then return 0 end
            return OldDrain(...)
        end)

        local OldSpend
        OldSpend = hookfunction(Sprint.GetSpendAmount, function(...)
            if getgenv().infstamina then return 0 end
            return OldSpend(...)
        end)

        local OldCost
        OldCost = hookfunction(BallHit.GetCost, function(...)
            if getgenv().infstamina then return 0 end
            return OldCost(...)
        end)
    end)
    if not ok then warn("[HUB] stam hook gagal: " .. tostring(err)) end
end

-- ============================================================
-- SPEED CONFIG
-- ============================================================
local MIN_SPEED = 1
local MAX_SPEED = 200
local DEFAULT_SPEED = 50
local STEP_DISTANCE = 5
local Speed = DEFAULT_SPEED
local SpeedRunning = false

local Keys = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
}
local Dir = { W = false, A = false, S = false, D = false }

-- ============================================================
-- GUI
-- ============================================================
local gui = Instance.new("ScreenGui")
gui.Name = "HubGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PG

local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 44, 0, 44)
openBtn.Position = UDim2.new(0, 20, 0.5, -22)
openBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 12
openBtn.Text = "HUB"
openBtn.BorderSizePixel = 0
openBtn.Active = true
openBtn.Draggable = true
openBtn.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(1, 0)
oc.Parent = openBtn

local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 280, 0, 460)
panel.Position = UDim2.new(0.5, -140, 0.5, -230)
panel.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
panel.BorderSizePixel = 0
panel.Active = true
panel.Draggable = true
panel.Visible = false
panel.Parent = gui
local pc = Instance.new("UICorner")
pc.CornerRadius = UDim.new(0, 10)
pc.Parent = panel

local header = Instance.new("TextLabel")
header.Size = UDim2.new(1, 0, 0, 34)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
header.TextColor3 = Color3.new(1, 1, 1)
header.Font = Enum.Font.GothamBold
header.TextSize = 13
header.Text = "ILLEGAL SOCCER HUB"
header.BorderSizePixel = 0
header.Parent = panel
local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 10)
hc.Parent = header

-- ============================================================
-- SECTION 1: INFINITE STAMINA
-- ============================================================
local stamTitle = Instance.new("TextLabel")
stamTitle.Size = UDim2.new(1, -20, 0, 22)
stamTitle.Position = UDim2.new(0, 10, 0, 42)
stamTitle.BackgroundTransparency = 1
stamTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
stamTitle.Font = Enum.Font.GothamBold
stamTitle.TextSize = 12
stamTitle.TextXAlignment = Enum.TextXAlignment.Left
stamTitle.Text = "INFINITE STAMINA"
stamTitle.Parent = panel

local stamBtn = Instance.new("TextButton")
stamBtn.Size = UDim2.new(1, -20, 0, 44)
stamBtn.Position = UDim2.new(0, 10, 0, 66)
stamBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
stamBtn.TextColor3 = Color3.new(1, 1, 1)
stamBtn.Font = Enum.Font.GothamBold
stamBtn.TextSize = 15
stamBtn.Text = "OFF"
stamBtn.BorderSizePixel = 0
stamBtn.Active = true
stamBtn.Parent = panel
local sbc = Instance.new("UICorner")
sbc.CornerRadius = UDim.new(0, 8)
sbc.Parent = stamBtn

-- divider
local div1 = Instance.new("Frame")
div1.Size = UDim2.new(1, -20, 0, 1)
div1.Position = UDim2.new(0, 10, 0, 120)
div1.BackgroundColor3 = Color3.fromRGB(60, 60, 75)
div1.BorderSizePixel = 0
div1.Parent = panel

-- ============================================================
-- SECTION 2: SPEED CONTROL
-- ============================================================
local speedTitle = Instance.new("TextLabel")
speedTitle.Size = UDim2.new(1, -20, 0, 22)
speedTitle.Position = UDim2.new(0, 10, 0, 130)
speedTitle.BackgroundTransparency = 1
speedTitle.TextColor3 = Color3.fromRGB(180, 180, 200)
speedTitle.Font = Enum.Font.GothamBold
speedTitle.TextSize = 12
speedTitle.TextXAlignment = Enum.TextXAlignment.Left
speedTitle.Text = "SPEED CONTROL"
speedTitle.Parent = panel

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 36)
speedLabel.Position = UDim2.new(0, 10, 0, 154)
speedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 20
speedLabel.Text = tostring(Speed)
speedLabel.BorderSizePixel = 0
speedLabel.Parent = panel
local slc = Instance.new("UICorner")
slc.CornerRadius = UDim.new(0, 6)
slc.Parent = speedLabel

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.4, -15, 0, 36)
minusBtn.Position = UDim2.new(0, 10, 0, 196)
minusBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
minusBtn.TextColor3 = Color3.new(1, 1, 1)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 16
minusBtn.Text = "- " .. STEP_DISTANCE
minusBtn.BorderSizePixel = 0
minusBtn.Active = true
minusBtn.Parent = panel
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 8)
mc.Parent = minusBtn

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.4, -15, 0, 36)
plusBtn.Position = UDim2.new(0.6, 5, 0, 196)
plusBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
plusBtn.TextColor3 = Color3.new(1, 1, 1)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 16
plusBtn.Text = "+ " .. STEP_DISTANCE
plusBtn.BorderSizePixel = 0
plusBtn.Active = true
plusBtn.Parent = panel
local plc = Instance.new("UICorner")
plc.CornerRadius = UDim.new(0, 8)
plc.Parent = plusBtn

local function makePreset(text, value, x, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 78, 0, 32)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 12
    b.Text = text
    b.BorderSizePixel = 0
    b.Active = true
    b.Parent = panel
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = b
    b.MouseButton1Click:Connect(function()
        Speed = value
        speedLabel.Text = tostring(Speed)
    end)
    return b
end

makePreset("20", 20, 10, 240)
makePreset("50", 50, 96, 240)
makePreset("100", 100, 182, 240)
makePreset("1", 1, 10, 278)
makePreset("150", 150, 96, 278)
makePreset("200", 200, 182, 278)

local speedToggle = Instance.new("TextButton")
speedToggle.Size = UDim2.new(1, -20, 0, 44)
speedToggle.Position = UDim2.new(0, 10, 0, 318)
speedToggle.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
speedToggle.TextColor3 = Color3.new(1, 1, 1)
speedToggle.Font = Enum.Font.GothamBold
speedToggle.TextSize = 15
speedToggle.Text = "OFF"
speedToggle.BorderSizePixel = 0
speedToggle.Active = true
speedToggle.Parent = panel
local stc = Instance.new("UICorner")
stc.CornerRadius = UDim.new(0, 8)
stc.Parent = speedToggle

-- ============================================================
-- D-PAD
-- ============================================================
local dpad = Instance.new("Frame")
dpad.Size = UDim2.new(0, 160, 0, 160)
dpad.Position = UDim2.new(0, 20, 1, -180)
dpad.BackgroundTransparency = 1
dpad.Visible = false
dpad.Parent = gui

local function makeDirBtn(label, x, y, key)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 50, 0, 50)
    b.Position = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    b.TextColor3 = Color3.new(1, 1, 1)
    b.Font = Enum.Font.GothamBold
    b.TextSize = 20
    b.Text = label
    b.BorderSizePixel = 0
    b.Active = true
    b.Parent = dpad
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = b
    b.MouseButton1Down:Connect(function() Dir[key] = true end)
    b.MouseButton1Up:Connect(function() Dir[key] = false end)
    b.MouseLeave:Connect(function() Dir[key] = false end)
end

makeDirBtn("W", 55, 0, "W")
makeDirBtn("A", 0, 55, "A")
makeDirBtn("S", 55, 55, "S")
makeDirBtn("D", 110, 55, "D")

-- ============================================================
-- INPUT
-- ============================================================
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then Keys[Enum.KeyCode.W] = true end
    if input.KeyCode == Enum.KeyCode.A then Keys[Enum.KeyCode.A] = true end
    if input.KeyCode == Enum.KeyCode.S then Keys[Enum.KeyCode.S] = true end
    if input.KeyCode == Enum.KeyCode.D then Keys[Enum.KeyCode.D] = true end
end)

UIS.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.W then Keys[Enum.KeyCode.W] = false end
    if input.KeyCode == Enum.KeyCode.A then Keys[Enum.KeyCode.A] = false end
    if input.KeyCode == Enum.KeyCode.S then Keys[Enum.KeyCode.S] = false end
    if input.KeyCode == Enum.KeyCode.D then Keys[Enum.KeyCode.D] = false end
end)

-- ============================================================
-- MOVEMENT LOOP
-- ============================================================
local lastTime = tick()
RunService.Heartbeat:Connect(function()
    if not SpeedRunning then return end
    local char = LP.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dt = tick() - lastTime
    lastTime = tick()
    if dt > 0.1 then dt = 0.1 end

    local move = Vector3.new(0, 0, 0)
    local cam = workspace.CurrentCamera
    local camCF = cam and cam.CFrame or CFrame.new()

    if Keys[Enum.KeyCode.W] or Dir.W then move = move + camCF.LookVector end
    if Keys[Enum.KeyCode.S] or Dir.S then move = move - camCF.LookVector end
    if Keys[Enum.KeyCode.A] or Dir.A then move = move - camCF.RightVector end
    if Keys[Enum.KeyCode.D] or Dir.D then move = move + camCF.RightVector end

    if move.Magnitude > 0.01 then
        move = Vector3.new(move.X, 0, move.Z).Unit
        hrp.CFrame = hrp.CFrame + move * Speed * dt
    end
end)

-- ============================================================
-- INPUT DISPATCHER
-- ============================================================
local function pointIn(g, p)
    local ap, as = g.AbsolutePosition, g.AbsoluteSize
    return p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y
end

local function findBtnAt(pos)
    local best, bz = nil, -1
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Active and d.AbsoluteSize.X > 0 then
            if pointIn(d, pos) and d.ZIndex > bz then best, bz = d, d.ZIndex end
        end
    end
    return best
end

local function fire(btn)
    if not btn then return end
    if type(getconnections) == "function" then
        for _, c in ipairs(getconnections(btn.MouseButton1Click)) do
            pcall(function() c:Fire() end)
        end
    else
        pcall(function() btn:Activate() end)
    end
end

local lastTap = 0
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Touch
       or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if tick() - lastTap < 0.15 then return end
        lastTap = tick()
        local b = findBtnAt(input.Position)
        if b then fire(b) end
    end
end)

-- ============================================================
-- ACTIONS
-- ============================================================
openBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)

minusBtn.MouseButton1Click:Connect(function()
    Speed = math.max(MIN_SPEED, Speed - STEP_DISTANCE)
    speedLabel.Text = tostring(Speed)
end)

plusBtn.MouseButton1Click:Connect(function()
    Speed = math.min(MAX_SPEED, Speed + STEP_DISTANCE)
    speedLabel.Text = tostring(Speed)
end)

stamBtn.MouseButton1Click:Connect(function()
    getgenv().infstamina = not getgenv().infstamina
    if getgenv().infstamina then
        stamBtn.Text = "ON"
        stamBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
    else
        stamBtn.Text = "OFF"
        stamBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
    end
end)

speedToggle.MouseButton1Click:Connect(function()
    SpeedRunning = not SpeedRunning
    if SpeedRunning then
        speedToggle.Text = "ON"
        speedToggle.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
        dpad.Visible = true
        speedLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
        lastTime = tick()
    else
        speedToggle.Text = "OFF"
        speedToggle.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        dpad.Visible = false
        speedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
        Dir.W = false Dir.A = false Dir.S = false Dir.D = false
    end
end)

warn("[HUB] loaded. tap tombol HUB di kiri tengah.")