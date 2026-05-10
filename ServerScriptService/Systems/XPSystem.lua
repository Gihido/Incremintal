local CoreSystems = script.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))

local XPSystem = {}

local XP_UPGRADES = PlayerDataSystem.Config.XPUpgrades
local XP_BOOST_CONFIG = PlayerDataSystem.Config.XPBoost
local initialized = false

local function safeNumber(value, defaultValue)
	local n = tonumber(value)
	if n == nil then
		return defaultValue
	end
	return n
end

local function fireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if not notifyEvent then
		return
	end

	notifyEvent:FireClient(player, {
		kind = "simple",
		text = tostring(text),
	})
end

function XPSystem.GetXPBoostMultiplier(player)
	local boostFolder = PlayerDataSystem.GetXPBoostFolder(player)
	if not boostFolder then
		return 1
	end

	local lvl = boostFolder:FindFirstChild(XP_BOOST_CONFIG.levelName)
	return 1 + math.max(0, safeNumber(lvl and lvl.Value, 0))
end

function XPSystem.ResetXPProgress(player)
	local xp = PlayerDataSystem.GetXPCurrencyObject(player)
	local xpUpgrades = PlayerDataSystem.GetXPUpgradesFolder(player)
	local xpBoost = PlayerDataSystem.GetXPBoostFolder(player)

	if xp then
		xp.Value = 0
	end

	if xpUpgrades then
		for _, cfg in pairs(XP_UPGRADES) do
			local lvl = xpUpgrades:FindFirstChild(cfg.levelName)
			local cost = xpUpgrades:FindFirstChild(cfg.costName)
			if lvl then
				lvl.Value = 0
			end
			if cost then
				cost.Value = cfg.startCost
			end
		end
	end

	if xpBoost then
		if xpBoost:FindFirstChild(XP_BOOST_CONFIG.levelName) then
			xpBoost[XP_BOOST_CONFIG.levelName].Value = 0
		end
		if xpBoost:FindFirstChild(XP_BOOST_CONFIG.costName) then
			xpBoost[XP_BOOST_CONFIG.costName].Value = XP_BOOST_CONFIG.startCost
		end
	end

	PlayerDataSystem.MarkDirty(player)
end

function XPSystem.HandleXPAction(player, actionName)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	local xp = PlayerDataSystem.GetXPCurrencyObject(player)
	local xpBoost = PlayerDataSystem.GetXPBoostFolder(player)
	if not rebirth or not xp or not xpBoost then
		return
	end

	if not rebirth.SecondAreaUnlocked.Value then
		fireSimple(player, "XP откроется на 2-м перерождении")
		return
	end

	if actionName ~= "BuyXPBoost" then
		return
	end

	local levelObj = xpBoost:FindFirstChild(XP_BOOST_CONFIG.levelName)
	local costObj = xpBoost:FindFirstChild(XP_BOOST_CONFIG.costName)
	if not levelObj or not costObj then
		return
	end

	if levelObj.Value >= XP_BOOST_CONFIG.maxLevel then
		fireSimple(player, "XP Boost уже в MAX")
		return
	end

	if not PlayerDataSystem.SpendCurrency(xp, costObj.Value) then
		fireSimple(player, "Не хватает XP")
		return
	end

	levelObj.Value += 1
	if levelObj.Value >= XP_BOOST_CONFIG.maxLevel then
		costObj.Value = 0
	else
		costObj.Value = math.floor(costObj.Value * XP_BOOST_CONFIG.priceMultiplier + 0.5)
	end

	PlayerDataSystem.MarkDirty(player)
	fireSimple(player, "XP Boost улучшен")
end

function XPSystem.Init()
	if initialized then
		return
	end
	initialized = true

	local xpActionEvent = RemoteRegistry.GetRemote("XPAction")
	xpActionEvent.OnServerEvent:Connect(function(player, actionName)
		XPSystem.HandleXPAction(player, actionName)
	end)
end

return XPSystem
