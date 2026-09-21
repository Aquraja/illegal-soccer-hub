--[[
    Illegal Soccer — Multi-Feature Exploit
    Panel + Toggle, Delta Executor Compatible, Infinite Stamina Multi-Strategy
    Author: outcome
    Loadstring:
        loadstring(game:HttpGet("https://raw.githubusercontent.com/USER/illegal-soccer-exploit/main/main.lua"))()
]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera      = Workspace.CurrentCamera

-- ============================================================
-- EXECUTOR SANITY + DETECTION
-- ============================================================
local function has(fn) return type(fn) == "function" end

local ExecutorName = "unknown"
if has(identifyexecutor) then
    local ok, name = pcall(identifyexecutor)
    if ok then ExecutorName = name end
end
local IsDelta = ExecutorName:lower():find("delta") ~= nil

local genv = has(getgenv) and getgenv() or _G
genv.IS_EXPLOIT = genv.IS_EXPLOIT or {}
local State = genv.IS_EXPLOIT

State.Config = State.Config or {}
local defaults = {
    BallMagnet      = false,
    BallMagnetRange = 12,
    AutoKick        = false,
    AutoKickRange   = 8,
    AutoKickPower   = 350,
    SpeedBoost      = false,
    WalkSpeed       = 60,
    InfiniteStamina = false,
    StaminaMax      = 100,
    AimbotKick      = false,
    ESP             = false,
    BallESP         = true,
    ESPColor        = Color3.fromRGB(255, 60, 60),
    TweenSpeed      = 120,
}
for k, v in pairs(defaults) do
    if State.Config[k] == nil then State.Config[k] = v end
end

-- ============================================================
-- UI PARENT HELPER (dengan write-access check)
-- ============================================================
local function tryParent(inst, parent)
    if not parent then return false end
    local ok = pcall(function() inst.Parent = parent end)
    return ok and inst.Parent == parent
end

local function getUIParent()
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then return hui end
    end
    local dummy = Instance.new("Folder")
    if tryParent(dummy, CoreGui) then
        dummy:Destroy()
        return CoreGui
    end
    dummy:Destroy()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
        or LocalPlayer:WaitForChild("PlayerGui", 10)
    return pg or CoreGui
end

-- ============================================================
-- UTIL
-- ============================================================
local function safeFire(remote, ...)
    if not remote then return false end
    local ok, err = pcall(function()
        if remote:IsA("RemoteEvent") then remote:FireServer(...)
        elseif remote:IsA("RemoteFunction") then remote:InvokeServer(...) end
    end)
    if not ok then warn("[IS-E] fire gagal:", err) end
    return ok
end

local function tweenTo(targetCFrame, speed)
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    local startCF = hrp.CFrame
    local dist    = (startCF.Position - targetCFrame.Position).Magnitude
    if dist < 0.5 then hrp.CFrame = targetCFrame return end
    local duration = dist / (speed or State.Config.TweenSpeed)
    local t0 = os.clock()
    local conn
    conn = RunService.Heartbeat:Connect(function()
        local a = math.clamp((os.clock() - t0) / duration, 0, 1)
        hrp.CFrame = startCF:Lerp(targetCFrame, a)
        if a >= 1 then conn:Disconnect() end
    end)
end

-- ============================================================
-- DISCOVERY
-- ============================================================
local Cache = { ball=nil, ballLast=0, goals={}, remotes={}, character=nil, humanoid=nil }

local function isBallCandidate(inst)
    if not inst:IsA("BasePart") then return false end
    local n = inst.Name:lower()
    if n:find("ball") or n:find("bola") then return true end
    if inst:IsA("Part") and inst.Shape == Enum.PartType.Ball then
        local sz = inst.Size
        if sz.X >= 0.8 and sz.X <= 4 then return true end
    end
    return false
end

local function findBall()
    local now = os.clock()
    if Cache.ball and Cache.ball.Parent and (now - Cache.ballLast) < 1 then
        return Cache.ball
    end
    local best, bestScore = nil, 0
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if isBallCandidate(inst) then
            local score = 1
            if inst.AssemblyLinearVelocity.Magnitude > 0.5 then score = score + 2 end
            local char = LocalPlayer.Character
            if char and char:FindFirstChild("HumanoidRootPart") then
                local d = (char.HumanoidRootPart.Position - inst.Position).Magnitude
                if d < 100 then score = score + (100 - d) / 50 end
            end
            if score > bestScore then best, bestScore = inst, score end
        end
    end
    Cache.ball = best
    Cache.ballLast = now
    return best
end

local function findGoals()
    Cache.goals = {}
    for _, inst in ipairs(Workspace:GetDescendants()) do
        if inst:IsA("Model") or inst:IsA("BasePart") then
            local n = inst.Name:lower()
            if n:find("goal") or n:find("gawang") or n:find("net") or n:find("target") then
                local cf
                if inst:IsA("Model") then
                    local prim = inst.PrimaryPart or inst:FindFirstChildWhichIsA("BasePart")
                    if prim then cf = prim.CFrame end
                else cf = inst.CFrame end
                if cf then table.insert(Cache.goals, { obj=inst, cframe=cf, name=inst.Name }) end
            end
        end
    end
end

local function scanRemotes()
    Cache.remotes = {}
    local seen = {}
    local function add(r)
        if r and not seen[r] then
            seen[r] = true
            table.insert(Cache.remotes, r)
        end
    end
    for _, inst in ipairs(ReplicatedStorage:GetDescendants()) do
        if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
            local n = inst.Name:lower()
            if n:find("kick") or n:find("shoot") or n:find("ball")
               or n:find("sprint") or n:find("stamina") or n:find("tackle")
               or n:find("action") or n:find("input")
               or n:find("drain") or n:find("energy") or n:find("fatigue")
               or n:find("cooldown") then
                add(inst)
            end
        end
    end
    for _, folderName in ipairs({"Remotes","Events","Net","Network","RemoteEvents"}) do
        local folder = ReplicatedStorage:FindFirstChild(folderName)
        if folder then
            for _, inst in ipairs(folder:GetChildren()) do
                if inst:IsA("RemoteEvent") or inst:IsA("RemoteFunction") then
                    add(inst)
                end
            end
        end
    end
end

local function refreshCharacter()
    local char = LocalPlayer.Character
    if not char or char == Cache.character then return end
    Cache.character = char
    Cache.humanoid  = char:WaitForChild("Humanoid", 3)
end

LocalPlayer.CharacterAdded:Connect(function()
    Cache.character = nil
    task.wait(0.5)
    refreshCharacter()
end)

task.spawn(function()
    refreshCharacter(); findBall(); findGoals(); scanRemotes()
end)

task.spawn(function()
    while task.wait(5) do
        pcall(findBall); pcall(findGoals)
        if #Cache.remotes == 0 then pcall(scanRemotes) end
    end
end)

-- ============================================================
-- INFINITE STAMINA — MULTI-STRATEGY
-- ============================================================
local hookedValues  = {}
local knownRemotes  = {}
local knownAttrs    = {}

-- strategi 1: freeze NumberValue
local function hookStaminaValue(val)
    if hookedValues[val] then return end
    hookedValues[val] = true
    task.spawn(function()
        while task.wait(0.05) do
            if State.Config.InfiniteStamina and val.Parent then
                pcall(function() val.Value = State.Config.StaminaMax end)
            elseif not val.Parent then
                hookedValues[val] = nil
                break
            end
        end
    end)
end

-- strategi 2: hook __newindex di game metatable
local function installMetaHook()
    if type(hookmetamethod) ~= "function" or type(getrawmetatable) ~= "function" then
        return false
    end
    local ok = pcall(function()
        local mt = getrawmetatable(game)
        local oldNewIndex = mt.__newindex
        if setreadonly then setreadonly(mt, false) end
        mt.__newindex = newcclosure(function(self, key, value)
            if State.Config.InfiniteStamina
               and type(self) == "Instance"
               and self:IsA("NumberValue") then
                local n = self.Name:lower()
                if n:find("stamina") or n:find("energy")
                   or n:find("sprint") or n:find("fatigue") then
                    return oldNewIndex(self, key, State.Config.StaminaMax)
                end
            end
            return oldNewIndex(self, key, value)
        end)
        if setreadonly then setreadonly(mt, true) end
    end)
    return ok
end

-- strategi 3: hook FireServer di remote stamina
local function hookStaminaRemote(remote)
    if type(hookfunction) ~= "function" then
        task.spawn(function()
            while task.wait(0.5) do
                if State.Config.InfiniteStamina then
                    pcall(function() remote:FireServer("reset") end)
                    pcall(function() remote:FireServer(State.Config.StaminaMax) end)
                end
            end
        end)
        return
    end
    local ok = pcall(function()
        local oldFire
        oldFire = hookfunction(remote.FireServer, function(self, ...)
            if State.Config.InfiniteStamina and self == remote then
                local args = {...}
                for i, v in ipairs(args) do
                    if type(v) == "number" and v < State.Config.StaminaMax then
                        args[i] = State.Config.StaminaMax
                    end
                end
                return oldFire(self, table.unpack(args))
            end
            return oldFire(self, ...)
        end)
    end)
    if not ok then
        -- fallback spam
        task.spawn(function()
            while task.wait(0.5) do
                if State.Config.InfiniteStamina then
                    pcall(function() remote:FireServer("reset") end)
                end
            end
        end)
    end
end

-- strategi 4: freeze attribute
local function freezeAttribute(name)
    task.spawn(function()
        while task.wait(0.1) do
            if State.Config.InfiniteStamina then
                pcall(function()
                    LocalPlayer:SetAttribute(name, State.Config.StaminaMax)
                end)
            end
        end
    end)
end

-- scanner
local function scanStaminaTargets()
    if not State.Config.InfiniteStamina then return end

    for _, container in ipairs({
        LocalPlayer,
        LocalPlayer:FindFirstChildOfClass("PlayerGui"),
        LocalPlayer.Character,
    }) do
        if container then
            for _, inst in ipairs(container:GetDescendants()) do
                if inst:IsA("NumberValue") then
                    local n = inst.Name:lower()
                    if n:find("stamina") or n:find("energy") or n:find("fatigue")
                       or n:find("sprint") or n:find("endurance") then
                        if not hookedValues[inst] then hookStaminaValue(inst) end
                    end
                end
            end
        end
    end

    for _, attrName in ipairs({"Stamina","stamina","Energy","energy","Sprint","Fatigue"}) do
        local ok, val = pcall(function() return LocalPlayer:GetAttribute(attrName) end)
        if ok and val ~= nil and not knownAttrs[attrName] then
            knownAttrs[attrName] = true
            freezeAttribute(attrName)
        end
    end

    for _, r in ipairs(Cache.remotes) do
        local n = r.Name:lower()
        if (n:find("stamina") or n:find("sprint") or n:find("drain")
            or n:find("energy") or n:find("fatigue") or n:find("cooldown"))
           and not knownRemotes[r] then
            knownRemotes[r] = true
            hookStaminaRemote(r)
        end
    end
end

installMetaHook()

task.spawn(function()
    while task.wait(0.3) do
        pcall(scanStaminaTargets)
    end
end)

task.spawn(function()
    while task.wait(5) do
        if State.Config.InfiniteStamina then
            knownRemotes = {}
            knownAttrs = {}
        end
    end
end)

-- ============================================================
-- FEATURE LOOPS
-- ============================================================

-- Ball Magnet
task.spawn(function()
    while task.wait(0.05) do
        if State.Config.BallMagnet then
            local char = Cache.character or LocalPlayer.Character
            local ball = findBall()
            if char and ball then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - ball.Position).Magnitude
                    if d <= State.Config.BallMagnetRange and d > 1.5 then
                        local dir = (hrp.Position - ball.Position).Unit
                        local pull = dir * (State.Config.BallMagnetRange - d) * 4
                        ball.AssemblyLinearVelocity = Vector3.new(pull.X, 0, pull.Z)
                    end
                end
            end
        end
    end
end)

