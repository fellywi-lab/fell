-- 🧩 Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
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
-- 🧍 MAIN TAB
-------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

-------------------------------------------------
-- 🧍 PLAYER TAB
-------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10 -- responsif tapi tetap halus

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

local WalkSpeedToggle = PlayerTab:CreateToggle({
    Name = "Enable WalkSpeed",
    CurrentValue = false,
    Flag = "WalkSpeedToggle",
    Callback = function(Value)
        SpeedEnabled = Value
    end
})

local function getCharParts()
    local char = player.Character
    if not char then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if root and humanoid then
        return char, root, humanoid
    end
end

local velocity = Vector3.zero

RunService.RenderStepped:Connect(function(dt)
    if not SpeedEnabled then
        velocity = Vector3.zero
        return
    end

    local char, root, humanoid = getCharParts()
    if not (char and root and humanoid) then return end

    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude > 0 then
        local targetVelocity = moveDir.Unit * SpeedValue
        velocity = velocity:Lerp(targetVelocity, math.clamp(SmoothFactor * dt, 0, 1))
    else
        velocity = velocity:Lerp(Vector3.zero, math.clamp(SmoothFactor * dt * 1.5, 0, 1))
    end

    root.CFrame = root.CFrame + (velocity * dt)
end)

player.CharacterAdded:Connect(function(char)
    char:WaitForChild("HumanoidRootPart")
    char:WaitForChild("Humanoid")
    velocity = Vector3.zero
end)

-------------------------------------------------
-- ♾️ INFINITE JUMP (Fixed)
-------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local InfiniteJumpEnabled = false
local canJump = true

-- 🧩 Tambahkan Toggle di Tab Player
PlayerTab:CreateToggle({
	Name = "Infinite Jump",
	CurrentValue = false,
	Flag = "InfiniteJumpToggle",
	Callback = function(v)
		InfiniteJumpEnabled = v
		Rayfield:Notify({
			Title = "Infinite Jump",
			Content = v and "✅ Aktif" or "❌ Nonaktif",
			Duration = 2
		})
	end
})

-- 🌀 Sistem lompat tanpa batas
UserInputService.JumpRequest:Connect(function()
	if InfiniteJumpEnabled and canJump then
		canJump = false
		local character = player.Character or player.CharacterAdded:Wait()
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
			task.wait(0.05) -- delay kecil agar tidak spam error
			humanoid:ChangeState(Enum.HumanoidStateType.Seated) -- trik supaya bisa lompat terus
			task.wait(0.05)
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
		end
		canJump = true
	end
end)

-- 🔁 Pastikan tetap aktif setelah respawn
player.CharacterAdded:Connect(function(char)
	task.wait(1)
	if InfiniteJumpEnabled then
		local hum = char:WaitForChild("Humanoid")
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
	end
end)
