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
-- 🧍 PLAYER TAB
-------------------------------------------------
local PlayerTab = Window:CreateTab("Player", 4483362458)

local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10
local velocity = Vector3.zero
local WalkOnWaterEnabled = false
local WaterHeightOffset = 3

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

-- 🌊 Walk on Water Toggle
PlayerTab:CreateToggle({
	Name = "Walk on Water",
	CurrentValue = false,
	Flag = "WaterToggle",
	Callback = function(v)
		WalkOnWaterEnabled = v
	end
})

local function GetChar()
	local c = player.Character or player.CharacterAdded:Wait()
	local hrp = c:WaitForChild("HumanoidRootPart", 3)
	local hum = c:FindFirstChildOfClass("Humanoid")
	return c, hrp, hum
end

-- 🌀 Movement
RunService.RenderStepped:Connect(function(dt)
	local c, hrp, hum = GetChar()
	if not (c and hrp and hum) then return end

	-- 🚶 Smooth Speed System
	if SpeedEnabled then
		local dir = hum.MoveDirection
		if dir.Magnitude > 0 then
			velocity = velocity:Lerp(dir.Unit * SpeedValue, math.clamp(SmoothFactor * dt, 0, 1))
		else
			velocity = velocity:Lerp(Vector3.zero, math.clamp(SmoothFactor * dt * 1.5, 0, 1))
		end
		hrp.CFrame = hrp.CFrame + (velocity * dt)
	end

	-- 🌊 Walk on Water System
	if WalkOnWaterEnabled then
		local ray = Ray.new(hrp.Position, Vector3.new(0, -10, 0))
		local hit, pos = Workspace:FindPartOnRay(ray, c)
		if hit and hit.Material == Enum.Material.Water then
			local desiredY = pos.Y + WaterHeightOffset
			if hrp.Position.Y < desiredY then
				hrp.Velocity = Vector3.zero
				hrp.CFrame = CFrame.new(hrp.Position.X, desiredY, hrp.Position.Z)
			end
		end
	end
end)

-- 🔄 Load Dropdown
RefreshDropdown()