-- power shot helper
local function powerShot()
    local ball = findBall()
    if not ball then return end
    local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name or nil
    local targetCF = nil
    for _, g in ipairs(Cache.goals) do
        if myTeam and not g.name:lower():find(myTeam:lower()) then
            targetCF = g.cframe break
        end
    end
    if not targetCF and #Cache.goals > 0 then
        local hrp = Cache.character and Cache.character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local maxD, best = 0, nil
            for _, g in ipairs(Cache.goals) do
                local d = (g.cframe.Position - hrp.Position).Magnitude
                if d > maxD then maxD, best = d, g end
            end
            targetCF = best and best.cframe or nil
        end
    end
    if not targetCF then return end
    local dir = (targetCF.Position - ball.Position)
    if dir.Magnitude < 0.5 then return end
    dir = dir.Unit
    ball.AssemblyLinearVelocity = dir * State.Config.AutoKickPower
    for _, r in ipairs(Cache.remotes) do
        local n = r.Name:lower()
        if n:find("kick") or n:find("shoot") then
            safeFire(r, ball, dir, State.Config.AutoKickPower)
            break
        end
    end
end

-- Auto Kick
task.spawn(function()
    while task.wait(0.1) do
        if State.Config.AutoKick then
            local char, ball = Cache.character, findBall()
            if char and ball then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp and (hrp.Position - ball.Position).Magnitude <= State.Config.AutoKickRange then
                    powerShot()
                end
            end
        end
    end
end)

