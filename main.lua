local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Player = Players.LocalPlayer
local PG = Player:WaitForChild("PlayerGui", 10)

--==================================================
-- KONFIGURASI
--==================================================
local MIN_SPEED = 1
local MAX_SPEED = 200
local DEFAULT_SPEED = 50
local STEP_DISTANCE = 5
local Speed = DEFAULT_SPEED
local Running = false

--==================================================
-- STATUS TOMBOL
--==================================================
local Keys = {
    [Enum.KeyCode.W] = false,
    [Enum.KeyCode.A] = false,
    [Enum.KeyCode.S] = false,
    [Enum.KeyCode.D] = false,
}

local Dir = { W = false, A = false, S = false, D = false }

--==================================================
-- GUI
--==================================================
local gui = Instance.new("ScreenGui")
gui.Name = "SpeedGUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.Parent = PG

-- tombol buka panel
local openBtn = Instance.new("TextButton")
openBtn.Size = UDim2.new(0, 40, 0, 40)
openBtn.Position = UDim2.new(0, 20, 0.5, -20)
openBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
openBtn.TextColor3 = Color3.new(1, 1, 1)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 11
openBtn.Text = "SPD"
openBtn.BorderSizePixel = 0
openBtn.Active = true
openBtn.Draggable = true
openBtn.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(1, 0)
oc.Parent = openBtn

-- panel
local panel = Instance.new("Frame")
panel.Size = UDim2.new(0, 260, 0, 300)
panel.Position = UDim2.new(0.5, -130, 0.5, -150)
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
header.Text = "SPEED CONTROL"
header.BorderSizePixel = 0
header.Parent = panel
local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 10)
hc.Parent = header

-- display speed
local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -20, 0, 40)
speedLabel.Position = UDim2.new(0, 10, 0, 44)
speedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextSize = 22
speedLabel.Text = tostring(Speed)
speedLabel.BorderSizePixel = 0
speedLabel.Parent = panel
local slc = Instance.new("UICorner")
slc.CornerRadius = UDim.new(0, 6)
slc.Parent = speedLabel

-- tombol -STEP dan +STEP
local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0.4, -15, 0, 40)
minusBtn.Position = UDim2.new(0, 10, 0, 94)
minusBtn.BackgroundColor3 = Color3.fromRGB(180, 60, 60)
minusBtn.TextColor3 = Color3.new(1, 1, 1)
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextSize = 18
minusBtn.Text = "- " .. STEP_DISTANCE
minusBtn.BorderSizePixel = 0
minusBtn.Active = true
minusBtn.Parent = panel
local mc = Instance.new("UICorner")
mc.CornerRadius = UDim.new(0, 8)
mc.Parent = minusBtn

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0.4, -15, 0, 40)
plusBtn.Position = UDim2.new(0.6, 5, 0, 94)
plusBtn.BackgroundColor3 = Color3.fromRGB(60, 180, 90)
plusBtn.TextColor3 = Color3.new(1, 1, 1)
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextSize = 18
plusBtn.Text = "+ " .. STEP_DISTANCE
plusBtn.BorderSizePixel = 0
plusBtn.Active = true
plusBtn.Parent = panel
local plc = Instance.new("UICorner")
plc.CornerRadius = UDim.new(0, 8)
plc.Parent = plusBtn

-- preset buttons
local function makePreset(text, value, x, y)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(0, 74, 0, 34)
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

makePreset("20", 20, 10, 144)
makePreset("50", 50, 92, 144)
makePreset("100", 100, 174, 144)

makePreset("1", 1, 10, 184)
makePreset("150", 150, 92, 184)
makePreset("200", 200, 174, 184)

-- tombol ON/OFF
local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(1, -20, 0, 50)
toggleBtn.Position = UDim2.new(0, 10, 0, 234)
toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
toggleBtn.TextColor3 = Color3.new(1, 1, 1)
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 16
toggleBtn.Text = "OFF"
toggleBtn.BorderSizePixel = 0
toggleBtn.Active = true
toggleBtn.Parent = panel
local tc = Instance.new("UICorner")
tc.CornerRadius = UDim.new(0, 8)
tc.Parent = toggleBtn

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

