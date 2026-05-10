local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local RuneNotifySystem = {}

function RuneNotifySystem.FireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "simple", text = tostring(text)})
	end
end

function RuneNotifySystem.FirePayload(player, payload)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if notifyEvent then
		notifyEvent:FireClient(player, payload)
	end
end

return RuneNotifySystem
