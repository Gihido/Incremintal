local Players = game:GetService("Players")

local CurrencyService = {}
CurrencyService.__index = CurrencyService

function CurrencyService.new(context)
	local self = setmetatable({}, CurrencyService)
	self.context = context
	self.playerWallets = {}
	return self
end

local function ensureWallet(wallets, player)
	wallets[player] = wallets[player] or {Coins = 0, Wood = 0, Paper = 0}
	return wallets[player]
end

function CurrencyService:init()
	Players.PlayerAdded:Connect(function(player)
		ensureWallet(self.playerWallets, player)
	end)
end

function CurrencyService:start()
	task.spawn(function()
		while true do
			task.wait(1)
		end
	end)
end

return CurrencyService
