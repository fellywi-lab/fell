-- 🌟 ThanStyle Hub (Rayfield UI - Yellow White Theme)
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-------------------------------------------------
-- 🪄 Custom Theme (Yellow-White)
-------------------------------------------------
Rayfield:LoadConfiguration({
    Theme = {
        Background = Color3.fromRGB(255, 255, 240),
        Topbar = Color3.fromRGB(255, 230, 100),
        TabBackground = Color3.fromRGB(250, 250, 250),
        TabStroke = Color3.fromRGB(230, 200, 80),
        ElementBackground = Color3.fromRGB(255, 255, 255),
        ElementStroke = Color3.fromRGB(255, 240, 140),
        PrimaryText = Color3.fromRGB(60, 50, 0),
        SecondaryText = Color3.fromRGB(100, 90, 30),
        Accent = Color3.fromRGB(255, 210, 40)
    }
})

-------------------------------------------------
-- 🪪 Main Window
-------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "ThanStyle Hub",
    LoadingTitle = "ThanStyle Hub",
    LoadingSubtitle = "by Fell",
    Theme = "Default",
    ToggleUIKeybind = "K",

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "ThanStyleHub",
        FileName = "HubConfig"
    }
})

-------------------------------------------------
-- 🧍 Player Tab
-------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10
local velocity = Vector3.zero

PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    CurrentValue = SpeedValue,
    Suffix = "Speed",
    Flag = "SpeedSlider",
    Callback = function(v)
        SpeedValue = v
    end
})

PlayerTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Flag = "SpeedToggle",
    Callback = function(v)
        SpeedEnabled = v
    end
})

local function GetChar()
    local c = player.Character
    if not c then return end
    local hrp = c:FindFirstChild("HumanoidRootPart")
    local hum = c:FindFirstChildOfClass("Humanoid")
    return c, hrp, hum
end

RunService.RenderStepped:Connect(function(dt)
    if not SpeedEnabled then return end
    local c, hrp, hum = GetChar()
    if not (c and hrp and hum) then return end
    local dir = hum.MoveDirection
    if dir.Magnitude > 0 then
        velocity = velocity:Lerp(dir.Unit * SpeedValue, math.clamp(SmoothFactor * dt, 0, 1))
    else
        velocity = velocity:Lerp(Vector3.zero, math.clamp(SmoothFactor * dt * 1.5, 0, 1))
    end
    hrp.CFrame += (velocity * dt)
end)

-------------------------------------------------
-- 🌍 Teleport Tab (Sea 3 Islands)
-------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport (Sea 3)", 6034287595)

local Islands = {
    ["Castle on the Sea"] = Vector3.new(-5500, 313, -2800),
    ["Port Town"] = Vector3.new(-6100, 75, 1630),
    ["Hydra Island"] = Vector3.new(5200, 100, -3200),
    ["Great Tree"] = Vector3.new(2285, 25, -6400),
    ["Floating Turtle"] = Vector3.new(-12000, 340, -8700),
    ["Haunted Castle"] = Vector3.new(-9500, 140, 6100),
    ["Sea of Treats"] = Vector3.new(-12000, 110, 11000)
}

local CustomSpots = {}
local SelectedLocation = nil

local TeleportDropdown = TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = {},
    CurrentOption = "",
    Flag = "TeleportDropdown",
    Callback = function(opt)
        SelectedLocation = opt
    end
})

local function RefreshDropdown()
    TeleportDropdown:ClearOptions()
    for name, _ in pairs(Islands) do
        TeleportDropdown:AddOption(name)
    end
    for name, _ in pairs(CustomSpots) do
        TeleportDropdown:AddOption(name)
    end
end

local function TweenTeleport(pos)
    local c, hrp = GetChar()
    if not hrp then return end
    local dist = (hrp.Position - pos).Magnitude
    local tweenTime = math.clamp(dist / 300, 1, 10)
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
end

TeleportTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        local pos = Islands[SelectedLocation] or CustomSpots[SelectedLocation]
        if pos then
            Rayfield:Notify({
                Title = "Teleporting...",
                Content = "Traveling to " .. SelectedLocation .. " 🌊",
                Duration = 3
            })
            TweenTeleport(pos)
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Select a valid island first!",
                Duration = 3
            })
        end
    end
})

TeleportTab:CreateInput({
    Name = "Add Custom Location",
    PlaceholderText = "Name this spot...",
    RemoveTextAfterFocusLost = false,
    Callback = function(name)
        local _, hrp = GetChar()
        if not hrp or name == "" then return end
        CustomSpots[name] = hrp.Position
        RefreshDropdown()
        Rayfield:Notify({
            Title = "Saved",
            Content = "Custom spot '" .. name .. "' added!",
            Duration = 3
        })
    end
})

TeleportTab:CreateButton({
    Name = "Delete Selected Location",
    Callback = function()
        if CustomSpots[SelectedLocation] then
            CustomSpots[SelectedLocation] = nil
            RefreshDropdown()
            Rayfield:Notify({
                Title = "Deleted",
                Content = "Removed: " .. SelectedLocation,
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Only custom spots can be deleted.",
                Duration = 3
            })
        end
    end
})

RefreshDropdown()

