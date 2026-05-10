local BaseRuneSet = require(script.Parent:WaitForChild("BaseRuneSet"))

local ForestRune = {}

ForestRune.Order = {"Palka", "ObrublennyKonec", "VetvDereva", "Brevno", "Poleno", "ObgorevshiyPen"}

function ForestRune.BuildDef()
	return BaseRuneSet.CloneSet({
		name = "Forest",
		order = ForestRune.Order,
		unlockRebirth = 6,
		currency = "Paper",
		cost = 50,
		insufficientText = "Недостаточно Paper",
		baseDenominators = {
			Palka = 1,
			ObrublennyKonec = 5,
			VetvDereva = 25,
			Brevno = 100,
			Poleno = 250,
			ObgorevshiyPen = 1000,
		},
	})
end

function ForestRune.ResolveBlock(forestRuneBlock)
	return forestRuneBlock
end

return ForestRune
