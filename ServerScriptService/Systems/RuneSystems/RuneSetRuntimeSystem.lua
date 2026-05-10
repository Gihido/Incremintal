local RuneSetRuntimeSystem = {}

function RuneSetRuntimeSystem.ShouldStopRolling(player, setConfig, rebirthCount, isCharacterOnBlock)
	if not setConfig or not setConfig.block then return true end
	if rebirthCount < setConfig.unlockRebirth then return true end
	if not isCharacterOnBlock(player, setConfig.block, Vector3.new(0.8, 3.2, 0.8)) then return true end
	return false
end

return RuneSetRuntimeSystem
