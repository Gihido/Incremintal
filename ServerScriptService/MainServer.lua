local Systems = script.Parent:WaitForChild("Systems")
local CoreSystems = Systems:WaitForChild("Core")
local UpgradeBoards = Systems:WaitForChild("UpgradeBoards")

local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local CoinSystem = require(Systems:WaitForChild("CoinSystem"))
local CoinUpgradeBoard = require(UpgradeBoards:WaitForChild("CoinUpgradeBoard"))

RemoteRegistry.Init()
PlayerDataSystem.Init()
CoinUpgradeBoard.Init()
CoinSystem.Init()
