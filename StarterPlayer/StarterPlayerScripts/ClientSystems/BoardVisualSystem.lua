local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientFormatters = require(script.Parent:WaitForChild("ClientFormatters"))
local ClientContext = require(script.Parent:WaitForChild("ClientContext"))

local BoardVisualSystem = {}

local BOARD_THEMES = {
	Coin = {a = Color3.fromRGB(111, 70, 16), b = Color3.fromRGB(45, 27, 5), s = Color3.fromRGB(255, 218, 83)},
	Wood = {a = Color3.fromRGB(46, 91, 42), b = Color3.fromRGB(35, 25, 12), s = Color3.fromRGB(155, 230, 112)},
	Paper = {a = Color3.fromRGB(219, 229, 242), b = Color3.fromRGB(123, 148, 179), s = Color3.fromRGB(181, 222, 255), text = Color3.fromRGB(26, 35, 48)},
	Rebirth = {a = Color3.fromRGB(102, 42, 126), b = Color3.fromRGB(42, 17, 67), s = Color3.fromRGB(255, 149, 235)},
	XP = {a = Color3.fromRGB(45, 72, 150), b = Color3.fromRGB(45, 28, 106), s = Color3.fromRGB(152, 184, 255)},
}

local function findPath(root, path)
	local current = root
	for _, name in ipairs(path) do
		if not current then
			return nil
		end
		current = current:FindFirstChild(name)
	end
	return current
end

local function readValue(root, path, defaultValue)
	local object = findPath(root, path)
	if object and object.Value ~= nil then
		return object.Value
	end
	return defaultValue
end

