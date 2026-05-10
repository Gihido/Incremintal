local function getClientSystemsRoot()
	local direct = script.Parent:FindFirstChild("ClientSystems")
	if direct then
		return direct
	end
	local lowered = script.Parent:FindFirstChild("clientSystems")
	if lowered then
		return lowered
	end
	return script.Parent:WaitForChild("ClientSystems")
end

local function waitModule(folder, preferredName, fallbackName)
	local module = folder:FindFirstChild(preferredName)
	if not module and fallbackName then
		module = folder:FindFirstChild(fallbackName)
	end
	if module then
		return module
	end
	return folder:WaitForChild(preferredName)
end

local root = getClientSystemsRoot()

local ClientContext = require(waitModule(root, "ClientContext", "clientContext"))
local NotificationUI = require(waitModule(root, "NotificationUI", "notificationUI"))
local LeaderboardUI = require(waitModule(root, "LeaderboardUI", "leaderboardUI"))
local AdminPanelUI = require(waitModule(root, "AdminPanelUI", "adminPanelUI"))
local ClientRuntimeLoop = require(waitModule(root, "ClientRuntimeLoop", "clientRuntimeLoop"))

local context = ClientContext.Create()

NotificationUI.Init(context)
LeaderboardUI.Init(context)
AdminPanelUI.Init(context)
ClientRuntimeLoop.StartLeaderboardPolling(context)
