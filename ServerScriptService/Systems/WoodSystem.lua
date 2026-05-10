local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local WoodSystem = {}

local BASE_WOOD_COOLDOWN = 3
local MIN_WOOD_COOLDOWN = 0.5
local WOOD_COOLDOWN_STEP = 0.25

local woodCooldowns = {}
local initialized = false

local dependencies = {
	GetPassiveMultipliers = function()
		return 1, 1, 1, 1
	end,
	GetRuneBonusMultipliers = function()
		return 1, 1, 1, 1
	end,
	ComputeGoalWoodFactorFromCoins = function()
		return 1
	end,
	GetServerEventMultipliers = function()
		return 1, 1, 1, 1, 1
	end,
	GetGamepassMultiplier = function()
		return 1
	end,
}

local function roundToTenth(value)
	return PlayerDataSystem.RoundToTenth(value)
end

local function firePickup(player, iconKey, amount)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, {
		kind = "pickup",
		icon = iconKey,
		amount = amount,
	})
end

function WoodSystem.GetWoodReward(player)
	local coinUpgrades = PlayerDataSystem.GetCoinUpgradesFolder(player)
	local woodUpgrades = PlayerDataSystem.GetWoodUpgradesFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local coins = PlayerDataSystem.GetCoinsObject(player)

	if not coinUpgrades or not woodUpgrades or not rebirth or not coins then
		return 1
	end

	local _, passiveWoodMultiplier, passiveGlobalMultiplier = dependencies.GetPassiveMultipliers(player)
	local _, runeWoodMultiplier = dependencies.GetRuneBonusMultipliers(player)

	local baseValue = 1 + woodUpgrades.WoodValueLevel.Value
	local woodMultiplier = 1 + woodUpgrades.WoodMultiplierLevel.Value + (coinUpgrades.WoodBoostLevel.Value * 0.25)

	local goalFactor = 1
	if rebirth.FourthSystemsUnlocked.Value then
		goalFactor = dependencies.ComputeGoalWoodFactorFromCoins(coins.Value)
	end

	local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
	local xpMul = 1 + ((xpUpgrades and xpUpgrades:FindFirstChild("WoodXPLevel") and xpUpgrades.WoodXPLevel.Value or 0) * 0.2)
	local _, eventWoodMul = dependencies.GetServerEventMultipliers(player)
	local gamepassWoodMul = dependencies.GetGamepassMultiplier(player, "DoubleWood", 2)
	return roundToTenth(baseValue * woodMultiplier * goalFactor * rebirth.WoodMultiplierBonus.Value * passiveWoodMultiplier * passiveGlobalMultiplier * runeWoodMultiplier * xpMul * eventWoodMul * gamepassWoodMul)
end

function WoodSystem.GetWoodCooldown(player)
	local woodUpgrades = PlayerDataSystem.GetWoodUpgradesFolder(player)
	if not woodUpgrades then
		return BASE_WOOD_COOLDOWN
	end

	local value = BASE_WOOD_COOLDOWN - (woodUpgrades.WoodSpeedLevel.Value * WOOD_COOLDOWN_STEP)
	local _, _, _, passiveSpeedMultiplier = dependencies.GetPassiveMultipliers(player)
	value /= math.max(1, passiveSpeedMultiplier)
	if value < MIN_WOOD_COOLDOWN then
		value = MIN_WOOD_COOLDOWN
	end

	return roundToTenth(value)
end

function WoodSystem.HandleWoodClick(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth or not rebirth.SecondAreaUnlocked.Value then
		return
	end

	local now = os.clock()
	local lastClick = woodCooldowns[player.UserId] or 0
	local cooldown = WoodSystem.GetWoodCooldown(player)

	if now - lastClick < cooldown then
		return
	end

	woodCooldowns[player.UserId] = now

	local reward = WoodSystem.GetWoodReward(player)
	PlayerDataSystem.AddCurrency(PlayerDataSystem.GetWoodCurrencyObject(player), reward)
	PlayerDataSystem.MarkDirty(player)

	firePickup(player, "Tree", reward)
end

function WoodSystem.Init(customDependencies)
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

	local woodClickEvent = RemoteRegistry.GetRemote("WoodClick")
	woodClickEvent.OnServerEvent:Connect(function(player)
		WoodSystem.HandleWoodClick(player)
	end)
end

return WoodSystem
