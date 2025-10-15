-- // Load Rayfield UI
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- // Window Setup
local Window = Rayfield:CreateWindow({
    Name = "Coba Coba Hub",
    LoadingTitle = "Coba Coba Hub",
    LoadingSubtitle = "by Fell",
    Theme = "Default",
    ToggleUIKeybind = Enum.KeyCode.K,

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CobaCobaHub",
        FileName = "BigHub"
    },

    Discord = {
        Enabled = true,
        Invite = "Am3HvspbV6",
        RememberJoins = true
    },

    KeySystem = false,
})

------------------------------------------------
-- // PLAYER TAB
------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Variables
local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10
local velocity = Vector3.new(0, 0, 0)

-- Slider
PlayerTab:CreateSlider({
    Name = "WalkSpeed",
    Range = {16, 300},
    Increment = 1,
    Suffix = "Speed",
    CurrentValue = SpeedValue,
    Flag = "WalkSpeedSlider",
    Callback = function(Value)
        SpeedValue = Value
    end
})

-- Toggle
PlayerTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Flag = "WalkSpeedToggle",
    Callback = function(Value)
        SpeedEnabled = Value
        if not Value then
            velocity = Vector3.new(0, 0, 0)
        end
    end
})

-- Function ambil karakter dan komponen
local function getCharParts()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if root and humanoid then
        return char, root, humanoid
    end
end

-- Movement handler
RunService.RenderStepped:Connect(function(dt)
    if not SpeedEnabled then return end

    local char, root, humanoid = getCharParts()
    if not (char and root and humanoid) then return end

    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        local targetVelocity = moveDir.Unit * SpeedValue
        velocity = velocity:Lerp(targetVelocity, math.clamp(SmoothFactor * dt, 0, 1))
    else
        velocity = velocity:Lerp(Vector3.new(0, 0, 0), math.clamp(SmoothFactor * dt * 1.5, 0, 1))
    end

    root.CFrame = root.CFrame + (velocity * dt)
end)

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")
    velocity = Vector3.new(0, 0, 0)
end)

------------------------------------------------
-- // TELEPORT TAB (SEA 3)
------------------------------------------------
local TeleportTab = Window:CreateTab("Teleport (Sea 3)", 6034287595)

-- Daftar koordinat island Sea 3
local Islands = {
    ["Castle on the Sea"] = Vector3.new(-5500, 313, -2800),
    ["Port Town"] = Vector3.new(-6100, 75, 1630),
    ["Hydra Island"] = Vector3.new(5200, 100, -3200),
    ["Great Tree"] = Vector3.new(2285, 25, -6400),
    ["Floating Turtle"] = Vector3.new(-12000, 340, -8700),
    ["Haunted Castle"] = Vector3.new(-9500, 140, 6100),
    ["Sea of Treats"] = Vector3.new(-12000, 110, 11000)
}

local SelectedIsland = nil
local TweenSpeed = 300 -- semakin besar = semakin cepat

-- Dropdown pilih island
local IslandDropdown = TeleportTab:CreateDropdown({
    Name = "Select Island",
    Options = {},
    CurrentOption = "",
    Flag = "IslandDropdown",
    Callback = function(Option)
        SelectedIsland = Option
    end,
})

for name, _ in pairs(Islands) do
    IslandDropdown:AddOption(name)
end

-- Fungsi Tween Teleport
local function TweenTeleport(position)
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local distance = (root.Position - position).Magnitude
    local tweenTime = math.clamp(distance / TweenSpeed, 1, 10)

    local tweenInfo = TweenInfo.new(tweenTime, Enum.EasingStyle.Linear)
    local tween = TweenService:Create(root, tweenInfo, {CFrame = CFrame.new(position)})
    tween:Play()
end

-- Tombol Teleport
TeleportTab:CreateButton({
    Name = "Teleport Now",
    Callback = function()
        if SelectedIsland and Islands[SelectedIsland] then
            Rayfield:Notify({
                Title = "Teleporting...",
                Content = "Traveling to " .. SelectedIsland .. " 🌊",
                Duration = 3
            })
            TweenTeleport(Islands[SelectedIsland])
        else
            Rayfield:Notify({
                Title = "Error",
                Content = "Please select an island first!",
                Duration = 3
            })
        end
    end,
})
