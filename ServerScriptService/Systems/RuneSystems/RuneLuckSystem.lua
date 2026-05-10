local CoreSystems = script.Parent.Parent:WaitForChild("Core")
local PlayerDataSystem = require(CoreSystems:WaitForChild("PlayerDataSystem"))
local RemoteRegistry = require(CoreSystems:WaitForChild("RemoteRegistry"))
local RuneInventorySystem = require(script.Parent:WaitForChild("RuneInventorySystem"))

local RuneLuckSystem = {}

local RUNE_UPGRADES = PlayerDataSystem.Config.RuneUpgrades

local function fireSimple(player, text)
	local notifyEvent = RemoteRegistry.GetRemote("Notify")
	if notifyEvent then
		notifyEvent:FireClient(player, {kind = "simple", text = tostring(text)})
	end
end

local function getCurrencyObject(player, currencyName)
	if currencyName == "Wood" then
		return PlayerDataSystem.GetWoodCurrencyObject(player)
	elseif currencyName == "Paper" then
		return PlayerDataSystem.GetPaperCurrencyObject(player)
	elseif currencyName == "Hay" then
		return PlayerDataSystem.GetHayCurrencyObject(player)
	end
	return PlayerDataSystem.GetCoinsObject(player)
end

function RuneLuckSystem.TryBuy(player, silent)
	local cfg = RUNE_UPGRADES.Luck
	local upgrades = RuneInventorySystem.GetRuneUpgradeFolder(player)
	local rebirth = PlayerDataSystem.GetRebirthFolder(player)
	if not cfg or not upgrades then return false end
	if not rebirth or not rebirth.SecondAreaUnlocked.Value then
		if not silent then fireSimple(player, "Forest Runes откроются на 2-м перерождении") end
		return false
	end
	local levelObj = upgrades:FindFirstChild(cfg.levelName)
	local costObj = upgrades:FindFirstChild(cfg.costName)
	local currencyObj = getCurrencyObject(player, cfg.currency)
	if not levelObj or not costObj or not currencyObj then return false end
	if levelObj.Value >= cfg.maxLevel then
		if not silent then fireSimple(player, "Улучшение на максимуме") end
		return false
	end
	if not PlayerDataSystem.SpendCurrency(currencyObj, costObj.Value) then
		if not silent then fireSimple(player, "Недостаточно ресурса") end
		return false
	end
	levelObj.Value += 1
	costObj.Value = math.floor(costObj.Value * 2 + 0.5)
	PlayerDataSystem.MarkDirty(player)
	if not silent then fireSimple(player, "Улучшение рун куплено") end
	return true
end

function RuneLuckSystem.TryBuyMax(player)
	for _ = 1, 200 do
		if not RuneLuckSystem.TryBuy(player, true) then break end
	end
end

return RuneLuckSystem
