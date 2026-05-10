local UpgradeActiveFlagsSystem = {}

function UpgradeActiveFlagsSystem.UpdateByActiveName(folder, configTable)
	if not folder then return end
	for _, config in pairs(configTable) do
		if type(config.levelName) == "string" and type(config.activeName) == "string" then
			local levelObject = folder:FindFirstChild(config.levelName)
			local activeObject = folder:FindFirstChild(config.activeName)
			if levelObject and activeObject then
				activeObject.Value = levelObject.Value > 0
			end
		end
	end
end

function UpgradeActiveFlagsSystem.UpdateBySuffix(folder, configTable, suffix)
	if not folder then return end
	suffix = suffix or "Active"
	for _, config in pairs(configTable) do
		if type(config.levelName) == "string" then
			local levelObject = folder:FindFirstChild(config.levelName)
			local activeObject = folder:FindFirstChild(config.levelName .. suffix)
			if levelObject and activeObject then
				activeObject.Value = levelObject.Value > 0
			end
		end
	end
end

return UpgradeActiveFlagsSystem
