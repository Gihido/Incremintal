local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))

local RuneCurrencySystem = {}

function RuneCurrencySystem.GetCurrencyObjectForSet(player, setConfig)
	if setConfig.currency == "Paper" then
		return PlayerDataSystem.GetPaperCurrencyObject(player)
	end
	return PlayerDataSystem.GetCoinsObject(player)
end

function RuneCurrencySystem.SpendOpenCost(player, setConfig)
	local currencyObject = RuneCurrencySystem.GetCurrencyObjectForSet(player, setConfig)
	if not currencyObject then return false end
	if (tonumber(currencyObject.Value) or 0) < setConfig.cost then return false end
	if not PlayerDataSystem.SpendCurrency(currencyObject, setConfig.cost) then return false end
	return true
end

return RuneCurrencySystem
