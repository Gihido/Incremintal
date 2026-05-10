local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local RuneSessionSystem = {}

local runeRollingSessions = {}
local initialized = false

local function fireRuneRollState(player, payload)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, payload)
end

function RuneSessionSystem.GetSession(player)
	return runeRollingSessions[player]
end

function RuneSessionSystem.StartRuneRolling(player, setName)
	local session = runeRollingSessions[player] or {}
	if session.active and session.setName == setName then
		return session
	end

	session = {
		active = true,
		setName = setName,
		lastRollAt = 0,
		sessionCounts = {},
	}
	runeRollingSessions[player] = session

	fireRuneRollState(player, {
		kind = "rune_roll_state",
		active = true,
		system = setName,
	})

	return session
end

function RuneSessionSystem.StopRuneRolling(player, setName)
	local session = runeRollingSessions[player]
	if not session or not session.active or (setName and session.setName ~= setName) then
		return
	end

	session.active = false
	fireRuneRollState(player, {
		kind = "rune_roll_state",
		active = false,
		system = session.setName,
		session = session.sessionCounts,
	})
end

function RuneSessionSystem.RecordRolledRunes(player, rolled)
	local session = runeRollingSessions[player]
	if not session then
		return nil
	end

	for _, runeId in ipairs(rolled or {}) do
		session.sessionCounts[runeId] = (session.sessionCounts[runeId] or 0) + 1
	end

	return session.sessionCounts
end

function RuneSessionSystem.SetLastRollAt(player, rollTime)
	local session = runeRollingSessions[player]
	if session then
		session.lastRollAt = rollTime
	end
end

function RuneSessionSystem.ClearPlayer(player)
	runeRollingSessions[player] = nil
end

function RuneSessionSystem.Init()
	if initialized then
		return
	end
	initialized = true
end

return RuneSessionSystem