-- Speed Boost (dengan reset defaultSpeed)
local defaultSpeed = nil

LocalPlayer.CharacterAdded:Connect(function()
    defaultSpeed = nil
end)

task.spawn(function()
    while task.wait(0.2) do
        local hum = Cache.humanoid
        if hum then
            if defaultSpeed == nil then defaultSpeed = hum.WalkSpeed end
            hum.WalkSpeed = State.Config.SpeedBoost
                and (State.Config.WalkSpeed or 60)
                or (defaultSpeed or 16)
        end
    end
end)

-- Aimbot Kick
task.spawn(function()
    while task.wait(0.1) do
        if State.Config.AimbotKick then
            local ball = findBall()
            if ball and #Cache.goals > 0 then
                local myTeam = LocalPlayer.Team and LocalPlayer.Team.Name or nil
                local target = nil
                for _, g in ipairs(Cache.goals) do
                    if not myTeam or not g.name:lower():find(myTeam:lower()) then
                        target = g break
                    end
                end
                target = target or Cache.goals[1]
                local corner = target.cframe * CFrame.new(3, 1, 0)
                local dir = (corner.Position - ball.Position).Unit
                ball.AssemblyLinearVelocity = dir * State.Config.AutoKickPower
            end
        end
    end
end)

-- ============================================================
-- ESP
-- ============================================================
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "IS_ESP"
for _, parent in ipairs({
    CoreGui,
    LocalPlayer:FindFirstChildOfClass("PlayerGui"),
}) do
    if tryParent(ESPFolder, parent) then break end
