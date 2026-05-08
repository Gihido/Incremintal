local Players = game:GetService("Players")

local CurrencyService = {}
CurrencyService.__index = CurrencyService

local CURRENCY_PATHS = {
	Coins = {"PlayerData", "Coins"},
	Wood = {"PlayerData", "Wood", "WoodCurrency"},
	Paper = {"PlayerData", "Wood", "PaperFactory", "Paper"},
	Hay = {"PlayerData", "Hay", "HayCurrency"},
	XP = {"PlayerData", "XP", "XPValue"},
}

local function roundToTenth(value)
	return math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
end

local function findByPath(root, path)
	local current = root
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

function CurrencyService.new(context)
	local self = setmetatable({}, CurrencyService)
	self.context = context
	self.changedConnections = {}
	self.leaderstats = {}
	return self
end

function CurrencyService:getCurrencyObject(player, currencyName)
	local path = CURRENCY_PATHS[currencyName]
	if not path then
		return nil
	end
	return findByPath(player, path)
end

function CurrencyService:updateCurrency(player, currencyName, delta)
	local object = self:getCurrencyObject(player, currencyName)
	if not object or typeof(object.Value) ~= "number" then
		return false
	end
	object.Value = roundToTenth(object.Value + (tonumber(delta) or 0))
	self:syncLeaderstats(player)
	return true
end

function CurrencyService:addCoins(player, amount)
	return self:updateCurrency(player, "Coins", math.abs(tonumber(amount) or 0))
end

function CurrencyService:spendCoins(player, amount)
	local coins = self:getCurrencyObject(player, "Coins")
	local spend = math.abs(tonumber(amount) or 0)
	if not coins or typeof(coins.Value) ~= "number" or coins.Value < spend then
		return false
	end
	coins.Value = roundToTenth(coins.Value - spend)
	self:syncLeaderstats(player)
	return true
end

function CurrencyService:getCoins(player)
	local coins = self:getCurrencyObject(player, "Coins")
	if not coins or typeof(coins.Value) ~= "number" then
		return 0
	end
	return coins.Value
end

function CurrencyService:syncLeaderstats(player)
	local stats = self.leaderstats[player]
	if not stats then
		return
	end
	stats.Coins.Value = self:getCoins(player)
end

function CurrencyService:ensureLeaderstats(player)
	if self.leaderstats[player] then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player

	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Value = self:getCoins(player)
	coins.Parent = folder

	self.leaderstats[player] = {
		folder = folder,
		Coins = coins,
	}
end

function CurrencyService:bindCurrencyChanged(player)
	local coinsObj = self:getCurrencyObject(player, "Coins")
	if not coinsObj then
		return
	end
	self.changedConnections[player] = coinsObj.Changed:Connect(function()
		self:syncLeaderstats(player)
	end)
end

function CurrencyService:unbindPlayer(player)
	local changed = self.changedConnections[player]
	if changed then
		changed:Disconnect()
		self.changedConnections[player] = nil
	end
	self.leaderstats[player] = nil
end

function CurrencyService:onPlayerAdded(player)
	self:ensureLeaderstats(player)
	self:bindCurrencyChanged(player)
	self:syncLeaderstats(player)
end

function CurrencyService:init()
	Players.PlayerAdded:Connect(function(player)
		task.defer(function()
			self:onPlayerAdded(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player)
		self:unbindPlayer(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function()
			self:onPlayerAdded(player)
		end)
	end
end

function CurrencyService:start()
	task.spawn(function()
		while true do
			task.wait(1)
			for _, player in ipairs(Players:GetPlayers()) do
				self:syncLeaderstats(player)
			end
		end
	end)
end

return CurrencyService
