local NatureRune = require(script.Parent:WaitForChild("NatureRune"))

local HayRune = {}

function HayRune.BuildDef(natureRuneBlock, fallbackRuneBlock)
	return NatureRune.BuildDef(natureRuneBlock, fallbackRuneBlock)
end

return HayRune
