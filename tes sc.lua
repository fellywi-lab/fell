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

local PlayerTab = Window:CreateTab("Main", 4483362458)

local AutoFishingEnabled = false
local FishingDelay = 0.4 -- delay between checks
local HookNameCandidates = {"Hook", "Bobber", "FishingHook", "HookPart"} -- common names
local FishFolderCandidates = {"Fishes", "FishFolder", "Fishies", "Fish"} -- possible folders
local RodNameKeyword = "rod" -- cari tool yang namanya mengandung ini
local AutoUseRod = true -- gunakan Tool:Activate() ketika kondisi terpenuhi
local CastOnEmpty = true -- cast otomatis jika hook tidak ada/rusak

PlayerTab:CreateToggle({
	Name = "Auto Fishing",
	CurrentValue = false,
	Flag = "AutoFishToggle",
	Callback = function(v) AutoFishingEnabled = v end
})

PlayerTab:CreateSlider({
	Name = "Fishing Delay",
	Range = {0.1, 2},
	Increment = 0.1,
	CurrentValue = FishingDelay,
	Suffix = "s",
	Flag = "FishingDelay",
	Callback = function(v) FishingDelay = v end
})

-- helper: cari rod/tool
local function GetRod()
	-- prioritas: equipped -> backpack
	local char = player.Character
	if char then
		for _, obj in pairs(char:GetChildren()) do
			if obj:IsA("Tool") and obj.Name:lower():find(RodNameKeyword) then
				return obj
			end
		end
	end
	for _, obj in pairs(player.Backpack:GetChildren()) do
		if obj:IsA("Tool") and obj.Name:lower():find(RodNameKeyword) then
			return obj
		end
	end
	-- fallback: cari tool apa saja yang kelihatan seperti pancing
	for _, obj in pairs(player.Backpack:GetChildren()) do
		if obj:IsA("Tool") and (obj.Name:lower():find("fishing") or obj.Name:lower():find("rod") or obj.Name:lower():find("pole")) then
			return obj
		end
	end
	return nil
end

-- helper: cari hook di workspace
local function FindHook()
	-- coba nama-nama kandidat
	for _, name in ipairs(HookNameCandidates) do
		local h = Workspace:FindFirstChild(name, true)
		if h then return h end
	end
	-- fallback: cari object dengan tag/part kecil bernama "Bobber" / "hook"
	for _, descendant in pairs(Workspace:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local ln = descendant.Name:lower()
			if ln:find("bob") or ln:find("hook") or ln:find("bobber") then
				return descendant
			end
		end
	end
	return nil
end

-- helper: cari folder ikan (opsional)
local function FindFishFolder()
	for _, name in ipairs(FishFolderCandidates) do
		local f = Workspace:FindFirstChild(name)
		if f and f:IsA("Folder") then return f end
	end
	-- fallback: cari folder-model besar yang berisi banyak part/ikan
	for _, child in pairs(Workspace:GetChildren()) do
		if child:IsA("Folder") and #child:GetChildren() > 3 then
			return child
		end
	end
	return nil
end

-- helper: cek ikan dekat hook
local function IsFishNearHook(hook, maxDistance)
	if not hook then return false end
	local fishFolder = FindFishFolder()
	maxDistance = maxDistance or 6
	if fishFolder then
		for _, fish in pairs(fishFolder:GetChildren()) do
			local posPart = nil
			if fish:IsA("Model") then
				posPart = fish:FindFirstChild("HumanoidRootPart") or fish:FindFirstChildWhichIsA("BasePart")
			else
				posPart = fish:IsA("BasePart") and fish or fish:FindFirstChildWhichIsA("BasePart")
			end
			if posPart and posPart.Position and hook.Position then
				if (posPart.Position - hook.Position).Magnitude <= maxDistance then
					return true, fish
				end
			end
		end
	end
	-- tambahan: cek sekitar hook ada part yang gerak/kecil (beberapa ikan adalah part)
	for _, d in pairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart") and d ~= hook then
			local name = d.Name:lower()
			if (name:find("fish") or name:find("salmon") or name:find("tuna") or name:find("shark")) and (d.Position - hook.Position).Magnitude <= maxDistance then
				return true, d
			end
		end
	end
	return false, nil
end

-- equip rod safely
local function EquipRod(rod)
	if not rod then return false end
	if rod.Parent ~= player.Character then
		rod.Parent = player.Character
	end
	-- small wait to ensure equip
	wait(0.05)
	return true
end

-- try to cast or use rod
local function UseRodOnce(rod)
	if not rod then return false end
	-- prefer :Activate() if available
	local succ, err = pcall(function()
		if rod.Parent ~= player.Character then rod.Parent = player.Character end
		-- some tools expect :Activate(); others use RemoteEvents (not handled here)
		if typeof(rod.Activate) == "function" then
			rod:Activate()
		elseif rod:FindFirstChildWhichIsA("RemoteEvent") then
			-- DO NOT auto-fire remotes generically. This is a safe placeholder.
			-- If you know remote name & args, we can add it explicitly (with risk).
		end
	end)
	return succ
end

-- main auto-fishing routine (client-side)
local AutoFishDebounce = false
local function AutoFishTick()
	if not AutoFishingEnabled then return end
	if AutoFishDebounce then return end
	AutoFishDebounce = true

	local rod = GetRod()
	if not rod then
		AutoFishDebounce = false
		return
	end

	-- find hook (bobber)
	local hook = FindHook()

	-- if no hook found, cast if allowed
	if not hook and CastOnEmpty then
		EquipRod(rod)
		UseRodOnce(rod)
		wait(0.25)
		AutoFishDebounce = false
		return
	end

	-- if hook exists: check fish near hook
	local near, fish = IsFishNearHook(hook, 6)
	if near then
		-- equip + try to reel / activate quickly to catch
		EquipRod(rod)
		UseRodOnce(rod)
		-- small wait to allow server to process
		wait(0.15)
	else
		-- not near: ensure rod is cast (if rod is not cast, cast)
		-- heuristic: if player's tool handle is not far from hook, skip
		EquipRod(rod)
		-- If hook is present but no fish near, we may retry cast to reposition
		if CastOnEmpty then
			UseRodOnce(rod)
			wait(0.25)
		end
	end

	-- cooldown
	wait(FishingDelay)
	AutoFishDebounce = false
end

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

-- 👁️ Player ESP Toggle
local ESPEnabled = false
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = Workspace

PlayerTab:CreateToggle({
	Name = "Player ESP",
	CurrentValue = false,
	Flag = "ESPToggle",
	Callback = function(v)
		ESPEnabled = v
		if not ESPEnabled then
			for _, obj in pairs(ESPFolder:GetChildren()) do
				obj:Destroy()
			end
		end
	end
})

-------------------------------------------------
-- 🛠️ Functions
-------------------------------------------------
local function GetChar()
	local c = player.Character or player.CharacterAdded:Wait()
	local hrp = c:WaitForChild("HumanoidRootPart", 3)
	local hum = c:FindFirstChildOfClass("Humanoid")
	return c, hrp, hum
end

-- ESP Creation
local function CreateESP(plr)
	if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
	if ESPFolder:FindFirstChild(plr.Name) then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Name = plr.Name
	billboard.Size = UDim2.new(0, 100, 0, 50)
	billboard.Adornee = plr.Character.HumanoidRootPart
	billboard.AlwaysOnTop = true
	billboard.Parent = ESPFolder
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1,0,1,0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255,255,0)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.SourceSansBold
	label.TextScaled = true
	label.Parent = billboard
