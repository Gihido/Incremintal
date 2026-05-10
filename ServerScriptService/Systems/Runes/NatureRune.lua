local BaseRuneSet = require(script.Parent:WaitForChild("BaseRuneSet"))

local NatureRune = {}

NatureRune.Order = {"Grass", "DarkGrass", "Dandelion", "Flower", "Violet", "Rose"}

function NatureRune.BuildDef(natureRuneBlock, fallbackRuneBlock)
	return BaseRuneSet.CloneSet({
		name = "Nature",
		order = NatureRune.Order,
		unlockRebirth = 2,
		currency = "Coins",
		cost = 500,
		insufficientText = "Недостаточно Coins",
		baseDenominators = {
			Grass = 1,
			DarkGrass = 5,
			Dandelion = 25,
			Flower = 100,
			Violet = 250,
			Rose = 1000,
		},
	})
end

function NatureRune.ResolveBlock(natureRuneBlock, fallbackRuneBlock)
	return natureRuneBlock or fallbackRuneBlock
end

return NatureRune
