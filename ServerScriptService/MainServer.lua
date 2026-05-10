local CoreSystems = script.Parent:WaitForChild("Systems"):WaitForChild("Core")

local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))

RemoteRegistry.Init()
PlayerDataSystem.Init()