end

-------------------------------------------------
-- 🔄 RenderStepped Loop
-------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local c, hrp, hum = GetChar()
	if not (c and hrp and hum) then return end

	-- 🚶 Smooth WalkSpeed
	if SpeedEnabled then
		local dir = hum.MoveDirection
		if dir.Magnitude > 0 then
			velocity = velocity:Lerp(dir.Unit * SpeedValue, math.clamp(SmoothFactor * dt, 0, 1))
		else
			velocity = velocity:Lerp(Vector3.zero, math.clamp(SmoothFactor * dt * 1.5, 0, 1))
		end
		hrp.CFrame = hrp.CFrame + (velocity * dt)
	end

	-- 🌊 Walk on Water (Fish It)
	if WalkOnWaterEnabled then
		local rayParams = RaycastParams.new()
		rayParams.FilterDescendantsInstances = {c}
		rayParams.FilterType = Enum.RaycastFilterType.Blacklist

		local rayResult = Workspace:Raycast(hrp.Position, Vector3.new(0, -50, 0), rayParams)
		if rayResult then
			local hitPart = rayResult.Instance
			-- cek nama part kalau ada kata "water" atau "sea"
			if hitPart.Name:lower():find("water") or hitPart.Name:lower():find("sea") then
				local desiredY = rayResult.Position.Y + WaterHeightOffset
				if hrp.Position.Y < desiredY then
					hrp.Velocity = Vector3.zero
					hrp.CFrame = CFrame.new(hrp.Position.X, desiredY, hrp.Position.Z)
				end
			end
		end
	end

	-- 👁️ Player ESP
	if ESPEnabled then
		for _, plr in pairs(Players:GetPlayers()) do
			if plr ~= player then
				CreateESP(plr)
				local esp = ESPFolder:FindFirstChild(plr.Name)
				if esp and esp:FindFirstChildOfClass("TextLabel") then
					esp.TextLabel.Text = plr.Name
				end
			end
		end
	end
end)

local PlayerTab = Window:CreateTab("MISC", 4483362458)


-- WebHook
local PlayerTab = Window:CreateTab("WebHook", 4483362458)

