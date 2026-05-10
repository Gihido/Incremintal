local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientFormatters = require(script.Parent:WaitForChild("ClientFormatters"))

local LeaderboardUI = {}

local BOARD_ORDER = {"Coins", "Wood", "Paper", "Hay", "XP"}
local function createRow(parent, text, textColor, height)
	local row = Instance.new("TextLabel")
	row.BackgroundTransparency = 1
	row.Size = UDim2.new(1, 0, 0, height or 22)
	row.Font = Enum.Font.GothamBold
	row.TextSize = 18
	row.TextScaled = true
	row.TextWrapped = true
	row.TextXAlignment = Enum.TextXAlignment.Left
	row.TextColor3 = textColor or Color3.fromRGB(235, 235, 235)
	row.Text = text
	row.Parent = parent
	return row
end

local function createSection(parent, boardName)
	local section = GuiFactory.CreateFrame(parent, {
		name = boardName .. "Section",
		size = UDim2.new(0, 172, 1, -8),
		backgroundColor3 = Color3.fromRGB(25, 28, 38),
		backgroundTransparency = 0.05,
		cornerRadius = 12,
	})
	GuiFactory.CreateStroke(section, Color3.fromRGB(255, 220, 120), 1, 0.45)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 8)
	padding.PaddingBottom = UDim.new(0, 8)
	padding.PaddingLeft = UDim.new(0, 8)
	padding.PaddingRight = UDim.new(0, 8)
	padding.Parent = section

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 3)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = section

	local header = createRow(section, boardName .. " TOP", Color3.fromRGB(255, 220, 120), 26)
	header.Font = Enum.Font.GothamBlack
	header.TextXAlignment = Enum.TextXAlignment.Center

	local rows = {}
	for i = 1, 5 do
		rows[i] = createRow(section, "#" .. i .. " ...", Color3.fromRGB(238, 242, 255), 24)
	end

	return {header = header, rows = rows}
end

local function resolveLeaderboardPart(context)
	if context and type(context.ResolveWorkspaceObjectFromCandidates) == "function" then
		return context.ResolveWorkspaceObjectFromCandidates(context.BoardPartNames and context.BoardPartNames.Leaderboard)
	end
	if GuiFactory.FindWorkspacePart then
		return GuiFactory.FindWorkspacePart({"LederstartsBoard", "LeaderstartsBoard", "LeaderstatsBoard", "LeaderboardBoard", "LeaderBoard", "Leaderboard"}, 10)
	end
	return nil
end

local function createWorldLeaderboard(context)
	local boardPart = resolveLeaderboardPart(context)
	if not boardPart then
		warn("Leaderboard board part not found")
		return nil
	end

	local surfaceGui = GuiFactory.CreateSurfaceGui(context.playerGui, "LeaderboardBoardSurfaceGui", boardPart, Enum.NormalId.Front, 72)
	local root = GuiFactory.CreateFrame(surfaceGui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = Color3.fromRGB(12, 14, 20),
		backgroundTransparency = 0.02,
		cornerRadius = 18,
	})
	GuiFactory.CreateStroke(root, Color3.fromRGB(255, 220, 120), 2, 0.08)

	GuiFactory.CreateTextLabel(root, {
		name = "Title",
		position = UDim2.fromOffset(16, 10),
		size = UDim2.new(1, -32, 0, 40),
		text = "SERVER LEADERBOARDS",
		textColor3 = Color3.fromRGB(255, 220, 120),
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local content = GuiFactory.CreateFrame(root, {
		name = "Content",
		position = UDim2.fromOffset(12, 58),
		size = UDim2.new(1, -24, 1, -70),
		backgroundTransparency = 1,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = content

	return content
end

function LeaderboardUI.Init(context)
	local parent = createWorldLeaderboard(context)
	if not parent then
		return
	end

	local rowsByBoard = {}
	for _, boardName in ipairs(BOARD_ORDER) do
		rowsByBoard[boardName] = createSection(parent, boardName)
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
