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
-- 🧍 INVITE DISCORD
-------------------------------------------------
local PlayerTab = Window:CreateTab("DISCORD", 4483362458)

-------------------------------------------------
-- 🏠 HOME TAB (with Discord Invite)
-------------------------------------------------
local HomeTab = Window:CreateTab("🏠 Home", 4483362458)

HomeTab:CreateLabel("Selamat datang di Coba Coba Hub!")
HomeTab:CreateLabel("⚡ Skrip ini dibuat oleh Fell")

-------------------------------------------------
-- 💜 DISCORD INVITE BUTTON (Premium Style)
-------------------------------------------------
local DiscordInviteLink = "https://discord.gg/YOURSERVERCODE" -- ganti dengan link server kamu
local TweenService = game:GetService("TweenService")

local DiscordButton = HomeTab:CreateButton({
	Name = "💜 Join Discord Server",
	Callback = function()
		local success = false

		pcall(function()
			if syn and syn.request then
				syn.request({Url = DiscordInviteLink, Method = "GET"})
				success = true
			elseif request then
				request({Url = DiscordInviteLink, Method = "GET"})
				success = true
			elseif http_request then
				http_request({Url = DiscordInviteLink, Method = "GET"})
				success = true
			end
		end)

		if not success then
			setclipboard(DiscordInviteLink)
			Rayfield:Notify({
				Title = "Discord Invite",
				Content = "📋 Link Discord telah disalin!\nTempel di browser untuk join server.",
				Duration = 5,
			})
		else
			Rayfield:Notify({
				Title = "Discord Invite",
				Content = "✅ Membuka Discord server di browser!",
				Duration = 4,
			})
		end
	end
})

-- 🌈 Animasi tombol saat diklik
local ButtonFrame = DiscordButton.Instance or DiscordButton
if ButtonFrame and ButtonFrame:FindFirstChildOfClass("TextButton") then
	local btn = ButtonFrame:FindFirstChildOfClass("TextButton")
	btn.BackgroundColor3 = Color3.fromRGB(88, 101, 242) -- Warna ungu Discord
	btn.TextColor3 = Color3.fromRGB(255, 255, 255)
	btn.Font = Enum.Font.SourceSansBold
	btn.TextScaled = true

	btn.MouseButton1Click:Connect(function()
		local tweenIn = TweenService:Create(btn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(114, 137, 218)})
		local tweenOut = TweenService:Create(btn, TweenInfo.new(0.4), {BackgroundColor3 = Color3.fromRGB(88, 101, 242)})
		tweenIn:Play()
		tweenIn.Completed:Wait()
		tweenOut:Play()
	end)
end

-------------------------------------------------
-- ✨ DESAIN TAMBAHAN (opsional)
-------------------------------------------------
HomeTab:CreateParagraph({
	Title = "✨ Tips:",
	Content = [[
🟡 Gunakan tombol di tab Player untuk mengatur kecepatan.
🎣 Aktifkan Auto Fishing untuk mancing otomatis.
👁️ Aktifkan ESP untuk melihat player lain.
💜 Klik tombol di atas untuk masuk ke server Discord resmi kami!]]
})

-------------------------------------------------
-- 🧍 MAIN
-------------------------------------------------
local PlayerTab = Window:CreateTab("MAIN", 4483362458)

-------------------------------------------------
-- 🧍 MISC
-------------------------------------------------
local PlayerTab = Window:CreateTab("MISC", 4483362458)

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




