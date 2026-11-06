-- Config (ModuleScript in ReplicatedStorage > Shared)
-- Every number in the game lives here. Tweak these to rebalance the game!
-- Both the server and the client read this file.

local Config = {}

Config.GameName = "Stardust Clicker"
Config.CurrencyName = "Stardust"

Config.BaseClickGain = 1
Config.ClicksPerSecondLimit = 20 -- server-side cap so auto-clickers can't break the game
Config.AutoSaveInterval = 60 -- seconds between automatic saves

---------------------------------------------------------------------------
-- UPGRADES (reset when you rebirth)
---------------------------------------------------------------------------
Config.Upgrades = {
	ClickPower = {
		Order = 1,
		DisplayName = "Bigger Clicks",
		Description = "+1 base Stardust per click",
		BaseCost = 15,
		CostGrowth = 1.45, -- each level costs 45% more than the last
		MaxLevel = 200,
	},
	AutoCollector = {
		Order = 2,
		DisplayName = "Star Collector",
		Description = "+1 base Stardust per second",
		BaseCost = 50,
		CostGrowth = 1.5,
		MaxLevel = 200,
	},
	LuckyStars = {
		Order = 3,
		DisplayName = "Lucky Stars",
		Description = "+10% luck on egg rolls",
		BaseCost = 200,
		CostGrowth = 1.6,
		MaxLevel = 100,
	},
}

---------------------------------------------------------------------------
-- RNG EGG ROLLS (free, kept forever)
-- Roll for eggs from common to insanely rare. Your RAREST egg ever found
-- multiplies all your Stardust. "Chance = 500" means a 1 in 500 roll.
-- Keep this list ordered from most common to rarest.
---------------------------------------------------------------------------
Config.RollCooldown = 1.5 -- seconds between rolls (server enforced)
Config.AnnounceChance = 1000 -- rolls this rare get announced to the whole server

Config.RngEggs = {
	{ Name = "Plain Egg", Chance = 1, Boost = 1, Color = Color3.fromRGB(235, 230, 220) },
	{ Name = "Dusty Egg", Chance = 2, Boost = 1.05, Color = Color3.fromRGB(190, 170, 140) },
	{ Name = "Shiny Egg", Chance = 5, Boost = 1.1, Color = Color3.fromRGB(200, 230, 255) },
	{ Name = "Glowing Egg", Chance = 20, Boost = 1.25, Color = Color3.fromRGB(120, 255, 150) },
	{ Name = "Starlit Egg", Chance = 100, Boost = 1.5, Color = Color3.fromRGB(90, 180, 255) },
	{ Name = "Nebula Swirl Egg", Chance = 500, Boost = 2, Color = Color3.fromRGB(190, 110, 255) },
	{ Name = "Supernova Egg", Chance = 2500, Boost = 3, Color = Color3.fromRGB(255, 170, 40) },
	{ Name = "Galactic Egg", Chance = 10000, Boost = 5, Color = Color3.fromRGB(255, 80, 160) },
	{ Name = "Black Hole Egg", Chance = 50000, Boost = 10, Color = Color3.fromRGB(150, 60, 255) },
	{ Name = "Singularity Egg", Chance = 250000, Boost = 25, Color = Color3.fromRGB(40, 255, 220) },
}

Config.LuckPerLevel = 0.1 -- from Lucky Stars upgrade
Config.LuckPerRebirth = 0.25 -- rebirths also make you luckier

---------------------------------------------------------------------------
-- PETS (kept forever, even through rebirths)
-- Your best pets are equipped automatically and multiply ALL earnings.
---------------------------------------------------------------------------
Config.Pets = {
	["Pebble Pup"] = { Multiplier = 1.1, Rarity = "Common", Color = Color3.fromRGB(170, 170, 180) },
	["Comet Kitten"] = { Multiplier = 1.25, Rarity = "Uncommon", Color = Color3.fromRGB(120, 200, 255) },
	["Nebula Newt"] = { Multiplier = 1.5, Rarity = "Rare", Color = Color3.fromRGB(190, 110, 255) },
	["Solar Slime"] = { Multiplier = 2, Rarity = "Epic", Color = Color3.fromRGB(255, 170, 40) },
	["Galaxy Gecko"] = { Multiplier = 3, Rarity = "Legendary", Color = Color3.fromRGB(255, 80, 160) },
	["Void Dragon"] = { Multiplier = 6, Rarity = "Mythic", Color = Color3.fromRGB(40, 255, 200) },
}

