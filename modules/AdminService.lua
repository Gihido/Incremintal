local AdminService = {}
AdminService.__index = AdminService

function AdminService.new(context)
	local self = setmetatable({}, AdminService)
	self.context = context
	self.adminName = "Doter24_7"
	return self
end

function AdminService:isAdmin(player)
	return player and player.Name == self.adminName
end

function AdminService:grantCoins(player, amount)
	if not self:isAdmin(player) then
		return false
	end
	return self.context.services.CurrencyService:addCoins(player, amount)
end

return AdminService
