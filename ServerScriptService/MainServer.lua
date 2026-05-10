local Systems = script.Parent:WaitForChild("Systems")
local CoreSystems = Systems:WaitForChild("Core")
local UpgradeBoards = Systems:WaitForChild("UpgradeBoards")

local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local GamepassSystem = require(CoreSystems:WaitForChild("GamepassSystem"))
local CoinSystem = require(Systems:WaitForChild("CoinSystem"))
local WoodSystem = require(Systems:WaitForChild("WoodSystem"))
local PaperFactorySystem = require(Systems:WaitForChild("PaperFactorySystem"))
local HaySystem = require(Systems:WaitForChild("HaySystem"))
local XPSystem = require(Systems:WaitForChild("XPSystem"))
local PassiveSystem = require(Systems:WaitForChild("PassiveSystem"))
local CoinUpgradeBoard = require(UpgradeBoards:WaitForChild("CoinUpgradeBoard"))
local WoodUpgradeBoard = require(UpgradeBoards:WaitForChild("WoodUpgradeBoard"))
local PaperUpgradeBoard = require(UpgradeBoards:WaitForChild("PaperUpgradeBoard"))
local HayUpgradeBoard = require(UpgradeBoards:WaitForChild("HayUpgradeBoard"))
local XPUpgradeBoard = require(UpgradeBoards:WaitForChild("XPUpgradeBoard"))

RemoteRegistry.Init()
PlayerDataSystem.Init()
GamepassSystem.Init()
CoinUpgradeBoard.Init()
WoodUpgradeBoard.Init()
PaperUpgradeBoard.Init()
HayUpgradeBoard.Init()
XPUpgradeBoard.Init()
XPSystem.Init()
PassiveSystem.Init()
CoinSystem.Init({
	GetXPBoostMultiplier = XPSystem.GetXPBoostMultiplier,
	GetPassiveMultipliers = PassiveSystem.GetPassiveMultipliers,
	GetPassiveSpecialBoosts = PassiveSystem.GetPassiveSpecialBoosts,
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
WoodSystem.Init({
	GetPassiveMultipliers = PassiveSystem.GetPassiveMultipliers,
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
PaperFactorySystem.Init({
	GetGamepassMultiplier = GamepassSystem.GetGamepassMultiplier,
})
HaySystem.Init()
