local UpgradeCostSystem = {}

function UpgradeCostSystem.ApplyNextCost(levelObject, costObject, config)
	if levelObject.Value >= config.maxLevel then
		costObject.Value = 0
	elseif config.fixedCost then
		costObject.Value = config.startCost
	else
		costObject.Value = math.ceil(costObject.Value * config.priceMultiplier)
	end
end

return UpgradeCostSystem
