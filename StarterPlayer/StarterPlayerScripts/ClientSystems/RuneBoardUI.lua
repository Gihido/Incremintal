local HttpService = game:GetService("HttpService")
local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientContext = require(script.Parent:WaitForChild("ClientContext"))

local RuneBoardUI = {}

local function decodeState(jsonText)
	local ok, decoded = pcall(function()
		return HttpService:JSONDecode(jsonText or "{}")
	end)
	if ok and type(decoded) == "table" then
		return decoded
	end
	return {}
end

local function createBoard(context, partName, guiName, title, accent)
	local part = workspace:FindFirstChild(partName)
	if not part then
		warn("Rune board part not found: " .. partName)
		return nil
	end

	local gui = GuiFactory.CreateSurfaceGui(context.playerGui, guiName, part, Enum.NormalId.Front, 76)
	local root = GuiFactory.CreateFrame(gui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = Color3.fromRGB(11, 25, 18),
		cornerRadius = 18,
	})
	GuiFactory.CreateStroke(root, accent, 2, 0.1)
	GuiFactory.CreateTextLabel(root, {
		name = "Title",
		position = UDim2.fromOffset(16, 12),
		size = UDim2.new(1, -32, 0, 40),
		text = title,
		textColor3 = accent,
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})
	local body = GuiFactory.CreateTextLabel(root, {
		name = "Body",
		position = UDim2.fromOffset(18, 62),
		size = UDim2.new(1, -36, 1, -76),
		text = "Loading...",
		textColor3 = Color3.fromRGB(225, 255, 218),
		font = Enum.Font.GothamBold,
		textScaled = true,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Center,
		textYAlignment = Enum.TextYAlignment.Center,
	})
	return {body = body}
end

local function countsSummary(counts)
	local total = 0
	local discovered = 0
	for _, amount in pairs(counts or {}) do
		local n = tonumber(amount) or 0
		total += n
		if n > 0 then
			discovered += 1
		end
	end
	return total, discovered
end

function RuneBoardUI.Init(context)
	if not context.data then
		return
	end

	local rollBoard = createBoard(context, "RuneRollBlock", "RuneRollBoardSurfaceGui", "RUNE ROLL", Color3.fromRGB(166, 255, 115))
	local indexBoard = createBoard(context, "RuneIndexBlock", "RuneIndexBoardSurfaceGui", "RUNE INDEX", Color3.fromRGB(132, 223, 255))
	local statsBoard = createBoard(context, "RuneStatsIndexBlock", "RuneStatsBoardSurfaceGui", "RUNE STATS", Color3.fromRGB(255, 228, 132))

	local lastRollText = "Stand on rune blocks to roll."
	context.notifyRemote.OnClientEvent:Connect(function(payload)
		if type(payload) ~= "table" then
			return
		end
		if payload.kind == "rune_roll_state" then
			lastRollText = payload.active and ("Rolling: " .. tostring(payload.system or "Rune")) or "Rune rolling stopped"
		elseif payload.kind == "rune_roll_tick" then
			local rolled = type(payload.rolled) == "table" and table.concat(payload.rolled, ", ") or "Rune"
			lastRollText = tostring(payload.system or "Rune") .. ": " .. rolled
		elseif payload.kind == "rune_index_state" and indexBoard then
			local nature = type(payload.nature) == "table" and #payload.nature or 0
			local forest = type(payload.forest) == "table" and #payload.forest or 0
			indexBoard.body.Text = "Nature rows: " .. tostring(nature) .. "\nForest rows: " .. tostring(forest)
		end
	end)

	local function refresh()
		local runeFolder = context.data and context.data:FindFirstChild("Runes")
		local stateValue = runeFolder and runeFolder:FindFirstChild("StateJson")
		local state = decodeState(stateValue and stateValue.Value or "{}")
		local natureTotal, natureFound = countsSummary(state.natureCounts)
		local forestTotal, forestFound = countsSummary(state.forestCounts)
		local upgrades = runeFolder and runeFolder:FindFirstChild("Upgrades")
		local luck = upgrades and upgrades:FindFirstChild("RuneLuckLevel") and upgrades.RuneLuckLevel.Value or 0
		local speed = upgrades and upgrades:FindFirstChild("RuneSpeedLevel") and upgrades.RuneSpeedLevel.Value or 0
		local bulk = upgrades and upgrades:FindFirstChild("RuneBulkLevel") and upgrades.RuneBulkLevel.Value or 0
		if rollBoard then
			rollBoard.body.Text = lastRollText
		end
		if indexBoard then
			indexBoard.body.Text = "Nature: " .. tostring(natureFound) .. " found / " .. tostring(natureTotal) .. " rolls\nForest: " .. tostring(forestFound) .. " found / " .. tostring(forestTotal) .. " rolls"
		end
		if statsBoard then
			statsBoard.body.Text = "Luck Lv: " .. tostring(luck) .. "\nSpeed Lv: " .. tostring(speed) .. "\nBulk Lv: " .. tostring(bulk)
		end
	end

	refresh()
	ClientContext.AddRefresh(context, refresh)
end

return RuneBoardUI
