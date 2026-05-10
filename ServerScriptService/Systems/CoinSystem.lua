local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local CoinSystem = {}

local MAX_COINS = 10
local BASE_COIN_RESPAWN = 3
local MIN_COIN_RESPAWN = 0.5

local spawnedCoinsFolder = nil
local zonePart = nil
local coinTemplate = nil
local activeCoinCount = 0
local animatedCoins = {}
local initialized = false

local dependencies = {
	GetPassiveMultipliers = function()
		return 1, 1, 1, 1
	end,
	GetPassiveSpecialBoosts = function()
		return 1, 1, 1, 1
	end,
	GetRuneBonusMultipliers = function()
		return 1, 1, 1, 1
	end,
	SyncRebirthCoinMultiplierBonus = function(player)
		local rebirth = PlayerDataSystem.GetRebirthFolder(player)
		local bonus = rebirth and rebirth:FindFirstChild("CoinMultiplierBonus")
		return bonus and bonus.Value or 1
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
	GetXPBoostMultiplier = function()
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

local function ensureSpawnedCoinsFolder()
	local folder = Workspace:FindFirstChild("SpawnedCoins")
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = "SpawnedCoins"
	folder.Parent = Workspace
	return folder
end

local function getRandomCoinCFrame()
	local zoneSize = zonePart.Size
	local coinSize = coinTemplate.Size

	local halfX = math.max((zoneSize.X / 2) - (coinSize.X / 2), 0)
	local halfZ = math.max((zoneSize.Z / 2) - (coinSize.Z / 2), 0)

	local randomX = (math.random() * 2 - 1) * halfX
	local randomZ = (math.random() * 2 - 1) * halfZ
	local yOffset = (zoneSize.Y / 2) + (coinSize.Y / 2) + 0.05

	local localPosition = Vector3.new(randomX, yOffset, randomZ)
	local worldPosition = zonePart.CFrame:PointToWorldSpace(localPosition)

	return CFrame.new(worldPosition)
end

local function applyCoinVisuals(coin)
	if not coin:FindFirstChild("CoinLight") then
		local light = Instance.new("PointLight")
		light.Name = "CoinLight"
		light.Color = Color3.fromRGB(255, 222, 88)
		light.Brightness = 1.8
		light.Range = 8
		light.Parent = coin
	end

	if not coin:FindFirstChild("CoinHighlight") then
		local highlight = Instance.new("Highlight")
		highlight.Name = "CoinHighlight"
		highlight.Adornee = coin
		highlight.FillColor = Color3.fromRGB(255, 217, 82)
		highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 0.35
		highlight.OutlineTransparency = 0.05
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = coin
	end
end

function CoinSystem.CalculateFinalCoinGain(player, baseAmount)
	local coinUpgrades = PlayerDataSystem.GetCoinUpgradesFolder(player)
	local woodUpgrades = PlayerDataSystem.GetWoodUpgradesFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local coinsObject = PlayerDataSystem.GetCoinsObject(player)
	local passiveCoin, _, passiveGlobalMultiplier = dependencies.GetPassiveMultipliers(player)
	local runeCoinMultiplier = select(1, dependencies.GetRuneBonusMultipliers(player))

	local baseCoinGain = math.max(0, tonumber(baseAmount) or 1)
	local coinValueLevel = coinUpgrades and coinUpgrades:FindFirstChild("CoinValueLevel") and coinUpgrades.CoinValueLevel.Value or 0
	local multiplierLevel = coinUpgrades and coinUpgrades:FindFirstChild("MultiplierLevel") and coinUpgrades.MultiplierLevel.Value or 0
	local upgradedCoinGain = (baseCoinGain + coinValueLevel) * (1 + (multiplierLevel * 0.1))
	local rebirthCoinMul = rebirth and dependencies.SyncRebirthCoinMultiplierBonus(player) or 1
	local afterRebirthGain = upgradedCoinGain * rebirthCoinMul
	local coinGoalBoostMultiplier = (rebirth and rebirth.FourthSystemsUnlocked.Value) and dependencies.ComputeGoalWoodFactorFromCoins(coinsObject and coinsObject.Value or 0) or 1
	local woodCoinBoostLevel = woodUpgrades and woodUpgrades:FindFirstChild("CoinBoostLevel") and woodUpgrades.CoinBoostLevel.Value or 0
	local woodCoinBoostMultiplier = 1.1 ^ woodCoinBoostLevel
	local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
	local xpMul = 1 + ((xpUpgrades and xpUpgrades:FindFirstChild("CoinXPLevel") and xpUpgrades.CoinXPLevel.Value or 0) * 0.2)
	local eventCoinMul = dependencies.GetServerEventMultipliers(player)
	local gamepassCoinMul = dependencies.GetGamepassMultiplier(player, "DoubleCoins", 2)
	local finalCoinGain = afterRebirthGain * coinGoalBoostMultiplier * woodCoinBoostMultiplier * passiveCoin * passiveGlobalMultiplier * runeCoinMultiplier * xpMul * eventCoinMul * gamepassCoinMul
	local floorGain = baseCoinGain * rebirthCoinMul
	return roundToTenth(math.max(finalCoinGain, floorGain))
end

function CoinSystem.GetCoinRespawnDelay(player)
	local coinUpgrades = PlayerDataSystem.GetCoinUpgradesFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)

	if not coinUpgrades or not rebirth then
		return BASE_COIN_RESPAWN
	end

	local value = BASE_COIN_RESPAWN
	value -= coinUpgrades.SpawnSpeedLevel.Value * 0.5
	value -= rebirth.SpawnSpeedBonus.Value
	local _, _, _, passiveSpeedMultiplier = dependencies.GetPassiveMultipliers(player)
	value /= math.max(1, passiveSpeedMultiplier)

	if value < MIN_COIN_RESPAWN then
		value = MIN_COIN_RESPAWN
	end

	return roundToTenth(value)
