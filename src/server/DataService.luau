-- DataService (ModuleScript in ServerScriptService)
-- Loads and saves each player's progress with DataStoreService.
--
-- Safety rule: if loading FAILS (Roblox outage, or API access is off in Studio),
-- we never save for that player, so a blank profile can't overwrite a real save.

local DataStoreService = game:GetService("DataStoreService")

local DataService = {}

local STORE_NAME = "StardustClicker_v1" -- change the version to wipe everyone's data
local MAX_RETRIES = 3

local TEMPLATE = {
	Stardust = 0,
	Rebirths = 0,
	TotalClicks = 0,
	Upgrades = {
		ClickPower = 0,
		AutoCollector = 0,
		LuckyStars = 0,
	},
	Pets = {},
	RngEggs = {}, -- [eggName] = how many times rolled
}

local store = nil
local storeOk, storeErr = pcall(function()
	store = DataStoreService:GetDataStore(STORE_NAME)
end)
if not storeOk then
	warn("[DataService] DataStores unavailable: " .. tostring(storeErr))
end

local profiles = {} -- [player] = { Data = table, CanSave = bool }

local function deepCopy(t)
	local copy = {}
	for k, v in pairs(t) do
		if type(v) == "table" then
			copy[k] = deepCopy(v)
		else
			copy[k] = v
		end
	end
	return copy
end

-- Fills in any fields added to TEMPLATE after a player's data was first saved.
local function reconcile(data, template)
	for key, value in pairs(template) do
		if data[key] == nil then
			data[key] = type(value) == "table" and deepCopy(value) or value
		elseif type(value) == "table" and type(data[key]) == "table" then
			reconcile(data[key], value)
		end
	end
end

local function keyFor(player)
	return "Player_" .. player.UserId
end

local function retry(fn)
	local lastErr
	for attempt = 1, MAX_RETRIES do
		local ok, result = pcall(fn)
		if ok then
			return true, result
		end
		lastErr = result
		task.wait(attempt) -- back off 1s, 2s, 3s
	end
	return false, lastErr
end

function DataService.Load(player)
	local data, canSave

	if store then
		local ok, result = retry(function()
			return store:GetAsync(keyFor(player))
		end)
		if ok then
			data = type(result) == "table" and result or deepCopy(TEMPLATE)
			canSave = true
		else
			warn("[DataService] Could not load data for " .. player.Name .. ": " .. tostring(result))
		end
	end

	if not data then
		data = deepCopy(TEMPLATE)
		canSave = false
		warn(
			"[DataService] Progress will NOT be saved this session. In Studio: File > Publish to Roblox, "
				.. "then Game Settings > Security > turn on 'Enable Studio Access to API Services'."
		)
	end

	reconcile(data, TEMPLATE)
	profiles[player] = { Data = data, CanSave = canSave }
	return data
end

function DataService.Get(player)
	local profile = profiles[player]
	return profile and profile.Data
end

function DataService.CanSave(player)
	local profile = profiles[player]
	return profile ~= nil and profile.CanSave
end

function DataService.Save(player)
	local profile = profiles[player]
	if not profile or not profile.CanSave then
		return false
	end
	local ok, err = retry(function()
		store:SetAsync(keyFor(player), profile.Data, { player.UserId })
	end)
	if not ok then
		warn("[DataService] Save failed for " .. player.Name .. ": " .. tostring(err))
	end
	return ok
end

-- Call after the final save when a player leaves.
function DataService.Release(player)
	profiles[player] = nil
end

return DataService
