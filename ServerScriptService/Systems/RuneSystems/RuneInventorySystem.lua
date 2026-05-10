local HttpService = game:GetService("HttpService")

local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))

local RuneInventorySystem = {}

local runeStates = {}
local initialized = false

function RuneInventorySystem.EmptyRuneState()
	return {
		natureCounts = {Grass = 0, DarkGrass = 0, Dandelion = 0, Flower = 0, Violet = 0, Rose = 0},
		forestCounts = {Palka = 0, ObrublennyKonec = 0, VetvDereva = 0, Brevno = 0, Poleno = 0, ObgorevshiyPen = 0},
		counts = {Grass = 0, DarkGrass = 0, Dandelion = 0, Flower = 0, Violet = 0, Rose = 0},
	}
end

function RuneInventorySystem.GetRuneFolder(player)
	return PlayerDataSystem.GetRuneFolder(player)
end

function RuneInventorySystem.GetRuneUpgradeFolder(player)
	return PlayerDataSystem.GetRuneUpgradeFolder(player)
end

function RuneInventorySystem.GetRuneState(player)
	if not runeStates[player] then
		runeStates[player] = RuneInventorySystem.EmptyRuneState()
	end
	return runeStates[player]
end

function RuneInventorySystem.SetRuneState(player, state)
	runeStates[player] = type(state) == "table" and state or RuneInventorySystem.EmptyRuneState()
	RuneInventorySystem.WriteRuneStateValue(player)
end

function RuneInventorySystem.WriteRuneStateValue(player)
	local folder = RuneInventorySystem.GetRuneFolder(player)
	if not folder then
		return
	end

	local jsonValue = folder:FindFirstChild("StateJson")
	if jsonValue then
		jsonValue.Value = HttpService:JSONEncode(RuneInventorySystem.GetRuneState(player))
	end
end

function RuneInventorySystem.ResetRuneState(player)
	runeStates[player] = RuneInventorySystem.EmptyRuneState()
	RuneInventorySystem.WriteRuneStateValue(player)
end

function RuneInventorySystem.ClearPlayer(player)
	runeStates[player] = nil
end

function RuneInventorySystem.Init()
	if initialized then
		return
	end
	initialized = true
end

return RuneInventorySystem
