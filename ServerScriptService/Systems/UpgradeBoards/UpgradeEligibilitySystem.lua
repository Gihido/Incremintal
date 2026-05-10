local UpgradeEligibilitySystem = {}

function UpgradeEligibilitySystem.CheckByRequiredRebirth(config, currentRebirthCount)
	if config.requiredRebirth and currentRebirthCount < config.requiredRebirth then
		return false
	end
	return true
end

function UpgradeEligibilitySystem.CheckMinimumRebirth(currentRebirthCount, minimum)
	return currentRebirthCount >= minimum
end

return UpgradeEligibilitySystem
