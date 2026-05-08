local UpgradeService = {}
UpgradeService.__index = UpgradeService

function UpgradeService.new(context)
	local self = setmetatable({}, UpgradeService)
	self.context = context
	self.levels = {}
	return self
end

local function ensureUpgradeSet(levels, key)
	levels[key] = levels[key] or {}
	return levels[key]
end

function UpgradeService:init()
	ensureUpgradeSet(self.levels, "Coin")
	ensureUpgradeSet(self.levels, "Wood")
	ensureUpgradeSet(self.levels, "Paper")
end

function UpgradeService:start()
	task.spawn(function()
		while true do
			task.wait(1)
		end
	end)
end

return UpgradeService