end
if not ESPFolder.Parent then
    warn("[IS-E] ESP folder gagal dipasang — ESP gak render.")
end

local function makeESP(part, color, label)
    local box = Instance.new("BoxHandleAdornment")
    box.Size         = part.Size + Vector3.new(0.2, 0.2, 0.2)
    box.Adornee      = part
    box.AlwaysOnTop  = true
    box.ZIndex       = 5
    box.Transparency = 0.6
    box.Color3       = color
    box.Parent       = ESPFolder

    if label then
        local bb = Instance.new("BillboardGui")
        bb.Size        = UDim2.new(0, 100, 0, 20)
        bb.StudsOffset = Vector3.new(0, 3, 0)
        bb.AlwaysOnTop = true
        bb.Adornee     = part
        bb.Parent      = ESPFolder

        local txt = Instance.new("TextLabel")
        txt.Size                   = UDim2.new(1, 0, 1, 0)
        txt.BackgroundTransparency = 1
        txt.TextColor3             = color
        txt.TextStrokeTransparency = 0
        txt.TextScaled             = true
        txt.Font                   = Enum.Font.GothamBold
        txt.Text                   = label
        txt.Parent                 = bb
    end
    return box
end

local espCache = {}
local function clearESP()
    for _, v in pairs(espCache) do pcall(function() v:Destroy() end) end
    espCache = {}
