local Workspace = game:GetService("Workspace")

local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local RuneInventorySystem = require(script.Parent:WaitForChild("RuneInventorySystem"))
local RuneStatsSystem = require(script.Parent:WaitForChild("RuneStatsSystem"))
local RuneSessionSystem = require(script.Parent:WaitForChild("RuneSessionSystem"))
local RuneLuckSystem = require(script.Parent:WaitForChild("RuneLuckSystem"))
local RuneSpeedSystem = require(script.Parent:WaitForChild("RuneSpeedSystem"))
local RuneBulkSystem = require(script.Parent:WaitForChild("RuneBulkSystem"))
local RuneIndexSystem = require(script.Parent:WaitForChild("RuneIndexSystem"))
local Runes = script.Parent.Parent:WaitForChild("Runes")
local NatureRune = require(Runes:WaitForChild("NatureRune"))
local ForestRune = require(Runes:WaitForChild("ForestRune"))
local PaperRune = require(Runes:WaitForChild("PaperRune"))
local HayRune = require(Runes:WaitForChild("HayRune"))
local RuneRuntimeSystem = require(script.Parent.Parent:WaitForChild("RuntimeLoops"):WaitForChild("RuneRuntimeSystem"))
local RuneActionSystem = require(script.Parent:WaitForChild("RuneActionSystem"))

local RuneRollSystem = {}

local RUNE_OPEN_BASE_TIME = 10

local FOREST_RUNE_ORDER = ForestRune.Order
local NATURE_RUNE_ORDER = NatureRune.Order

local runeOpenCooldowns = {}
local activeForestRuneRolls = {}
local activeNatureRuneRolls = {}
local RUNE_SET_DEFS = {}
local initialized = false

local function safeNumber(value, defaultValue)
	local n = tonumber(value)
	if n == nil then
		return defaultValue
	end
	return n
end

local function fireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, {
		kind = "simple",
		text = tostring(text),
	})
end

local function fireRuneRollTick(player, payload)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, payload)
end

function RuneRollSystem.GetRuneOpenDuration(player)
	local upgrades = RuneInventorySystem.GetRuneUpgradeFolder(player)
	if not upgrades then
		return RUNE_OPEN_BASE_TIME
	end
	local speedLevel = upgrades.RuneSpeedLevel.Value
	local t = RUNE_OPEN_BASE_TIME - (speedLevel * 2.5)
	return math.max(5, t)
end

function RuneRollSystem.GetEffectiveRuneChanceDenominator(baseDenominator, runeLuck)
	local base = math.max(1, math.floor(tonumber(baseDenominator) or 1))
	local luck = math.max(1, tonumber(runeLuck) or 1)
	local effective = math.floor(base / luck + 0.5)
	return math.max(1, effective)
end

local function isCharacterOnBlock(player, block, tolerance)
	if not block then
		return false
	end
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end
	local hrp = character and character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return false
	end
	local tol = tolerance or Vector3.new(1.2, 3.5, 1.2)
	local localPos = block.CFrame:PointToObjectSpace(hrp.Position)
	local half = block.Size * 0.5
	return math.abs(localPos.X) <= (half.X + tol.X)
		and math.abs(localPos.Z) <= (half.Z + tol.Z)
		and math.abs(localPos.Y) <= (half.Y + tol.Y)
end

function RuneRollSystem.RollFromSet(player, setName)
	local setDef = RUNE_SET_DEFS[setName]
	if not setDef then
		return nil
	end

	local state = RuneInventorySystem.GetRuneState(player)
	state.natureCounts = state.natureCounts or {}
	state.forestCounts = state.forestCounts or {}
	local targetCounts = setName == "Forest" and state.forestCounts or state.natureCounts
	local luck, _, bulkLevel = RuneStatsSystem.GetEffectiveRuneStats(player)
	local bulk = math.max(1, 1 + math.floor(tonumber(bulkLevel) or 0))
	local rolled = {}
	local denominators = {}

	for _, runeId in ipairs(setDef.order) do
		denominators[runeId] = RuneRollSystem.GetEffectiveRuneChanceDenominator(setDef.baseDenominators[runeId], luck)
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
	RuneInventorySystem.WriteRuneStateValue(player)
	PlayerDataSystem.MarkDirty(player)
	return rolled, state, denominators
end

function RuneRollSystem.GetRuneRollInterval(player)
	local _, speed = RuneStatsSystem.GetEffectiveRuneStats(player)
	local baseInterval = 1.2
	local interval = baseInterval / math.max(1, speed)
	return math.max(0.2, interval)
end

local function getCurrencyObjectForRuneSet(player, cfg)
	if cfg.currency == "Paper" then
		return PlayerDataSystem.GetPaperCurrencyObject(player)
	end
	return PlayerDataSystem.GetCoinsObject(player)
end