local function createBoard(context, partName, guiName, themeName, titleText, subtitleText)
	local part = workspace:FindFirstChild(partName)
	if not part then
		warn("Board part not found: " .. partName)
		return nil
	end

	local theme = BOARD_THEMES[themeName] or BOARD_THEMES.Coin
	local surfaceGui = GuiFactory.CreateSurfaceGui(context.playerGui, guiName, part, Enum.NormalId.Front, 72)
	local root = GuiFactory.CreateFrame(surfaceGui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = theme.b,
		cornerRadius = 18,
	})
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(theme.a, theme.b)
	gradient.Rotation = 90
	gradient.Parent = root
	GuiFactory.CreateStroke(root, theme.s, 2, 0.08)

	local padding = Instance.new("UIPadding")
	padding.PaddingTop = UDim.new(0, 16)
	padding.PaddingLeft = UDim.new(0, 18)
	padding.PaddingRight = UDim.new(0, 18)
	padding.PaddingBottom = UDim.new(0, 16)
	padding.Parent = root

	local title = GuiFactory.CreateTextLabel(root, {
		name = "Title",
		size = UDim2.new(1, 0, 0, 42),
		text = titleText,
		textColor3 = theme.text or Color3.fromRGB(255, 245, 210),
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local subtitle = GuiFactory.CreateTextLabel(root, {
		name = "Subtitle",
		position = UDim2.fromOffset(0, 46),
		size = UDim2.new(1, 0, 0, 28),
		text = subtitleText or "",
		textColor3 = theme.text or Color3.fromRGB(230, 235, 255),
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local body = GuiFactory.CreateTextLabel(root, {
		name = "Body",
		position = UDim2.fromOffset(0, 86),
		size = UDim2.new(1, 0, 1, -86),
		text = "Loading...",
		textColor3 = theme.text or Color3.fromRGB(245, 248, 255),
		font = Enum.Font.GothamBold,
		textScaled = true,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Center,
		textYAlignment = Enum.TextYAlignment.Center,
	})

	return {root = root, title = title, subtitle = subtitle, body = body}
end

function BoardVisualSystem.Init(context)
	if not context.data then
		return
	end

	local coinBoard = createBoard(context, "DoskaPart", "CoinsBoardSurfaceGui", "Coin", "COINS", "Основная валюта")
	local rebirthBoard = createBoard(context, "RebirthDoska", "RebirthBoardSurfaceGui", "Rebirth", "REBIRTH", "Сброс ради новых зон")
	local woodBoard = createBoard(context, "TreeDoska", "TreeBoardSurfaceGui", "Wood", "WOOD", "Открывается после 2 rebirth")
	local factoryBoard = createBoard(context, "PaperFactoryDoska", "PaperFactoryBoardSurfaceGui", "Paper", "PAPER FACTORY", "Топливо превращается в бумагу")
	local boostBoard = createBoard(context, "BoostDoska", "BoostBoardSurfaceGui", "XP", "BOOSTS", "Rebirth / XP / Gamepass статус")

	if rebirthBoard then
		local buyRebirthButton = GuiFactory.CreateTextButton(rebirthBoard.root, {
			name = "BuyRebirthButton",
			position = UDim2.new(0.5, -92, 1, -54),
			size = UDim2.fromOffset(184, 38),
			text = "BUY REBIRTH",
			backgroundColor3 = Color3.fromRGB(255, 149, 235),
			textColor3 = Color3.fromRGB(45, 18, 65),
			font = Enum.Font.GothamBlack,
			textScaled = true,
		})
		buyRebirthButton.MouseButton1Click:Connect(function()
			context.purchaseRebirthRemote:FireServer()
		end)
	end

	if factoryBoard then
		local addFuelButton = GuiFactory.CreateTextButton(factoryBoard.root, {
			name = "AddFuelButton",
			position = UDim2.new(0.5, -150, 1, -54),
			size = UDim2.fromOffset(140, 38),
			text = "+1 FUEL",
			backgroundColor3 = Color3.fromRGB(181, 222, 255),
			textColor3 = Color3.fromRGB(26, 35, 48),
			font = Enum.Font.GothamBlack,
			textScaled = true,
		})
		local addMaxButton = GuiFactory.CreateTextButton(factoryBoard.root, {
			name = "AddMaxFuelButton",
			position = UDim2.new(0.5, 10, 1, -54),
			size = UDim2.fromOffset(140, 38),
			text = "MAX FUEL",
			backgroundColor3 = Color3.fromRGB(244, 249, 255),
			textColor3 = Color3.fromRGB(26, 35, 48),
			font = Enum.Font.GothamBlack,
			textScaled = true,
		})
		addFuelButton.MouseButton1Click:Connect(function()
			context.factoryRemote:FireServer("AddFuelOnce")
		end)
		addMaxButton.MouseButton1Click:Connect(function()
			context.factoryRemote:FireServer("AddFuelMax")
		end)
	end

	local function refresh()
		local data = context.data
		if not data then
			return
		end

		local coins = readValue(data, {"Coins"}, 0)
		local wood = readValue(data, {"Wood", "WoodCurrency"}, 0)
		local paper = readValue(data, {"Wood", "PaperFactory", "Paper"}, 0)
		local hay = readValue(data, {"Hay", "HayCurrency"}, 0)
		local xp = readValue(data, {"XP", "XPValue"}, 0)
		local rebirth = readValue(data, {"Rebirth", "Count"}, 0)
		local nextCost = readValue(data, {"Rebirth", "NextCost"}, 0)
		local nextCurrency = readValue(data, {"Rebirth", "NextCurrency"}, "None")

		if coinBoard then
			coinBoard.body.Text = "Coins: " .. ClientFormatters.Compact(coins) .. "\nXP: " .. ClientFormatters.Compact(xp)
		end
		if rebirthBoard then
			rebirthBoard.body.Text = "Rebirths: " .. tostring(rebirth) .. "\nNext: " .. ClientFormatters.Compact(nextCost) .. " " .. tostring(nextCurrency)
		end
		if woodBoard then
			woodBoard.body.Text = "Wood: " .. ClientFormatters.Compact(wood) .. "\nHay: " .. ClientFormatters.Compact(hay)
		end
		if factoryBoard then
			local fuel = readValue(data, {"Wood", "PaperFactory", "Fuel"}, 0)
			local countdown = readValue(data, {"Wood", "PaperFactory", "Countdown"}, 0)
			local running = readValue(data, {"Wood", "PaperFactory", "IsRunning"}, false)
			factoryBoard.body.Text = "Paper: " .. ClientFormatters.Compact(paper) .. "\nFuel: " .. tostring(fuel) .. "\n" .. (running and ("Next in: " .. string.format("%.1fs", tonumber(countdown) or 0)) or "Factory idle")
		end
		if boostBoard then
			local coinMul = readValue(data, {"Rebirth", "CoinMultiplierBonus"}, 1)
			local woodMul = readValue(data, {"Rebirth", "WoodMultiplierBonus"}, 1)
			boostBoard.body.Text = "Coin rebirth x" .. tostring(coinMul) .. "\nWood rebirth x" .. tostring(woodMul) .. "\nXP: " .. ClientFormatters.Compact(xp)
		end
	end

	refresh()
	ClientContext.AddRefresh(context, refresh)
end

return BoardVisualSystem
