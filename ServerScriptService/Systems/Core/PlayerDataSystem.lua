local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PlayerDataSystem = {}

local dirtyPlayers = {}

local BASE_PAPER_PRODUCTION_TIME = 10
local MAX_COIN_SPAWN_SPEED_LEVEL = 3

local START_COIN_VALUE_COST = 2
local START_COIN_MULTIPLIER_COST = 1
local START_COIN_SPAWN_COST = 10
local START_COIN_WOODBOOST_COST = 10000

local START_WOOD_VALUE_COST = 5
local START_WOOD_MULTIPLIER_COST = 15
local START_WOOD_SPEED_COST = 25
local START_WOOD_COINBOOST_COST = 250

local START_PAPER_VALUE_COST = 10
local START_PAPER_MULTIPLIER_COST = 50
local START_PAPER_SPEED_COST = 15

local START_HAY_AMOUNT_COST = 1
local START_HAY_MULTIPLIER_COST = 25
local START_HAY_COOLDOWN_COST = 500

local GamepassIds = {
	DoubleCoins = 0,
	DoublePaper = 0,
	DoubleWood = 0,
	TripleRuneLuck = 0,
}

local RUNE_UPGRADES = {
	Luck = {levelName = "RuneLuckLevel", costName = "RuneLuckCost", startCost = 50000, maxLevel = 4, currency = "Coins"},
	Speed = {levelName = "RuneSpeedLevel", costName = "RuneSpeedCost", startCost = 5000, maxLevel = 5, currency = "Wood"},
	Bulk = {levelName = "RuneBulkLevel", costName = "RuneBulkCost", startCost = 50, maxLevel = 5, currency = "Paper"},
}

