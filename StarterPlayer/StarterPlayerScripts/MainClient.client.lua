local root = script.Parent:WaitForChild("ClientSystems")

local ClientContext = require(root:WaitForChild("ClientContext"))
local NotificationUI = require(root:WaitForChild("NotificationUI"))
local LeaderboardUI = require(root:WaitForChild("LeaderboardUI"))

local context = ClientContext.Create()

NotificationUI.Init(context)
LeaderboardUI.Init(context)