end

function CoinSystem.SpawnCoin()
	if activeCoinCount >= MAX_COINS then
		return
	end

	local coin = coinTemplate:Clone()
	coin.Name = "Coin"
	coin.CFrame = getRandomCoinCFrame()
	coin.Anchored = true
	coin.CanCollide = false
	coin.CanTouch = true
	coin.Parent = spawnedCoinsFolder

	applyCoinVisuals(coin)

	activeCoinCount += 1
	animatedCoins[coin] = {
		baseCFrame = coin.CFrame,
		seed = math.random() * 1000,
		spinSpeed = math.rad(math.random(100, 150)),
	}

	local taken = false
	local touchConnection

	touchConnection = coin.Touched:Connect(function(hit)
		if taken then
			return
		end

		local character = hit.Parent
		if not character then
			return
		end

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if not humanoid then
			return
		end

		local player = Players:GetPlayerFromCharacter(character)
		if not player then
			return
		end

		taken = true
		coin.CanTouch = false

		local coinsObject = PlayerDataSystem.GetCoinsObject(player)
		if not coinsObject then
			return
		end

		local coinsBefore = coinsObject.Value
		local reward = CoinSystem.CalculateFinalCoinGain(player, 1)
		local rebirth = PlayerDataSystem.GetRebirthFolder(player)
		local floorReward = rebirth and dependencies.SyncRebirthCoinMultiplierBonus(player) or 1
		if reward < floorReward then
			reward = floorReward
		end

		PlayerDataSystem.AddCurrency(coinsObject, reward)
		local coinsAdded = roundToTenth(coinsObject.Value - coinsBefore)
		if math.abs(coinsAdded - reward) > 0.001 then
			warn(string.format("[CoinGainMismatch] %s reward=%s added=%s before=%s after=%s", player.Name, tostring(reward), tostring(coinsAdded), tostring(coinsBefore), tostring(coinsObject.Value)))
		end

		if rebirth and rebirth.SecondAreaUnlocked.Value then
			local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
			local xpPerCoin = 1 + (xpUpgrades and xpUpgrades:FindFirstChild("XPMultiplierLevel") and xpUpgrades.XPMultiplierLevel.Value or 0)
			local _, _, _, passiveXpMul = dependencies.GetPassiveSpecialBoosts(player)
			local _, _, _, runeXpMul = dependencies.GetRuneBonusMultipliers(player)
			local _, _, _, _, eventXPMul = dependencies.GetServerEventMultipliers(player)
			local xpReward = roundToTenth(xpPerCoin * dependencies.GetXPBoostMultiplier(player) * passiveXpMul * runeXpMul * eventXPMul)
			PlayerDataSystem.AddCurrency(PlayerDataSystem.GetXPCurrencyObject(player), xpReward)
			firePickup(player, "XP", xpReward)
		end

		PlayerDataSystem.MarkDirty(player)

		if touchConnection then
			touchConnection:Disconnect()
		end

		animatedCoins[coin] = nil
		activeCoinCount -= 1
		coin:Destroy()

		firePickup(player, "Coin", coinsAdded)

		local respawnDelay = CoinSystem.GetCoinRespawnDelay(player)
		task.delay(respawnDelay, function()
			if zonePart.Parent and coinTemplate.Parent then
				CoinSystem.SpawnCoin()
			end
		end)
	end)
end

local function startCoinAnimationLoop()
	RunService.Heartbeat:Connect(function()
		local now = os.clock()

		for coin, info in pairs(animatedCoins) do
			if coin and coin.Parent then
				local bobOffset = math.sin(now * 2 + info.seed) * 0.35
				local rotationY = now * info.spinSpeed + info.seed

				coin.CFrame = info.baseCFrame
					* CFrame.new(0, bobOffset, 0)
					* CFrame.Angles(0, rotationY, 0)
			else
				animatedCoins[coin] = nil
			end
		end
	end)
end

function CoinSystem.Init(customDependencies)
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

	RemoteRegistry.Init()
	zonePart = Workspace:WaitForChild("ZonePart")
	coinTemplate = ServerStorage:WaitForChild("CoinPart")
	spawnedCoinsFolder = ensureSpawnedCoinsFolder()

	startCoinAnimationLoop()

	for _ = 1, MAX_COINS do
		CoinSystem.SpawnCoin()
	end
end

return CoinSystem
