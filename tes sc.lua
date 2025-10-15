-- ThanHub-style Minimal UI (Yellow & White)
-- Features: Player controls (speed/jump/fly/noclip/infinite jump), Teleport Sea3 (tween), Misc (anti-afk, rejoin, server hop), custom teleport library
-- Note: If CoreGui is blocked on your executor, change `guiParent` to PlayerGui.

-- ===== Services =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local HttpService = game:GetService("HttpService")

local player = Players.LocalPlayer
local guiParent = game:GetService("CoreGui") -- change to player:WaitForChild("PlayerGui") if needed

-- ===== Config & State =====
local Theme = {
    Background = Color3.fromRGB(28, 28, 28),
    Accent = Color3.fromRGB(255, 204, 51), -- yellow
    White = Color3.fromRGB(245, 245, 245),
    Dark = Color3.fromRGB(16, 16, 16)
}

local state = {
    speed = 16,
    jump = 50,
    fly = false,
    noclip = false,
    infjump = false,
    tweenMode = true,
    selectedLocation = nil,
    customSpots = {}, -- name -> Vector3
    velocity = Vector3.new(0,0,0),
    smoothFactor = 10,
    flyForce = 200
}

-- default Sea 3 islands (approx)
local Sea3Islands = {
    ["Castle on the Sea"] = Vector3.new(-5500, 313, -2800),
    ["Port Town"] = Vector3.new(-6100, 75, 1630),
    ["Hydra Island"] = Vector3.new(5200, 100, -3200),
    ["Great Tree"] = Vector3.new(2285, 25, -6400),
    ["Floating Turtle"] = Vector3.new(-12000, 340, -8700),
    ["Haunted Castle"] = Vector3.new(-9500, 140, 6100),
    ["Sea of Treats"] = Vector3.new(-12000, 110, 11000),
    ["Candy Land"] = Vector3.new(-11108, 100, 12094),
    ["Cake Land"] = Vector3.new(-10383, 100, 9978),
    ["Ice Cream Island"] = Vector3.new(-9250, 100, 10736),
    ["Peanut Island"] = Vector3.new(-12051, 100, 9565),
    ["Chocolate Island"] = Vector3.new(-12500, 100, 9112),
    ["Mansion"] = Vector3.new(-12450, 375, -8700),
    ["Tiki Outpost"] = Vector3.new(-16500, 400, -12000)
}

-- persistence file (optional)
local saveFilename = "thanhub_custom_spots.json"
local function tryWriteFile(name, content)
    local ok, _ = pcall(function() writefile(name, content) end)
    return ok
end
local function tryReadFile(name)
    local ok, content = pcall(function() return readfile(name) end)
    if ok then return content end
    return nil
end

-- load saved custom spots (if available)
do
    local data = tryReadFile(saveFilename)
    if data then
        local ok, t = pcall(function() return HttpService:JSONDecode(data) end)
        if ok and type(t) == "table" then
            for k,v in pairs(t) do
                if type(v) == "table" and #v==3 then
                    state.customSpots[k] = Vector3.new(v[1], v[2], v[3])
                end
            end
        end
    end
end

-- ===== Utility =====
local function GetChar()
    local c = player.Character or player.CharacterAdded:Wait()
    local hrp = c:FindFirstChild("HumanoidRootPart") or c:WaitForChild("HumanoidRootPart", 5)
    local hum = c:FindFirstChildOfClass("Humanoid")
    return c, hrp, hum
end

local function Notify(title, text, duration)
    duration = duration or 3
    pcall(function() -- try using Rayfield notify if present
        if Rayfield and Rayfield.Notify then
            Rayfield:Notify({Title = title, Content = text, Duration = duration})
            return
        end
    end)
    -- fallback simple print
    print(("[Notify] %s: %s"):format(title or "Info", text or ""))
end

-- ===== Tween / Instant Teleport =====
local function TweenTeleport(position)
    local _, hrp = GetChar()
    if not hrp then return end
    local dist = (hrp.Position - position).Magnitude
    local tweenTime = math.clamp(dist / 400, 0.6, 8) -- tweak speed
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(position + Vector3.new(0,3,0))})
    tween:Play()
end

local function InstantTeleport(position)
    local _, hrp = GetChar()
    if hrp then
        hrp.CFrame = CFrame.new(position + Vector3.new(0,3,0))
    end
end

-- ===== GUI BUILD =====
-- basic minimal container
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ThanHubMinimal_YW" -- YW = yellow white
screenGui.ResetOnSpawn = false
screenGui.Parent = guiParent

local mainFrame = Instance.new("Frame")
mainFrame.Name = "Main"
mainFrame.Size = UDim2.new(0, 740, 0, 460)
mainFrame.Position = UDim2.new(0.5, -370, 0.5, -230)
mainFrame.AnchorPoint = Vector2.new(0.5,0.5)
mainFrame.BackgroundColor3 = Theme.Background
mainFrame.BorderSizePixel = 0
mainFrame.Parent = screenGui

-- top bar
local topBar = Instance.new("Frame", mainFrame)
topBar.Size = UDim2.new(1,0,0,34)
topBar.BackgroundColor3 = Theme.Dark
topBar.BorderSizePixel = 0
topBar.Name = "TopBar"

local title = Instance.new("TextLabel", topBar)
title.Text = "ThanHub-style (Minimal) - Yellow/White"
title.TextColor3 = Theme.White
title.Font = Enum.Font.GothamSemibold
title.TextSize = 14
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -10, 1, 0)
title.Position = UDim2.new(0, 8, 0, 0)
title.TextXAlignment = Enum.TextXAlignment.Left