Config.MaxPets = 24 -- inventory size
Config.MaxEquipped = 3 -- how many pets boost you at once

-- Weights are relative: Weight 60 out of a total of 100 = 60% chance.
Config.Eggs = {
	SpaceEgg = {
		Order = 1,
		DisplayName = "Space Egg",
		Cost = 100,
		Chances = {
			{ Pet = "Pebble Pup", Weight = 60 },
			{ Pet = "Comet Kitten", Weight = 30 },
			{ Pet = "Nebula Newt", Weight = 10 },
		},
	},
	CosmicEgg = {
		Order = 2,
		DisplayName = "Cosmic Egg",
		Cost = 5000,
		Chances = {
			{ Pet = "Nebula Newt", Weight = 50 },
			{ Pet = "Solar Slime", Weight = 35 },
			{ Pet = "Galaxy Gecko", Weight = 14 },
			{ Pet = "Void Dragon", Weight = 1 },
		},
	},
}

---------------------------------------------------------------------------
-- REBIRTH: reset Stardust + upgrades for a permanent multiplier
---------------------------------------------------------------------------
Config.Rebirth = {
	BaseCost = 10000,
	CostGrowth = 4, -- each rebirth costs 4x the last
	BonusPerRebirth = 0.5, -- +50% earnings per rebirth
}

---------------------------------------------------------------------------
-- Formulas (shared so the UI shows exactly what the server uses)
---------------------------------------------------------------------------
function Config.GetUpgradeCost(upgradeId, level)
	local upgrade = Config.Upgrades[upgradeId]
	return math.floor(upgrade.BaseCost * upgrade.CostGrowth ^ level)
end

function Config.GetRebirthCost(rebirths)
	return math.floor(Config.Rebirth.BaseCost * Config.Rebirth.CostGrowth ^ rebirths)
end

-- Returns the names of the best pets (highest multiplier first), up to MaxEquipped.
function Config.GetEquippedPets(petList)
	local sorted = {}
	for _, name in ipairs(petList) do
		if Config.Pets[name] then
			table.insert(sorted, name)
		end
	end
	table.sort(sorted, function(a, b)
		return Config.Pets[a].Multiplier > Config.Pets[b].Multiplier
	end)
	local equipped = {}
	for i = 1, math.min(Config.MaxEquipped, #sorted) do
		equipped[i] = sorted[i]
	end
	return equipped
end

-- Pet bonuses stack by adding: two x1.5 pets = x2.0 total.
function Config.GetPetMultiplier(equipped)
	local multiplier = 1
	for _, name in ipairs(equipped) do
		multiplier = multiplier + (Config.Pets[name].Multiplier - 1)
	end
	return multiplier
end

function Config.GetRebirthMultiplier(rebirths)
	return 1 + rebirths * Config.Rebirth.BonusPerRebirth
end

function Config.GetLuck(data)
	return 1 + (data.Upgrades.LuckyStars or 0) * Config.LuckPerLevel + data.Rebirths * Config.LuckPerRebirth
end

-- Returns the boost and info of the rarest RNG egg this player has ever rolled.
function Config.GetBestEgg(data)
	local found = data.RngEggs or {}
	for i = #Config.RngEggs, 1, -1 do
		local egg = Config.RngEggs[i]
		if (found[egg.Name] or 0) > 0 then
			return egg.Boost, egg
		end
	end
	return 1, nil
end

function Config.GetTotalMultiplier(data)
	local equipped = Config.GetEquippedPets(data.Pets)
	local eggBoost = Config.GetBestEgg(data)
	return Config.GetPetMultiplier(equipped) * Config.GetRebirthMultiplier(data.Rebirths) * eggBoost
end

function Config.GetClickGain(data)
	local base = Config.BaseClickGain + (data.Upgrades.ClickPower or 0)
	return math.floor(base * Config.GetTotalMultiplier(data))
end

function Config.GetAutoGain(data)
	local base = data.Upgrades.AutoCollector or 0
	return math.floor(base * Config.GetTotalMultiplier(data))
end

return Config
