local Players = game:GetService("Players")

local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local PaperRuntimeSystem = require(script.Parent:WaitForChild("RuntimeLoops"):WaitForChild("PaperRuntimeSystem"))

local PaperFactorySystem = {}

local BASE_PAPER_PRODUCTION_TIME = 10
local MIN_PAPER_PRODUCTION_TIME = 5
local PAPER_SPEED_STEP = 0.5
local WOOD_PER_FUEL = 250

local paperProcessAnchors = {}
local initialized = false

local dependencies = {
	GetRuneBonusMultipliers = function()
		return 1, 1, 1, 1
	end,
	GetServerEventMultipliers = function()
		return 1, 1, 1, 1, 1
	end,
	GetGamepassMultiplier = function()
		return 1
	end,
}

local function roundToTenth(value)
	return PlayerDataSystem.RoundToTenth(value)
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

function PaperFactorySystem.GetPaperProductionAmount(player)
	local paperUpgrades = PlayerDataSystem.GetPaperUpgradesFolder(player)
	if not paperUpgrades then
		return 1
	end

	local baseValue = 1 + paperUpgrades.PaperValueLevel.Value
	local multiplier = 1 + (paperUpgrades.PaperMultiplierLevel.Value * 0.1)
	local _, _, runePaperMultiplier = dependencies.GetRuneBonusMultipliers(player)

	local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
	local xpMul = 1 + ((xpUpgrades and xpUpgrades:FindFirstChild("PaperXPLevel") and xpUpgrades.PaperXPLevel.Value or 0) * 0.2)
	local _, _, eventPaperMul = dependencies.GetServerEventMultipliers(player)
	local gamepassPaperMul = dependencies.GetGamepassMultiplier(player, "DoublePaper", 2)
	return roundToTenth(baseValue * multiplier * runePaperMultiplier * xpMul * eventPaperMul * gamepassPaperMul)
end

function PaperFactorySystem.GetPaperCycleTime(player)
	local paperUpgrades = PlayerDataSystem.GetPaperUpgradesFolder(player)
	if not paperUpgrades then
		return BASE_PAPER_PRODUCTION_TIME
	end

	local value = BASE_PAPER_PRODUCTION_TIME - (paperUpgrades.PaperSpeedLevel.Value * PAPER_SPEED_STEP)
	if value < MIN_PAPER_PRODUCTION_TIME then
		value = MIN_PAPER_PRODUCTION_TIME
	end

	return roundToTenth(value)
end

function PaperFactorySystem.HandleFactoryAction(player, actionName)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local woodCurrency = PlayerDataSystem.GetWoodCurrencyObject(player)
	local paperFactory = PlayerDataSystem.GetPaperFactoryFolder(player)

	if not rebirth or not woodCurrency or not paperFactory then
		return
	end

	if not rebirth.FourthSystemsUnlocked.Value then
		fireSimple(player, "Откроется на 4-м перерождении")
		return
	end

	if actionName == "AddFuelOnce" then
		if woodCurrency.Value < WOOD_PER_FUEL then
			fireSimple(player, "Не хватает дерева")
			return
		end

		if PlayerDataSystem.SpendCurrency(woodCurrency, WOOD_PER_FUEL) then
			paperFactory.Fuel.Value += 1
			paperProcessAnchors[player] = os.clock()
			PlayerDataSystem.MarkDirty(player)
			fireSimple(player, "Топливо добавлено")
		end
	elseif actionName == "AddFuelMax" then
		local fuelToAdd = math.floor(woodCurrency.Value / WOOD_PER_FUEL)
		if fuelToAdd <= 0 then
			fireSimple(player, "Не хватает дерева")
			return
		end

		local totalCost = fuelToAdd * WOOD_PER_FUEL
		if PlayerDataSystem.SpendCurrency(woodCurrency, totalCost) then
			paperFactory.Fuel.Value += fuelToAdd
			paperProcessAnchors[player] = os.clock()
			PlayerDataSystem.MarkDirty(player)
			fireSimple(player, "Добавлено топлива: " .. fuelToAdd)
		end
	end
end

function PaperFactorySystem.UpdatePlayerFactory(player, now)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local paperFactory = PlayerDataSystem.GetPaperFactoryFolder(player)

	if not rebirth or not paperFactory then
		return
	end

	if not rebirth.FourthSystemsUnlocked.Value then
		paperFactory.IsRunning.Value = false
		paperFactory.Countdown.Value = BASE_PAPER_PRODUCTION_TIME
		paperProcessAnchors[player] = now
		return
	end

	local cycleTime = PaperFactorySystem.GetPaperCycleTime(player)

	if paperFactory.Fuel.Value > 0 then
		local lastTick = paperProcessAnchors[player] or now
		local elapsed = now - lastTick

		while elapsed >= cycleTime and paperFactory.Fuel.Value > 0 do
			paperFactory.Fuel.Value -= 1
			paperFactory.Paper.Value = roundToTenth(paperFactory.Paper.Value + PaperFactorySystem.GetPaperProductionAmount(player))
			lastTick += cycleTime
			elapsed = now - lastTick
			PlayerDataSystem.MarkDirty(player)
		end

		paperProcessAnchors[player] = lastTick
		paperFactory.IsRunning.Value = paperFactory.Fuel.Value > 0

		if paperFactory.Fuel.Value > 0 then
			paperFactory.Countdown.Value = roundToTenth(math.max(0, cycleTime - (now - lastTick)))
		else
			paperFactory.Countdown.Value = cycleTime
		end
	else
		paperFactory.IsRunning.Value = false
		paperFactory.Countdown.Value = cycleTime
		paperProcessAnchors[player] = now
	end
end

function PaperFactorySystem.Init(customDependencies)
	if initialized then
		return
	end
	initialized = true

	if type(customDependencies) == "table" then
		for key, callback in pairs(customDependencies) do
			if dependencies[key] ~= nil and type(callback) == "function" then
				dependencies[key] = callback
			end
		end
	end

	local factoryActionEvent = RemoteRegistry.GetRemote("FactoryAction")
	factoryActionEvent.OnServerEvent:Connect(function(player, actionName)
		PaperFactorySystem.HandleFactoryAction(player, actionName)
	end)

	PaperRuntimeSystem.Start(PaperFactorySystem.UpdatePlayerFactory)
end

return PaperFactorySystem
