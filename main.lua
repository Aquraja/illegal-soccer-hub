local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local LP = Players.LocalPlayer
local PG = LP:WaitForChild("PlayerGui", 10)
if not PG then warn("[E] PlayerGui gak ada") return end

local State = {
    BallMagnet = false,
    AutoKick = false,
    SpeedBoost = false,
    InfiniteStamina = false,
    AimbotKick = false,
    ESP = false,
    BallESP = true,
}

local gui = Instance.new("ScreenGui")
gui.Name = "ISP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 99999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = PG

local openBtn = Instance.new("TextButton")
openBtn.Name = "OpenBtn"
openBtn.Size = UDim2.new(0, 80, 0, 80)
openBtn.Position = UDim2.new(1, -100, 1, -200)
openBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
openBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
openBtn.Font = Enum.Font.GothamBold
openBtn.TextSize = 22
openBtn.Text = "IS"
openBtn.BorderSizePixel = 0
openBtn.Active = true
openBtn.Draggable = true
openBtn.Parent = gui
local oc = Instance.new("UICorner")
oc.CornerRadius = UDim.new(1, 0)
oc.Parent = openBtn

local panel = Instance.new("Frame")
panel.Name = "Panel"
panel.Size = UDim2.new(0, 300, 0, 420)
panel.Position = UDim2.new(1, -320, 1, -640)
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
header.Size = UDim2.new(1, 0, 0, 40)
header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
header.TextColor3 = Color3.fromRGB(255, 255, 255)
header.Font = Enum.Font.GothamBold
header.TextSize = 14
header.Text = "ILLEGAL SOCCER"
header.BorderSizePixel = 0
header.Parent = panel
local hc = Instance.new("UICorner")
hc.CornerRadius = UDim.new(0, 10)
hc.Parent = header

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 30, 0, 30)
closeBtn.Position = UDim2.new(1, -35, 0, 5)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextSize = 14
closeBtn.Text = "X"
closeBtn.BorderSizePixel = 0
closeBtn.Active = true
closeBtn.Parent = header
local cc = Instance.new("UICorner")
cc.CornerRadius = UDim.new(1, 0)
cc.Parent = closeBtn

local list = Instance.new("ScrollingFrame")
list.Size = UDim2.new(1, -10, 1, -50)
list.Position = UDim2.new(0, 5, 0, 45)
list.BackgroundTransparency = 1
list.BorderSizePixel = 0
list.ScrollBarThickness = 4
list.CanvasSize = UDim2.new(0, 0, 0, 0)
list.AutomaticCanvasSize = Enum.AutomaticSize.Y
list.Parent = panel
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 6)
layout.Parent = list

local function makeToggle(label, key)
    local btn = Instance.new("TextButton")
    btn.Name = "T_" .. key
    btn.Size = UDim2.new(1, -6, 0, 42)
    btn.BackgroundColor3 = State[key] and Color3.fromRGB(45, 160, 80) or Color3.fromRGB(38, 38, 48)
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.Gotham
    btn.TextSize = 13
    btn.Text = label .. "  [" .. (State[key] and "ON" or "OFF") .. "]"
    btn.BorderSizePixel = 0
    btn.Active = true
    btn.Parent = list
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    btn.MouseButton1Click:Connect(function()
        State[key] = not State[key]
        btn.Text = label .. "  [" .. (State[key] and "ON" or "OFF") .. "]"
        btn.BackgroundColor3 = State[key] and Color3.fromRGB(45, 160, 80) or Color3.fromRGB(38, 38, 48)
    end)
end

local function makeAction(label, color, cb)
    local btn = Instance.new("TextButton")
    btn.Name = "A_" .. label
    btn.Size = UDim2.new(1, -6, 0, 42)
    btn.BackgroundColor3 = color
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 13
    btn.Text = label
    btn.BorderSizePixel = 0
    btn.Active = true
    btn.Parent = list
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = btn
    btn.MouseButton1Click:Connect(cb)
end

makeToggle("Ball Magnet", "BallMagnet")
makeToggle("Auto Kick", "AutoKick")
makeToggle("Speed Boost", "SpeedBoost")
makeToggle("Infinite Stamina", "InfiniteStamina")
makeToggle("Aimbot Kick", "AimbotKick")
makeToggle("ESP Pemain", "ESP")
makeToggle("ESP Bola", "BallESP")

makeAction("PANIC OFF", Color3.fromRGB(200, 60, 60), function()
    for k, _ in pairs(State) do State[k] = false end
    for _, ch in ipairs(list:GetChildren()) do
        if ch:IsA("TextButton") and ch.Name:sub(1, 2) == "T_" then
            local base = ch.Text:match("^(.-)%s*%[")
            if base then
                ch.Text = base .. "  [OFF]"
                ch.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
            end
        end
    end
end)

openBtn.MouseButton1Click:Connect(function()
    panel.Visible = not panel.Visible
end)
closeBtn.MouseButton1Click:Connect(function()
    panel.Visible = false
end)

-- dispatcher untuk bypass delta input eater
local function pointInGui(g, p)
    local ap, as = g.AbsolutePosition, g.AbsoluteSize
    return p.X >= ap.X and p.X <= ap.X + as.X and p.Y >= ap.Y and p.Y <= ap.Y + as.Y
end

local function findTopBtnAt(pos)
    local best, bestz = nil, -1
    for _, d in ipairs(gui:GetDescendants()) do
        if d:IsA("GuiButton") and d.Visible and d.Active and d.AbsoluteSize.X > 0 then
            if pointInGui(d, pos) and (d.ZIndex > bestz) then
                best, bestz = d, d.ZIndex
            end
        end
    end
    return best
end

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
UIS.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.Touch
       or input.UserInputType == Enum.UserInputType.MouseButton1 then
        if tick() - lastTap < 0.15 then return end
        lastTap = tick()
        local btn = findTopBtnAt(input.Position)
        if btn then fireBtn(btn) end
    end
end)

print("[IS] panel siap. tap tombol 'IS' biru di kanan bawah.")