local ClientFormatters = require(script.Parent:WaitForChild("ClientFormatters"))

local LeaderboardUI = {}

local BOARD_ORDER = {"Coins", "Wood", "Paper", "Hay", "XP"}

local function createRow(parent, y, text)
	local row = Instance.new("TextLabel")
	row.BackgroundTransparency = 1
	row.Size = UDim2.fromScale(1, 0)
	row.AutomaticSize = Enum.AutomaticSize.Y
	row.Position = UDim2.fromScale(0, y)
	row.Font = Enum.Font.Gotham
	row.TextSize = 16
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = Color3.fromRGB(235, 235, 235)
	row.Text = text
	row.Parent = parent
	return row
end

local function ensureGui(playerGui)
	local gui = playerGui:FindFirstChild("LeaderboardGui")
	if not gui then
		gui = Instance.new("ScreenGui")
		gui.Name = "LeaderboardGui"
		gui.ResetOnSpawn = false
		gui.Parent = playerGui
	end

	local frame = gui:FindFirstChild("Frame")
	if not frame then
		frame = Instance.new("Frame")
		frame.Name = "Frame"
		frame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
		frame.BackgroundTransparency = 0.2
		frame.Size = UDim2.fromOffset(300, 320)
		frame.Position = UDim2.new(1, -320, 0, 24)
		frame.Parent = gui

		local uiList = Instance.new("UIListLayout")
		uiList.Padding = UDim.new(0, 4)
		uiList.Parent = frame
	end

	return frame
end

function LeaderboardUI.Init(context)
	local frame = ensureGui(context.playerGui)
	local rowsByBoard = {}

	for _, boardName in ipairs(BOARD_ORDER) do
		local header = createRow(frame, 0, boardName .. " TOP:")
		header.TextColor3 = Color3.fromRGB(255, 220, 120)
		rowsByBoard[boardName] = {header = header, rows = {}}
		for i = 1, 5 do
			rowsByBoard[boardName].rows[i] = createRow(frame, 0, "#" .. i .. " ...")
		end
	end

	context.leaderboardRemote.OnClientEvent:Connect(function(boardName, payload)
		if type(boardName) ~= "string" or type(payload) ~= "table" then
			return
		end
		local board = rowsByBoard[boardName]
		if not board then
			return
		end

		for i = 1, 5 do
			local item = payload[i]
			if type(item) == "table" then
				local display = item.displayName ~= "" and item.displayName or (item.name or "Unknown")
				local valueText = item.formattedValue or ClientFormatters.Compact(item.value)
				board.rows[i].Text = string.format("#%d %s — %s", i, display, valueText)
			else
				board.rows[i].Text = string.format("#%d ---", i)
			end
		end
	end)

end

return LeaderboardUI
