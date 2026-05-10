local MarketplaceService = game:GetService("MarketplaceService")

local PlayerDataSystem = require(script.Parent:WaitForChild("PlayerDataSystem"))

local GamepassSystem = {}

local GamepassIds = PlayerDataSystem.Config.GamepassIds
local initialized = false

function GamepassSystem.PlayerHasGamepass(player, gamepassName)
	local folder = PlayerDataSystem.GetGamepassFolder(player)
	local flag = folder and folder:FindFirstChild(gamepassName)
	return flag and flag.Value == true
end

function GamepassSystem.GetGamepassMultiplier(player, gamepassName, ownedMultiplier)
	return GamepassSystem.PlayerHasGamepass(player, gamepassName) and ownedMultiplier or 1
end

function GamepassSystem.RefreshPlayerGamepasses(player, savedGamepasses)
	local folder = PlayerDataSystem.GetGamepassFolder(player)
	if not folder then
		return
	end

	savedGamepasses = type(savedGamepasses) == "table" and savedGamepasses or {}
	for gamepassName, gamepassId in pairs(GamepassIds) do
		local flag = folder:FindFirstChild(gamepassName)
		if flag then
			local owns = savedGamepasses[gamepassName] == true
			if tonumber(gamepassId) and tonumber(gamepassId) > 0 then
				local ok, result = pcall(function()
					return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
				end)
				if ok then
					owns = result == true
				else
					warn(string.format("[GamepassCheckFailed] %s %s: %s", player.Name, gamepassName, tostring(result)))
				end
			end
			flag.Value = owns
		end
	end
end

function GamepassSystem.Init()
	if initialized then
		return
	end
	initialized = true
end

return GamepassSystem
