local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local WoodUpgradeBoard = {}

local WOOD_UPGRADES = PlayerDataSystem.Config.WoodUpgrades
local initialized = false

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

local function tryBuyUpgrade(player, upgradeKey, configTable, folder, currencyObject, currentRebirthCount)
	local config = configTable[upgradeKey]
	if not config then
		return "INVALID"
	end

	if config.requiredRebirth and currentRebirthCount < config.requiredRebirth then
		return "LOCKED"
	end

	local levelObject = folder:FindFirstChild(config.levelName)
	local costObject = folder:FindFirstChild(config.costName)

	if not levelObject or not costObject then
		return "INVALID"
	end

	if levelObject.Value >= config.maxLevel then
		costObject.Value = 0
		updateUpgradeActiveFlags(folder, configTable)
		return "AT_MAX"
	end

	local cost = costObject.Value
	if cost <= 0 then
		return "AT_MAX"
	end

	if not PlayerDataSystem.SpendCurrency(currencyObject, cost) then
		return "NO_MONEY"
	end

	levelObject.Value += 1

	if levelObject.Value >= config.maxLevel then
		costObject.Value = 0
	elseif config.fixedCost then
		costObject.Value = config.startCost
	else
		costObject.Value = math.ceil(cost * config.priceMultiplier)
	end

	updateUpgradeActiveFlags(folder, configTable)
	PlayerDataSystem.MarkDirty(player)

	return "BOUGHT"
end

function WoodUpgradeBoard.HandlePurchase(player, upgradeKey, mode)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth then
		return
	end

	if not rebirth.SecondAreaUnlocked.Value then
		fireSimple(player, "Дерево откроется на 2-м перерождении")
		return
	end

	local folder = PlayerDataSystem.GetWoodUpgradesFolder(player)
	local currencyObject = PlayerDataSystem.GetWoodCurrencyObject(player)
	if not folder or not currencyObject then
		return
	end

	local notEnoughText = "Не хватает дерева"
	local lockedText = "Откроется на 3-м перерождении"

	if mode == "Max" then
		local bought = 0

		for _ = 1, 500 do
			local result = tryBuyUpgrade(player, upgradeKey, WOOD_UPGRADES, folder, currencyObject, rebirth.Count.Value)
			if result == "BOUGHT" then
				bought += 1
			else
				if bought > 0 then
					fireSimple(player, "Куплено уровней: " .. bought)
				elseif result == "AT_MAX" then
					fireSimple(player, "Улучшение уже в MAX")
				elseif result == "LOCKED" then
					fireSimple(player, lockedText)
				else
					fireSimple(player, notEnoughText)
				end
				break
			end
		end
	else
		local result = tryBuyUpgrade(player, upgradeKey, WOOD_UPGRADES, folder, currencyObject, rebirth.Count.Value)
		if result == "BOUGHT" then
			fireSimple(player, "Улучшение куплено")
		elseif result == "AT_MAX" then
			fireSimple(player, "Улучшение уже в MAX")
		elseif result == "LOCKED" then
			fireSimple(player, lockedText)
		else
			fireSimple(player, notEnoughText)
		end
	end
end

function WoodUpgradeBoard.Init()
	if initialized then
		return
	end
	initialized = true

	local purchaseUpgradeEvent = RemoteRegistry.GetRemote("PurchaseUpgrade")
	purchaseUpgradeEvent.OnServerEvent:Connect(function(player, upgradeFamily, upgradeKey, mode)
		if upgradeFamily ~= "Wood" then
			return
		end

		WoodUpgradeBoard.HandlePurchase(player, upgradeKey, mode)
	end)
end

return WoodUpgradeBoard
