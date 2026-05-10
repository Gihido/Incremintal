local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local HayRuntimeSystem = require(script.Parent:WaitForChild("RuntimeLoops"):WaitForChild("HayRuntimeSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local HaySystem = {}

local BASE_HAY_COOLDOWN = 5
local MIN_HAY_COOLDOWN = 0.8
local HAY_UPGRADE_KEYS = {"HayAmount", "HayMultiplier", "HayCooldown"}

local hayBlock = nil
local hayCooldowns = {}
local activeHayCollection = {}
local initialized = false

local dependencies = {
	GetServerEventMultipliers = function()
		return 1, 1, 1, 1, 1
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

local function isCharacterOnBlock(player, block, tolerance)
	if not block then
		return false
	end

	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end

	local tol = tolerance or Vector3.new(1.2, 3.5, 1.2)
	local localPos = block.CFrame:PointToObjectSpace(hrp.Position)
	local half = block.Size * 0.5
	return math.abs(localPos.X) <= (half.X + tol.X)
		and math.abs(localPos.Z) <= (half.Z + tol.Z)
		and math.abs(localPos.Y) <= (half.Y + tol.Y)
end

function HaySystem.NormalizeHaySaveData(savedHay)
	local hayTable = type(savedHay) == "table" and savedHay or {}
	hayTable.HayUpgrades = type(hayTable.HayUpgrades) == "table" and hayTable.HayUpgrades or {}
	local nestedUpgrades = hayTable.HayUpgrades
	local normalizedLevels = {}
	local hayUpgradesConfig = PlayerDataSystem.Config.HayUpgrades

	for _, key in ipairs(HAY_UPGRADE_KEYS) do
		local levelName = hayUpgradesConfig[key].levelName
		normalizedLevels[levelName] = tonumber(hayTable[levelName]) or tonumber(nestedUpgrades[key]) or 0
	end

	nestedUpgrades.HayAmount = normalizedLevels.HayAmountLevel or 0
	nestedUpgrades.HayMultiplier = normalizedLevels.HayMultiplierLevel or 0
	nestedUpgrades.HayCooldown = normalizedLevels.HayCooldownLevel or 0

	return {
		HayCurrency = tonumber(hayTable.HayCurrency) or 0,
		HayAmountLevel = normalizedLevels.HayAmountLevel or 0,
		HayMultiplierLevel = normalizedLevels.HayMultiplierLevel or 0,
		HayCooldownLevel = normalizedLevels.HayCooldownLevel or 0,
		HayAmountCost = tonumber(hayTable.HayAmountCost),
		HayMultiplierCost = tonumber(hayTable.HayMultiplierCost),
		HayCooldownCost = tonumber(hayTable.HayCooldownCost),
		HayUpgrades = {
			HayAmount = nestedUpgrades.HayAmount,
			HayMultiplier = nestedUpgrades.HayMultiplier,
			HayCooldown = nestedUpgrades.HayCooldown,
		},
	}
end

function HaySystem.GetHayReward(player)
	local hayUpgrades = PlayerDataSystem.GetHayUpgradesFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not hayUpgrades or not rebirth or (tonumber(rebirth.Count.Value) or 0) < 7 then
		return 0
	end

	local amountLevel = hayUpgrades.HayAmountLevel.Value
	local multiplierLevel = hayUpgrades.HayMultiplierLevel.Value
	local base = 1 + amountLevel
	local multiplier = 1 + (multiplierLevel * 0.5)
	local _, _, _, eventHayMul = dependencies.GetServerEventMultipliers(player)
	return roundToTenth(base * multiplier * eventHayMul)
end

function HaySystem.GetHayCooldown(player)
	local hayUpgrades = PlayerDataSystem.GetHayUpgradesFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not hayUpgrades or not rebirth or (tonumber(rebirth.Count.Value) or 0) < 7 then
		return BASE_HAY_COOLDOWN
	end

	local level = hayUpgrades.HayCooldownLevel.Value
	return math.max(MIN_HAY_COOLDOWN, roundToTenth(BASE_HAY_COOLDOWN - (level * 0.1)))
end

function HaySystem.IsCharacterOnHayBlock(player)
	if not hayBlock then
		return false
	end

	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth or (tonumber(rebirth.Count.Value) or 0) < 7 then
		return false
	end

	return isCharacterOnBlock(player, hayBlock, Vector3.new(0.2, 3, 0.2))
end

function HaySystem.UpdatePlayerHayCollection(player, now)
	if HaySystem.IsCharacterOnHayBlock(player) then
		activeHayCollection[player] = true
		local nextHayAt = hayCooldowns[player.UserId] or 0
		if now >= nextHayAt then
			local hayReward = HaySystem.GetHayReward(player)
			if hayReward > 0 then
				PlayerDataSystem.AddCurrency(PlayerDataSystem.GetHayCurrencyObject(player), hayReward)
				firePickup(player, "Hay", hayReward)
				PlayerDataSystem.MarkDirty(player)
			end
			hayCooldowns[player.UserId] = now + HaySystem.GetHayCooldown(player)
		end
	else
		activeHayCollection[player] = nil
		hayCooldowns[player.UserId] = now
	end
end

function HaySystem.Init(customDependencies)
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

	hayBlock = Workspace:FindFirstChild("HayBlock")
	HayRuntimeSystem.Start(HaySystem.UpdatePlayerHayCollection)
end

HaySystem.ActiveHayCollection = activeHayCollection
HaySystem.HayCooldowns = hayCooldowns
HaySystem.HayUpgradeKeys = HAY_UPGRADE_KEYS

return HaySystem
