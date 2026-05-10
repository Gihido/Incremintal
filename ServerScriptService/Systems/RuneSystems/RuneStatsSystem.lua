local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RuneInventorySystem = require(script.Parent:WaitForChild("RuneInventorySystem"))

local RuneStatsSystem = {}

local DEFAULT_RUNE_CAP_STACKS = 10

local RUNE_TYPES = {
	Grass = {displayName = "Трава", rarity = "Common", weight = 1, coinBonus = 0.1, woodBonus = 0, paperBonus = 0, xpBonus = 0, capStacks = 15},
	DarkGrass = {displayName = "Тёмная трава", rarity = "Uncommon", weight = 0.25, coinBonus = 0.25, woodBonus = 0, paperBonus = 0, xpBonus = 0, capStacks = 56},
	Dandelion = {displayName = "Одуванчик", rarity = "Rare", weight = 0.1, coinBonus = 0, woodBonus = 0, paperBonus = 0, xpBonus = 0.1, capStacks = 40},
	Flower = {displayName = "Цветок", rarity = "Epic", weight = 0.05, coinBonus = 0, woodBonus = 0, paperBonus = 0, xpBonus = 0, capStacks = 20, runeLuckBonus = 0.1, runeSpeedBonus = 0.1, runeBulkBonus = 1},
	Violet = {displayName = "Фиалка", rarity = "Legendary", weight = 0.02, coinBonus = 0, woodBonus = 0.1, paperBonus = 0.05, xpBonus = 0.05, capStacks = 20},
	Rose = {displayName = "Роза", rarity = "Mythic", weight = 0.01, coinBonus = 0, woodBonus = 0, paperBonus = 0, xpBonus = 0, capStacks = 20, passiveLuckBonus = 0.1},
}

local initialized = false

local dependencies = {
	GetPassiveSpecialBoosts = function()
		return 1, 1, 1, 1
	end,
	GetServerRuneEventBoosts = function()
		return 1, 1, 1, 0
	end,
	GetGamepassMultiplier = function()
		return 1
	end,
}

local function safeNumber(value, defaultValue)
	local n = tonumber(value)
	if n == nil then
		return defaultValue
	end
	return n
end

function RuneStatsSystem.ChooseRuneType(luckLevel)
	local luckFactor = 1 + (math.max(0, luckLevel or 0) * 0.12)
	local weighted = {}
	local total = 0
	for runeId, runeDef in pairs(RUNE_TYPES) do
		local weight = safeNumber(runeDef.weight, 0)
		if runeId ~= "Grass" then
			weight *= safeNumber(luckFactor, 1)
		end
		total += safeNumber(weight, 0)
		weighted[runeId] = weight
	end
	local roll = math.random() * total
	local running = 0
	for runeId, weight in pairs(weighted) do
		running += weight
		if roll <= running then
			return runeId
		end
	end
	return "Grass"
end

function RuneStatsSystem.GetRuneBonusMultipliers(player)
	local state = RuneInventorySystem.GetRuneState(player)
	local coinMul, woodMul, paperMul, xpMul = 1, 1, 1, 1
	local runeLuckMul, runeSpeedMul, runeBulkAdd, passiveLuckMul = 1, 1, 0, 1
	for runeId, runeDef in pairs(RUNE_TYPES) do
		local count = 0
		if state.counts then
			count = safeNumber(state.counts[runeId], 0)
		end
		local stacks = math.clamp(safeNumber(count, 0), 0, safeNumber(runeDef.capStacks, DEFAULT_RUNE_CAP_STACKS))
		coinMul += safeNumber(runeDef.coinBonus, 0) * stacks
		woodMul += safeNumber(runeDef.woodBonus, 0) * stacks
		paperMul += safeNumber(runeDef.paperBonus, 0) * stacks
		xpMul += safeNumber(runeDef.xpBonus, 0) * stacks
		runeLuckMul += safeNumber(runeDef.runeLuckBonus, 0) * stacks
		runeSpeedMul += safeNumber(runeDef.runeSpeedBonus, 0) * stacks
		runeBulkAdd += safeNumber(runeDef.runeBulkBonus, 0) * stacks
		passiveLuckMul += safeNumber(runeDef.passiveLuckBonus, 0) * stacks
	end
	local forest = state and state.forestCounts or {}
	local palka = math.min(15, safeNumber(forest.Palka, 0))
	local obrub = math.min(56, safeNumber(forest.ObrublennyKonec, 0))
	local vetv = math.min(40, safeNumber(forest.VetvDereva, 0))
	local brevno = math.min(20, safeNumber(forest.Brevno, 0))
	local poleno = math.min(40, safeNumber(forest.Poleno, 0))
	local obgPen = math.min(20, safeNumber(forest.ObgorevshiyPen, 0))
	coinMul += (palka * 0.1) + (obrub * 0.25)
	xpMul += vetv * 0.1
	runeLuckMul += brevno * 0.1
	runeSpeedMul += brevno * 0.1
	runeBulkAdd += math.min(5, brevno)
	paperMul += poleno * 0.1
	woodMul += poleno * 0.1
	passiveLuckMul += obgPen * 0.1
	return coinMul, woodMul, paperMul, xpMul, runeLuckMul, runeSpeedMul, runeBulkAdd, passiveLuckMul
