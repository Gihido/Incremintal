local RuneService = {}

RuneService.FOREST_RUNE_ORDER = {"Palka", "ObrublennyKonec", "VetvDereva", "Brevno", "Poleno", "ObgorevshiyPen"}
RuneService.NATURE_RUNE_ORDER = {"Grass", "DarkGrass", "Dandelion", "Flower", "Violet", "Rose"}

function RuneService.createSetDefs(blocks)
	return {
		Forest = {
			order = RuneService.FOREST_RUNE_ORDER,
			unlockRebirth = 6,
			currency = "Paper",
			cost = 50,
			block = blocks.forestRuneBlock,
			insufficientText = "Недостаточно Paper",
			baseDenominators = {Palka = 1, ObrublennyKonec = 5, VetvDereva = 25, Brevno = 100, Poleno = 250, ObgorevshiyPen = 1000},
		},
		Nature = {
			order = RuneService.NATURE_RUNE_ORDER,
			unlockRebirth = 2,
			currency = "Coins",
			cost = 500,
			block = blocks.natureRuneBlock or blocks.runeRollBlock,
			insufficientText = "Недостаточно Coins",
			baseDenominators = {Grass = 1, DarkGrass = 5, Dandelion = 25, Flower = 100, Violet = 250, Rose = 1000},
		},
	}
end

function RuneService.getEffectiveRuneChanceDenominator(baseDenominator, runeLuck)
	local base = math.max(1, math.floor(tonumber(baseDenominator) or 1))
	local luck = math.max(1, tonumber(runeLuck) or 1)
	local effective = math.floor(base / luck + 0.5)
	return math.max(1, effective)
end

function RuneService.isCharacterOnBlock(player, block, tolerance)
	if not block then return false end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return false end
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then return false end
	local tol = tolerance or Vector3.new(1.2, 3.5, 1.2)
	local localPos = block.CFrame:PointToObjectSpace(hrp.Position)
	local half = block.Size * 0.5
	return math.abs(localPos.X) <= (half.X + tol.X)
		and math.abs(localPos.Z) <= (half.Z + tol.Z)
		and math.abs(localPos.Y) <= (half.Y + tol.Y)
end

function RuneService.rollFromSet(player, setName, deps)
	local setDef = deps.RUNE_SET_DEFS[setName]
	if not setDef then return nil end

	local state = deps.getRuneState(player)
	state.natureCounts = state.natureCounts or {}
	state.forestCounts = state.forestCounts or {}
	local targetCounts = setName == "Forest" and state.forestCounts or state.natureCounts

	local luck, _, bulkLevel = deps.getEffectiveRuneStats(player)
	local bulk = math.max(1, 1 + math.floor(tonumber(bulkLevel) or 0))
	local rolled = {}
	local denominators = {}

	for _, runeId in ipairs(setDef.order) do
		denominators[runeId] = RuneService.getEffectiveRuneChanceDenominator(setDef.baseDenominators[runeId], luck)
	end

	for _ = 1, bulk do
		local chosen = setDef.order[1]
		for i = #setDef.order, 1, -1 do
			local runeId = setDef.order[i]
			if math.random(1, denominators[runeId]) == 1 then
				chosen = runeId
				break
			end
		end
		targetCounts[chosen] = (targetCounts[chosen] or 0) + 1
		table.insert(rolled, chosen)
	end

	state.counts = state.natureCounts
	deps.writeRuneStateValue(player)
	deps.markDirty(player)
	return rolled, state, denominators
end

return RuneService
