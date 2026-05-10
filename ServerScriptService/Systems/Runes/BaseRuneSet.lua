local BaseRuneSet = {}

function BaseRuneSet.CloneSet(def)
	return {
		name = def.name,
		order = table.clone(def.order),
		unlockRebirth = def.unlockRebirth,
		currency = def.currency,
		cost = def.cost,
		insufficientText = def.insufficientText,
		baseDenominators = table.clone(def.baseDenominators),
	}
end

return BaseRuneSet
