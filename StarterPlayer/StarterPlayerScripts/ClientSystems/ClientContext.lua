local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ClientContext = {}

local REMOTE_WAIT_TIMEOUT = 15

local BOARD_PART_NAMES = {
	Coin = "UpgradeDoska",
	Wood = "TreeUpgradeDoska",
	Paper = "PaperUpgradeDoska",
	Rune = "RuneUpgradeDoska",
	Hay = "HayUpgradeBoard",
	XP = "XPUpgradeDoska",
	XPProgress = "XPProgressDoska",
	PassiveRoll = "PassiveRollBlock",
	PassiveInventory = "PassiveInventoryBlock",
	RuneRoll = "RuneRollBlock",
	RuneIndex = "RuneIndexBlock",
	RuneStatsIndex = "RuneStatsIndexBlock",
	NatureRune = "NatureRuneBlock",
	ForestRune = "ForestRuneBlock",
	HayBlock = "HayBlock",
	CoinInfo = "DoskaPart",
	Rebirth = "RebirthDoska",
	TreeInfo = "TreeDoska",
	Boost = "BoostDoska",
	PaperFactory = "PaperFactoryDoska",
	Leaderboard = {
		"LederstartsBoard",
		"LeaderstartsBoard",
		"LeaderstatsBoard",
		"LeaderboardBoard",
		"LeaderBoard",
		"Leaderboard",
	},
}

local function resolveWorkspaceObject(name)
	if not name or name == "" then
		return nil
	end

	local direct = Workspace:FindFirstChild(name)
	if direct then
		return direct
	end

	local recursive = Workspace:FindFirstChild(name, true)
	if recursive then
		return recursive
	end

	warn("Workspace object not found:", name)
	return nil
end

local function resolveWorkspaceObjectFromCandidates(names)
	if type(names) ~= "table" then
		return resolveWorkspaceObject(names)
	end

	for _, name in ipairs(names) do
		local object = resolveWorkspaceObject(name)
		if object then
			return object
		end
	end
	return nil
end

local function waitForRequiredChild(parent, childName, timeoutSeconds)
	local timeoutAt = os.clock() + (timeoutSeconds or REMOTE_WAIT_TIMEOUT)
	local child = parent:FindFirstChild(childName)
	while not child and os.clock() < timeoutAt do
		task.wait(0.05)
		child = parent:FindFirstChild(childName)
	end

	if not child then
		error(childName .. " was not created under " .. parent:GetFullName() .. " within " .. tostring(timeoutSeconds or REMOTE_WAIT_TIMEOUT) .. " seconds")
	end
	return child
end

local function waitForRemote(remotesFolder, remoteName)
	return waitForRequiredChild(remotesFolder, remoteName, REMOTE_WAIT_TIMEOUT)
end

ClientContext.BoardPartNames = BOARD_PART_NAMES
ClientContext.ResolveWorkspaceObject = resolveWorkspaceObject
ClientContext.ResolveWorkspaceObjectFromCandidates = resolveWorkspaceObjectFromCandidates

function ClientContext.Create()
	local player = Players.LocalPlayer
	local remotesFolder = waitForRequiredChild(ReplicatedStorage, "IncrementalRemotes", REMOTE_WAIT_TIMEOUT)
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
		BoardPartNames = BOARD_PART_NAMES,
		ResolveWorkspaceObject = resolveWorkspaceObject,
		ResolveWorkspaceObjectFromCandidates = resolveWorkspaceObjectFromCandidates,
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
