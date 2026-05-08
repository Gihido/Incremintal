local Players = game:GetService("Players")

local CurrencyService = {}
CurrencyService.__index = CurrencyService

local CURRENCIES = {"Coins", "Wood", "Paper", "XP"}

local function roundToTenth(value)
	return math.floor((tonumber(value) or 0) * 10 + 0.5) / 10
end

function CurrencyService.new(context)
	local self = setmetatable({}, CurrencyService)
	self.context = context
	self.changedConnections = {}
	self.leaderstats = {}
	return self
end

function CurrencyService:getState(player)
	return self.context.services.GameState:get(player)
end

function CurrencyService:updateCurrency(player, currencyName, delta)
	if not table.find(CURRENCIES, currencyName) then
		return false
	end
	self.context.services.GameState:patch(player, function(state)
		state[currencyName] = roundToTenth((state[currencyName] or 0) + (tonumber(delta) or 0))
	end)
	return true
end

function CurrencyService:addCoins(player, amount)
	return self:updateCurrency(player, "Coins", math.abs(tonumber(amount) or 0))
end

function CurrencyService:spendCoins(player, amount)
	local spend = math.abs(tonumber(amount) or 0)
	local state = self:getState(player)
	if (state.Coins or 0) < spend then
		return false
	end
	return self:updateCurrency(player, "Coins", -spend)
end

function CurrencyService:getCoins(player)
	return self:getState(player).Coins or 0
end

function CurrencyService:syncPlayerDataValues(player)
	local state = self:getState(player)
	local data = player:FindFirstChild("PlayerData")
	if not data then
		return
	end
	local coins = data:FindFirstChild("Coins")
	if coins then coins.Value = state.Coins or 0 end
	local wood = data:FindFirstChild("Wood")
	if wood and wood:FindFirstChild("WoodCurrency") then wood.WoodCurrency.Value = state.Wood or 0 end
	if wood and wood:FindFirstChild("PaperFactory") and wood.PaperFactory:FindFirstChild("Paper") then wood.PaperFactory.Paper.Value = state.Paper or 0 end
	local xp = data:FindFirstChild("XP")
	if xp and xp:FindFirstChild("XPValue") then xp.XPValue.Value = state.XP or 0 end
end

function CurrencyService:syncLeaderstats(player)
	local stats = self.leaderstats[player]
	if not stats then return end
	stats.Coins.Value = self:getCoins(player)
end

function CurrencyService:ensureLeaderstats(player)
	if self.leaderstats[player] then return end
	local folder = Instance.new("Folder")
	folder.Name = "leaderstats"
	folder.Parent = player
	local coins = Instance.new("NumberValue")
	coins.Name = "Coins"
	coins.Parent = folder
	self.leaderstats[player] = {folder = folder, Coins = coins}
end

function CurrencyService:onStateChanged(player)
	self:syncPlayerDataValues(player)
	self:syncLeaderstats(player)
end

function CurrencyService:onPlayerAdded(player)
	self:ensureLeaderstats(player)
	self.changedConnections[player] = self.context.services.GameState:onChanged(player, function()
		self:onStateChanged(player)
	end)
	self:onStateChanged(player)
end

function CurrencyService:unbindPlayer(player)
	local conn = self.changedConnections[player]
	if conn then conn:Disconnect() end
	self.changedConnections[player] = nil
	self.leaderstats[player] = nil
end

function CurrencyService:init()
	Players.PlayerAdded:Connect(function(player)
		task.defer(function() self:onPlayerAdded(player) end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:unbindPlayer(player)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		task.defer(function() self:onPlayerAdded(player) end)
	end
end

return CurrencyService
