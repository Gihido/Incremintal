local RuneDenominatorSystem = {}

function RuneDenominatorSystem.GetEffectiveDenominator(baseDenominator, runeLuck)
	local base = math.max(1, math.floor(tonumber(baseDenominator) or 1))
	local luck = math.max(1, tonumber(runeLuck) or 1)
	local effective = math.floor(base / luck + 0.5)
	return math.max(1, effective)
end

function RuneDenominatorSystem.BuildDenominators(order, baseDenominators, luck)
	local result = {}
	for _, runeId in ipairs(order) do
		result[runeId] = RuneDenominatorSystem.GetEffectiveDenominator(baseDenominators[runeId], luck)
	end
	return result
end

return RuneDenominatorSystem
