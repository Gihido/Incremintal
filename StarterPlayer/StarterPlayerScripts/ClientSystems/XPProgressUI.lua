local GuiFactory = require(script.Parent:WaitForChild("GuiFactory"))
local ClientFormatters = require(script.Parent:WaitForChild("ClientFormatters"))
local ClientContext = require(script.Parent:WaitForChild("ClientContext"))

local XPProgressUI = {}

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

function XPProgressUI.Init(context)
	if not context.data then
		return
	end

	local part = workspace:FindFirstChild("XPProgressDoska")
	if not part then
		warn("XP progress board part not found: XPProgressDoska")
		return
	end

	local surfaceGui = GuiFactory.CreateSurfaceGui(context.playerGui, "XPProgressBoardSurfaceGui", part, Enum.NormalId.Front, 78)
	local root = GuiFactory.CreateFrame(surfaceGui, {
		name = "Root",
		size = UDim2.fromScale(1, 1),
		backgroundColor3 = Color3.fromRGB(24, 29, 55),
		cornerRadius = 18,
	})
	GuiFactory.CreateStroke(root, Color3.fromRGB(152, 184, 255), 2, 0.1)

	local title = GuiFactory.CreateTextLabel(root, {
		name = "Title",
		position = UDim2.fromOffset(16, 12),
		size = UDim2.new(1, -32, 0, 44),
		text = "XP PROGRESS",
		textColor3 = Color3.fromRGB(152, 184, 255),
		font = Enum.Font.GothamBlack,
		textScaled = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local status = GuiFactory.CreateTextLabel(root, {
		name = "Status",
		position = UDim2.fromOffset(24, 70),
		size = UDim2.new(1, -48, 0, 110),
		text = "Loading...",
		textColor3 = Color3.fromRGB(235, 242, 255),
		font = Enum.Font.GothamBold,
		textScaled = true,
		textWrapped = true,
		textXAlignment = Enum.TextXAlignment.Center,
	})

	local buyButton = GuiFactory.CreateTextButton(root, {
		name = "BuyXPBoostButton",
		position = UDim2.new(0.5, -105, 1, -58),
		size = UDim2.fromOffset(210, 40),
		text = "BUY XP BOOST",
		backgroundColor3 = Color3.fromRGB(152, 184, 255),
		textColor3 = Color3.fromRGB(20, 24, 40),
		font = Enum.Font.GothamBlack,
		textScaled = true,
	})
	buyButton.MouseButton1Click:Connect(function()
		context.xpRemote:FireServer("BuyXPBoost")
	end)

	local function refresh()
		local data = context.data
		local xp = readValue(data, {"XP", "XPValue"}, 0)
		local level = readValue(data, {"XP", "XPBoost", "Level"}, 0)
		local cost = readValue(data, {"XP", "XPBoost", "NextCost"}, 10)
		local unlocked = readValue(data, {"Rebirth", "SecondAreaUnlocked"}, false)
		local atMax = level >= 10
		status.Text = "XP: " .. ClientFormatters.Compact(xp) .. "\nBoost Level: " .. tostring(level) .. "/10\nNext Cost: " .. ClientFormatters.Compact(cost)
		if not unlocked then
			status.Text = status.Text .. "\nUnlocks after 2 rebirths"
		elseif atMax then
			status.Text = status.Text .. "\nMAX"
		end
		buyButton.Active = unlocked and not atMax
		buyButton.AutoButtonColor = unlocked and not atMax
		buyButton.BackgroundTransparency = (unlocked and not atMax) and 0 or 0.45
	end

	refresh()
	ClientContext.AddRefresh(context, refresh)
end

return XPProgressUI
