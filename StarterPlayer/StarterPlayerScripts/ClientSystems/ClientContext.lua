local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientContext = {}

local REMOTES_FOLDER_NAME = "IncrementalRemotes"
local REMOTE_WAIT_TIMEOUT = 30

local function waitForChildWithWarning(parent, childName, timeout)
	local child = parent:WaitForChild(childName, timeout)
	if not child then
		warn(string.format("%s.%s was not available after %d seconds", parent:GetFullName(), childName, timeout))
	end
	return child
end

local function getOrCreateLocalRemotesFolder()
	local remotesFolder = waitForChildWithWarning(ReplicatedStorage, REMOTES_FOLDER_NAME, REMOTE_WAIT_TIMEOUT)
	if remotesFolder then
		return remotesFolder
	end

	-- Keep the client UI booting even if the server failed before creating remotes.
	-- These client-only placeholders will not reach the server, but they prevent one
	-- missing remote folder from blocking every GUI while Studio reports the server
	-- error that needs to be fixed.
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = REMOTES_FOLDER_NAME
	remotesFolder:SetAttribute("ClientFallback", true)
	remotesFolder.Parent = ReplicatedStorage
	return remotesFolder
end

local function waitForRemote(remotesFolder, remoteName)
	local remote = remotesFolder:FindFirstChild(remoteName)
	if not remote and not remotesFolder:GetAttribute("ClientFallback") then
		remote = waitForChildWithWarning(remotesFolder, remoteName, REMOTE_WAIT_TIMEOUT)
	end
	if remote then
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = remoteName
	remote.Parent = remotesFolder
	return remote
end

function ClientContext.Create()
	local player = Players.LocalPlayer
	local remotesFolder = getOrCreateLocalRemotesFolder()
	local data = player:WaitForChild("PlayerData", 30)
	if not data then
		warn("PlayerData was not created within 30 seconds for " .. player.Name)
	end

	return {
		player = player,
		playerGui = player:WaitForChild("PlayerGui"),
		data = data,
		remotesFolder = remotesFolder,
		notifyRemote = waitForRemote(remotesFolder, "Notify"),
		leaderboardRemote = waitForRemote(remotesFolder, "LeaderboardRequest"),
		adminRemote = waitForRemote(remotesFolder, "AdminAction"),
		purchaseUpgradeRemote = waitForRemote(remotesFolder, "PurchaseUpgrade"),
		purchaseRebirthRemote = waitForRemote(remotesFolder, "PurchaseRebirth"),
		factoryRemote = waitForRemote(remotesFolder, "FactoryAction"),
		passiveRemote = waitForRemote(remotesFolder, "PassiveAction"),
		runeRemote = waitForRemote(remotesFolder, "RuneAction"),
		xpRemote = waitForRemote(remotesFolder, "XPAction"),
		_refreshCallbacks = {},
	}
end

function ClientContext.AddRefresh(context, callback)
	if type(callback) ~= "function" then
		return
	end
	context._refreshCallbacks = context._refreshCallbacks or {}
	context._refreshCallbacks[#context._refreshCallbacks + 1] = callback
end

return ClientContext
