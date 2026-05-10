local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientFormatters = require(script.Parent:WaitForChild("ClientFormatters"))
local ClientContext = require(script.Parent:WaitForChild("ClientContext"))

local UpgradeBoardUI = {}

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

local function createSurfaceRoot(context, partName, guiName, titleText, accentColor)
	local part = workspace:FindFirstChild(partName)
	if not part then
		warn("Upgrade board part not found: " .. partName)
		return nil
	end

	local surfaceGui = GuiFactory.CreateSurfaceGui(context.playerGui, guiName, part, Enum.NormalId.Front, 78)
	local root = GuiFactory.CreateFrame(surfaceGui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = Color3.fromRGB(18, 20, 28),
		cornerRadius = 18,
	})
	GuiFactory.CreateStroke(root, accentColor, 2, 0.1)

	local title = GuiFactory.CreateTextLabel(root, {
		name = "Title",
		position = UDim2.fromOffset(16, 10),
		size = UDim2.new(1, -32, 0, 38),
		text = titleText,
		textColor3 = accentColor,
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local list = GuiFactory.CreateFrame(root, {
		name = "List",
		position = UDim2.fromOffset(14, 58),
		size = UDim2.new(1, -28, 1, -72),
		backgroundTransparency = 1,
	})
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.Padding = UDim.new(0, 10)
	layout.Parent = list

	return {root = root, title = title, list = list}
end

local function createCard(parent, cardConfig, accentColor)
	local card = GuiFactory.CreateFrame(parent, {
		name = cardConfig.key .. "Card",
		size = UDim2.new(0, 170, 1, -8),
		backgroundColor3 = Color3.fromRGB(31, 35, 48),
		cornerRadius = 14,
	})
	GuiFactory.CreateStroke(card, accentColor, 1, 0.25)

	local nameLabel = GuiFactory.CreateTextLabel(card, {
		name = "Name",
		position = UDim2.fromOffset(8, 8),
		size = UDim2.new(1, -16, 0, 34),
		text = cardConfig.title,
		textColor3 = accentColor,
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local statusLabel = GuiFactory.CreateTextLabel(card, {
		name = "Status",
		position = UDim2.fromOffset(10, 50),
		size = UDim2.new(1, -20, 0, 76),
		text = "Loading...",
		textColor3 = Color3.fromRGB(235, 240, 255),
		font = Enum.Font.GothamBold,
		textScaled = true,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local buyButton = GuiFactory.CreateTextButton(card, {
		name = "BuyButton",
		position = UDim2.new(0, 10, 1, -76),
		size = UDim2.new(1, -20, 0, 30),
		text = "BUY",
		backgroundColor3 = accentColor,
		textColor3 = Color3.fromRGB(20, 24, 34),
		font = Enum.Font.GothamBlack,
		textScaled = true,
	})

	local maxButton = GuiFactory.CreateTextButton(card, {
		name = "MaxButton",
		position = UDim2.new(0, 10, 1, -38),
		size = UDim2.new(1, -20, 0, 28),
		text = "MAX",
		backgroundColor3 = Color3.fromRGB(245, 245, 255),
		textColor3 = Color3.fromRGB(20, 24, 34),
		font = Enum.Font.GothamBlack,
		textScaled = true,
	})

	return {
		nameLabel = nameLabel,
		statusLabel = statusLabel,
		buyButton = buyButton,
		maxButton = maxButton,
		config = cardConfig,
	}
end

local function setButtonState(button, enabled)
	button.Active = enabled
	button.AutoButtonColor = enabled
	button.BackgroundTransparency = enabled and 0 or 0.45
end

local function bindPurchase(context, card, boardConfig)
	if boardConfig.remote == "RuneAction" then
		card.buyButton.MouseButton1Click:Connect(function()
			context.runeRemote:FireServer(card.config.buyAction)
		end)
		card.maxButton.MouseButton1Click:Connect(function()
			context.runeRemote:FireServer(card.config.maxAction)
		end)
		return
	end

	card.buyButton.MouseButton1Click:Connect(function()
		context.purchaseUpgradeRemote:FireServer(boardConfig.family, card.config.key, "Buy")
	end)
	card.maxButton.MouseButton1Click:Connect(function()
		context.purchaseUpgradeRemote:FireServer(boardConfig.family, card.config.key, "Max")
	end)
end

local BOARD_CONFIGS = {
	{
		partName = "UpgradeDoska",
		guiName = "UpgradeBoardSurfaceGui",
		title = "COIN UPGRADES",
		family = "Coin",
		currencyPath = {"Coins"},
		folderPath = {"CoinUpgrades"},
		accent = Color3.fromRGB(255, 218, 83),
		cards = {
			{key = "CoinValue", title = "Coin Gain", levelName = "CoinValueLevel", costName = "CoinValueCost", activeName = "CoinValueActive", maxLevel = math.huge},
			{key = "Multiplier", title = "Multiplier", levelName = "MultiplierLevel", costName = "MultiplierCost", activeName = "MultiplierActive", maxLevel = math.huge},
			{key = "SpawnSpeed", title = "Spawn", levelName = "SpawnSpeedLevel", costName = "SpawnSpeedCost", activeName = "SpawnSpeedActive", maxLevel = 3},
			{key = "WoodBoost", title = "Wood Boost", levelName = "WoodBoostLevel", costName = "WoodBoostCost", activeName = "WoodBoostActive", maxLevel = 10},
		},
	},
	{
		partName = "TreeUpgradeDoska",
		guiName = "TreeUpgradeBoardSurfaceGui",
		title = "WOOD UPGRADES",
		family = "Wood",
		currencyPath = {"Wood", "WoodCurrency"},
		folderPath = {"Wood", "WoodUpgrades"},
		accent = Color3.fromRGB(155, 230, 112),
		cards = {
			{key = "WoodValue", title = "Wood Gain", levelName = "WoodValueLevel", costName = "WoodValueCost", activeName = "WoodValueActive", maxLevel = math.huge},
			{key = "WoodMultiplier", title = "Wood Multi", levelName = "WoodMultiplierLevel", costName = "WoodMultiplierCost", activeName = "WoodMultiplierActive", maxLevel = math.huge},
			{key = "WoodSpeed", title = "Wood Speed", levelName = "WoodSpeedLevel", costName = "WoodSpeedCost", activeName = "WoodSpeedActive", maxLevel = math.huge},
			{key = "CoinBoost", title = "Coin Boost", levelName = "CoinBoostLevel", costName = "CoinBoostCost", activeName = "CoinBoostActive", maxLevel = 20},
		},
	},
	{
		partName = "PaperUpgradeDoska",
		guiName = "PaperUpgradeBoardSurfaceGui",
		title = "PAPER UPGRADES",
		family = "Paper",
		currencyPath = {"Wood", "PaperFactory", "Paper"},
		folderPath = {"Wood", "PaperUpgrades"},
		accent = Color3.fromRGB(181, 222, 255),
		cards = {
			{key = "PaperValue", title = "Paper Gain", levelName = "PaperValueLevel", costName = "PaperValueCost", activeName = "PaperValueActive", maxLevel = math.huge},
			{key = "PaperMultiplier", title = "Paper Multi", levelName = "PaperMultiplierLevel", costName = "PaperMultiplierCost", activeName = "PaperMultiplierActive", maxLevel = math.huge},
			{key = "PaperSpeed", title = "Paper Speed", levelName = "PaperSpeedLevel", costName = "PaperSpeedCost", activeName = "PaperSpeedActive", maxLevel = 10},
		},
	},
	{
		partName = "HayUpgradeBoard",
		guiName = "HayUpgradeBoardSurfaceGui",
		title = "HAY UPGRADES",
		family = "Hay",
		currencyPath = {"Hay", "HayCurrency"},
		folderPath = {"Hay", "HayUpgrades"},
		accent = Color3.fromRGB(255, 220, 116),
		cards = {
			{key = "HayAmount", title = "Hay Amount", levelName = "HayAmountLevel", costName = "HayAmountCost", activeName = "HayAmountLevelActive", maxLevel = 250},
			{key = "HayMultiplier", title = "Hay Multi", levelName = "HayMultiplierLevel", costName = "HayMultiplierCost", activeName = "HayMultiplierLevelActive", maxLevel = 50},
			{key = "HayCooldown", title = "Cooldown", levelName = "HayCooldownLevel", costName = "HayCooldownCost", activeName = "HayCooldownLevelActive", maxLevel = 25},
		},
	},
	{
		partName = "XPUpgradeDoska",
		guiName = "XPUpgradeBoardSurfaceGui",
		title = "XP UPGRADES",
		family = "XP",
		currencyPath = {"XP", "XPValue"},
		folderPath = {"XP", "XPUpgrades"},
		accent = Color3.fromRGB(152, 184, 255),
		cards = {
			{key = "CoinXP", title = "Coin XP", levelName = "CoinXPLevel", costName = "CoinXPCost", maxLevel = 10},
			{key = "WoodXP", title = "Wood XP", levelName = "WoodXPLevel", costName = "WoodXPCost", maxLevel = 10},
			{key = "PaperXP", title = "Paper XP", levelName = "PaperXPLevel", costName = "PaperXPCost", maxLevel = 10},
			{key = "XPMultiplier", title = "XP Multi", levelName = "XPMultiplierLevel", costName = "XPMultiplierCost", maxLevel = 5},
			{key = "RuneLuckXP", title = "Rune Luck", levelName = "RuneLuckXPLevel", costName = "RuneLuckXPCost", maxLevel = 3},
			{key = "RuneBulkXP", title = "Rune Bulk", levelName = "RuneBulkXPLevel", costName = "RuneBulkXPCost", maxLevel = 5},
			{key = "RuneSpeedXP", title = "Rune Speed", levelName = "RuneSpeedXPLevel", costName = "RuneSpeedXPCost", maxLevel = 2},
		},
	},
	{
		partName = "RuneUpgradeDoska",
		guiName = "RuneUpgradeBoardSurfaceGui",
		title = "RUNE UPGRADES",
		remote = "RuneAction",
		currencyPath = {"Coins"},
		folderPath = {"Runes", "Upgrades"},
		accent = Color3.fromRGB(166, 255, 115),
		cards = {
			{key = "RuneLuck", title = "Rune Luck", levelName = "RuneLuckLevel", costName = "RuneLuckCost", maxLevel = 4, buyAction = "UpgradeLuck", maxAction = "UpgradeLuckMax"},
			{key = "RuneSpeed", title = "Rune Speed", levelName = "RuneSpeedLevel", costName = "RuneSpeedCost", maxLevel = 5, buyAction = "UpgradeSpeed", maxAction = "UpgradeSpeedMax"},
			{key = "RuneBulk", title = "Rune Bulk", levelName = "RuneBulkLevel", costName = "RuneBulkCost", maxLevel = 5, buyAction = "UpgradeBulk", maxAction = "UpgradeBulkMax"},
		},
	},
}

function UpgradeBoardUI.Init(context)
	if not context.data then
		return
	end

	local createdBoards = {}
	for _, boardConfig in ipairs(BOARD_CONFIGS) do
		local surface = createSurfaceRoot(context, boardConfig.partName, boardConfig.guiName, boardConfig.title, boardConfig.accent)
		if surface then
			local cards = {}
			for _, cardConfig in ipairs(boardConfig.cards) do
				local card = createCard(surface.list, cardConfig, boardConfig.accent)
				cards[#cards + 1] = card
				bindPurchase(context, card, boardConfig)
			end
			createdBoards[#createdBoards + 1] = {config = boardConfig, cards = cards}
		end
	end

	local function refresh()
		for _, board in ipairs(createdBoards) do
			local data = context.data
			local folder = findPath(data, board.config.folderPath)
			local currency = readValue(data, board.config.currencyPath, 0)
			for _, card in ipairs(board.cards) do
				local cfg = card.config
				local level = folder and readValue(folder, {cfg.levelName}, 0) or 0
				local cost = folder and readValue(folder, {cfg.costName}, 0) or 0
				local active = cfg.activeName == nil and true or readValue(folder, {cfg.activeName}, false)
				local maxText = cfg.maxLevel == math.huge and "∞" or tostring(cfg.maxLevel)
				local atMax = cfg.maxLevel ~= math.huge and level >= cfg.maxLevel
				local canBuy = active and not atMax and currency >= cost
				card.statusLabel.Text = "Lv " .. tostring(level) .. "/" .. maxText .. "\nCost: " .. ClientFormatters.Compact(cost) .. "\nHave: " .. ClientFormatters.Compact(currency)
				if atMax then
					card.statusLabel.Text = "Lv " .. tostring(level) .. "/" .. maxText .. "\nMAX"
				elseif not active then
					card.statusLabel.Text = card.statusLabel.Text .. "\nLOCKED"
				end
				setButtonState(card.buyButton, canBuy or active)
				setButtonState(card.maxButton, active and not atMax)
			end
		end
	end

	refresh()
	ClientContext.AddRefresh(context, refresh)
end

return UpgradeBoardUI
