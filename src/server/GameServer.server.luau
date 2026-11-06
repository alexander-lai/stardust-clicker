-- GameServer (Script in ServerScriptService)
-- The server is the boss: it owns everyone's Stardust and checks every purchase,
-- so exploiters can't just give themselves money from the client.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Util = require(Shared:WaitForChild("Util"))
local DataService = require(script.Parent:WaitForChild("DataService"))
local MapBuilder = require(script.Parent:WaitForChild("MapBuilder"))

---------------------------------------------------------------------------
-- RemoteEvents (created automatically if they don't exist yet)
---------------------------------------------------------------------------
local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "Remotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getRemote(name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end
	return remote
end

local ClickRemote = getRemote("Click") -- client -> server
local BuyUpgradeRemote = getRemote("BuyUpgrade") -- client -> server (upgradeId)
local HatchEggRemote = getRemote("HatchEgg") -- client -> server (eggId)
local RebirthRemote = getRemote("Rebirth") -- client -> server
local RequestStateRemote = getRemote("RequestState") -- client -> server
local StateUpdateRemote = getRemote("StateUpdate") -- server -> client (state table)
local NotifyRemote = getRemote("Notify") -- server -> client (message, kind)
local RollEggRemote = getRemote("RollEgg") -- client -> server
local RollResultRemote = getRemote("RollResult") -- server -> client (eggName, isNew)

---------------------------------------------------------------------------
-- World setup: the clickable Star Crystal (the map itself is in MapBuilder)
---------------------------------------------------------------------------
local tryClick -- defined below, used by the crystal

local function createStarCrystal()
	if workspace:FindFirstChild("StarCrystal") then
		return
	end
	local crystal = Instance.new("Part")
	crystal.Name = "StarCrystal"
	crystal.Size = Vector3.new(6, 6, 6)
	crystal.CFrame = CFrame.new(0, 7, -25) * CFrame.Angles(math.rad(45), math.rad(45), 0)
	crystal.Anchored = true
	crystal.Material = Enum.Material.Neon
	crystal.Color = Color3.fromRGB(255, 215, 90)

	local light = Instance.new("PointLight")
	light.Color = crystal.Color
	light.Range = 20
	light.Brightness = 2
	light.Parent = crystal

	local clickDetector = Instance.new("ClickDetector")
	clickDetector.MaxActivationDistance = 40
	clickDetector.Parent = crystal
	clickDetector.MouseClick:Connect(function(player)
		tryClick(player)
	end)

	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 220, 0, 50)
	billboard.StudsOffset = Vector3.new(0, 6, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = crystal

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "Click the crystal!"
	label.TextScaled = true
	label.Font = Enum.Font.FredokaOne
	label.TextColor3 = Color3.fromRGB(255, 240, 180)
	label.TextStrokeTransparency = 0.2
	label.Parent = billboard

	crystal.Parent = workspace
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------
local leaderstatsValues = {} -- [player] = { Stardust = NumberValue, Rebirths = IntValue }
local clickTracker = {} -- [player] = { windowStart = number, count = number }
local lastRoll = {} -- [player] = os.clock() of their last egg roll
local rng = Random.new()

local function buildState(data)
	local equipped = Config.GetEquippedPets(data.Pets)
	local eggBoost, bestEgg = Config.GetBestEgg(data)
	local upgradeCosts = {}
	for id in pairs(Config.Upgrades) do
		upgradeCosts[id] = Config.GetUpgradeCost(id, data.Upgrades[id] or 0)
	end
	return {
		Stardust = data.Stardust,
		Rebirths = data.Rebirths,
		TotalClicks = data.TotalClicks,
		Upgrades = data.Upgrades,
		UpgradeCosts = upgradeCosts,
		Pets = data.Pets,
		Equipped = equipped,
		PetMultiplier = Config.GetPetMultiplier(equipped),
		RebirthMultiplier = Config.GetRebirthMultiplier(data.Rebirths),
		ClickGain = Config.GetClickGain(data),
		AutoGain = Config.GetAutoGain(data),
		RebirthCost = Config.GetRebirthCost(data.Rebirths),
		RngEggs = data.RngEggs,
		BestEgg = bestEgg and bestEgg.Name or nil,
		EggBoost = eggBoost,
		Luck = Config.GetLuck(data),
	}
end

-- Pushes the latest numbers to the leaderboard and the player's UI.
local function sync(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local values = leaderstatsValues[player]
	if values then
		values.Stardust.Value = data.Stardust
		values.Rebirths.Value = data.Rebirths
	end
	StateUpdateRemote:FireClient(player, buildState(data))
end

local function notify(player, message, kind)
	NotifyRemote:FireClient(player, message, kind or "info")
end

local function rollPet(egg)
	local total = 0
	for _, chance in ipairs(egg.Chances) do
		total = total + chance.Weight
	end
	local roll = rng:NextNumber(0, total)
	local running = 0
	for _, chance in ipairs(egg.Chances) do
		running = running + chance.Weight
		if roll <= running then
			return chance.Pet
		end
	end
	return egg.Chances[#egg.Chances].Pet
end

---------------------------------------------------------------------------
-- Gameplay actions
---------------------------------------------------------------------------
tryClick = function(player)
	local data = DataService.Get(player)
	if not data then
		return
	end

	-- Rate limit: at most ClicksPerSecondLimit clicks in any 1-second window.
	local now = os.clock()
	local tracker = clickTracker[player]
	if not tracker or now - tracker.windowStart >= 1 then
		tracker = { windowStart = now, count = 0 }
		clickTracker[player] = tracker
	end
	if tracker.count >= Config.ClicksPerSecondLimit then
		return
	end
	tracker.count = tracker.count + 1

	data.Stardust = data.Stardust + Config.GetClickGain(data)
	data.TotalClicks = data.TotalClicks + 1
	sync(player)
end

ClickRemote.OnServerEvent:Connect(tryClick)

BuyUpgradeRemote.OnServerEvent:Connect(function(player, upgradeId)
	-- Never trust what the client sends: check the type and that it exists.
	if type(upgradeId) ~= "string" then
		return
	end
	local upgrade = Config.Upgrades[upgradeId]
	local data = DataService.Get(player)
	if not upgrade or not data then
		return
	end

	local level = data.Upgrades[upgradeId] or 0
	if level >= upgrade.MaxLevel then
		notify(player, upgrade.DisplayName .. " is already maxed!", "error")
		return
	end
	local cost = Config.GetUpgradeCost(upgradeId, level)
	if data.Stardust < cost then
		notify(player, "Not enough Stardust!", "error")
		return
	end

	data.Stardust = data.Stardust - cost
	data.Upgrades[upgradeId] = level + 1
	notify(player, upgrade.DisplayName .. " is now level " .. (level + 1) .. "!", "success")
	sync(player)
end)

HatchEggRemote.OnServerEvent:Connect(function(player, eggId)
	if type(eggId) ~= "string" then
		return
	end
	local egg = Config.Eggs[eggId]
	local data = DataService.Get(player)
	if not egg or not data then
		return
	end
	if data.Stardust < egg.Cost then
		notify(player, "You need " .. Util.FormatNumber(egg.Cost) .. " Stardust for a " .. egg.DisplayName .. "!", "error")
		return
	end

	data.Stardust = data.Stardust - egg.Cost
	local petName = rollPet(egg)
	local pet = Config.Pets[petName]
	local label = pet.Rarity .. " " .. petName .. " (x" .. Util.FormatMultiplier(pet.Multiplier) .. ")"

	if #data.Pets < Config.MaxPets then
		table.insert(data.Pets, petName)
		notify(player, "You hatched a " .. label .. "!", "success")
	else
		-- Inventory full: replace the weakest pet if the new one is better.
		local weakestIndex, weakestMultiplier = 1, math.huge
		for i, name in ipairs(data.Pets) do
			local info = Config.Pets[name]
			local m = info and info.Multiplier or 0
			if m < weakestMultiplier then
				weakestIndex, weakestMultiplier = i, m
			end
		end
		if pet.Multiplier > weakestMultiplier then
			local oldName = data.Pets[weakestIndex]
			data.Pets[weakestIndex] = petName
			notify(player, "Inventory full! Swapped a " .. tostring(oldName) .. " for a " .. label .. "!", "success")
		else
			notify(player, "Hatched a " .. label .. ", but your inventory is full so it was auto-deleted.", "info")
		end
	end
	sync(player)
end)

RebirthRemote.OnServerEvent:Connect(function(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local cost = Config.GetRebirthCost(data.Rebirths)
	if data.Stardust < cost then
		notify(player, "You need " .. Util.FormatNumber(cost) .. " Stardust to rebirth!", "error")
		return
	end

	data.Stardust = 0
	for id in pairs(data.Upgrades) do
		data.Upgrades[id] = 0
	end
	data.Rebirths = data.Rebirths + 1
	local mult = Util.FormatMultiplier(Config.GetRebirthMultiplier(data.Rebirths))
	notify(player, "REBIRTH! You now earn x" .. mult .. " Stardust forever!", "success")
	sync(player)
end)

-- RNG egg roll: check from the rarest egg down. Luck multiplies every chance.
local function rollRngEgg(luck)
	for i = #Config.RngEggs, 2, -1 do
		local egg = Config.RngEggs[i]
		if rng:NextNumber() < luck / egg.Chance then
			return egg
		end
	end
	return Config.RngEggs[1]
end

RollEggRemote.OnServerEvent:Connect(function(player)
	local data = DataService.Get(player)
	if not data then
		return
	end
	local now = os.clock()
	if lastRoll[player] and now - lastRoll[player] < Config.RollCooldown - 0.1 then
		return -- too fast
	end
	lastRoll[player] = now

	local oldBoost = Config.GetBestEgg(data)
	local egg = rollRngEgg(Config.GetLuck(data))
	local count = data.RngEggs[egg.Name] or 0
	data.RngEggs[egg.Name] = count + 1

	RollResultRemote:FireClient(player, egg.Name, count == 0)
	if egg.Boost > oldBoost then
		notify(player, "NEW BEST EGG! " .. egg.Name .. " gives x" .. Util.FormatMultiplier(egg.Boost) .. " Stardust!", "rare")
	end
	if egg.Chance >= Config.AnnounceChance then
		NotifyRemote:FireAllClients(
			player.DisplayName .. " rolled a " .. egg.Name .. " (1 in " .. Util.FormatCommas(egg.Chance) .. ")!",
			"rare"
		)
	end
	sync(player)
end)

RequestStateRemote.OnServerEvent:Connect(function(player)
	sync(player)
end)

---------------------------------------------------------------------------
-- Players joining / leaving
---------------------------------------------------------------------------
local function onPlayerAdded(player)
	DataService.Load(player)
	if not player.Parent then -- left while we were loading
		DataService.Release(player)
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats" -- this exact name makes Roblox show the leaderboard

	local stardust = Instance.new("NumberValue")
	stardust.Name = Config.CurrencyName
	stardust.Parent = leaderstats

	local rebirths = Instance.new("IntValue")
	rebirths.Name = "Rebirths"
	rebirths.Parent = leaderstats

	leaderstats.Parent = player
	leaderstatsValues[player] = { Stardust = stardust, Rebirths = rebirths }

	if not DataService.CanSave(player) then
		notify(player, "Saving is OFF this session (see the Output window for how to fix).", "error")
	end
	sync(player)
end

local function onPlayerRemoving(player)
	DataService.Save(player)
	DataService.Release(player)
	leaderstatsValues[player] = nil
	clickTracker[player] = nil
	lastRoll[player] = nil
end

MapBuilder.Build()
createStarCrystal()

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)
for _, player in ipairs(Players:GetPlayers()) do -- anyone who joined before this ran
	task.spawn(onPlayerAdded, player)
end

-- Passive income from Star Collectors, once per second.
task.spawn(function()
	while true do
		task.wait(1)
		for _, player in ipairs(Players:GetPlayers()) do
			local data = DataService.Get(player)
			if data then
				local gain = Config.GetAutoGain(data)
				if gain > 0 then
					data.Stardust = data.Stardust + gain
					sync(player)
				end
			end
		end
	end
end)

-- Autosave so a crash doesn't wipe much progress.
task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		for _, player in ipairs(Players:GetPlayers()) do
			task.spawn(DataService.Save, player)
		end
	end
end)

-- When the server shuts down, save everyone (Roblox gives us up to 30 seconds).
game:BindToClose(function()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending = pending + 1
		task.spawn(function()
			DataService.Save(player)
			pending = pending - 1
		end)
	end
	local start = os.clock()
	while pending > 0 and os.clock() - start < 25 do
		task.wait()
	end
end)
