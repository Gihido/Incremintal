local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteRegistry = {}

local REMOTE_FOLDER_NAME = "IncrementalRemotes"

local REMOTE_NAMES = {
	PurchaseUpgrade = "PurchaseUpgrade",
	PurchaseRebirth = "PurchaseRebirth",
	AdminAction = "AdminAction",
	Notify = "Notify",
	WoodClick = "WoodClick",
	FactoryAction = "FactoryAction",
	PassiveAction = "PassiveAction",
	RuneAction = "RuneAction",
	XPAction = "XPAction",
	LeaderboardRequest = "LeaderboardRequest",
}

local remotesFolder = nil
local remotes = nil

local function ensureRemotesFolder()
	local folder = ReplicatedStorage:FindFirstChild(REMOTE_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end

	folder = Instance.new("Folder")
	folder.Name = REMOTE_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local function ensureRemote(folder, name)
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = folder
	return remote
end

function RemoteRegistry.Init()
	if remotes then
		return remotes
	end

	remotesFolder = ensureRemotesFolder()
	remotes = {}

	for key, remoteName in pairs(REMOTE_NAMES) do
		remotes[key] = ensureRemote(remotesFolder, remoteName)
	end

	return remotes
end

function RemoteRegistry.GetFolder()
	return remotesFolder or ensureRemotesFolder()
end

function RemoteRegistry.GetRemotes()
	return RemoteRegistry.Init()
end

function RemoteRegistry.GetRemote(remoteKey)
	local allRemotes = RemoteRegistry.Init()
	return allRemotes[remoteKey]
end

RemoteRegistry.RemoteNames = REMOTE_NAMES
RemoteRegistry.FolderName = REMOTE_FOLDER_NAME

return RemoteRegistry
