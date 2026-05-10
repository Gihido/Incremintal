local UpgradePurchaseSystem = {}

function UpgradePurchaseSystem.TryBuy(args)
	local config = args.configTable[args.upgradeKey]
	if not config then return "INVALID" end
	if not args.isUnlocked(config, args.currentRebirthCount) then return "LOCKED" end

	local levelObject = args.folder:FindFirstChild(config.levelName)
	local costObject = args.folder:FindFirstChild(config.costName)
	if not levelObject or not costObject then return "INVALID" end

	if levelObject.Value >= config.maxLevel then
		costObject.Value = 0
		args.updateFlags(args.folder, args.configTable)
		return "AT_MAX"
	end

	if costObject.Value <= 0 then return "AT_MAX" end
	if not args.spendCurrency(args.currencyObject, costObject.Value) then return "NO_MONEY" end

	levelObject.Value += 1
	args.applyNextCost(levelObject, costObject, config)
	args.updateFlags(args.folder, args.configTable)
	args.markDirty(args.player)
	return "BOUGHT"
end

return UpgradePurchaseSystem