local XP_UPGRADES = {
	CoinXP = {levelName = "CoinXPLevel", costName = "CoinXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 10},
	PaperXP = {levelName = "PaperXPLevel", costName = "PaperXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 10},
	WoodXP = {levelName = "WoodXPLevel", costName = "WoodXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 10},
	XPMultiplier = {levelName = "XPMultiplierLevel", costName = "XPMultiplierCost", startCost = 10, priceMultiplier = 1.5, maxLevel = 5},
	RuneLuckXP = {levelName = "RuneLuckXPLevel", costName = "RuneLuckXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 3},
	RuneBulkXP = {levelName = "RuneBulkXPLevel", costName = "RuneBulkXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 5},
	RuneSpeedXP = {levelName = "RuneSpeedXPLevel", costName = "RuneSpeedXPCost", startCost = 1, priceMultiplier = 1.5, maxLevel = 2},
}

local XP_BOOST_CONFIG = {
	levelName = "Level",
	costName = "NextCost",
	startCost = 10,
	priceMultiplier = 3,
	maxLevel = 10,
}

local REBIRTH_STAGES = {
	[1] = {
		cost = 500,
		currency = "Coins",
		coinMultiplier = 2,
		spawnBonus = 0.1,
		woodMultiplier = 1,
		unlockTree = false,
		unlockThirdUpgrades = false,
		unlockFourthSystems = false,
		unlockFifthSystems = false,
	},
	[2] = {
		cost = 2500,
		currency = "Coins",
		coinMultiplier = 5,
		spawnBonus = 0,
		woodMultiplier = 1,
		unlockTree = true,
		unlockThirdUpgrades = false,
		unlockFourthSystems = false,
		unlockFifthSystems = false,
	},
	[3] = {
		cost = 500,
		currency = "Wood",
		coinMultiplier = 10,
		spawnBonus = 0,
		woodMultiplier = 1,
		unlockTree = true,
		unlockThirdUpgrades = true,
		unlockFourthSystems = false,
		unlockFifthSystems = false,
	},
	[4] = {
		cost = 5000,
		currency = "Wood",
		coinMultiplier = 1,
		spawnBonus = 0,
		woodMultiplier = 2,
		unlockTree = true,
		unlockThirdUpgrades = true,
		unlockFourthSystems = true,
		unlockFifthSystems = false,
	},
	[5] = {
		cost = 50,
		currency = "Paper",
		coinMultiplier = 1,
		spawnBonus = 0,
		woodMultiplier = 1,
		unlockTree = true,
		unlockThirdUpgrades = true,
		unlockFourthSystems = true,
		unlockFifthSystems = true,
		unlockSixthSystems = false,
	},
	[6] = {
		cost = 500,
		currency = "Paper",
		coinMultiplier = 1,
		spawnBonus = 0,
		woodMultiplier = 1,
		unlockTree = true,
		unlockThirdUpgrades = true,
		unlockFourthSystems = true,
		unlockFifthSystems = true,
		unlockSixthSystems = true,
	},
	[7] = {
		cost = 2500,
		currency = "Paper",
		coinMultiplier = 1,
		spawnBonus = 0,
		woodMultiplier = 1,
		unlockTree = true,
		unlockThirdUpgrades = true,
		unlockFourthSystems = true,
		unlockFifthSystems = true,
		unlockSixthSystems = true,
	},
}
local MAX_REBIRTH_COUNT = 7

local COIN_UPGRADES = {
	CoinValue = {
		levelName = "CoinValueLevel",
		costName = "CoinValueCost",
		activeName = "CoinValueActive",
		startCost = START_COIN_VALUE_COST,
		priceMultiplier = 1.5,
		maxLevel = math.huge,
		displayName = "CoinGain",
		requiredRebirth = 0,
	},
	Multiplier = {
		levelName = "MultiplierLevel",
		costName = "MultiplierCost",
		activeName = "MultiplierActive",
		startCost = START_COIN_MULTIPLIER_COST,
		priceMultiplier = 2,
		maxLevel = math.huge,
		displayName = "CoinMulti",
		requiredRebirth = 0,
	},
	SpawnSpeed = {
		levelName = "SpawnSpeedLevel",
		costName = "SpawnSpeedCost",
		activeName = "SpawnSpeedActive",
		startCost = START_COIN_SPAWN_COST,
		priceMultiplier = 1.5,
		maxLevel = MAX_COIN_SPAWN_SPEED_LEVEL,
		displayName = "SpawnBoost",
		requiredRebirth = 0,
	},
	WoodBoost = {
		levelName = "WoodBoostLevel",
		costName = "WoodBoostCost",
		activeName = "WoodBoostActive",
		startCost = START_COIN_WOODBOOST_COST,
		fixedCost = true,
		priceMultiplier = 1,
		maxLevel = 10,
		displayName = "WoodBoost",
		requiredRebirth = 3,
	},
}

local WOOD_UPGRADES = {
	WoodValue = {
		levelName = "WoodValueLevel",
		costName = "WoodValueCost",
		activeName = "WoodValueActive",
		startCost = START_WOOD_VALUE_COST,
		priceMultiplier = 1.5,
		maxLevel = math.huge,
		displayName = "WoodGain",
		requiredRebirth = 2,
	},
	WoodMultiplier = {
		levelName = "WoodMultiplierLevel",
		costName = "WoodMultiplierCost",
		activeName = "WoodMultiplierActive",
		startCost = START_WOOD_MULTIPLIER_COST,
		priceMultiplier = 2,
		maxLevel = math.huge,
		displayName = "WoodMulti",
		requiredRebirth = 2,
	},
	WoodSpeed = {
		levelName = "WoodSpeedLevel",
		costName = "WoodSpeedCost",
		activeName = "WoodSpeedActive",
		startCost = START_WOOD_SPEED_COST,
		priceMultiplier = 1.5,
		maxLevel = math.huge,
		displayName = "WoodSpeed",
		requiredRebirth = 2,
	},
	CoinBoost = {
		levelName = "CoinBoostLevel",
		costName = "CoinBoostCost",
		activeName = "CoinBoostActive",
		startCost = START_WOOD_COINBOOST_COST,
		fixedCost = true,
		priceMultiplier = 1,
		maxLevel = 20,
		displayName = "CoinBoost",
		requiredRebirth = 3,
	},
}

local PAPER_UPGRADES = {
	PaperValue = {
		levelName = "PaperValueLevel",
		costName = "PaperValueCost",
		activeName = "PaperValueActive",
		startCost = START_PAPER_VALUE_COST,
		priceMultiplier = 1.5,
		maxLevel = math.huge,
		displayName = "PaperGain",
		requiredRebirth = 4,
	},
	PaperMultiplier = {
		levelName = "PaperMultiplierLevel",
		costName = "PaperMultiplierCost",
		activeName = "PaperMultiplierActive",
		startCost = START_PAPER_MULTIPLIER_COST,
		priceMultiplier = 1.5,
		maxLevel = math.huge,
		displayName = "PaperMulti",
		requiredRebirth = 4,
	},
	PaperSpeed = {
		levelName = "PaperSpeedLevel",
		costName = "PaperSpeedCost",
		activeName = "PaperSpeedActive",
		startCost = START_PAPER_SPEED_COST,
		priceMultiplier = 2,
		maxLevel = 10,
		displayName = "PaperSpeed",
		requiredRebirth = 4,
	},
}

local HAY_UPGRADES = {
	HayAmount = {levelName = "HayAmountLevel", costName = "HayAmountCost", startCost = START_HAY_AMOUNT_COST, priceMultiplier = 3, maxLevel = 250},
	HayMultiplier = {levelName = "HayMultiplierLevel", costName = "HayMultiplierCost", startCost = START_HAY_MULTIPLIER_COST, priceMultiplier = 3, maxLevel = 50},
	HayCooldown = {levelName = "HayCooldownLevel", costName = "HayCooldownCost", startCost = START_HAY_COOLDOWN_COST, priceMultiplier = 2.5, maxLevel = 25},
}


function PlayerDataSystem.RoundToTenth(value)
	return math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
end

function PlayerDataSystem.AddCurrency(currencyObject, amount)
	if currencyObject then
		currencyObject.Value = PlayerDataSystem.RoundToTenth(currencyObject.Value + amount)
	end
end

function PlayerDataSystem.SpendCurrency(currencyObject, amount)
	if not currencyObject then
		return false
	end

	if currencyObject.Value < amount then
		return false
	end

	currencyObject.Value = PlayerDataSystem.RoundToTenth(currencyObject.Value - amount)
	return true
end

function PlayerDataSystem.MarkDirty(player)
	if player and player.Parent == Players then
		dirtyPlayers[player] = true
	end
end

function PlayerDataSystem.ClearDirty(player)
	dirtyPlayers[player] = nil
end

function PlayerDataSystem.GetDirtyPlayers()
	return dirtyPlayers
end

local function ensureFolder(parent, name)
	local folder = parent:FindFirstChild(name)
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createValue(parent, className, name, defaultValue)
	local existing = parent:FindFirstChild(name)
	if existing and existing.ClassName == className then
		return existing
	end

	local obj = Instance.new(className)
	obj.Name = name
	obj.Value = defaultValue
	obj.Parent = parent
	return obj
end

local function updateUpgradeActiveFlags(folder, configTable)
	if not folder then
		return
	end

	for _, config in pairs(configTable) do
		if type(config.levelName) ~= "string" or type(config.activeName) ~= "string" then
			continue
		end
		local levelObject = folder:FindFirstChild(config.levelName)
		local activeObject = folder:FindFirstChild(config.activeName)
		if levelObject and activeObject then
			activeObject.Value = levelObject.Value > 0
		end
	end
end

local function emptyPassiveState()
	return {
		inventory = {},
		equippedUid = "",
	}
end

local function emptyRuneState()
	return {
		natureCounts = {Grass = 0, DarkGrass = 0, Dandelion = 0, Flower = 0, Violet = 0, Rose = 0},
		forestCounts = {Palka = 0, ObrublennyKonec = 0, VetvDereva = 0, Brevno = 0, Poleno = 0, ObgorevshiyPen = 0},
		counts = {Grass = 0, DarkGrass = 0, Dandelion = 0, Flower = 0, Violet = 0, Rose = 0},
	}
end

function PlayerDataSystem.GetPlayerData(player)
	return player:FindFirstChild("PlayerData")
end

function PlayerDataSystem.GetCoinsObject(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Coins") or nil
end

function PlayerDataSystem.GetGamepassFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Gamepasses") or nil
end

function PlayerDataSystem.GetCoinUpgradesFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("CoinUpgrades") or nil
end

function PlayerDataSystem.GetWoodFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Wood") or nil
end

function PlayerDataSystem.GetWoodCurrencyObject(player)
	local woodFolder = PlayerDataSystem.GetWoodFolder(player)
	return woodFolder and woodFolder:FindFirstChild("WoodCurrency") or nil
end

function PlayerDataSystem.GetWoodUpgradesFolder(player)
	local woodFolder = PlayerDataSystem.GetWoodFolder(player)
	return woodFolder and woodFolder:FindFirstChild("WoodUpgrades") or nil
end

function PlayerDataSystem.GetPaperFactoryFolder(player)
	local woodFolder = PlayerDataSystem.GetWoodFolder(player)
	return woodFolder and woodFolder:FindFirstChild("PaperFactory") or nil
end

function PlayerDataSystem.GetPaperUpgradesFolder(player)
	local woodFolder = PlayerDataSystem.GetWoodFolder(player)
	return woodFolder and woodFolder:FindFirstChild("PaperUpgrades") or nil
end

function PlayerDataSystem.GetPaperCurrencyObject(player)
	local paperFactory = PlayerDataSystem.GetPaperFactoryFolder(player)
	return paperFactory and paperFactory:FindFirstChild("Paper") or nil
end

function PlayerDataSystem.GetHayFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Hay") or nil
end

function PlayerDataSystem.GetHayCurrencyObject(player)
	local hayFolder = PlayerDataSystem.GetHayFolder(player)
	return hayFolder and hayFolder:FindFirstChild("HayCurrency") or nil
end

function PlayerDataSystem.GetHayUpgradesFolder(player)
	local hayFolder = PlayerDataSystem.GetHayFolder(player)
	return hayFolder and hayFolder:FindFirstChild("HayUpgrades") or nil
end

function PlayerDataSystem.GetXPFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("XP") or nil
end

function PlayerDataSystem.GetXPCurrencyObject(player)
	local xpFolder = PlayerDataSystem.GetXPFolder(player)
	return xpFolder and xpFolder:FindFirstChild("XPValue") or nil
end

function PlayerDataSystem.GetXPUpgradesFolder(player)
	local xpFolder = PlayerDataSystem.GetXPFolder(player)
	return xpFolder and xpFolder:FindFirstChild("XPUpgrades") or nil
end

function PlayerDataSystem.GetXPBoostFolder(player)
	local xpFolder = PlayerDataSystem.GetXPFolder(player)
	return xpFolder and xpFolder:FindFirstChild("XPBoost") or nil
end

function PlayerDataSystem.GetRebirthFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Rebirth") or nil
end

function PlayerDataSystem.GetPassiveFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Passives") or nil
end

function PlayerDataSystem.GetRuneFolder(player)
	local data = PlayerDataSystem.GetPlayerData(player)
	return data and data:FindFirstChild("Runes") or nil
end

function PlayerDataSystem.GetRuneUpgradeFolder(player)
	local folder = PlayerDataSystem.GetRuneFolder(player)
	return folder and folder:FindFirstChild("Upgrades") or nil
end

function PlayerDataSystem.GetCurrencyObjectForName(player, currencyName)
	if currencyName == "Coins" then
		return PlayerDataSystem.GetCoinsObject(player)
	elseif currencyName == "Wood" then
		return PlayerDataSystem.GetWoodCurrencyObject(player)
	elseif currencyName == "Paper" then
		return PlayerDataSystem.GetPaperCurrencyObject(player)
	elseif currencyName == "Hay" then
		return PlayerDataSystem.GetHayCurrencyObject(player)
	end
	return nil
end

function PlayerDataSystem.SetupPlayerDataObjects(player)
	local playerData = ensureFolder(player, "PlayerData")

	createValue(playerData, "NumberValue", "Coins", 0)
	local gamepassFolder = ensureFolder(playerData, "Gamepasses")
	for gamepassName, _ in pairs(GamepassIds) do
		createValue(gamepassFolder, "BoolValue", gamepassName, false)
	end

	local coinUpgrades = ensureFolder(playerData, "CoinUpgrades")
	for _, config in pairs(COIN_UPGRADES) do
		createValue(coinUpgrades, "IntValue", config.levelName, 0)
		createValue(coinUpgrades, "IntValue", config.costName, config.startCost)
		createValue(coinUpgrades, "BoolValue", config.activeName, false)
	end

	local woodFolder = ensureFolder(playerData, "Wood")
	createValue(woodFolder, "NumberValue", "WoodCurrency", 0)

	local woodUpgrades = ensureFolder(woodFolder, "WoodUpgrades")
	for _, config in pairs(WOOD_UPGRADES) do
		createValue(woodUpgrades, "IntValue", config.levelName, 0)
		createValue(woodUpgrades, "IntValue", config.costName, config.startCost)
		createValue(woodUpgrades, "BoolValue", config.activeName, false)
	end

	local paperFactory = ensureFolder(woodFolder, "PaperFactory")
	createValue(paperFactory, "NumberValue", "Paper", 0)
	createValue(paperFactory, "IntValue", "Fuel", 0)
	createValue(paperFactory, "NumberValue", "Countdown", BASE_PAPER_PRODUCTION_TIME)
	createValue(paperFactory, "BoolValue", "IsRunning", false)

	local paperUpgrades = ensureFolder(woodFolder, "PaperUpgrades")
	for _, config in pairs(PAPER_UPGRADES) do
		createValue(paperUpgrades, "IntValue", config.levelName, 0)
		createValue(paperUpgrades, "IntValue", config.costName, config.startCost)
		createValue(paperUpgrades, "BoolValue", config.activeName, false)
	end

	local hayFolder = ensureFolder(playerData, "Hay")
	createValue(hayFolder, "NumberValue", "HayCurrency", 0)
	local hayUpgrades = ensureFolder(hayFolder, "HayUpgrades")
	for _, config in pairs(HAY_UPGRADES) do
		createValue(hayUpgrades, "IntValue", config.levelName, 0)
		createValue(hayUpgrades, "NumberValue", config.costName, config.startCost)
		createValue(hayUpgrades, "BoolValue", config.levelName .. "Active", false)
	end

	local xpFolder = ensureFolder(playerData, "XP")
	createValue(xpFolder, "NumberValue", "XPValue", 0)
	local xpUpgrades = ensureFolder(xpFolder, "XPUpgrades")
	for _, cfg in pairs(XP_UPGRADES) do
		createValue(xpUpgrades, "IntValue", cfg.levelName, 0)
		createValue(xpUpgrades, "NumberValue", cfg.costName, cfg.startCost)
	end
	local xpBoost = ensureFolder(xpFolder, "XPBoost")
	createValue(xpBoost, "IntValue", XP_BOOST_CONFIG.levelName, 0)
	createValue(xpBoost, "NumberValue", XP_BOOST_CONFIG.costName, XP_BOOST_CONFIG.startCost)

	local rebirthFolder = ensureFolder(playerData, "Rebirth")
	createValue(rebirthFolder, "IntValue", "Count", 0)
	createValue(rebirthFolder, "IntValue", "NextCost", REBIRTH_STAGES[1].cost)
	createValue(rebirthFolder, "StringValue", "NextCurrency", REBIRTH_STAGES[1].currency)
	createValue(rebirthFolder, "NumberValue", "CoinMultiplierBonus", 1)
	createValue(rebirthFolder, "NumberValue", "SpawnSpeedBonus", 0)
	createValue(rebirthFolder, "NumberValue", "WoodMultiplierBonus", 1)
	createValue(rebirthFolder, "BoolValue", "SecondAreaUnlocked", false)
	createValue(rebirthFolder, "BoolValue", "ThirdUpgradeUnlocked", false)
	createValue(rebirthFolder, "BoolValue", "FourthSystemsUnlocked", false)
	createValue(rebirthFolder, "BoolValue", "FifthSystemsUnlocked", false)
	createValue(rebirthFolder, "BoolValue", "SixthSystemsUnlocked", false)

	local passiveFolder = ensureFolder(playerData, "Passives")
	createValue(passiveFolder, "StringValue", "StateJson", HttpService:JSONEncode(emptyPassiveState()))

	local runeFolder = ensureFolder(playerData, "Runes")
	createValue(runeFolder, "StringValue", "StateJson", HttpService:JSONEncode(emptyRuneState()))
	local runeUpgrades = ensureFolder(runeFolder, "Upgrades")
	for _, config in pairs(RUNE_UPGRADES) do
		createValue(runeUpgrades, "IntValue", config.levelName, 0)
		createValue(runeUpgrades, "NumberValue", config.costName, config.startCost)
	end

	updateUpgradeActiveFlags(coinUpgrades, COIN_UPGRADES)
	updateUpgradeActiveFlags(woodUpgrades, WOOD_UPGRADES)
	updateUpgradeActiveFlags(paperUpgrades, PAPER_UPGRADES)
	updateUpgradeActiveFlags(hayUpgrades, HAY_UPGRADES)

	return playerData
end


function PlayerDataSystem.GetRebirthCoinMultiplier(count)
	local c = math.max(0, math.floor(tonumber(count) or 0))
	if c == 0 then return 1 end
	if c == 1 then return 2 end
	if c == 2 then return 10 end
	if c == 3 then return 100 end

	local mul = 1
	for i = 1, c do
		local stage = REBIRTH_STAGES[i]
		if stage then
			mul *= (tonumber(stage.coinMultiplier) or 1)
		end
	end
	return mul
end

function PlayerDataSystem.RecalculateRebirthStats(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth then
		return
	end

	local count = tonumber(rebirth.Count.Value) or 0
	local totalSpawnBonus = 0
	local totalWoodMultiplier = 1
	local secondUnlocked = false
	local thirdUnlocked = false
	local fourthUnlocked = false
	local fifthUnlocked = false
	local sixthUnlocked = false

	for i = 1, count do
		local stage = REBIRTH_STAGES[i]
		if stage then
			totalSpawnBonus += tonumber(stage.spawnBonus) or 0
			totalWoodMultiplier *= tonumber(stage.woodMultiplier) or 1
			if stage.unlockTree then secondUnlocked = true end
			if stage.unlockThirdUpgrades then thirdUnlocked = true end
			if stage.unlockFourthSystems then fourthUnlocked = true end
			if stage.unlockFifthSystems then fifthUnlocked = true end
			if stage.unlockSixthSystems then sixthUnlocked = true end
		end
	end

	rebirth.CoinMultiplierBonus.Value = PlayerDataSystem.GetRebirthCoinMultiplier(count)
	rebirth.SpawnSpeedBonus.Value = totalSpawnBonus
	rebirth.WoodMultiplierBonus.Value = totalWoodMultiplier
	rebirth.SecondAreaUnlocked.Value = secondUnlocked
	rebirth.ThirdUpgradeUnlocked.Value = thirdUnlocked
	rebirth.FourthSystemsUnlocked.Value = fourthUnlocked
	rebirth.FifthSystemsUnlocked.Value = fifthUnlocked
	rebirth.SixthSystemsUnlocked.Value = sixthUnlocked

	local nextStage = REBIRTH_STAGES[count + 1]
	if nextStage then
		rebirth.NextCost.Value = nextStage.cost
		rebirth.NextCurrency.Value = nextStage.currency
	else
		rebirth.NextCost.Value = 0
		rebirth.NextCurrency.Value = "None"
	end
end

function PlayerDataSystem.ResetCoinProgress(player)
	local coins = PlayerDataSystem.GetCoinsObject(player)
	local coinUpgrades = PlayerDataSystem.GetCoinUpgradesFolder(player)
	if coins then
		coins.Value = 0
	end
	if coinUpgrades then
		for _, config in pairs(COIN_UPGRADES) do
			local levelObject = coinUpgrades:FindFirstChild(config.levelName)
			local costObject = coinUpgrades:FindFirstChild(config.costName)
			if levelObject then levelObject.Value = 0 end
			if costObject then costObject.Value = config.startCost end
		end
		updateUpgradeActiveFlags(coinUpgrades, COIN_UPGRADES)
	end
end

function PlayerDataSystem.ResetWoodProgress(player)
	local woodCurrency = PlayerDataSystem.GetWoodCurrencyObject(player)
	local woodUpgrades = PlayerDataSystem.GetWoodUpgradesFolder(player)
	local hayCurrency = PlayerDataSystem.GetHayCurrencyObject(player)
	local hayUpgrades = PlayerDataSystem.GetHayUpgradesFolder(player)
	local paperFactory = PlayerDataSystem.GetPaperFactoryFolder(player)
	local paperUpgrades = PlayerDataSystem.GetPaperUpgradesFolder(player)

	if woodCurrency then woodCurrency.Value = 0 end
	if woodUpgrades then
		for _, config in pairs(WOOD_UPGRADES) do
			local levelObject = woodUpgrades:FindFirstChild(config.levelName)
			local costObject = woodUpgrades:FindFirstChild(config.costName)
			if levelObject then levelObject.Value = 0 end
			if costObject then costObject.Value = config.startCost end
		end
		updateUpgradeActiveFlags(woodUpgrades, WOOD_UPGRADES)
	end

	if hayCurrency then hayCurrency.Value = 0 end
	if hayUpgrades then
		for _, config in pairs(HAY_UPGRADES) do
			local levelObject = hayUpgrades:FindFirstChild(config.levelName)
			local costObject = hayUpgrades:FindFirstChild(config.costName)
			if levelObject then levelObject.Value = 0 end
			if costObject then costObject.Value = config.startCost end
		end
		updateUpgradeActiveFlags(hayUpgrades, HAY_UPGRADES)
	end

	if paperFactory then
		paperFactory.Paper.Value = 0
		paperFactory.Fuel.Value = 0
		paperFactory.Countdown.Value = BASE_PAPER_PRODUCTION_TIME
		paperFactory.IsRunning.Value = false
	end
	if paperUpgrades then
		for _, config in pairs(PAPER_UPGRADES) do
			local levelObject = paperUpgrades:FindFirstChild(config.levelName)
			local costObject = paperUpgrades:FindFirstChild(config.costName)
			if levelObject then levelObject.Value = 0 end
			if costObject then costObject.Value = config.startCost end
		end
		updateUpgradeActiveFlags(paperUpgrades, PAPER_UPGRADES)
	end
end

function PlayerDataSystem.TryPurchaseRebirth(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth then
		return false, "NO_REBIRTH"
	end
	local currentCount = rebirth.Count.Value
	if currentCount >= MAX_REBIRTH_COUNT then
		return false, "MAX"
	end
	local nextStage = REBIRTH_STAGES[currentCount + 1]
	if not nextStage then
		return false, "MAX"
	end
	local currencyObject = PlayerDataSystem.GetCurrencyObjectForName(player, nextStage.currency)
	if not currencyObject then
		return false, "NO_CURRENCY"
	end
	if currencyObject.Value < nextStage.cost then
		return false, "NO_MONEY", nextStage.currency
	end
	if not PlayerDataSystem.SpendCurrency(currencyObject, nextStage.cost) then
		return false, "NO_MONEY", nextStage.currency
	end

	rebirth.Count.Value += 1
	PlayerDataSystem.RecalculateRebirthStats(player)
	PlayerDataSystem.ResetCoinProgress(player)
	PlayerDataSystem.ResetWoodProgress(player)
	PlayerDataSystem.MarkDirty(player)
	return true
end

function PlayerDataSystem.ApplyAdminRuneBoost(player, minLevel)
	local runeUpgrades = PlayerDataSystem.GetRuneUpgradeFolder(player)
	if not runeUpgrades then
		return false
	end

	local targetLevel = math.max(0, math.floor(tonumber(minLevel) or 20))
	local luck = runeUpgrades:FindFirstChild("RuneLuckLevel")
	local speed = runeUpgrades:FindFirstChild("RuneSpeedLevel")
	local bulk = runeUpgrades:FindFirstChild("RuneBulkLevel")
	if not (luck and speed and bulk) then
		return false
	end

	luck.Value = math.max(luck.Value, targetLevel)
	speed.Value = math.max(speed.Value, targetLevel)
	bulk.Value = math.max(bulk.Value, targetLevel)
	PlayerDataSystem.MarkDirty(player)
	return true
end

function PlayerDataSystem.Init()
	local Remotes = ReplicatedStorage:WaitForChild("Remotes")
	local purchaseRebirthEvent = Remotes:WaitForChild("PurchaseRebirth")
	local notifyEvent = Remotes:WaitForChild("NotifyClient")

	purchaseRebirthEvent.OnServerEvent:Connect(function(player)
		local success, reason, currencyName = PlayerDataSystem.TryPurchaseRebirth(player)
		if success then
			notifyEvent:FireClient(player, {kind = "Simple", text = "Перерождение куплено"})
			return
		end

		if reason == "MAX" then
			notifyEvent:FireClient(player, {kind = "Simple", text = "Перерождение уже в MAX"})
		elseif reason == "NO_MONEY" then
			local messageByCurrency = {
				Coins = "Не хватает монет для перерождения",
				Wood = "Не хватает дерева для перерождения",
				Paper = "Не хватает бумаги для перерождения",
			}
			notifyEvent:FireClient(player, {kind = "Simple", text = messageByCurrency[currencyName] or "Не хватает ресурса для перерождения"})
		end
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		PlayerDataSystem.SetupPlayerDataObjects(player)
		PlayerDataSystem.RecalculateRebirthStats(player)
	end

	Players.PlayerAdded:Connect(function(player)
		PlayerDataSystem.SetupPlayerDataObjects(player)
		PlayerDataSystem.RecalculateRebirthStats(player)
	end)
end

PlayerDataSystem.Config = {
	GamepassIds = GamepassIds,
	CoinUpgrades = COIN_UPGRADES,
	WoodUpgrades = WOOD_UPGRADES,
	PaperUpgrades = PAPER_UPGRADES,
	HayUpgrades = HAY_UPGRADES,
	XPUpgrades = XP_UPGRADES,
	XPBoost = XP_BOOST_CONFIG,
	RuneUpgrades = RUNE_UPGRADES,
	RebirthStages = REBIRTH_STAGES,
}

return PlayerDataSystem
