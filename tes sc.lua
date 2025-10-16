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

-------------------------------------------------
-- 👁️ PLAYER ESP (SHOW NAME + DISTANCE)
-------------------------------------------------
local ESPEnabled = false
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = Workspace

-- Tambahkan Toggle ke tab Player
PlayerTab:CreateToggle({
	Name = "Player ESP (With Distance)",
	CurrentValue = false,
	Flag = "PlayerESPToggle",
	Callback = function(state)
		ESPEnabled = state
		if not state then
			for _, v in pairs(ESPFolder:GetChildren()) do
				v:Destroy()
			end
		end
	end
})

-- Fungsi buat label ESP
local function CreateESP(plr)
	task.spawn(function()
		repeat task.wait(0.5) until plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")

		if not plr.Character or ESPFolder:FindFirstChild(plr.Name) then return end

		local billboard = Instance.new("BillboardGui")
		billboard.Name = plr.Name
		billboard.Size = UDim2.new(0, 200, 0, 40)
		billboard.AlwaysOnTop = true
		billboard.Adornee = plr.Character:WaitForChild("HumanoidRootPart")
		billboard.Parent = ESPFolder

		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 1, 0)
		label.BackgroundTransparency = 1
		label.TextColor3 = Color3.fromRGB(255, 255, 0)
		label.TextStrokeTransparency = 0.2
		label.Font = Enum.Font.SourceSansBold
		label.TextScaled = true
		label.Parent = billboard
	end)
end

-- Update ESP tiap frame
RunService.RenderStepped:Connect(function()
	if not ESPEnabled then return end

	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= player and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
			if not ESPFolder:FindFirstChild(plr.Name) then
				CreateESP(plr)
			end

			local esp = ESPFolder:FindFirstChild(plr.Name)
			if esp and esp:FindFirstChildOfClass("TextLabel") then
				local label = esp:FindFirstChildOfClass("TextLabel")
				local distance = math.floor((player.Character.HumanoidRootPart.Position - plr.Character.HumanoidRootPart.Position).Magnitude)
				label.Text = string.format("%s\n[%dm]", plr.DisplayName or plr.Name, distance)

				-- Warna dinamis
				if distance < 50 then
					label.TextColor3 = Color3.fromRGB(255, 70, 70)
				elseif distance < 150 then
					label.TextColor3 = Color3.fromRGB(255, 255, 100)
				else
					label.TextColor3 = Color3.fromRGB(100, 255, 100)
				end
			end
		end
	end
end)

-- Update saat pemain baru join
Players.PlayerAdded:Connect(function(plr)
	if ESPEnabled then
		CreateESP(plr)
	end
end)

-- Bersihkan saat keluar
Players.PlayerRemoving:Connect(function(plr)
	local esp = ESPFolder:FindFirstChild(plr.Name)
	if esp then
		esp:Destroy()
	end
end)
