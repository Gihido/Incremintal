local HttpService = game:GetService("HttpService")

local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local PassiveSystem = {}

local PASSIVE_ROLL_COST = 50
local PASSIVE_INVENTORY_CAPACITY = 10
local PASSIVE_ROLL_COOLDOWN = 3.5

local PASSIVE_DEFS = {
	CoinBallA = {
		id = "CoinBallA",
		name = "Coin Ball A",
		rarity = "Common",
		coinMultiplier = 1.5,
		woodMultiplier = 1,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 35,
	},
	CoinBallB = {
		id = "CoinBallB",
		name = "Coin Ball B",
		rarity = "Common",
		coinMultiplier = 2,
		woodMultiplier = 1,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 25,
	},
	WoodBallA = {
		id = "WoodBallA",
		name = "Wood Ball A",
		rarity = "Uncommon",
		coinMultiplier = 1,
		woodMultiplier = 1.5,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 15,
	},
	DualBall = {
		id = "DualBall",
		name = "Dual Ball",
		rarity = "Uncommon",
		coinMultiplier = 1.5,
		woodMultiplier = 1.5,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 12,
	},
	RareSprout = {
		id = "RareSprout",
		name = "Rare Sprout",
		rarity = "Rare",
		coinMultiplier = 1,
		woodMultiplier = 2,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 7,
	},
	RareForest = {
		id = "RareForest",
		name = "Rare Forest",
		rarity = "Rare",
		coinMultiplier = 1,
		woodMultiplier = 3,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 6,
	},
	EpicBloom = {
		id = "EpicBloom",
		name = "Epic Bloom",
		rarity = "Epic",
		coinMultiplier = 3,
		woodMultiplier = 5,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 4,
	},
	LegendSeed = {
		id = "LegendSeed",
		name = "Legend Seed",
		rarity = "Legendary",
		coinMultiplier = 5,
		woodMultiplier = 5,
		globalMultiplier = 1,
		speedMultiplier = 1,
		weight = 1,
	},
	SwiftLeaf = {
		id = "SwiftLeaf",
		name = "Swift Leaf",
		rarity = "Epic",
		coinMultiplier = 1.2,
		woodMultiplier = 1.2,
		globalMultiplier = 1,
		speedMultiplier = 1.35,
		weight = 2,
	},
	MythicCore = {
		id = "MythicCore",
		name = "Mythic Core",
		rarity = "Mythic",
		coinMultiplier = 1,
		woodMultiplier = 1,
		globalMultiplier = 2,
		speedMultiplier = 1,
		weight = 1,
	},
	XPSeeker = {
		id = "XPSeeker",
		name = "XP Seeker",
		rarity = "Rare",
		coinMultiplier = 1,
		woodMultiplier = 1,
		globalMultiplier = 1,
		speedMultiplier = 1,
		xpMultiplier = 1.5,
		weight = 6,
	},
	PaperPulse = {id = "PaperPulse", name = "Paper Pulse", rarity = "Rare", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1.15, speedMultiplier = 1, weight = 5},
	ForestMint = {id = "ForestMint", name = "Forest Mint", rarity = "Uncommon", coinMultiplier = 1.35, woodMultiplier = 1.35, globalMultiplier = 1, speedMultiplier = 1, weight = 10},
	ClockworkLeaf = {id = "ClockworkLeaf", name = "Clockwork Leaf", rarity = "Epic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1.25, weight = 4},
	RuneScout = {id = "RuneScout", name = "Rune Scout", rarity = "Rare", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1, runeLuckMultiplier = 1.25, weight = 5},
	BulkCrafter = {id = "BulkCrafter", name = "Bulk Crafter", rarity = "Epic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1, runeBulkMultiplier = 1.3, weight = 3},
	VelocityRune = {id = "VelocityRune", name = "Velocity Rune", rarity = "Epic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1, runeSpeedMultiplier = 1.4, weight = 3},
	MythicPrism = {id = "MythicPrism", name = "Mythic Prism", rarity = "Mythic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 2, speedMultiplier = 1, weight = 0.7},
	MythicRunelord = {id = "MythicRunelord", name = "Mythic Runelord", rarity = "Mythic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1, runeLuckMultiplier = 3, runeSpeedMultiplier = 3, runeBulkMultiplier = 2, weight = 0.5},
	MythicChronicle = {id = "MythicChronicle", name = "Mythic Chronicle", rarity = "Mythic", coinMultiplier = 1.35, woodMultiplier = 1.35, globalMultiplier = 1.35, speedMultiplier = 1.1, xpMultiplier = 2, weight = 0.3},
	SecretRunicOverlord = {id = "SecretRunicOverlord", name = "Secret Runic Overlord", rarity = "Mythic", coinMultiplier = 1, woodMultiplier = 1, globalMultiplier = 1, speedMultiplier = 1, runeLuckMultiplier = 50, runeSpeedMultiplier = 25, runeBulkMultiplier = 5, weight = 0.0001},
}

local passiveStates = {}
local passiveRollCooldowns = {}
local initialized = false

local dependencies = {
	GetRuneBonusMultipliers = function()
		return 1, 1, 1, 1, 1, 1, 1, 1
	end,
}

local function safeNumber(value, defaultValue)
	local n = tonumber(value)
	if n == nil then
		return defaultValue
	end
	return n
end

local function fireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, {
		kind = "simple",
		text = tostring(text),
	})
end

local function firePassiveRoll(player, passiveId)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, {
		kind = "passive_roll_result",
		passiveId = passiveId,
	})
end

function PassiveSystem.EmptyPassiveState()
	return {
		inventory = {},
		equippedUid = "",
	}
end

function PassiveSystem.GetPassiveState(player)
	if not passiveStates[player] then
		passiveStates[player] = PassiveSystem.EmptyPassiveState()
	end
	return passiveStates[player]
end

function PassiveSystem.SetPassiveState(player, state)
	passiveStates[player] = type(state) == "table" and state or PassiveSystem.EmptyPassiveState()
	PassiveSystem.WritePassiveStateValue(player)
end

function PassiveSystem.WritePassiveStateValue(player)
	local passiveFolder = PlayerDataSystem.GetPassiveFolder(player)
	if not passiveFolder then
		return
	end

	local jsonValue = passiveFolder:FindFirstChild("StateJson")
	if not jsonValue then
		return
	end

	jsonValue.Value = HttpService:JSONEncode(PassiveSystem.GetPassiveState(player))
end

function PassiveSystem.GetEquippedPassiveEntry(player)
	local state = PassiveSystem.GetPassiveState(player)
	if state.equippedUid == "" then
		return nil
	end

	for _, entry in ipairs(state.inventory) do
		if type(entry) == "table" and entry.uid and entry.uid == state.equippedUid then
			return entry
		end
	end

	return nil
end

function PassiveSystem.GetEquippedPassiveDef(player)
	local entry = PassiveSystem.GetEquippedPassiveEntry(player)
	if not entry then
		return nil
	end

	return entry.passiveId and PASSIVE_DEFS[entry.passiveId] or nil
end

function PassiveSystem.GetPassiveMultipliers(player)
	local passiveDef = PassiveSystem.GetEquippedPassiveDef(player)
	if not passiveDef then
		return 1, 1, 1, 1
	end

	return passiveDef.coinMultiplier or 1, passiveDef.woodMultiplier or 1, passiveDef.globalMultiplier or 1, passiveDef.speedMultiplier or 1
end

function PassiveSystem.GetPassiveSpecialBoosts(player)
	local passiveDef = PassiveSystem.GetEquippedPassiveDef(player)
	if not passiveDef then
		return 1, 1, 1, 1
	end
	return passiveDef.runeLuckMultiplier or 1, passiveDef.runeSpeedMultiplier or 1, passiveDef.runeBulkMultiplier or 1, passiveDef.xpMultiplier or 1
end

function PassiveSystem.ChooseRandomPassiveId(player)
	local totalWeight = 0
	local passiveLuckMul = 1
	if player then
		_, _, _, _, _, _, _, passiveLuckMul = dependencies.GetRuneBonusMultipliers(player)
	end

	for _, passiveDef in pairs(PASSIVE_DEFS) do
		totalWeight += safeNumber(passiveDef.weight, 0) * safeNumber(passiveLuckMul, 1)
	end

	local roll = math.random() * totalWeight
	local running = 0

	for passiveId, passiveDef in pairs(PASSIVE_DEFS) do
		running += safeNumber(passiveDef.weight, 0) * safeNumber(passiveLuckMul, 1)
		if roll <= running then
			return passiveId
		end
	end

	return "CoinBallA"
end

function PassiveSystem.HandlePassiveAction(player, actionName, argument)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local paper = PlayerDataSystem.GetPaperCurrencyObject(player)

	if not rebirth or not paper then
		return
	end

	if not rebirth.FifthSystemsUnlocked.Value then
		fireSimple(player, "Откроется на 5-м перерождении")
		return
	end

	local state = PassiveSystem.GetPassiveState(player)

	if actionName == "Roll" then
		local now = os.clock()
		local nextRollAt = passiveRollCooldowns[player.UserId] or 0
		if now < nextRollAt then
			fireSimple(player, "Подожди, предыдущий ролл еще идет")
			return
		end
		if #state.inventory >= PASSIVE_INVENTORY_CAPACITY then
			fireSimple(player, "Инвентарь пассивов заполнен")
			return
		end

		if paper.Value < PASSIVE_ROLL_COST then
			fireSimple(player, "Не хватает бумаги")
			return
		end

		if not PlayerDataSystem.SpendCurrency(paper, PASSIVE_ROLL_COST) then
			return
		end

		local passiveId = PassiveSystem.ChooseRandomPassiveId(player)
		passiveRollCooldowns[player.UserId] = now + PASSIVE_ROLL_COOLDOWN
		table.insert(state.inventory, {
			uid = HttpService:GenerateGUID(false),
			passiveId = passiveId,
		})

		PassiveSystem.WritePassiveStateValue(player)
		PlayerDataSystem.MarkDirty(player)
		firePassiveRoll(player, passiveId)
	elseif actionName == "Equip" then
		local targetUid = tostring(argument or "")
		local found = false

		for _, entry in ipairs(state.inventory) do
			if type(entry) == "table" and entry.uid == targetUid then
				found = true
				break
			end
		end

		if found then
			state.equippedUid = targetUid
			PassiveSystem.WritePassiveStateValue(player)
			PlayerDataSystem.MarkDirty(player)
			fireSimple(player, "Пассив экипирован")
		end
	elseif actionName == "Unequip" then
		state.equippedUid = ""
		PassiveSystem.WritePassiveStateValue(player)
		PlayerDataSystem.MarkDirty(player)
		fireSimple(player, "Пассив снят")
	elseif actionName == "Delete" then
		local targetUid = tostring(argument or "")

		for i = #state.inventory, 1, -1 do
			if state.inventory[i].uid == targetUid then
				table.remove(state.inventory, i)
				break
			end
		end

		if state.equippedUid == targetUid then
			state.equippedUid = ""
		end

		PassiveSystem.WritePassiveStateValue(player)
		PlayerDataSystem.MarkDirty(player)
		fireSimple(player, "Пассив удалён")
	end
end

function PassiveSystem.HasPassiveDef(passiveId)
	return PASSIVE_DEFS[tostring(passiveId or "")] ~= nil
end

function PassiveSystem.GrantPassive(player, passiveId)
	local resolvedPassiveId = tostring(passiveId or "")
	if not PassiveSystem.HasPassiveDef(resolvedPassiveId) then
		return false, "NOT_FOUND"
	end

	local state = PassiveSystem.GetPassiveState(player)
	if #state.inventory >= PASSIVE_INVENTORY_CAPACITY then
		return false, "INVENTORY_FULL"
	end

	table.insert(state.inventory, {
		uid = HttpService:GenerateGUID(false),
		passiveId = resolvedPassiveId,
	})

	PassiveSystem.WritePassiveStateValue(player)
	PlayerDataSystem.MarkDirty(player)
	firePassiveRoll(player, resolvedPassiveId)
	return true
end

function PassiveSystem.Init(customDependencies)
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

	local passiveActionEvent = RemoteRegistry.GetRemote("PassiveAction")
	passiveActionEvent.OnServerEvent:Connect(function(player, actionName, argument)
		PassiveSystem.HandlePassiveAction(player, actionName, argument)
	end)
end

PassiveSystem.PassiveDefs = PASSIVE_DEFS
PassiveSystem.PassiveRollCost = PASSIVE_ROLL_COST
PassiveSystem.PassiveInventoryCapacity = PASSIVE_INVENTORY_CAPACITY

return PassiveSystem