-- left sidebar
local sideBar = Instance.new("Frame", mainFrame)
sideBar.Name = "Sidebar"
sideBar.Size = UDim2.new(0, 78, 1, -34)
sideBar.Position = UDim2.new(0,0,0,34)
sideBar.BackgroundColor3 = Theme.Dark
sideBar.BorderSizePixel = 0

-- container for content
local contentFrame = Instance.new("Frame", mainFrame)
contentFrame.Name = "Content"
contentFrame.Size = UDim2.new(1, -78, 1, -34)
contentFrame.Position = UDim2.new(0,78,0,34)
contentFrame.BackgroundColor3 = Theme.Background
contentFrame.BorderSizePixel = 0

-- simple function to create tab button in sidebar
local tabs = {}
local currentTab = nil
local function CreateTabButton(name, idx)
    local btn = Instance.new("TextButton", sideBar)
    btn.Name = name .. "_Btn"
    btn.Size = UDim2.new(1, 0, 0, 64)
    btn.Position = UDim2.new(0, 0, 0, (idx-1)*64)
    btn.BackgroundColor3 = Theme.Background
    btn.BorderSizePixel = 0
    btn.Text = ""
    btn.AutoButtonColor = true

    local ic = Instance.new("TextLabel", btn)
    ic.Text = string.upper(string.sub(name,1,1))
    ic.Font = Enum.Font.GothamBold
    ic.TextSize = 20
    ic.TextColor3 = Theme.Dark
    ic.BackgroundColor3 = Theme.Accent
    ic.Size = UDim2.new(0, 46, 0, 46)
    ic.Position = UDim2.new(0.5, -23, 0, 9)
    ic.BorderSizePixel = 0

    local lbl = Instance.new("TextLabel", btn)
    lbl.Text = name
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 11
    lbl.TextColor3 = Theme.White
    lbl.BackgroundTransparency = 1
    lbl.Position = UDim2.new(0, 6, 0, 40)
    lbl.Size = UDim2.new(1, -12, 0, 20)
    lbl.TextWrapped = true
    lbl.TextXAlignment = Enum.TextXAlignment.Center

    btn.MouseButton1Click:Connect(function()
        -- hide all tabs
        for _,v in pairs(tabs) do
            v.frame.Visible = false
        end
        btn.BackgroundColor3 = Theme.Background
        -- show this tab
        local t = tabs[name]
        if t then
            t.frame.Visible = true
            currentTab = name
        end
    end)

    return btn
end

-- helper create control elements (label, toggle, slider, button, dropdown, input)
local function CreateLabel(parent, text, posY)
    local lbl = Instance.new("TextLabel", parent)
    lbl.Size = UDim2.new(1, -24, 0, 24)
    lbl.Position = UDim2.new(0, 12, 0, posY)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.TextColor3 = Theme.White
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    return lbl
end

local function CreateToggle(parent, text, posY, default, callback)
    CreateLabel(parent, text, posY)
    local tbtn = Instance.new("TextButton", parent)
    tbtn.Size = UDim2.new(0, 54, 0, 24)
    tbtn.Position = UDim2.new(1, -66, 0, posY)
    tbtn.Text = ""
    tbtn.BackgroundColor3 = default and Theme.Accent or Theme.Dark
    tbtn.BorderSizePixel = 0

    local dot = Instance.new("Frame", tbtn)
    dot.Size = UDim2.new(0, 18, 0, 18)
    dot.Position = UDim2.new(0, 4, 0, 3)
    dot.BackgroundColor3 = default and Theme.White or Color3.fromRGB(120,120,120)
    dot.Name = "dot"

    local stateVal = default
    tbtn.MouseButton1Click:Connect(function()
        stateVal = not stateVal
        tbtn.BackgroundColor3 = stateVal and Theme.Accent or Theme.Dark
        dot.BackgroundColor3 = stateVal and Theme.White or Color3.fromRGB(120,120,120)
        pcall(callback, stateVal)
    end)
    return tbtn
end

local function CreateSlider(parent, text, posY, min, max, default, callback)
    CreateLabel(parent, text, posY)
    local bar = Instance.new("Frame", parent)
    bar.Size = UDim2.new(1, -24, 0, 28)
    bar.Position = UDim2.new(0, 12, 0, posY + 26)
    bar.BackgroundColor3 = Theme.Dark
    bar.BorderSizePixel = 0

    local fill = Instance.new("Frame", bar)
    fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = Theme.Accent
    fill.BorderSizePixel = 0

    local valueLbl = Instance.new("TextLabel", bar)
    valueLbl.Size = UDim2.new(0, 60, 1, 0)
    valueLbl.Position = UDim2.new(1, -64, 0, 0)
    valueLbl.BackgroundTransparency = 1
    valueLbl.TextColor3 = Theme.White
    valueLbl.Font = Enum.Font.Gotham
    valueLbl.TextSize = 12
    valueLbl.Text = tostring(default)

    -- input logic
    local minv, maxv = min, max
    local dragging = false
    bar.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
        end
    end)
    bar.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if dragging and inp.UserInputType == Enum.UserInputType.MouseMovement then
            local mx = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(mx, 0, 1, 0)
            local val = math.floor(minv + (maxv - minv) * mx + 0.5)
            valueLbl.Text = tostring(val)
            pcall(callback, val)
        end
    end)
    return {bar = bar, fill = fill, valueLbl = valueLbl}
end

local function CreateButton(parent, text, posY, callback
