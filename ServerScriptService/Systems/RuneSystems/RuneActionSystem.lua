local RuneActionSystem = {}

function RuneActionSystem.Handle(player, actionName, handlers)
	if actionName == "Open" or actionName == "OpenNature" then
		handlers.fireSimple(player, "Nature Rune работает автоматически, пока стоишь на NatureRuneBlock")
		return
	elseif actionName == "OpenForest" then
		handlers.fireSimple(player, "Forest Rune работает автоматически, пока стоишь на ForestRuneBlock")
		return
	elseif not handlers.canUseRunes(player) then
		handlers.fireSimple(player, "Система Nature Rune откроется после 2-го перерождения")
		return
	elseif actionName == "UpgradeLuck" then
		handlers.buyLuck(player)
	elseif actionName == "UpgradeLuckMax" then
		handlers.buyLuckMax(player)
	elseif actionName == "UpgradeSpeed" then
		handlers.buySpeed(player)
	elseif actionName == "UpgradeSpeedMax" then
		handlers.buySpeedMax(player)
	elseif actionName == "UpgradeBulk" then
		handlers.buyBulk(player)
	elseif actionName == "UpgradeBulkMax" then
		handlers.buyBulkMax(player)
	elseif actionName == "RequestIndex" then
		handlers.pushIndex(player)
	end
end

return RuneActionSystem
