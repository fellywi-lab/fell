local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Window setup
local Window = Rayfield:CreateWindow({
    Name = "Coba Coba Hub",
    LoadingTitle = "Coba Coba Hub",
    LoadingSubtitle = "by Fell",
    ShowText = "Rayfield",
    Theme = "Default",
    ToggleUIKeybind = "K",

    ConfigurationSaving = {
        Enabled = true,
        FolderName = "CobaCobaHub",
        FileName = "BigHub"
    },

    Discord = {
        Enabled = true,
        Invite = "Am3HvspbV6", -- cukup kode undangan
        RememberJoins = true
    },

    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = true,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

-- Tab Player
local PlayerTab = Window:CreateTab("Player", 4483362458)

-- Variables
local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10
local velocity = Vector3.new(0, 0, 0)

-- Slider
local WalkSpeedSlider = PlayerTab:CreateSlider({
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
local WalkSpeedToggle = PlayerTab:CreateToggle({
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

-- Reset saat karakter respawn
player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")
    velocity = Vector3.new(0, 0, 0)
end)