end

function RuneStatsSystem.GetRuneSpeedOverflowBulk(speedStat)
	local interval = 1 / math.max(1, (1 + (math.max(0, speedStat) * 0.5)))
	if interval >= 0.01 then
		return 0
	end
	local overflowFactor = math.min(250, 0.01 / math.max(0.000001, interval))
	return math.max(0, math.floor((overflowFactor - 1) * 2 + 0.5))
end

function RuneStatsSystem.GetEffectiveRuneStats(player)
	local runeUpgrades = RuneInventorySystem.GetRuneUpgradeFolder(player)
	local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
	if not runeUpgrades then
		return 1, 1, 1
	end
	local luck = 1 + runeUpgrades.RuneLuckLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneLuckXPLevel") and xpUpgrades.RuneLuckXPLevel.Value or 0))
	local speed = 1 + runeUpgrades.RuneSpeedLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneSpeedXPLevel") and xpUpgrades.RuneSpeedXPLevel.Value or 0))
	local bulk = 1 + runeUpgrades.RuneBulkLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneBulkXPLevel") and xpUpgrades.RuneBulkXPLevel.Value or 0))
	local _, _, _, _, runeLuckMul, runeSpeedMul, runeBulkAdd = RuneStatsSystem.GetRuneBonusMultipliers(player)
	runeLuckMul = safeNumber(runeLuckMul, 1)
	runeSpeedMul = safeNumber(runeSpeedMul, 1)
	runeBulkAdd = safeNumber(runeBulkAdd, 0)
	luck = luck * runeLuckMul
	speed = speed * runeSpeedMul
	bulk = bulk + runeBulkAdd
	local passiveLuckMul, passiveSpeedMul, passiveBulkMul = dependencies.GetPassiveSpecialBoosts(player)
	passiveLuckMul = safeNumber(passiveLuckMul, 1)
	passiveSpeedMul = safeNumber(passiveSpeedMul, 1)
	passiveBulkMul = safeNumber(passiveBulkMul, 1)
	luck = math.floor(luck * passiveLuckMul + 0.5)
	speed = math.floor(speed * passiveSpeedMul + 0.5)
	bulk = math.floor(bulk * passiveBulkMul + 0.5)
	local eventLuckMul, eventSpeedMul, eventBulkMul, eventBulkAdd = dependencies.GetServerRuneEventBoosts()
	eventLuckMul = safeNumber(eventLuckMul, 1)
	eventSpeedMul = safeNumber(eventSpeedMul, 1)
	eventBulkMul = safeNumber(eventBulkMul, 1)
	eventBulkAdd = safeNumber(eventBulkAdd, 0)
	luck = math.floor(luck * eventLuckMul + 0.5)
	speed = math.floor(speed * eventSpeedMul + 0.5)
	bulk = math.floor(bulk * eventBulkMul + 0.5)
	bulk += eventBulkAdd
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if rebirth and rebirth.Count.Value >= 7 then
		luck = math.floor(luck * 1.5 + 0.5)
	end
	luck = math.floor(luck * dependencies.GetGamepassMultiplier(player, "TripleRuneLuck", 3) + 0.5)
	bulk += RuneStatsSystem.GetRuneSpeedOverflowBulk(speed)
	return luck, speed, bulk
end

function RuneStatsSystem.Init(customDependencies)
	if initialized then
		return
	end
	initialized = true

	if type(customDependencies) == "table" then
		for key, callback in pairs(customDependencies) do
			if dependencies[key] ~= nil and type(callback) == "function" then
				dependencies[key] = callback
			end
		end
	end
end

RuneStatsSystem.RuneTypes = RUNE_TYPES
RuneStatsSystem.DefaultRuneCapStacks = DEFAULT_RUNE_CAP_STACKS

return RuneStatsSystem
