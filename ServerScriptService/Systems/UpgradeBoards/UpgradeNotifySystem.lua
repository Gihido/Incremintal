local UpgradeNotifySystem = {}

function UpgradeNotifySystem.FireSimple(notifyRemote, player, text)
	if not notifyRemote then
		return
	end

	notifyRemote:FireClient(player, {
		kind = "simple",
		text = tostring(text),
	})
end

return UpgradeNotifySystem