end

task.spawn(function()
    while task.wait(0.5) do
        if State.Config.ESP then
            clearESP()
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        espCache[plr] = makeESP(hrp,
                            State.Config.ESPColor,
                            plr.Name .. " [" .. (plr.Team and plr.Team.Name or "?") .. "]")
                    end
                end
            end
            if State.Config.BallESP then
                local ball = findBall()
                if ball then
                    espCache["__ball"] = makeESP(ball, Color3.fromRGB(0,255,100), "BALL")
                end
            end
        else
            clearESP()
        end
    end
end)

-- Teleport ke bola
local function tpToBall()
    local ball, char = findBall(), Cache.character
    if not (ball and char) then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    tweenTo(ball.CFrame * CFrame.new(0, 0, 3), State.Config.TweenSpeed)
end

-- ============================================================
-- PANEL
-- ============================================================
local function buildPanel()
    local gui = Instance.new("ScreenGui")
    gui.Name           = "IS_Panel"
    gui.ResetOnSpawn   = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local parented = false
    local candidates = {}
    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then table.insert(candidates, hui) end
    end
    table.insert(candidates, CoreGui)
    table.insert(candidates, LocalPlayer:FindFirstChildOfClass("PlayerGui"))

    for _, parent in ipairs(candidates) do
        if parent and tryParent(gui, parent) then
            parented = true
            break
        end
    end

    if not parented then
        warn("[IS-E] FATAL: gagal parent ScreenGui. panel gak akan muncul.")
        return
    end
    print("[IS-E] panel dipasang ke: " .. gui.Parent:GetFullName())

    -- ukuran panel mobile-friendly
    local panelW, panelH = 300, 420
    if IsDelta or UserInputService.TouchEnabled then
        panelW, panelH = 320, 460
    end

    -- tombol floating
    local openBtn = Instance.new("TextButton")
    openBtn.Size             = UDim2.new(0, 60, 0, 60)
    openBtn.Position         = UDim2.new(0, 20, 0, 100)
    openBtn.BackgroundColor3 = Color3.fromRGB(50, 100, 200)
    openBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    openBtn.Font             = Enum.Font.GothamBold
    openBtn.TextSize         = 18
    openBtn.Text             = "IS"
    openBtn.BorderSizePixel  = 0
    openBtn.Draggable        = true
    openBtn.Active           = true
    openBtn.Parent           = gui
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = openBtn
    end

    -- panel utama
    local main = Instance.new("Frame")
    main.Size             = UDim2.new(0, panelW, 0, panelH)
    main.Position         = UDim2.new(0, 20, 0, 180)
    main.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    main.BorderSizePixel  = 0
    main.Active           = true
    main.Draggable        = true
    main.Visible          = false
    main.Parent           = gui
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = main
        local s = Instance.new("UIStroke")
        s.Color     = Color3.fromRGB(50, 100, 200)
        s.Thickness = 1.5
        s.Parent    = main
    end

    -- header
    local header = Instance.new("TextLabel")
    header.Size             = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    header.TextColor3       = Color3.fromRGB(255, 255, 255)
    header.Font             = Enum.Font.GothamBold
    header.TextSize         = 14
    header.Text             = "ILLEGAL SOCCER  •  outcome"
    header.BorderSizePixel  = 0
    header.Parent           = main
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 10) c.Parent = header
    end

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size             = UDim2.new(0, 30, 0, 30)
    closeBtn.Position         = UDim2.new(1, -35, 0, 5)
    closeBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60)
    closeBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    closeBtn.Font             = Enum.Font.GothamBold
    closeBtn.TextSize         = 14
    closeBtn.Text             = "X"
    closeBtn.BorderSizePixel  = 0
    closeBtn.Parent           = header
    do
        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = closeBtn
    end

    -- status
    local status = Instance.new("TextLabel")
    status.Size                   = UDim2.new(1, -10, 0, 18)
    status.Position               = UDim2.new(0, 5, 0, 42)
    status.BackgroundTransparency = 1
    status.TextColor3             = Color3.fromRGB(140, 140, 150)
    status.Font                   = Enum.Font.Gotham
    status.TextSize               = 11
    status.TextXAlignment         = Enum.TextXAlignment.Left
    status.Text                   = "executor: " .. ExecutorName
    status.Parent                 = main

    -- list
    local list = Instance.new("ScrollingFrame")
    list.Size                   = UDim2.new(1, -10, 1, -70)
    list.Position               = UDim2.new(0, 5, 0, 64)
    list.BackgroundTransparency = 1
    list.BorderSizePixel        = 0
    list.ScrollBarThickness     = 4
    list.CanvasSize             = UDim2.new(0, 0, 0, 0)
    list.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    list.Parent                 = main

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 6)
    layout.Parent  = list

    local function makeToggle(label, key)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, -6, 0, 40)
        btn.BackgroundColor3 = State.Config[key]
            and Color3.fromRGB(45, 160, 80)
            or Color3.fromRGB(38, 38, 48)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        btn.Font             = Enum.Font.Gotham
        btn.TextSize         = 13
        btn.Text             = label .. "  [" .. (State.Config[key] and "ON" or "OFF") .. "]"
        btn.BorderSizePixel  = 0
        btn.Parent           = list
        do
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
        end
        btn.MouseButton1Click:Connect(function()
            State.Config[key] = not State.Config[key]
            btn.Text = label .. "  [" .. (State.Config[key] and "ON" or "OFF") .. "]"
            btn.BackgroundColor3 = State.Config[key]
                and Color3.fromRGB(45, 160, 80)
                or Color3.fromRGB(38, 38, 48)
        end)
        return btn
    end

    local function makeAction(label, color, cb)
        local btn = Instance.new("TextButton")
        btn.Size             = UDim2.new(1, -6, 0, 40)
        btn.BackgroundColor3 = color or Color3.fromRGB(50, 100, 200)
        btn.TextColor3       = Color3.fromRGB(255, 255, 255)
        btn.Font             = Enum.Font.GothamBold
        btn.TextSize         = 13
        btn.Text             = label
        btn.BorderSizePixel  = 0
        btn.Parent           = list
        do
            local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 8) c.Parent = btn
        end
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    makeToggle("Ball Magnet",      "BallMagnet")
    makeToggle("Auto Kick",        "AutoKick")
    makeToggle("Speed Boost",      "SpeedBoost")
    makeToggle("Infinite Stamina", "InfiniteStamina")
    makeToggle("Aimbot Kick",      "AimbotKick")
    makeToggle("ESP Pemain",       "ESP")
    makeToggle("ESP Bola",         "BallESP")

    makeAction("TELEPORT KE BOLA", Color3.fromRGB(50, 100, 200), tpToBall)
    makeAction("PANIC OFF", Color3.fromRGB(200, 60, 60), function()
        for k, v in pairs(State.Config) do
            if type(v) == "boolean" then State.Config[k] = false end
        end
        for _, ch in ipairs(list:GetChildren()) do
            if ch:IsA("TextButton") then
                local base = ch.Text:match("^(.-)%s*%[")
                if base then
                    ch.Text = base .. "  [OFF]"
                    ch.BackgroundColor3 = Color3.fromRGB(38, 38, 48)
                end
            end
        end
    end)

    openBtn.MouseButton1Click:Connect(function()
        main.Visible = not main.Visible
    end)
    closeBtn.MouseButton1Click:Connect(function()
        main.Visible = false
    end)

    print("[IS-E] panel siap. tap tombol 'IS' buat buka.")
end

buildPanel()
print("[IS-E] Illegal Soccer exploit loaded.")