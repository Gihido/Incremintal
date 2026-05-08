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

function RuneService.getRuneSpeedOverflowBulk(speedStat)
	local interval = 1 / math.max(1, (1 + (math.max(0, speedStat) * 0.5)))
	if interval >= 0.01 then
		return 0
	end
	local overflowFactor = math.min(250, 0.01 / math.max(0.000001, interval))
	return math.max(0, math.floor((overflowFactor - 1) * 2 + 0.5))
end

function RuneService.getEffectiveRuneStats(player, deps)
	local runeUpgrades = deps.getRuneUpgradeFolder(player)
	local xpUpgrades = deps.getXPUpgradesFolder(player)
	if not runeUpgrades then
		return 1, 1, 1
	end

	local luck = 1 + runeUpgrades.RuneLuckLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneLuckXPLevel") and xpUpgrades.RuneLuckXPLevel.Value or 0))
	local speed = 1 + runeUpgrades.RuneSpeedLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneSpeedXPLevel") and xpUpgrades.RuneSpeedXPLevel.Value or 0))
	local bulk = 1 + runeUpgrades.RuneBulkLevel.Value + math.max(0, tonumber(xpUpgrades and xpUpgrades:FindFirstChild("RuneBulkXPLevel") and xpUpgrades.RuneBulkXPLevel.Value or 0))

	local _, _, _, _, runeLuckMul, runeSpeedMul, runeBulkAdd = deps.getRuneBonusMultipliers(player)
	runeLuckMul = deps.safeNumber(runeLuckMul, 1)
	runeSpeedMul = deps.safeNumber(runeSpeedMul, 1)
	runeBulkAdd = deps.safeNumber(runeBulkAdd, 0)
	luck = luck * runeLuckMul
	speed = speed * runeSpeedMul
	bulk = bulk + runeBulkAdd

	local passiveLuckMul, passiveSpeedMul, passiveBulkMul = deps.getPassiveSpecialBoosts(player)
	passiveLuckMul = deps.safeNumber(passiveLuckMul, 1)
	passiveSpeedMul = deps.safeNumber(passiveSpeedMul, 1)
	passiveBulkMul = deps.safeNumber(passiveBulkMul, 1)
	luck = math.floor(luck * passiveLuckMul + 0.5)
	speed = math.floor(speed * passiveSpeedMul + 0.5)
	bulk = math.floor(bulk * passiveBulkMul + 0.5)

	local eventLuckMul, eventSpeedMul, eventBulkMul, eventBulkAdd = deps.getServerRuneEventBoosts()
	eventLuckMul = deps.safeNumber(eventLuckMul, 1)
	eventSpeedMul = deps.safeNumber(eventSpeedMul, 1)
	eventBulkMul = deps.safeNumber(eventBulkMul, 1)
	eventBulkAdd = deps.safeNumber(eventBulkAdd, 0)
	luck = math.floor(luck * eventLuckMul + 0.5)
	speed = math.floor(speed * eventSpeedMul + 0.5)
	bulk = math.floor(bulk * eventBulkMul + 0.5)
	bulk += eventBulkAdd

	local rebirth = deps.getRebirthFolder(player)
	if rebirth and rebirth.Count.Value >= 7 then
		luck = math.floor(luck * 1.5 + 0.5)
	end
	luck = math.floor(luck * deps.getGamepassMultiplier(player, "TripleRuneLuck", 3) + 0.5)
	bulk += RuneService.getRuneSpeedOverflowBulk(speed)
	return luck, speed, bulk
end

function RuneService.getRuneRollInterval(player, deps)
	local _, speed = RuneService.getEffectiveRuneStats(player, deps)
	local baseInterval = 1.2
	local interval = baseInterval / math.max(1, speed)
	return math.max(0.2, interval)
end



RuneService.runtime = {
	activeSessions = {},
	timers = {},
	caches = {},
	runtimeData = {},
}

function RuneService.configureRuntime(config)
	RuneService.runtime.config = config or {}
end

function RuneService.StartRolling(player, setName)
	local sessions = RuneService.runtime.activeSessions
	local session = sessions[player] or {}
	if session.active and session.setName == setName then return session end
	session.active = true
	session.setName = setName
	session.lastRollAt = 0
	session.sessionCounts = session.sessionCounts or {}
	sessions[player] = session
	local notifyEvent = RuneService.runtime.config and RuneService.runtime.config.notifyEvent
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "rune_roll_state", active = true, system = setName})
	end
	return session
end

function RuneService.StopRolling(player, setName)
	local session = RuneService.runtime.activeSessions[player]
	if not session or not session.active or (setName and session.setName ~= setName) then return end
	session.active = false
	local notifyEvent = RuneService.runtime.config and RuneService.runtime.config.notifyEvent
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "rune_roll_state", active = false, system = session.setName, session = session.sessionCounts})
	end
end

function RuneService.UpdateSession(player, now, setName, deps)
	local cfg = deps.RUNE_SET_DEFS[setName]
	if not cfg or not cfg.block then
		RuneService.StopRolling(player, setName)
		return false
	end
	local rebirth = deps.getRebirthFolder(player)
	local rebirthCount = tonumber(rebirth and rebirth.Count.Value) or 0
	if rebirthCount < cfg.unlockRebirth then
		RuneService.StopRolling(player, setName)
		return false
	end
	if not RuneService.isCharacterOnBlock(player, cfg.block, Vector3.new(0.8, 3.2, 0.8)) then
		RuneService.StopRolling(player, setName)
		return false
	end

	local session = RuneService.StartRolling(player, setName)
	local interval = RuneService.getRuneRollInterval(player, deps)
	if now - (session.lastRollAt or 0) < interval then return true end
	session.lastRollAt = now
	RuneService.RollRune(player, setName, session, now, deps)
	return true
end

function RuneService.RollRune(player, setName, session, now, deps)
	local cfg = deps.RUNE_SET_DEFS[setName]
	local currencyObject = cfg.currency == "Paper" and deps.getPaperCurrencyObject(player) or deps.getCoinsObject(player)
	if not currencyObject or deps.safeNumber(currencyObject.Value, 0) < cfg.cost then
		local key = player.UserId .. "rune_no_" .. setName
		local cd = RuneService.runtime.timers[key] or 0
		if now >= cd then
			deps.fireSimple(player, cfg.insufficientText)
			RuneService.runtime.timers[key] = now + 2
		end
		return
	end
	if not deps.spendCurrency(currencyObject, cfg.cost) then return end
	local rolled, state, denoms = RuneService.rollFromSet(player, setName, deps)
	if not rolled then return end
	for _, runeId in ipairs(rolled) do
		session.sessionCounts[runeId] = (session.sessionCounts[runeId] or 0) + 1
	end
	deps.notifyEvent:FireClient(player, {kind = "rune_roll_tick", system = setName, rolled = rolled, session = session.sessionCounts, state = state, effectiveDenominators = denoms})
end

function RuneService.StartPlayerRuneSession(player)
	RuneService.runtime.activeSessions[player] = RuneService.runtime.activeSessions[player] or {active=false, sessionCounts={}}
end

function RuneService.StopPlayerRuneSession(player)
	RuneService.runtime.activeSessions[player] = nil
end

function RuneService.CalculateStats(player, deps)
	return RuneService.getEffectiveRuneStats(player, deps)
end

return RuneService
