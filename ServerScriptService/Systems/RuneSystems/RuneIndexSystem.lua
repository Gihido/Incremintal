local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local RuneInventorySystem = require(script.Parent:WaitForChild("RuneInventorySystem"))

local RuneIndexSystem = {}

local function buildCountsWithDiscovered(counts, ordered)
	local rows = {}
	for _, runeId in ipairs(ordered) do
		local count = math.max(0, tonumber(counts[runeId]) or 0)
		rows[#rows + 1] = {id = runeId, count = count, discovered = count > 0}
	end
	return rows
end

function RuneIndexSystem.BuildIndexPayload(player, natureOrder, forestOrder)
	local state = RuneInventorySystem.GetRuneState(player)
	state.natureCounts = state.natureCounts or {}
	state.forestCounts = state.forestCounts or {}
	return {
		kind = "rune_index_state",
		nature = buildCountsWithDiscovered(state.natureCounts, natureOrder),
		forest = buildCountsWithDiscovered(state.forestCounts, forestOrder),
	}
end

function RuneIndexSystem.PushIndexState(player, natureOrder, forestOrder)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if notifyEvent then
		notifyEvent:FireClient(player, RuneIndexSystem.BuildIndexPayload(player, natureOrder, forestOrder))
	end
end

return RuneIndexSystem