-- Services
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- Webhook URL
local WEBHOOK_URL = "https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN"

-- Rarity Settings
local FishRarity = {
    Common = {"Salmon","Carp"},
    Rare = {"Tuna","Cod"},
    Legendary = {"Shark","GoldenFish"}
}
local FishColor = {
    Common = 3447003,
    Rare = 16776960,
    Legendary = 16711680
}

-- ============================================
-- WEBHOOK FUNCTION
-- ============================================
local function SendWebhookEmbed(title, description, color, footer)
    local embedData = {
        ["embeds"] = {{
            ["title"] = title or "Fish It Hub Notification",
            ["description"] = description or "",
            ["color"] = color or 16777215,
            ["footer"] = {["text"] = footer or "Fish It Hub"},
            ["timestamp"] = os.date("!%Y-%m-%dT%H:%M:%SZ")
        }}
    }
    local jsonData = HttpService:JSONEncode(embedData)
    local success, err = pcall(function()
        HttpService:PostAsync(WEBHOOK_URL, jsonData, Enum.HttpContentType.ApplicationJson)
    end)
    if not success then warn("Gagal kirim webhook: "..tostring(err)) end
end

local function GetFishRarity(fishName)
    for rarity, names in pairs(FishRarity) do
        if table.find(names, fishName) then return rarity end
    end
    return "Common"
end

local function OnFishCaught(fish)
    if not fish then return end
    local fishName = fish.Name or "Unknown Fish"
    local playerName = player.Name
    local rarity = GetFishRarity(fishName)
    local color = FishColor[rarity] or 16777215

    local hookPos = Workspace:FindFirstChild("Hook") and Workspace.Hook.Position or Vector3.new(0,0,0)
    local rodLevel = "N/A"
    local rod = nil
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then rod = tool break end
    end
    if rod and rod:FindFirstChild("Level") then
        rodLevel = rod.Level.Value
    end

    local description = "**Player:** "..playerName.."\n"..
                        "**Fish:** "..fishName.."\n"..
                        "**Rarity:** "..rarity.."\n"..
                        "**Rod Level:** "..rodLevel.."\n"..
                        string.format("**Hook Pos:** %.1f, %.1f, %.1f", hookPos.X, hookPos.Y, hookPos.Z)

    SendWebhookEmbed("🎣 Fish Caught!", description, color, "Fish It Hub")
end

-- ============================================
-- AUTO FISHING WITH WEBHOOK
-- ============================================
local AutoFishingEnabled = true
local FishingDelay = 0.5
local AutoFishDebounce = false

local function GetRod()
    for _, tool in pairs(player.Character:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then return tool end
    end
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") and tool.Name:lower():find("rod") then return tool end
    end
    return nil
end

local function FindHook()
    local hook = Workspace:FindFirstChild("Hook") -- ganti sesuai nama hook di game
    return hook
end

local function FindFishNearHook(hook, maxDistance)
    if not hook then return nil end
    maxDistance = maxDistance or 6
    for _, fishFolderName in pairs({"Fishes","FishFolder","Fishies"}) do
        local fishFolder = Workspace:FindFirstChild(fishFolderName)
        if fishFolder then
            for _, fish in pairs(fishFolder:GetChildren()) do
                local posPart = fish:IsA("Model") and fish:FindFirstChild("HumanoidRootPart") or fish:FindFirstChildWhichIsA("BasePart")
                if posPart and (posPart.Position - hook.Position).Magnitude <= maxDistance then
                    return fish
                end
            end
        end
    end
    return nil
end

local function EquipRod(rod)
    if not rod then return false end
    if rod.Parent ~= player.Character then rod.Parent = player.Character end
    wait(0.05)
    return true
end

local function UseRod(rod)
    if not rod then return false end
    if typeof(rod.Activate) == "function" then
        rod:Activate()
        return true
    end
    return false
end

local function AutoFishTick()
    if not AutoFishingEnabled then return end
    if AutoFishDebounce then return end
    AutoFishDebounce = true

    local rod = GetRod()
    if not rod then AutoFishDebounce = false return end
    EquipRod(rod)

    local hook = FindHook()
    if not hook then
        UseRod(rod) -- cast jika hook belum ada
        wait(FishingDelay)
        AutoFishDebounce = false
        return
    end

    local fish = FindFishNearHook(hook, 6)
    if fish then
        UseRod(rod)
        OnFishCaught(fish) -- kirim webhook otomatis
    else
        UseRod(rod) -- cast ulang jika tidak ada ikan
    end

    wait(FishingDelay)
    AutoFishDebounce = false
end

-- ============================================
-- MAIN LOOP
-- ============================================
RunService.Heartbeat:Connect(function()
    if AutoFishingEnabled then
        spawn(AutoFishTick)
    end
end)

print("[Fish It Hub] AutoFishing + Webhook aktif.")


-- 🔄 Load Dropdown
RefreshDropdown()




