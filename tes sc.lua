-- 🧩 Load Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- 🌐 Window
local Window = Rayfield:CreateWindow({
	Name = "Coba Coba Hub",
	LoadingTitle = "Coba Coba Hub",
	LoadingSubtitle = "by Fell",
	Theme = "Default",
	ToggleUIKeybind = Enum.KeyCode.K,
	ConfigurationSaving = {Enabled=true, FolderName="CobaCobaHub", FileName="HubConfig"}
})

-- =================================
-- SETTINGS
-- =================================
local AutoFishingEnabled = false
local FishingDelay = 0.5
local HookCandidates = {"Hook","Bobber","FishingHook","HookPart"}
local FishFolders = {"Fishes","FishFolder","Fishies","Fish"}
local RodKeyword = "rod"
local CastOnEmpty = true
local AutoUseRod = true
local WalkOnWaterEnabled = false
local WaterOffset = 3
local SpeedValue = 16
local SpeedEnabled = false
local SmoothFactor = 10
local velocity = Vector3.zero
local ESPEnabled = false
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "ESPFolder"
ESPFolder.Parent = Workspace

-- Webhook
local WEBHOOK_URL = "https://discord.com/api/webhooks/WEBHOOK_ID/WEBHOOK_TOKEN"
local FishRarity = {Common={"Salmon","Carp"}, Rare={"Tuna","Cod"}, Legendary={"Shark","GoldenFish"}}
local FishColor = {Common=3447003, Rare=16776960, Legendary=16711680}

-- =================================
-- UI
-- =================================
local MainTab = Window:CreateTab("Main",4483362458)
MainTab:CreateToggle({Name="Auto Fishing", CurrentValue=false, Callback=function(v) AutoFishingEnabled=v end})
MainTab:CreateSlider({Name="Fishing Delay", Range={0.1,2}, Increment=0.1, CurrentValue=FishingDelay, Suffix="s", Callback=function(v) FishingDelay=v end})

local PlayerTab = Window:CreateTab("Player",4483362458)
PlayerTab:CreateSlider({Name="WalkSpeed", Range={16,300}, Increment=1, CurrentValue=SpeedValue, Suffix="Speed", Callback=function(v) SpeedValue=v end})
PlayerTab:CreateToggle({Name="Enable WalkSpeed", CurrentValue=false, Callback=function(v) SpeedEnabled=v end})
PlayerTab:CreateToggle({Name="Walk on Water", CurrentValue=false, Callback=function(v) WalkOnWaterEnabled=v end})
PlayerTab:CreateToggle({Name="Player ESP", CurrentValue=false, Callback=function(v)
	ESPEnabled=v
	if not ESPEnabled then
		for _,obj in pairs(ESPFolder:GetChildren()) do obj:Destroy() end
	end
end})

-- =================================
-- FUNCTIONS
-- =================================
local function GetChar()
	local c = player.Character or player.CharacterAdded:Wait()
	local hrp = c:WaitForChild("HumanoidRootPart",3)
	local hum = c:FindFirstChildOfClass("Humanoid")
	return c,hrp,hum
end