--==================================================
-- D-PAD (buat mobile)
--==================================================
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
    b.TouchLongPress:Connect(function() end)
    return b
end

makeDirBtn("W", 55, 0, "W")
makeDirBtn("A", 0, 55, "A")
makeDirBtn("S", 55, 55, "S")
makeDirBtn("D", 110, 55, "D")

--==================================================
-- KEYBOARD (buat pc / kalau ada keyboard fisik)
--==================================================
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.W then Keys[Enum.KeyCode.W] = true end
    if input.KeyCode == Enum.KeyCode.A then Keys[Enum.KeyCode.A] = true end
    if input.KeyCode == Enum.KeyCode.S then Keys[Enum.KeyCode.S] = true end
    if input.KeyCode == Enum.KeyCode.D then Keys[Enum.KeyCode.D] = true end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if input.KeyCode == Enum.KeyCode.W then Keys[Enum.KeyCode.W] = false end
    if input.KeyCode == Enum.KeyCode.A then Keys[Enum.KeyCode.A] = false end
    if input.KeyCode == Enum.KeyCode.S then Keys[Enum.KeyCode.S] = false end
    if input.KeyCode == Enum.KeyCode.D then Keys[Enum.KeyCode.D] = false end
end)

--==================================================
-- MOVEMENT LOOP
--==================================================
local lastTime = tick()

RunService.Heartbeat:Connect(function()
    if not Running then return end

    local char = Player.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local dt = tick() - lastTime
    lastTime = tick()
    if dt > 0.1 then dt = 0.1 end

    local move = Vector3.new(0, 0, 0)
    local cam = workspace.CurrentCamera
    local camCF = cam and cam.CFrame or CFrame.new()

    -- W = maju (arah kamera)
    local useW = Keys[Enum.KeyCode.W] or Dir.W
    local useS = Keys[Enum.KeyCode.S] or Dir.S
    local useA = Keys[Enum.KeyCode.A] or Dir.A
    local useD = Keys[Enum.KeyCode.D] or Dir.D

    if useW then move = move + camCF.LookVector end
    if useS then move = move - camCF.LookVector end
    if useA then move = move - camCF.RightVector end
    if useD then move = move + camCF.RightVector end

    if move.Magnitude > 0.01 then
        move = Vector3.new(move.X, 0, move.Z).Unit
        hrp.CFrame = hrp.CFrame + move * Speed * dt
    end
end)

--==================================================
-- INPUT DISPATCHER (bypass delta input eater)
--==================================================
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

local activeHold = nil

local function fireBtn(btn)
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
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Touch
       or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if tick() - lastTap < 0.15 then return end
        lastTap = tick()
        local b = findBtnAt(input.Position)
        if b then
            fireBtn(b)
            -- kalau itu tombol D-pad, tahan
            for _, d in ipairs(dpad:GetChildren()) do
                if d == b then activeHold = b end
            end
        end
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if activeHold then
        -- reset semua D-pad
        Dir.W = false
        Dir.A = false
        Dir.S = false
        Dir.D = false
        activeHold = nil
    end
end)

toggleBtn.MouseButton1Click:Connect(function()
    Running = not Running
    if Running then
        toggleBtn.Text = "ON"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(45, 160, 80)
        dpad.Visible = true
        speedLabel.TextColor3 = Color3.fromRGB(120, 255, 140)
    else
        toggleBtn.Text = "OFF"
        toggleBtn.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
        dpad.Visible = false
        speedLabel.TextColor3 = Color3.fromRGB(120, 200, 255)
        Dir.W = false Dir.A = false Dir.S = false Dir.D = false
    end
end)

warn("[SPD] loaded. tap tombol SPD di kiri tengah.")