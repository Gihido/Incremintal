local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))

local RuneCurrencySystem = {}

local currencyResolvers = {
	Coins = PlayerDataSystem.GetCoinsObject,
	Wood = PlayerDataSystem.GetWoodCurrencyObject,
	Paper = PlayerDataSystem.GetPaperCurrencyObject,
	Hay = PlayerDataSystem.GetHayCurrencyObject,
}

local function resolveSetCost(setConfig)
	if type(setConfig) ~= "table" then
		return nil
	end

	local directCost = tonumber(setConfig.cost)
	if directCost then
		return directCost
	end

	if tonumber(setConfig.openCostCoins) then
		return tonumber(setConfig.openCostCoins)
	end
	if tonumber(setConfig.openCostWood) then
		return tonumber(setConfig.openCostWood)
	end
	if tonumber(setConfig.openCostPaper) then
		return tonumber(setConfig.openCostPaper)
	end
	if tonumber(setConfig.openCostHay) then
		return tonumber(setConfig.openCostHay)
	end

	return nil
end

function RuneCurrencySystem.GetCurrencyObjectForSet(player, setConfig)
	if type(setConfig) ~= "table" then
		return nil
	end

	local resolver = currencyResolvers[setConfig.currency] or currencyResolvers.Coins
	return resolver(player)
end

function RuneCurrencySystem.GetOpenCostForSet(setConfig)
	return resolveSetCost(setConfig)
end

function RuneCurrencySystem.SpendOpenCost(player, setConfig)
	local currencyObject = RuneCurrencySystem.GetCurrencyObjectForSet(player, setConfig)
	local openCost = resolveSetCost(setConfig)
	if not currencyObject or not openCost then
		return false
	end
	if (tonumber(currencyObject.Value) or 0) < openCost then
		return false
	end
	if not PlayerDataSystem.SpendCurrency(currencyObject, openCost) then
		return false
	end
	return true
end

return RuneCurrencySystem
