-- 🧩 Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-------------------------------------------------
-- ⚙️ Window Setup
-------------------------------------------------
local Window = Rayfield:CreateWindow({
    Name = "Coba Coba Hub",
    LoadingTitle = "Coba Coba Hub",
    LoadingSubtitle = "by Fell",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.K,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CobaCobaHub",
        FileName = "HubConfig"
    }
})

-------------------------------------------------
-- 🧍 PLAYER TAB
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
    local c = player.Character or player.CharacterAdded:Wait()
    local hrp = c:WaitForChild("HumanoidRootPart", 3)
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
    hrp.CFrame = hrp.CFrame + (velocity * dt)
end)

-------------------------------------------------
-- 🌍 TELEPORT TAB (Sea 3 + Library)
-------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport", 6034287595)

-- 🏝️ Sea 3 Locations (updated)
local Islands = {
    ["Castle on the Sea"] = Vector3.new(-5496, 313, -2821),
    ["Port Town"] = Vector3.new(-6102, 75, 1616),
    ["Hydra Island"] = Vector3.new(5220, 100, -3200),
    ["Great Tree"] = Vector3.new(2275, 25, -6399),
    ["Floating Turtle"] = Vector3.new(-12038, 340, -8693),
    ["Haunted Castle"] = Vector3.new(-9515, 140, 6106),
    ["Sea of Treats"] = Vector3.new(-12262, 110, 11055)
}

local CustomSpots = {}
local SelectedLocation = nil
local TweenMode = true

-- 🌀 Tween Teleport
local function TweenTeleport(pos)
    local _, hrp = GetChar()
    if not hrp then return end
    local dist = (hrp.Position - pos).Magnitude
    local tweenTime = math.clamp(dist / 300, 1, 10)
    local tween = TweenService:Create(hrp, TweenInfo.new(tweenTime, Enum.EasingStyle.Linear), {CFrame = CFrame.new(pos)})
    tween:Play()
end

-- ⚡ Instant Teleport
local function InstantTeleport(pos)
    local _, hrp = GetChar()
    if hrp then
        hrp.CFrame = CFrame.new(pos)
    end
end

-- 📜 Dropdown (dynamic refresh)
local TeleportDropdown
TeleportDropdown = TeleportTab:CreateDropdown({
    Name = "Select Location",
    Options = {},
    CurrentOption = "",
    Flag = "TeleportDropdown",
    Callback = function(opt)
        SelectedLocation = opt
    end
})

local function RefreshDropdown()
    local allLocations = {}
    for name, _ in pairs(Islands) do
        table.insert(allLocations, name)
    end
    for name, _ in pairs(CustomSpots) do
        table.insert(allLocations, name)
    end
    TeleportDropdown:SetOptions(allLocations)
end

-- 🧭 Mode Switch (Tween / Instant)
TeleportTab:CreateToggle({
    Name = "Tween Mode (Smooth Travel)",
    CurrentValue = TweenMode,
    Callback = function(v)
        TweenMode = v
    end
})

-- 🚀 Teleport Button
TeleportTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        if not SelectedLocation then
            return Rayfield:Notify({
                Title = "⚠️ Error",
                Content = "Please select a location first!",
                Duration = 3
            })
        end

        local pos = Islands[SelectedLocation] or CustomSpots[SelectedLocation]
        if pos then
            Rayfield:Notify({
                Title = "🌊 Teleporting",
                Content = "Traveling to " .. SelectedLocation,
                Duration = 3
            })

            if TweenMode then
                TweenTeleport(pos)
            else
                InstantTeleport(pos)
            end
        else
            Rayfield:Notify({
                Title = "⚠️ Error",
                Content = "Location not found!",
                Duration = 3
            })
        end
    end
})

-- ➕ Add Custom Spot
TeleportTab:CreateInput({
    Name = "Add Custom Location (Name)",
    PlaceholderText = "Example: MySpot",
    RemoveTextAfterFocusLost = false,
    Callback = function(name)
        local _, hrp = GetChar()
        if not hrp or name == "" then return end
        CustomSpots[name] = hrp.Position
        RefreshDropdown()
        Rayfield:Notify({
            Title = "✅ Saved",
            Content = "Added custom spot: " .. name,
            Duration = 3
        })
    end
})

-- ❌ Delete Custom Spot
TeleportTab:CreateButton({
    Name = "Delete Selected Location",
    Callback = function()
        if CustomSpots[SelectedLocation] then
            CustomSpots[SelectedLocation] = nil
            RefreshDropdown()
            Rayfield:Notify({
                Title = "🗑️ Deleted",
                Content = "Removed custom spot: " .. SelectedLocation,
                Duration = 3
            })
        else
            Rayfield:Notify({
                Title = "⚠️ Error",
                Content = "Only custom spots can be deleted!",
                Duration = 3
            })
        end
    end
})

-- 🔄 Initialize
RefreshDropdown()
