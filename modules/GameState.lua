local Players = game:GetService("Players")

local GameState = {}
GameState.__index = GameState

local DEFAULTS = {
	Coins = 0,
	Wood = 0,
	Paper = 0,
	XP = 0,
	RuneLuck = 0,
	RuneBulk = 0,
	RuneSpeed = 0,
	Passives = {},
	Rebirths = 0,
	Unlocks = {},
	Multipliers = {
		Coins = 1,
		Wood = 1,
		Paper = 1,
		XP = 1,
	},
}

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, child in pairs(value) do
		result[key] = deepCopy(child)
	end
	return result
end

function GameState.new(context)
	local self = setmetatable({}, GameState)
	self.context = context
	self.playerStates = {}
	self.changedSignals = {}
	return self
end

function GameState:createPlayerState(player)
	local state = deepCopy(DEFAULTS)
	self.playerStates[player] = state
	self.changedSignals[player] = Instance.new("BindableEvent")
	return state
end

function GameState:get(player)
	return self.playerStates[player] or self:createPlayerState(player)
end

function GameState:patch(player, callback)
	local state = self:get(player)
	callback(state)
	local changed = self.changedSignals[player]
	if changed then
		changed:Fire(state)
	end
	return state
end

function GameState:onChanged(player, handler)
	local signal = self.changedSignals[player]
	if not signal then
		self:createPlayerState(player)
		signal = self.changedSignals[player]
	end
	return signal.Event:Connect(function(state)
		handler(state)
	end)
end

function GameState:remove(player)
	self.playerStates[player] = nil
	local signal = self.changedSignals[player]
	if signal then
		signal:Destroy()
		self.changedSignals[player] = nil
	end
end

function GameState:init()
	Players.PlayerAdded:Connect(function(player)
		self:createPlayerState(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		self:remove(player)
	end)

	for _, player in ipairs(Players:GetPlayers()) do
		self:createPlayerState(player)
	end
end

return GameState
