local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local UpgradeNotifySystem = require(script.Parent:WaitForChild("UpgradeNotifySystem"))
local UpgradeActiveFlagsSystem = require(script.Parent:WaitForChild("UpgradeActiveFlagsSystem"))
local UpgradeEligibilitySystem = require(script.Parent:WaitForChild("UpgradeEligibilitySystem"))
local UpgradeCostSystem = require(script.Parent:WaitForChild("UpgradeCostSystem"))
local UpgradePurchaseSystem = require(script.Parent:WaitForChild("UpgradePurchaseSystem"))

local HayUpgradeBoard = {}

local CONFIG = PlayerDataSystem.Config.HayUpgrades
local initialized = false

local function fireSimple(player, text)
	UpgradeNotifySystem.FireSimple(RemoteRegistry.GetRemote("Notify"), player, text)
end

local function tryBuy(player, upgradeKey, folder, currencyObject, currentRebirthCount)
	return UpgradePurchaseSystem.TryBuy({
		player = player,
		upgradeKey = upgradeKey,
		configTable = CONFIG,
		folder = folder,
		currencyObject = currencyObject,
		currentRebirthCount = currentRebirthCount,
		spendCurrency = PlayerDataSystem.SpendCurrency,
		markDirty = PlayerDataSystem.MarkDirty,
		applyNextCost = UpgradeCostSystem.ApplyNextCost,
		updateFlags = function(folder, configTable) return UpgradeActiveFlagsSystem.UpdateBySuffix(folder, configTable, "Active") end,
		isUnlocked = function(_, count) return UpgradeEligibilitySystem.CheckMinimumRebirth(count, 7) end,
	})
end

function HayUpgradeBoard.HandlePurchase(player, upgradeKey, mode)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not rebirth then return end
	if not ((tonumber(rebirth.Count.Value) or 0) >= 7) then
		fireSimple(player, "Hay откроется на 7-м перерождении")
		return
	end
	local folder = PlayerDataSystem.GetHayUpgradesFolder(player)
	local currencyObject = PlayerDataSystem.GetHayCurrencyObject(player)
	if not folder or not currencyObject then return end
	local notEnoughText = "Не хватает Hay"
	local lockedText = "Откроется на 7-м перерождении"
	if mode == "Max" then
		local bought = 0
		for _ = 1, 500 do
			local result = tryBuy(player, upgradeKey, folder, currencyObject, rebirth.Count.Value)
			if result == "BOUGHT" then bought += 1 else
				if bought > 0 then fireSimple(player, "Куплено уровней: " .. bought)
				elseif result == "AT_MAX" then fireSimple(player, "Улучшение уже в MAX")
				elseif result == "LOCKED" then fireSimple(player, lockedText)
				else fireSimple(player, notEnoughText) end
				break
			end
		end
	else
		local result = tryBuy(player, upgradeKey, folder, currencyObject, rebirth.Count.Value)
		if result == "BOUGHT" then fireSimple(player, "Улучшение куплено")
		elseif result == "AT_MAX" then fireSimple(player, "Улучшение уже в MAX")
		elseif result == "LOCKED" then fireSimple(player, lockedText)
		else fireSimple(player, notEnoughText) end
	end
end

function HayUpgradeBoard.Init()
	if initialized then return end
	initialized = true
	local purchaseUpgradeEvent = RemoteRegistry.GetRemote("PurchaseUpgrade")
	purchaseUpgradeEvent.OnServerEvent:Connect(function(player, upgradeFamily, upgradeKey, mode)
		if upgradeFamily ~= "Hay" then return end
		HayUpgradeBoard.HandlePurchase(player, upgradeKey, mode)
	end)
end

return HayUpgradeBoard