local function processRuneSet(player, setName, activeTable, now)
	local cfg = RUNE_SET_DEFS[setName]
	if not cfg or not cfg.block then
		activeTable[player] = nil
		RuneSessionSystem.StopRuneRolling(player, setName)
		return
	end

	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local rebirthCount = tonumber(rebirth and rebirth.Count.Value) or 0
	if rebirthCount < cfg.unlockRebirth then
		activeTable[player] = nil
		RuneSessionSystem.StopRuneRolling(player, setName)
		return
	end

	if not isCharacterOnBlock(player, cfg.block, Vector3.new(0.8, 3.2, 0.8)) then
		activeTable[player] = nil
		RuneSessionSystem.StopRuneRolling(player, setName)
		return
	end

	activeTable[player] = true
	RuneSessionSystem.StartRuneRolling(player, setName)
	local session = RuneSessionSystem.GetSession(player)
	local interval = RuneRollSystem.GetRuneRollInterval(player)
	if not session or (now - (session.lastRollAt or 0)) < interval then
		return
	end

	RuneSessionSystem.SetLastRollAt(player, now)
	local currencyObject = getCurrencyObjectForRuneSet(player, cfg)
	if not currencyObject or safeNumber(currencyObject.Value, 0) < cfg.cost then
		local key = "rune_no_" .. setName
		local cd = runeOpenCooldowns[player.UserId .. key] or 0
		if now >= cd then
			fireSimple(player, cfg.insufficientText)
			runeOpenCooldowns[player.UserId .. key] = now + 2
		end
		return
	end

	if not PlayerDataSystem.SpendCurrency(currencyObject, cfg.cost) then
		return
	end

	local rolled, state, denoms = RuneRollSystem.RollFromSet(player, setName)
	if rolled then
		local sessionCounts = RuneSessionSystem.RecordRolledRunes(player, rolled)
		fireRuneRollTick(player, {
			kind = "rune_roll_tick",
			system = setName,
			rolled = rolled,
			session = sessionCounts,
			state = state,
			effectiveDenominators = denoms,
		})
	end
end

function RuneRollSystem.UpdatePlayerRuneRolling(player, now)
	processRuneSet(player, "Forest", activeForestRuneRolls, now)
	processRuneSet(player, "Nature", activeNatureRuneRolls, now)
end

function RuneRollSystem.HandleRuneAction(player, actionName)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local runeUpgrades = RuneInventorySystem.GetRuneUpgradeFolder(player)
	local wood = PlayerDataSystem.GetWoodCurrencyObject(player)
	if not rebirth or not runeUpgrades or not wood then return end

	RuneActionSystem.Handle(player, actionName, {
		fireSimple = fireSimple,
		canUseRunes = function(currentPlayer)
			local currentRebirth = PlayerDataSystem.GetRebirthFolder(currentPlayer)
			return currentRebirth and currentRebirth.SecondAreaUnlocked.Value
		end,
		buyLuck = function(currentPlayer) RuneLuckSystem.TryBuy(currentPlayer, false) end,
		buyLuckMax = RuneLuckSystem.TryBuyMax,
		buySpeed = function(currentPlayer) RuneSpeedSystem.TryBuy(currentPlayer, false) end,
		buySpeedMax = RuneSpeedSystem.TryBuyMax,
		buyBulk = function(currentPlayer) RuneBulkSystem.TryBuy(currentPlayer, false) end,
		buyBulkMax = RuneBulkSystem.TryBuyMax,
		pushIndex = function(currentPlayer) RuneIndexSystem.PushIndexState(currentPlayer, NATURE_RUNE_ORDER, FOREST_RUNE_ORDER) end,
	})
end


local function buildRuneSetDefs()
	for key in pairs(RUNE_SET_DEFS) do
		RUNE_SET_DEFS[key] = nil
	end

	local runeRollBlock = Workspace:FindFirstChild("RuneRollBlock")
	local forestRuneBlock = Workspace:FindFirstChild("ForestRuneBlock")
	local natureRuneBlock = Workspace:FindFirstChild("NatureRuneBlock")

	RUNE_SET_DEFS.Forest = PaperRune.BuildDef()
	RUNE_SET_DEFS.Forest.block = ForestRune.ResolveBlock(forestRuneBlock)

	RUNE_SET_DEFS.Nature = HayRune.BuildDef(natureRuneBlock, runeRollBlock)
	RUNE_SET_DEFS.Nature.block = NatureRune.ResolveBlock(natureRuneBlock, runeRollBlock)
end

function RuneRollSystem.Init()
	if initialized then
		return
	end
	initialized = true

	buildRuneSetDefs()

	local runeActionEvent = RemoteRegistry.GetRemote("RuneAction")
	runeActionEvent.OnServerEvent:Connect(function(player, actionName)
		if type(actionName) ~= "string" then
			return
		end
		RuneRollSystem.HandleRuneAction(player, actionName)
	end)

	RuneRuntimeSystem.Start(RuneRollSystem.UpdatePlayerRuneRolling)
end

function RuneRollSystem.GetRuneSetDefs()
	return RUNE_SET_DEFS
end

RuneRollSystem.RuneSetDefs = RUNE_SET_DEFS
RuneRollSystem.ForestRuneOrder = FOREST_RUNE_ORDER
RuneRollSystem.NatureRuneOrder = NATURE_RUNE_ORDER

return RuneRollSystem