local function GetRod()
	for _,tool in pairs(player.Character:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find(RodKeyword) then return tool end
	end
	for _,tool in pairs(player.Backpack:GetChildren()) do
		if tool:IsA("Tool") and tool.Name:lower():find(RodKeyword) then return tool end
	end
	return nil
end

local function FindHook()
	for _,name in ipairs(HookCandidates) do
		local h = Workspace:FindFirstChild(name,true)
		if h then return h end
	end
	for _,desc in pairs(Workspace:GetDescendants()) do
		if desc:IsA("BasePart") and desc.Name:lower():find("hook") then return desc end
	end
	return nil
end

local function FindFishFolder()
	for _,name in ipairs(FishFolders) do
		local f = Workspace:FindFirstChild(name)
		if f and f:IsA("Folder") then return f end
	end
	return nil
end

local function IsFishNearHook(hook,maxDistance)
	maxDistance = maxDistance or 6
	if not hook then return false,nil end
	local folder = FindFishFolder()
	if folder then
		for _,fish in pairs(folder:GetChildren()) do
			local part = fish:IsA("Model") and fish:FindFirstChild("HumanoidRootPart") or fish:FindFirstChildWhichIsA("BasePart")
			if part and (part.Position-hook.Position).Magnitude<=maxDistance then
				return true,fish
			end
		end
	end
	for _,d in pairs(Workspace:GetDescendants()) do
		if d:IsA("BasePart") and d.Name:lower():find("fish") and (d.Position-hook.Position).Magnitude<=maxDistance then
			return true,d
		end
	end
	return false,nil
end

local function EquipRod(rod)
	if not rod then return false end
	if rod.Parent~=player.Character then rod.Parent=player.Character end
	wait(0.05)
	return true
end

local function UseRod(rod)
	if not rod then return false end
	if typeof(rod.Activate)=="function" then rod:Activate() return true end
	return false
end

local function GetFishRarity(fishName)
	for rarity,names in pairs(FishRarity) do
		if table.find(names,fishName) then return rarity end
	end
	return "Common"
end

local function SendWebhookEmbed(title,desc,color,footer)
	local data={["embeds"]={{["title"]=title,["description"]=desc,["color"]=color,["footer"]={["text"]=footer or "Fish It Hub"},["timestamp"]=os.date("!%Y-%m-%dT%H:%M:%SZ")}}}
	local json = HttpService:JSONEncode(data)
	pcall(function() HttpService:PostAsync(WEBHOOK_URL,json,Enum.HttpContentType.ApplicationJson) end)
end

local function OnFishCaught(fish)
	if not fish then return end
	local fishName = fish.Name or "Unknown"
	local rarity = GetFishRarity(fishName)
	local color = FishColor[rarity] or 16777215
	local hook = FindHook()
	local hookPos = hook and hook.Position or Vector3.new(0,0,0)
	local rodLevel="N/A"
	local rod=GetRod()
	if rod and rod:FindFirstChild("Level") then rodLevel=rod.Level.Value end
	local desc="**Player:** "..player.Name.."\n**Fish:** "..fishName.."\n**Rarity:** "..rarity.."\n**Rod Level:** "..rodLevel.."\n**Hook Pos:** "..string.format("%.1f, %.1f, %.1f",hookPos.X,hookPos.Y,hookPos.Z)
	SendWebhookEmbed("🎣 Fish Caught!",desc,color)
end

local AutoFishDebounce=false
local function AutoFishTick()
	if not AutoFishingEnabled then return end
	if AutoFishDebounce then return end
	AutoFishDebounce=true
	local rod=GetRod()
	if not rod then AutoFishDebounce=false return end
	EquipRod(rod)
	local hook=FindHook()
	if not hook and CastOnEmpty then UseRod(rod) wait(FishingDelay) AutoFishDebounce=false return end
	local near,fish=IsFishNearHook(hook,6)
	if near then
		UseRod(rod)
		OnFishCaught(fish)
	else
		if CastOnEmpty then UseRod(rod) end
	end
	wait(FishingDelay)
	AutoFishDebounce=false
end

local function CreateESP(plr)
	if not plr.Character or not plr.Character:FindFirstChild("HumanoidRootPart") then return end
	if ESPFolder:FindFirstChild(plr.Name) then return end
	local bill = Instance.new("BillboardGui")
	bill.Name=plr.Name
	bill.Size=UDim2.new(0,100,0,50)
	bill.Adornee=plr.Character.HumanoidRootPart
	bill.AlwaysOnTop=true
	bill.Parent=ESPFolder
	local label=Instance.new("TextLabel")
	label.Size=UDim2.new(1,0,1,0)
	label.BackgroundTransparency=1
	label.TextColor3=Color3.fromRGB(255,255,0)
	label.TextStrokeTransparency=0
	label.Font=Enum.Font.SourceSansBold
	label.TextScaled=true
	label.Parent=bill
end

-- =================================
-- MAIN LOOP
-- =================================
RunService.RenderStepped:Connect(function(dt)
	local c,hrp,hum=GetChar()
	if c and hrp and hum then
		-- WalkSpeed
		if SpeedEnabled then
			local dir = hum.MoveDirection
			if dir.Magnitude>0 then
				velocity = velocity:Lerp(dir.Unit*SpeedValue,math.clamp(SmoothFactor*dt,0,1))
			else
				velocity = velocity:Lerp(Vector3.zero,math.clamp(SmoothFactor*dt*1.5,0,1))
			end
			hrp.CFrame=hrp.CFrame + velocity*dt
		end
		-- Walk on Water
		if WalkOnWaterEnabled then
			local ray=Workspace:Raycast(hrp.Position,Vector3.new(0,-50,0),RaycastParams.new())
			if ray and ray.Instance and ray.Instance.Name:lower():find("water") then
				local desiredY=ray.Position.Y+WaterOffset
				if hrp.Position.Y<desiredY then
					hrp.Velocity=Vector3.zero
					hrp.CFrame=CFrame.new(hrp.Position.X,desiredY,hrp.Position.Z)
				end
			end
		end
		-- ESP
		if ESPEnabled then
			for _,plr in pairs(Players:GetPlayers()) do
				if plr~=player then
					CreateESP(plr)
					local esp=ESPFolder:FindFirstChild(plr.Name)
					if esp and esp:FindFirstChildOfClass("TextLabel") then
						esp.TextLabel.Text=plr.Name
					end
				end
			end
		end
	end
end)

RunService.Heartbeat:Connect(function()
	if AutoFishingEnabled then spawn(AutoFishTick) end
end)

print("[Coba Coba Hub] Script loaded successfully.")
